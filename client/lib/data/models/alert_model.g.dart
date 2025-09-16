// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertModel _$AlertModelFromJson(Map<String, dynamic> json) => AlertModel(
  id: json['id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  severity: json['severity'] as String,
  entityType: json['entity_type'] as String?,
  entityId: json['entity_id'] as String?,
  isResolved: json['is_resolved'] as bool,
  resolvedBy: json['resolved_by'] as String?,
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AlertModelToJson(AlertModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'message': instance.message,
      'severity': instance.severity,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'is_resolved': instance.isResolved,
      'resolved_by': instance.resolvedBy,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
