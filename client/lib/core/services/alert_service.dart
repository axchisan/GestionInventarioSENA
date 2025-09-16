import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'session_service.dart';
import '../../data/models/alert_model.dart';
import '../../data/models/inventory_check_item_model.dart';
import '../../data/models/notification_model.dart';
import 'notification_service.dart';

class AlertService {
  
  /// Get all system alerts with optional filters
  static Future<List<AlertModel>> getSystemAlerts({
    String? type,
    String? severity,
    bool? isResolved,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (severity != null) queryParams['severity'] = severity;
      if (isResolved != null) queryParams['is_resolved'] = isResolved.toString();

      final uri = Uri.parse('$baseUrl$systemAlertsEndpoint')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AlertModel.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('System alerts endpoint not found, returning empty list');
        return [];
      } else {
        throw Exception('Failed to load system alerts: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error getting system alerts: $e');
      return [];
    } on FormatException catch (e) {
      print('JSON parsing error getting system alerts: $e');
      return [];
    } catch (e) {
      print('Error getting system alerts: $e');
      return [];
    }
  }

  /// Get maintenance-related notifications
  static Future<List<NotificationModel>> getMaintenanceNotifications() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final uri = Uri.parse('$baseUrl$notificationsEndpoint')
          .replace(queryParameters: {'type': 'maintenance_request,maintenance_update'});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .where((json) => json != null)
            .map((json) {
              try {
                return NotificationModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing notification: $e, data: $json');
                return null;
              }
            })
            .where((notification) => notification != null)
            .cast<NotificationModel>() // Added explicit cast to remove nulls
            .toList();
      } else if (response.statusCode == 404) {
        print('Notification filtering not supported, getting all notifications');
        return await _getAllNotifications();
      } else {
        throw Exception('Failed to load maintenance notifications: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error getting maintenance notifications: $e');
      return [];
    } on FormatException catch (e) {
      print('JSON parsing error getting maintenance notifications: $e');
      return [];
    } catch (e) {
      print('Error getting maintenance notifications: $e');
      return [];
    }
  }

  static Future<List<NotificationModel>> _getAllNotifications() async {
    try {
      final allNotifications = await NotificationService.getNotifications();
      return allNotifications
          .map((json) {
            try {
              final notification = NotificationModel.fromJson(json);
              return notification.isMaintenanceRelated ? notification : null;
            } catch (e) {
              print('Error parsing notification in _getAllNotifications: $e');
              return null;
            }
          })
          .where((notification) => notification != null)
          .cast<NotificationModel>() // Added explicit cast to remove nulls
          .toList();
    } catch (e) {
      print('Error getting all notifications: $e');
      return [];
    }
  }

  /// Get inventory issues from inventory checks with problems
  static Future<List<InventoryCheckItemModel>> getInventoryCheckItems({
    String? environmentId,
    String? status,
    bool? hasIssues,
  }) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      Map<String, String> queryParams = {};
      if (environmentId != null) queryParams['environment_id'] = environmentId;
      if (hasIssues == true) {
        queryParams['status'] = 'issues'; // Filter for checks with issues
      }

      final uri = Uri.parse('$baseUrl/api/inventory-checks/')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<InventoryCheckItemModel> items = [];
        for (var checkData in data) {
          if (checkData != null && checkData is Map<String, dynamic>) {
            try {
              // Create synthetic inventory check items from inventory checks with issues
              if (checkData['status'] == 'issues') {
                final itemsDamaged = checkData['items_damaged'] ?? 0;
                final itemsMissing = checkData['items_missing'] ?? 0;
                
                if (itemsDamaged > 0 || itemsMissing > 0) {
                  items.add(InventoryCheckItemModel(
                    id: checkData['id'] ?? '',
                    itemId: checkData['environment_id'] ?? '',
                    environmentId: checkData['environment_id'] ?? '',
                    userId: checkData['student_id'],
                    status: itemsDamaged > 0 ? 'damaged' : 'missing',
                    quantityExpected: checkData['total_items'] ?? 0,
                    quantityFound: checkData['items_good'] ?? 0,
                    quantityDamaged: itemsDamaged,
                    quantityMissing: itemsMissing,
                    notes: checkData['instructor_comments'] ?? checkData['supervisor_comments'],
                    createdAt: DateTime.tryParse(checkData['created_at'] ?? '') ?? DateTime.now(),
                    updatedAt: DateTime.tryParse(checkData['updated_at'] ?? '') ?? DateTime.now(),
                  ));
                }
              }
            } catch (e) {
              print('Error parsing inventory check: $e');
            }
          }
        }
        return items;
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        print('Inventory checks endpoint not available, returning empty list');
        return [];
      } else {
        throw Exception('Failed to load inventory check items: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('Network error getting inventory check items: $e');
      return [];
    } on FormatException catch (e) {
      print('JSON parsing error getting inventory check items: $e');
      return [];
    } catch (e) {
      print('Error getting inventory check items: $e');
      return [];
    }
  }

  /// Mark system alert as resolved
  static Future<bool> resolveAlert(String alertId) async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) throw Exception('No token found');

      final response = await http.put(
        Uri.parse('$baseUrl$systemAlertsEndpoint$alertId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'is_resolved': true}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } on http.ClientException catch (e) {
      print('Network error resolving alert: $e');
      return false;
    } catch (e) {
      print('Error resolving alert: $e');
      return false;
    }
  }

  /// Get combined alerts data for the alerts screen
  static Future<Map<String, dynamic>> getCombinedAlertsData() async {
    try {
      final results = await Future.wait([
        getSystemAlerts(isResolved: false).catchError((e) {
          print('Error getting system alerts: $e');
          return <AlertModel>[];
        }),
        getMaintenanceNotifications().catchError((e) {
          print('Error getting maintenance notifications: $e');
          return <NotificationModel>[];
        }),
        getInventoryCheckItems(hasIssues: true).catchError((e) {
          print('Error getting inventory issues: $e');
          return <InventoryCheckItemModel>[];
        }),
      ]);

      final systemAlerts = results[0] as List<AlertModel>;
      final maintenanceNotifications = results[1] as List<NotificationModel>;
      final inventoryIssues = results[2] as List<InventoryCheckItemModel>;

      return {
        'systemAlerts': systemAlerts,
        'maintenanceNotifications': maintenanceNotifications,
        'inventoryIssues': inventoryIssues,
        'totalUnresolved': systemAlerts.length + 
                          maintenanceNotifications.where((n) => !n.isRead).length +
                          inventoryIssues.length,
      };
    } catch (e) {
      print('Error getting combined alerts data: $e');
      return {
        'systemAlerts': <AlertModel>[],
        'maintenanceNotifications': <NotificationModel>[],
        'inventoryIssues': <InventoryCheckItemModel>[],
        'totalUnresolved': 0,
      };
    }
  }

  /// Update alert configuration (for the configuration tab)
  static Future<bool> updateAlertConfiguration({
    required String type,
    required bool enabled,
    required int threshold,
  }) async {
    try {
      // This could be stored locally or the endpoint could be implemented later
      print('Alert configuration update simulated for type: $type, enabled: $enabled, threshold: $threshold');
      return true;
    } catch (e) {
      print('Error updating alert configuration: $e');
      return false;
    }
  }

  /// Get alert configurations
  static Future<List<Map<String, dynamic>>> getAlertConfigurations() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) {
        print('No token found, using default configurations');
        return _getDefaultConfigurations();
      }

      // Alert configurations endpoint not found, using defaults
      print('Alert configurations endpoint not found, using defaults');
      return _getDefaultConfigurations();
    } catch (e) {
      print('Error getting alert configurations: $e');
      return _getDefaultConfigurations();
    }
  }

  static List<Map<String, dynamic>> _getDefaultConfigurations() {
    return [
      {
        'type': 'Stock Bajo',
        'enabled': true,
        'threshold': 5,
        'description': 'Alertar cuando el stock sea menor a',
      },
      {
        'type': 'Mantenimiento',
        'enabled': true,
        'threshold': 7,
        'description': 'Alertar con días de anticipación',
      },
      {
        'type': 'Préstamos Vencidos',
        'enabled': true,
        'threshold': 1,
        'description': 'Alertar después de días de retraso',
      },
      {
        'type': 'Calibración',
        'enabled': false,
        'threshold': 30,
        'description': 'Alertar con días de anticipación',
      },
    ];
  }

  static Future<bool> testApiConnectivity() async {
    try {
      final token = await SessionService.getAccessToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl$notificationsEndpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('API connectivity test failed: $e');
      return false;
    }
  }
}
