import 'dart:convert';
import 'package:http/http.dart' as http;

class CityService {
  static final CityService _instance = CityService._internal();
  factory CityService() => _instance;
  CityService._internal();

  List<String>? _cachedCities;
  DateTime? _lastFetchTime;

  // Rate limiting: Cache for 1 hour
  static const Duration _cacheDuration = Duration(hours: 1);

  Future<List<String>> getIndianCities() async {
    // Return cache if valid
    if (_cachedCities != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedCities!;
    }

    try {
      final response = await http.get(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/cities/q?country=india'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false) {
          final List<dynamic> citiesJson = data['data'];
          _cachedCities = citiesJson.cast<String>().toList();
          _cachedCities?.sort(); // Sort alphabetically
          _lastFetchTime = DateTime.now();
          return _cachedCities!;
        }
      }
      throw Exception('Failed to load cities: ${response.statusCode}');
    } catch (e) {
      // Fallback or rethrow - for now we return empty list so UI can show constants
      print('City Fetch Error: $e');
      return [];
    }
  }
}
