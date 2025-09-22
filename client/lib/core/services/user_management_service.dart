import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/user_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../constants/api_constants.dart' as ApiConfig;

class UserManagementService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/users';
  final AuthProvider _authProvider = AuthProvider();

  Future<List<UserModel>> getUsers({
    int skip = 0,
    int limit = 100,
    String? role,
    bool? isActive,
    String? search,
  }) async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      
      if (role != null) queryParams['role'] = role;
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al crear usuario');
      }
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.put(
        Uri.parse('$_baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.delete(
        Uri.parse('$_baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.post(
        Uri.parse('$_baseUrl/$userId/activate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al activar usuario');
      }
    } catch (e) {
      throw Exception('Error al activar usuario: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final token = _authProvider.token; // Changed from getAccessToken()
      if (token == null) throw Exception('No hay token de autenticación');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/stats/admin-dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al obtener estadísticas del dashboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas del dashboard: $e');
    }
  }
}