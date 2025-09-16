import 'package:json_annotation/json_annotation.dart';

part 'alert_settings_model.g.dart';

@JsonSerializable()
class AlertSettingsModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'alert_type')
  final String alertType;
  @JsonKey(name: 'is_enabled')
  final bool isEnabled;
  @JsonKey(name: 'threshold_value')
  final int? thresholdValue;
  @JsonKey(name: 'notification_methods')
  final List<String>? notificationMethods;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const AlertSettingsModel({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.isEnabled,
    this.thresholdValue,
    this.notificationMethods,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertSettingsModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$AlertSettingsModelFromJson(json);
    } catch (e) {
      print('Error parsing AlertSettingsModel from JSON: $e');
      print('JSON data: $json');
      
      return AlertSettingsModel(
        id: json['id']?.toString() ?? 'unknown',
        userId: json['user_id']?.toString() ?? 'unknown',
        alertType: json['alert_type']?.toString() ?? 'unknown',
        isEnabled: json['is_enabled'] == true,
        thresholdValue: json['threshold_value'] != null 
            ? int.tryParse(json['threshold_value'].toString())
            : null,
        notificationMethods: json['notification_methods'] != null
            ? List<String>.from(json['notification_methods'])
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
  
  Map<String, dynamic> toJson() => _$AlertSettingsModelToJson(this);

  // Helper methods for UI
  String get alertTypeDisplayName {
    switch (alertType) {
      case 'low_stock':
        return 'Stock Bajo';
      case 'maintenance_overdue':
        return 'Mantenimiento Vencido';
      case 'equipment_missing':
        return 'Equipo Faltante';
      case 'loan_overdue':
        return 'Préstamo Vencido';
      case 'verification_pending':
        return 'Verificación Pendiente';
      default:
        return 'Desconocido';
    }
  }

  String get notificationMethodsText {
    if (notificationMethods == null || notificationMethods!.isEmpty) {
      return 'Sin métodos configurados';
    }
    return notificationMethods!.map((method) {
      switch (method) {
        case 'email':
          return 'Email';
        case 'push':
          return 'Push';
        case 'sms':
          return 'SMS';
        default:
          return method;
      }
    }).join(', ');
  }
}
