import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'session_service.dart';

class NotificationService {
  static const String _notificationsEndpoint = '/api/notifications/';

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl$_notificationsEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  static Future<bool> markAsRead(String notificationId) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('$baseUrl$_notificationsEndpoint$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_read': true}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<void> createVerificationNotification({
    required String userId,
    required String environmentName,
    required String scheduleTime,
    required String type,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) return;

      String title, message;
      switch (type) {
        case 'verification_pending':
          title = 'Verificación Pendiente';
          message = 'Tienes una verificación de inventario pendiente en $environmentName para el horario $scheduleTime';
          break;
        case 'verification_update':
          title = 'Verificación Actualizada';
          message = 'La verificación de inventario en $environmentName ha sido actualizada';
          break;
        case 'maintenance_update':
          title = 'Solicitud de Mantenimiento';
          message = 'Se ha creado una nueva solicitud de mantenimiento';
          break;
        default:
          return;
      }

      await http.post(
        Uri.parse('$baseUrl$_notificationsEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'type': type,
          'title': title,
          'message': message,
          'priority': type == 'verification_pending' ? 'high' : 'medium',
        }),
      );
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  static Future<void> createLoanNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    required String priority,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$baseUrl$_notificationsEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'type': type,
          'title': title,
          'message': message,
          'priority': priority,
        }),
      );
    } catch (e) {
      print('Error creating loan notification: $e');
    }
  }

  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !(n['is_read'] ?? false)).length;
  }
}
