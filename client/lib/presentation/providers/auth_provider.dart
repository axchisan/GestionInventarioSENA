import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/session_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkSession();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access_token') && data.containsKey('user')) {
          _token = data['access_token'];
          _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          _isAuthenticated = true;

          final expiresAt = JwtDecoder.decode(_token!)['exp'] * 1000;
          await SessionService.saveSession(
            token: _token!,
            role: _currentUser!.role ?? 'unknown',
            user: data['user'] as Map<String, dynamic>,
            expiresAt: expiresAt,
          );
        } else {
          _errorMessage = 'Respuesta del servidor inválida.';
        }
      } else {
        _errorMessage = 'Credenciales inválidas.';
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String role,
    String? program,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'phone': phone,
          'program': program,
        }),
      );

      if (response.statusCode == 201) {
        _errorMessage = 'Registro exitoso. Por favor, inicia sesión.';
      } else {
        _errorMessage = 'Error en el registro.';
      }
    } catch (e) {
      _errorMessage = 'Error al registrarse: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SessionService.clear();
    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    try {
      final hasValidSession = await SessionService.hasValidSession();
      if (hasValidSession) {
        final token = await SessionService.getAccessToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          if (response.statusCode == 200) {
            final updatedUserData = jsonDecode(response.body);
            _currentUser = UserModel.fromJson(updatedUserData);
            _token = token;
            _isAuthenticated = true;

            final expiresAt = JwtDecoder.decode(token)['exp'] * 1000;
            await SessionService.saveSession(
              token: token,
              role: _currentUser!.role ?? 'unknown',
              user: updatedUserData,
              expiresAt: expiresAt,
            );
            notifyListeners();
            return true;
          }
        }
      }
      _currentUser = null;
      _token = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } catch (e) {
      _currentUser = null;
      _token = null;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }
}