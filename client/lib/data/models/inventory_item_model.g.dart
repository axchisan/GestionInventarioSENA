// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      id: json['id'] as String,
      environmentId: json['environment_id'] as String,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String?,
      internalCode: json['internal_code'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      status: json['status'] as String,
      purchaseDate: json['purchase_date'] == null
          ? null
          : DateTime.parse(json['purchase_date'] as String),
      warrantyExpiry: json['warranty_expiry'] == null
          ? null
          : DateTime.parse(json['warranty_expiry'] as String),
      lastMaintenance: json['last_maintenance'] == null
          ? null
          : DateTime.parse(json['last_maintenance'] as String),
      nextMaintenance: json['next_maintenance'] == null
          ? null
          : DateTime.parse(json['next_maintenance'] as String),
      imageUrl: json['image_url'] as String?,
      notes: json['notes'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      quantityDamaged: (json['quantity_damaged'] as num).toInt(),
      quantityMissing: (json['quantity_missing'] as num).toInt(),
      itemType: json['item_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InventoryItemModelToJson(InventoryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'environment_id': instance.environmentId,
      'name': instance.name,
      'serial_number': instance.serialNumber,
      'internal_code': instance.internalCode,
      'category': instance.category,
      'brand': instance.brand,
      'model': instance.model,
      'status': instance.status,
      'purchase_date': instance.purchaseDate?.toIso8601String(),
      'warranty_expiry': instance.warrantyExpiry?.toIso8601String(),
      'last_maintenance': instance.lastMaintenance?.toIso8601String(),
      'next_maintenance': instance.nextMaintenance?.toIso8601String(),
      'image_url': instance.imageUrl,
      'notes': instance.notes,
      'quantity': instance.quantity,
      'quantity_damaged': instance.quantityDamaged,
      'quantity_missing': instance.quantityMissing,
      'item_type': instance.itemType,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
