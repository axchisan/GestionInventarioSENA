import 'dart:convert';
import 'package:client/core/constants/api_constants.dart' as APIConstants;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
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
        if (data.containsKey('access_token')) {
          _token = data['access_token'];
          await _fetchCurrentUser();
          _isAuthenticated = true;
        } else {
          _errorMessage = 'Respuesta del servidor inválida';
        }
      } else {
        _errorMessage = 'Credenciales inválidas. Código: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCurrentUser() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${APIConstants.baseUrl}${APIConstants.getUserEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel.fromJson(data);
      } else {
        _errorMessage = 'Error al obtener datos del usuario: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error al obtener datos del usuario: $e';
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName, // Cambiado a required
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
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
          'phone': phone,
          'program': program,
        }),
      );

      if (response.statusCode == 201) {
        _errorMessage = 'Registro exitoso. Espera la aprobación del administrador.';
      } else {
        _errorMessage = 'Error en el registro: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error al registrarse: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}