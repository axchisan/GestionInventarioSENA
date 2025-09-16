import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'inventory_check_item_model.g.dart';

@JsonSerializable()
class InventoryCheckItemModel {
  final String id;
  @JsonKey(name: 'item_id')
  final String itemId;
  @JsonKey(name: 'environment_id')
  final String environmentId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String status;
  @JsonKey(name: 'quantity_expected')
  final int quantityExpected;
  @JsonKey(name: 'quantity_found')
  final int quantityFound;
  @JsonKey(name: 'quantity_damaged')
  final int quantityDamaged;
  @JsonKey(name: 'quantity_missing')
  final int quantityMissing;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Related data that might be included in API response
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'environment_name')
  final String? environmentName;
  @JsonKey(name: 'user_name')
  final String? userName;

  const InventoryCheckItemModel({
    required this.id,
    required this.itemId,
    required this.environmentId,
    required this.userId,
    required this.status,
    required this.quantityExpected,
    required this.quantityFound,
    required this.quantityDamaged,
    required this.quantityMissing,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.itemName,
    this.environmentName,
    this.userName,
  });

  factory InventoryCheckItemModel.fromJson(Map<String, dynamic> json) => 
      _$InventoryCheckItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryCheckItemModelToJson(this);

  // Helper methods for UI
  String get statusText {
    switch (status) {
      case 'good':
        return 'Bueno';
      case 'damaged':
        return 'Dañado';
      case 'missing':
        return 'Faltante';
      default:
        return 'Desconocido';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'good':
        return const Color(0xFF4CAF50);
      case 'damaged':
        return const Color(0xFFFF9800);
      case 'missing':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }

  bool get hasIssues => quantityDamaged > 0 || quantityMissing > 0;
  
  String get issueDescription {
    List<String> issues = [];
    if (quantityMissing > 0) {
      issues.add('$quantityMissing faltante(s)');
    }
    if (quantityDamaged > 0) {
      issues.add('$quantityDamaged dañado(s)');
    }
    return issues.join(', ');
  }
}
