// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'environment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvironmentModel _$EnvironmentModelFromJson(Map<String, dynamic> json) =>
    EnvironmentModel(
      id: json['id'] as String,
      centerId: json['center_id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: (json['capacity'] as num).toInt(),
      qrCode: json['qr_code'] as String,
      description: json['description'] as String?,
      isWarehouse: json['is_warehouse'] as bool,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EnvironmentModelToJson(EnvironmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'center_id': instance.centerId,
      'name': instance.name,
      'location': instance.location,
      'capacity': instance.capacity,
      'qr_code': instance.qrCode,
      'description': instance.description,
      'is_warehouse': instance.isWarehouse,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
