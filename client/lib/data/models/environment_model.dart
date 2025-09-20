import 'package:json_annotation/json_annotation.dart';

part 'environment_model.g.dart';

@JsonSerializable()
class EnvironmentModel {
  final String id;
  @JsonKey(name: 'center_id')
  final String centerId;
  final String name;
  final String location;
  final int capacity;
  @JsonKey(name: 'qr_code')
  final String qrCode;
  final String? description;
  @JsonKey(name: 'is_warehouse')
  final bool isWarehouse;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const EnvironmentModel({
    required this.id,
    required this.centerId,
    required this.name,
    required this.location,
    required this.capacity,
    required this.qrCode,
    this.description,
    required this.isWarehouse,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnvironmentModel.fromJson(Map<String, dynamic> json) {
    try {
      return EnvironmentModel(
        id: json['id']?.toString() ?? 'unknown',
        centerId: json['center_id']?.toString() ?? 'unknown',
        name: json['name']?.toString() ?? 'Sin nombre',
        location: json['location']?.toString() ?? 'Sin ubicación',
        capacity: json['capacity'] != null 
            ? int.tryParse(json['capacity'].toString()) ?? 30
            : 30,
        qrCode: json['qr_code']?.toString() ?? 'unknown',
        description: json['description']?.toString(),
        isWarehouse: _parseBool(json['is_warehouse']) ?? false,
        isActive: _parseBool(json['is_active']) ?? true,
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing EnvironmentModel from JSON: $e');
      return EnvironmentModel(
        id: json['id']?.toString() ?? 'unknown',
        centerId: json['center_id']?.toString() ?? 'unknown',
        name: json['name']?.toString() ?? 'Sin nombre',
        location: json['location']?.toString() ?? 'Sin ubicación',
        capacity: 30,
        qrCode: 'unknown',
        description: null,
        isWarehouse: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }

  Map<String, dynamic> toJson() => _$EnvironmentModelToJson(this);

  String get displayName => isWarehouse ? '$name (Almacén)' : name;
  String get fullLocation => '$name - $location';
}
