import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();
  final AuthProvider? _authProvider;

  ApiService({AuthProvider? authProvider}) : _authProvider = authProvider;

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        return await post(redirectUrl.replaceFirst(baseUrl, ''), data);
      }
    }

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

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        return await get(redirectUrl.replaceFirst(baseUrl, ''), queryParams: queryParams);
      }
    }

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

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        return await getSingle(redirectUrl.replaceFirst(baseUrl, ''));
      }
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  // Nuevo método para DELETE
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.token != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.token}';
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await _client.delete(
      uri,
      headers: headers,
    );

    if (response.statusCode == 307 || response.statusCode == 301 || response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        return await delete(redirectUrl.replaceFirst(baseUrl, ''));
      }
    }

    if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content para deletes comunes
      return response.body.isNotEmpty ? json.decode(response.body) : {'status': 'success'};
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  void dispose() => _client.close();
}