// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceRequestModel _$MaintenanceRequestModelFromJson(
  Map<String, dynamic> json,
) => MaintenanceRequestModel(
  id: json['id'] as String,
  itemId: json['item_id'] as String?,
  userId: json['user_id'] as String,
  assignedTechnicianId: json['assigned_technician_id'] as String?,
  environmentId: json['environment_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String,
  priority: json['priority'] as String,
  status: json['status'] as String,
  category: json['category'] as String?,
  location: json['location'] as String?,
  estimatedCompletion: json['estimated_completion'] == null
      ? null
      : DateTime.parse(json['estimated_completion'] as String),
  actualCompletion: json['actual_completion'] == null
      ? null
      : DateTime.parse(json['actual_completion'] as String),
  cost: (json['cost'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
  imagesUrls: (json['images_urls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  quantityAffected: (json['quantity_affected'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MaintenanceRequestModelToJson(
  MaintenanceRequestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'item_id': instance.itemId,
  'user_id': instance.userId,
  'assigned_technician_id': instance.assignedTechnicianId,
  'environment_id': instance.environmentId,
  'title': instance.title,
  'description': instance.description,
  'priority': instance.priority,
  'status': instance.status,
  'category': instance.category,
  'location': instance.location,
  'estimated_completion': instance.estimatedCompletion?.toIso8601String(),
  'actual_completion': instance.actualCompletion?.toIso8601String(),
  'cost': instance.cost,
  'notes': instance.notes,
  'images_urls': instance.imagesUrls,
  'quantity_affected': instance.quantityAffected,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
