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
      return _$EnvironmentModelFromJson(json);
    } catch (e) {
      print('Error parsing EnvironmentModel from JSON: $e');
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
        isWarehouse: json['is_warehouse'] == true,
        isActive: json['is_active'] != false,
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() => _$EnvironmentModelToJson(this);

  String get displayName => isWarehouse ? '$name (Almacén)' : name;
  String get fullLocation => '$name - $location';
}
