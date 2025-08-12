import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';


class ApiService {
  final http.Client _client = http.Client();
  final AuthProvider? _authProvider; // Inyectar AuthProvider

  ApiService({AuthProvider? authProvider}) : _authProvider = authProvider;

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Agregar el token de autorización si está disponible
    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Agregar el token de autorización si está disponible
    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSingle(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Agregar el token de autorización si está disponible
    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  void dispose() => _client.close();
}