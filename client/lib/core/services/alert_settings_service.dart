import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/alert_settings_model.dart';
import '../constants/api_constants.dart' as ApiConfig;
import 'session_service.dart';

class AlertSettingsService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/api/alert-settings/';

  static Future<List<AlertSettingsModel>> getUserAlertSettings() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.get(
        Uri.parse('api/alert-settings/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AlertSettingsModel.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener configuraciones de alertas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getUserAlertSettings: $e');
      throw Exception('Error al obtener configuraciones de alertas: $e');
    }
  }

  static Future<AlertSettingsModel> createAlertSetting({
    required String alertType,
    required bool isEnabled,
    int? thresholdValue,
    List<String>? notificationMethods,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final body = {
        'alert_type': alertType,
        'is_enabled': isEnabled,
        if (thresholdValue != null) 'threshold_value': thresholdValue,
        if (notificationMethods != null) 'notification_methods': notificationMethods,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return AlertSettingsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear configuración de alerta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createAlertSetting: $e');
      throw Exception('Error al crear configuración de alerta: $e');
    }
  }

  static Future<AlertSettingsModel> updateAlertSetting({
    required String settingId,
    bool? isEnabled,
    int? thresholdValue,
    List<String>? notificationMethods,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final body = <String, dynamic>{};
      if (isEnabled != null) body['is_enabled'] = isEnabled;
      if (thresholdValue != null) body['threshold_value'] = thresholdValue;
      if (notificationMethods != null) body['notification_methods'] = notificationMethods;

      final response = await http.put(
        Uri.parse('$_baseUrl/$settingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return AlertSettingsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar configuración de alerta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateAlertSetting: $e');
      throw Exception('Error al actualizar configuración de alerta: $e');
    }
  }

  static Future<bool> deleteAlertSetting(String settingId) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/$settingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in deleteAlertSetting: $e');
      return false;
    }
  }
}
