import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'session_service.dart';

class MaintenanceService {
  static const String _maintenanceEndpoint = '/api/maintenance-requests/';

  static Future<bool> createMaintenanceRequest({
    String? itemId,
    required String environmentId,
    required String type,
    required String priority,
    required String description,
    String? category,
    String? location,
    String? itemName,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final requestBody = {
        'title': itemName ?? 'Solicitud de mantenimiento $type',
        'description': description,
        'priority': priority.toLowerCase(),
        'environment_id': environmentId,
      };

      if (itemId != null) {
        requestBody['item_id'] = itemId;
      }
      
      if (category != null) {
        requestBody['category'] = category;
      }
      
      if (location != null) {
        requestBody['location'] = location;
      }

      final response = await http.post(
        Uri.parse('$baseUrl$_maintenanceEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating maintenance request: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMaintenanceRequests() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl$_maintenanceEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load maintenance requests');
      }
    } catch (e) {
      print('Error getting maintenance requests: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getInventoryItems(String environmentId) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl$inventoryEndpoint?environment_id=$environmentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load inventory items');
      }
    } catch (e) {
      print('Error getting inventory items: $e');
      return [];
    }
  }
}
