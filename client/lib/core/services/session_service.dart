import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionService {
  static const String _kTokenKey = 'auth_token';
  static const String _kRoleKey = 'user_role';
  static const String _kUserKey = 'user_data';
  static const String _kExpiresAtKey = 'token_expires_at';

  static Future<void> saveSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
    required int expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
    await prefs.setString(_kRoleKey, role);
    await prefs.setString(_kUserKey, jsonEncode(user));
    await prefs.setInt(_kExpiresAtKey, expiresAt);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    await prefs.remove(_kRoleKey);
    await prefs.remove(_kUserKey);
    await prefs.remove(_kExpiresAtKey);
  }

  static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    if (token == null || token.isEmpty) return false;

    final isExpired = JwtDecoder.isExpired(token);
    if (isExpired) {
      await clear();
      return false;
    }
    return true;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRoleKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_kUserKey);
    return userJson != null ? jsonDecode(userJson) : null;
  }

  static Future<int?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kExpiresAtKey);
  }
}