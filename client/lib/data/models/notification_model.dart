import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String priority;
  final String? actionUrl;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.priority,
    this.actionUrl,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'system',
        title: json['title']?.toString() ?? 'Notificación',
        message: json['message']?.toString() ?? '',
        isRead: json['is_read'] == true || json['is_read'] == 'true',
        priority: json['priority']?.toString() ?? 'medium',
        actionUrl: json['action_url']?.toString(),
        expiresAt: json['expires_at'] != null 
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error in NotificationModel.fromJson: $e, json: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'title': title,
    'message': message,
    'is_read': isRead,
    'priority': priority,
    'action_url': actionUrl,
    'expires_at': expiresAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Helper methods for UI
  String get priorityText {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return 'Media';
    }
  }

  String get typeText {
    switch (type) {
      case 'loan_approved':
        return 'Préstamo Aprobado';
      case 'loan_rejected':
        return 'Préstamo Rechazado';
      case 'loan_overdue':
        return 'Préstamo Vencido';
      case 'check_reminder':
        return 'Recordatorio de Verificación';
      case 'verification_pending':
        return 'Verificación Pendiente';
      case 'verification_update':
        return 'Actualización de Verificación';
      case 'maintenance_request':
        return 'Solicitud de Mantenimiento';
      case 'maintenance_update':
        return 'Actualización de Mantenimiento';
      case 'alert':
        return 'Alerta';
      case 'system':
        return 'Sistema';
      default:
        return 'Notificación';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'loan_approved':
      case 'loan_rejected':
      case 'loan_overdue':
        return Icons.assignment;
      case 'check_reminder':
      case 'verification_pending':
      case 'verification_update':
        return Icons.checklist;
      case 'maintenance_request':
      case 'maintenance_update':
        return Icons.build;
      case 'alert':
        return Icons.warning;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  bool get isMaintenanceRelated => 
      type == 'maintenance_request' || type == 'maintenance_update';
}
