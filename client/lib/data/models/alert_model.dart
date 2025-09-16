import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_model.g.dart';

@JsonSerializable()
class AlertModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String severity;
  @JsonKey(name: 'entity_type')
  final String? entityType;
  @JsonKey(name: 'entity_id')
  final String? entityId;
  @JsonKey(name: 'is_resolved')
  final bool isResolved;
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.entityType,
    this.entityId,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$AlertModelFromJson(json);
    } catch (e) {
      print('Error parsing AlertModel from JSON: $e');
      print('JSON data: $json');
      
      // Return a default AlertModel with available data
      return AlertModel(
        id: json['id']?.toString() ?? 'unknown',
        type: json['type']?.toString() ?? 'unknown',
        title: json['title']?.toString() ?? 'Error al cargar alerta',
        message: json['message']?.toString() ?? 'No se pudo cargar el mensaje',
        severity: json['severity']?.toString() ?? 'medium',
        entityType: json['entity_type']?.toString(),
        entityId: json['entity_id']?.toString(),
        isResolved: json['is_resolved'] == true,
        resolvedBy: json['resolved_by']?.toString(),
        resolvedAt: json['resolved_at'] != null 
            ? DateTime.tryParse(json['resolved_at'].toString())
            : null,
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }
  }
  
  Map<String, dynamic> toJson() => _$AlertModelToJson(this);

  // Helper methods for UI
  String get priorityText {
    switch (severity) {
      case 'critical':
        return 'Crítica';
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
      case 'low_stock':
        return 'Stock Bajo';
      case 'maintenance_overdue':
        return 'Mantenimiento';
      case 'equipment_missing':
        return 'Equipo Faltante';
      case 'loan_overdue':
        return 'Préstamo Vencido';
      case 'verification_pending':
        return 'Verificación Pendiente';
      default:
        return 'Información';
    }
  }

  Color get priorityColor {
    switch (severity) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'high':
        return const Color(0xFFFF9800);
      case 'medium':
        return const Color(0xFF2196F3);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'low_stock':
        return Icons.warning;
      case 'maintenance_overdue':
        return Icons.build;
      case 'equipment_missing':
        return Icons.error;
      case 'loan_overdue':
        return Icons.schedule;
      case 'verification_pending':
        return Icons.assignment;
      default:
        return Icons.info;
    }
  }
}
