import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpSafetyRepository {
  final String baseUrl;

  HttpSafetyRepository({this.baseUrl = 'http://localhost:3000'});

  Future<void> sendSosSignal({
    required String userId,
    required double lat,
    required double lng,
    required String type, // 'emergency' or 'uncomfortable'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/safety/alert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'latitude': lat,
          'longitude': lng,
          'type': type,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send SOS: ${response.body}');
      }
    } catch (e) {
      print('Error sending SOS: $e');
      rethrow;
    }
  }
}
