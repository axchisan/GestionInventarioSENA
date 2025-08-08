import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_constants.dart' as APIConstants;
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

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}${APIConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Response data: $data"); // Depuración
        if (data.containsKey('access_token') && data.containsKey('user')) {
          _token = data['access_token'];
          print("User data: ${data['user']}"); // Depuración
          _currentUser = UserModel.fromJson(
            data['user'] as Map<String, dynamic>,
          );
          _isAuthenticated = true;

          // Guardar en SessionService con manejo de null
          await SessionService.saveSession(
            token: _token!,
            role: _currentUser!.role ?? 'unknown', // Manejo de null
            user: data['user'] as Map<String, dynamic>,
            expiresAt: DateTime.now().millisecondsSinceEpoch + (30 * 60 * 1000),
          );
        } else {
          _errorMessage = 'Respuesta del servidor inválida: $data';
        }
      } else {
        _errorMessage = 'Credenciales inválidas: ${response.body}';
      }
    } catch (e, stack) {
      _errorMessage = 'Error al iniciar sesión: $e';
      print("Error details: $e\nStack trace: $stack"); // Depuración completa
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
        Uri.parse('${APIConstants.baseUrl}${APIConstants.registerEndpoint}'),
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
        _errorMessage = 'Error en el registro: ${response.body}';
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
    if (await SessionService.hasValidSession()) {
      final userData = await SessionService.getUser();
      if (userData != null) {
        _currentUser = UserModel.fromJson(userData);
        _token = await SessionService.getAccessToken();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }
}
