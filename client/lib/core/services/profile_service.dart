import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../data/models/user_model.dart';

class ProfileService {
  final String? token;

  ProfileService({required this.token});

  Future<UserModel> getCurrentUser() async {
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$getUserEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Error al obtener datos del usuario');
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? program,
    String? ficha,
    String? avatarUrl,
  }) async {
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final Map<String, dynamic> updateData = {};
    if (firstName != null) updateData['first_name'] = firstName;
    if (lastName != null) updateData['last_name'] = lastName;
    if (phone != null) updateData['phone'] = phone;
    if (program != null) updateData['program'] = program;
    if (ficha != null) updateData['ficha'] = ficha;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    final response = await http.put(
      Uri.parse('$baseUrl$getUserEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserModel.fromJson(data);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al actualizar perfil');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/me/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al cambiar contraseña');
    }
  }
}
