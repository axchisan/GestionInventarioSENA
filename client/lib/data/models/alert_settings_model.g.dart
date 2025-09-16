// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertSettingsModel _$AlertSettingsModelFromJson(Map<String, dynamic> json) =>
    AlertSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertType: json['alert_type'] as String,
      isEnabled: json['is_enabled'] as bool,
      thresholdValue: (json['threshold_value'] as num?)?.toInt(),
      notificationMethods: (json['notification_methods'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AlertSettingsModelToJson(AlertSettingsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'alert_type': instance.alertType,
      'is_enabled': instance.isEnabled,
      'threshold_value': instance.thresholdValue,
      'notification_methods': instance.notificationMethods,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
