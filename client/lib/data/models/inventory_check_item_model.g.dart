// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_check_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryCheckItemModel _$InventoryCheckItemModelFromJson(
  Map<String, dynamic> json,
) => InventoryCheckItemModel(
  id: json['id'] as String,
  itemId: json['item_id'] as String,
  environmentId: json['environment_id'] as String,
  userId: json['user_id'] as String,
  status: json['status'] as String,
  quantityExpected: (json['quantity_expected'] as num).toInt(),
  quantityFound: (json['quantity_found'] as num).toInt(),
  quantityDamaged: (json['quantity_damaged'] as num).toInt(),
  quantityMissing: (json['quantity_missing'] as num).toInt(),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  itemName: json['item_name'] as String?,
  environmentName: json['environment_name'] as String?,
  userName: json['user_name'] as String?,
);

Map<String, dynamic> _$InventoryCheckItemModelToJson(
  InventoryCheckItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'item_id': instance.itemId,
  'environment_id': instance.environmentId,
  'user_id': instance.userId,
  'status': instance.status,
  'quantity_expected': instance.quantityExpected,
  'quantity_found': instance.quantityFound,
  'quantity_damaged': instance.quantityDamaged,
  'quantity_missing': instance.quantityMissing,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'item_name': instance.itemName,
  'environment_name': instance.environmentName,
  'user_name': instance.userName,
};
