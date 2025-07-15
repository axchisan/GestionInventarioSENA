import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';
import '../../data/models/auth_models.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const _storage = FlutterSecureStorage();

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiService.post(loginEndpoint, request.toJson());
    final token = response['access_token'] as String;
    final role = response['role'] as String;
    await _storage.write(key: 'access_token', value: token);
    await _storage.write(key: 'role', value: role);
    return AuthResponse(token: token, role: role);
  }

  Future<void> register(RegisterRequest request) async {
    await _apiService.post(registerEndpoint, request.toJson());
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'role');
  }

  Future<String?> getToken() async => await _storage.read(key: 'access_token');
  Future<String?> getRole() async => await _storage.read(key: 'role');
}