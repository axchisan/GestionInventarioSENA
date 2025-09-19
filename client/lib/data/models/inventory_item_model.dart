import 'package:json_annotation/json_annotation.dart';

part 'inventory_item_model.g.dart';

@JsonSerializable()
class InventoryItemModel {
  final String id;
  @JsonKey(name: 'environment_id')
  final String environmentId;
  final String name;
  @JsonKey(name: 'serial_number')
  final String? serialNumber;
  @JsonKey(name: 'internal_code')
  final String internalCode;
  final String category;
  final String? brand;
  final String? model;
  final String status;
  @JsonKey(name: 'purchase_date')
  final DateTime? purchaseDate;
  @JsonKey(name: 'warranty_expiry')
  final DateTime? warrantyExpiry;
  @JsonKey(name: 'last_maintenance')
  final DateTime? lastMaintenance;
  @JsonKey(name: 'next_maintenance')
  final DateTime? nextMaintenance;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String? notes;
  final int quantity;
  @JsonKey(name: 'quantity_damaged')
  final int quantityDamaged;
  @JsonKey(name: 'quantity_missing')
  final int quantityMissing;
  @JsonKey(name: 'item_type')
  final String itemType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const InventoryItemModel({
    required this.id,
    required this.environmentId,
    required this.name,
    this.serialNumber,
    required this.internalCode,
    required this.category,
    this.brand,
    this.model,
    required this.status,
    this.purchaseDate,
    this.warrantyExpiry,
    this.lastMaintenance,
    this.nextMaintenance,
    this.imageUrl,
    this.notes,
    required this.quantity,
    required this.quantityDamaged,
    required this.quantityMissing,
    required this.itemType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$InventoryItemModelFromJson(json);
    } catch (e) {
      print('Error parsing InventoryItemModel from JSON: $e');
      return InventoryItemModel(
        id: json['id']?.toString() ?? 'unknown',
        environmentId: json['environment_id']?.toString() ?? 'unknown',
        name: json['name']?.toString() ?? 'Sin nombre',
        serialNumber: json['serial_number']?.toString(),
        internalCode: json['internal_code']?.toString() ?? 'unknown',
        category: json['category']?.toString() ?? 'other',
        brand: json['brand']?.toString(),
        model: json['model']?.toString(),
        status: json['status']?.toString() ?? 'available',
        purchaseDate: json['purchase_date'] != null 
            ? DateTime.tryParse(json['purchase_date'].toString())
            : null,
        warrantyExpiry: json['warranty_expiry'] != null 
            ? DateTime.tryParse(json['warranty_expiry'].toString())
            : null,
        lastMaintenance: json['last_maintenance'] != null 
            ? DateTime.tryParse(json['last_maintenance'].toString())
            : null,
        nextMaintenance: json['next_maintenance'] != null 
            ? DateTime.tryParse(json['next_maintenance'].toString())
            : null,
        imageUrl: json['image_url']?.toString(),
        notes: json['notes']?.toString(),
        quantity: json['quantity'] != null 
            ? int.tryParse(json['quantity'].toString()) ?? 1
            : 1,
        quantityDamaged: json['quantity_damaged'] != null 
            ? int.tryParse(json['quantity_damaged'].toString()) ?? 0
            : 0,
        quantityMissing: json['quantity_missing'] != null 
            ? int.tryParse(json['quantity_missing'].toString()) ?? 0
            : 0,
        itemType: json['item_type']?.toString() ?? 'individual',
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);

  // Helper methods for UI
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'computer':
        return 'Computador';
      case 'projector':
        return 'Proyector';
      case 'keyboard':
        return 'Teclado';
      case 'mouse':
        return 'Mouse';
      case 'tv':
        return 'Televisor';
      case 'camera':
        return 'Cámara';
      case 'microphone':
        return 'Micrófono';
      case 'tablet':
        return 'Tablet';
      case 'other':
        return 'Otro';
      default:
        return category;
    }
  }

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'in_use':
        return 'En Uso';
      case 'maintenance':
        return 'Mantenimiento';
      case 'damaged':
        return 'Dañado';
      case 'lost':
        return 'Perdido';
      case 'missing':
        return 'Faltante';
      case 'good':
        return 'Bueno';
      default:
        return status;
    }
  }

  bool get hasIssues => quantityDamaged > 0 || quantityMissing > 0;
  bool get needsMaintenance => nextMaintenance != null && 
      nextMaintenance!.isBefore(DateTime.now().add(const Duration(days: 30)));
  
  int get totalAvailable => quantity - quantityDamaged - quantityMissing;
}
