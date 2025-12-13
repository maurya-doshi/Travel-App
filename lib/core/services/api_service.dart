import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (e) {
    }
    return 'http://127.0.0.1:3000';
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    debugPrint('API POST: $_baseUrl$endpoint');
    debugPrint('API POST body: $body');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      debugPrint('API POST response: ${response.statusCode} - ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API POST error: $e');
      throw Exception('Failed to connect to backend: $e');
    }
  }


  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
        // No body usually for delete
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
