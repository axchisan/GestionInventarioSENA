import 'dart:convert';
import '../constants/api_constants.dart';
import 'api_service.dart';
import '../../presentation/providers/auth_provider.dart';

class AuditService {
  final ApiService _apiService;

  AuditService({required AuthProvider authProvider}) 
      : _apiService = ApiService(authProvider: authProvider);

  /// Get audit logs with pagination and filters
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int perPage = 20,
    String? actionFilter,
    String? userId,
    String? entityType,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    Map<String, String> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (actionFilter != null && actionFilter.isNotEmpty) {
      queryParams['action_filter'] = actionFilter;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams['user_id'] = userId;
    }
    if (entityType != null && entityType.isNotEmpty) {
      queryParams['entity_type'] = entityType;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    return await _apiService.get(auditLogsEndpoint, queryParams: queryParams);
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getAuditStats({int days = 30}) async {
    Map<String, String> queryParams = {
      'days': days.toString(),
    };

    return await _apiService.get('${auditLogsEndpoint}stats', queryParams: queryParams);
  }

  /// Get user activity
  Future<Map<String, dynamic>> getUserActivity(String userId, {int days = 30}) async {
    Map<String, String> queryParams = {
      'days': days.toString(),
    };

    return await _apiService.get('${auditLogsEndpoint}user/$userId/activity', queryParams: queryParams);
  }

  /// Get entity audit trail
  Future<List<dynamic>> getEntityAuditTrail(String entityType, String entityId) async {
    return await _apiService.get('${auditLogsEndpoint}entity/$entityType/$entityId/trail');
  }

  /// Get specific audit log by ID
  Future<Map<String, dynamic>> getAuditLog(String logId) async {
    return await _apiService.getSingle('$auditLogsEndpoint$logId');
  }

  /// Create audit log (for manual logging)
  Future<Map<String, dynamic>> createAuditLog({
    required String action,
    required String entityType,
    String? entityId,
    String? userId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? sessionId,
  }) async {
    final data = {
      'action': action,
      'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (userId != null) 'user_id': userId,
      if (oldValues != null) 'old_values': oldValues,
      if (newValues != null) 'new_values': newValues,
      if (sessionId != null) 'session_id': sessionId,
    };

    return await _apiService.post(auditLogsEndpoint, data);
  }

  /// Cleanup old logs (admin only)
  Future<Map<String, dynamic>> cleanupOldLogs({int daysToKeep = 90}) async {
    Map<String, String> queryParams = {
      'days_to_keep': daysToKeep.toString(),
    };

    return await _apiService.delete('${auditLogsEndpoint}cleanup');
  }

  /// Export audit logs for reporting
  Future<List<dynamic>> exportAuditLogs({
    required String startDate,
    required String endDate,
    String format = 'json',
  }) async {
    Map<String, String> queryParams = {
      'start_date': startDate,
      'end_date': endDate,
      'format': format,
    };

    return await _apiService.get('${auditLogsEndpoint}export', queryParams: queryParams);
  }

  /// Get available actions for filtering
  List<String> getAvailableActions() {
    return [
      'LOGIN',
      'LOGOUT',
      'REGISTER',
      'INVENTORY_CREATE',
      'INVENTORY_UPDATE',
      'INVENTORY_DELETE',
      'INVENTORY_VIEW',
      'LOAN_CREATE',
      'LOAN_UPDATE',
      'LOAN_DELETE',
      'LOAN_VIEW',
      'USER_CREATE',
      'USER_UPDATE',
      'USER_DELETE',
      'USER_VIEW',
      'MAINTENANCE_CREATE',
      'MAINTENANCE_UPDATE',
      'MAINTENANCE_DELETE',
      'MAINTENANCE_VIEW',
      'CHECK_CREATE',
      'CHECK_UPDATE',
      'CHECK_DELETE',
      'CHECK_VIEW',
      'ENVIRONMENT_CREATE',
      'ENVIRONMENT_UPDATE',
      'ENVIRONMENT_DELETE',
      'ENVIRONMENT_VIEW',
    ];
  }

  /// Get available entity types for filtering
  List<String> getAvailableEntityTypes() {
    return [
      'inventory_item',
      'loan',
      'user',
      'maintenance_request',
      'environment',
      'inventory_check',
      'authentication',
    ];
  }

  /// Get severity level for an action
  String getActionSeverity(String action) {
    final warningActions = ['delete', 'update', 'modify', 'change', 'remove'];
    final errorActions = ['error', 'fail', 'exception', 'reject'];
    final successActions = ['create', 'login', 'approve', 'complete', 'success'];

    final lowerAction = action.toLowerCase();

    if (warningActions.any((warning) => lowerAction.contains(warning))) {
      return 'warning';
    } else if (errorActions.any((error) => lowerAction.contains(error))) {
      return 'error';
    } else if (successActions.any((success) => lowerAction.contains(success))) {
      return 'success';
    } else {
      return 'info';
    }
  }

  /// Format action for display
  String formatActionForDisplay(String action) {
    return action
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  /// Format entity type for display
  String formatEntityTypeForDisplay(String entityType) {
    final displayNames = {
      'inventory_item': 'Elemento de Inventario',
      'loan': 'Préstamo',
      'user': 'Usuario',
      'maintenance_request': 'Solicitud de Mantenimiento',
      'environment': 'Ambiente',
      'inventory_check': 'Verificación de Inventario',
      'authentication': 'Autenticación',
    };

    return displayNames[entityType] ?? entityType;
  }

  void dispose() {
    _apiService.dispose();
  }
}

/// Model classes for audit data
class AuditLog {
  final String id;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      action: json['action'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      oldValues: json['old_values'],
      newValues: json['new_values'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      sessionId: json['session_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AuditStats {
  final int totalLogs;
  final int todayLogs;
  final int warningLogs;
  final int errorLogs;
  final int infoLogs;
  final int successLogs;
  final List<ActionCount> topActions;
  final List<UserCount> topUsers;

  AuditStats({
    required this.totalLogs,
    required this.todayLogs,
    required this.warningLogs,
    required this.errorLogs,
    required this.infoLogs,
    required this.successLogs,
    required this.topActions,
    required this.topUsers,
  });

  factory AuditStats.fromJson(Map<String, dynamic> json) {
    return AuditStats(
      totalLogs: json['total_logs'] ?? 0,
      todayLogs: json['today_logs'] ?? 0,
      warningLogs: json['warning_logs'] ?? 0,
      errorLogs: json['error_logs'] ?? 0,
      infoLogs: json['info_logs'] ?? 0,
      successLogs: json['success_logs'] ?? 0,
      topActions: (json['top_actions'] as List<dynamic>?)
          ?.map((item) => ActionCount.fromJson(item))
          .toList() ?? [],
      topUsers: (json['top_users'] as List<dynamic>?)
          ?.map((item) => UserCount.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ActionCount {
  final String action;
  final int count;

  ActionCount({required this.action, required this.count});

  factory ActionCount.fromJson(Map<String, dynamic> json) {
    return ActionCount(
      action: json['action'],
      count: json['count'],
    );
  }
}

class UserCount {
  final String name;
  final String email;
  final int count;

  UserCount({required this.name, required this.email, required this.count});

  factory UserCount.fromJson(Map<String, dynamic> json) {
    return UserCount(
      name: json['name'],
      email: json['email'],
      count: json['count'],
    );
  }
}
