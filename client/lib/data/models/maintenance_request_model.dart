import 'package:json_annotation/json_annotation.dart';

part 'maintenance_request_model.g.dart';

@JsonSerializable()
class MaintenanceRequestModel {
  final String id;
  @JsonKey(name: 'item_id')
  final String? itemId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'assigned_technician_id')
  final String? assignedTechnicianId;
  @JsonKey(name: 'environment_id')
  final String? environmentId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? category;
  final String? location;
  @JsonKey(name: 'estimated_completion')
  final DateTime? estimatedCompletion;
  @JsonKey(name: 'actual_completion')
  final DateTime? actualCompletion;
  final double? cost;
  final String? notes;
  @JsonKey(name: 'images_urls')
  final List<String>? imagesUrls;
  @JsonKey(name: 'quantity_affected')
  final int quantityAffected;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const MaintenanceRequestModel({
    required this.id,
    this.itemId,
    required this.userId,
    this.assignedTechnicianId,
    this.environmentId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.category,
    this.location,
    this.estimatedCompletion,
    this.actualCompletion,
    this.cost,
    this.notes,
    this.imagesUrls,
    required this.quantityAffected,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$MaintenanceRequestModelFromJson(json);
    } catch (e) {
      print('Error parsing MaintenanceRequestModel from JSON: $e');
      print('JSON data: $json');
      
      return MaintenanceRequestModel(
        id: json['id']?.toString() ?? 'unknown',
        itemId: json['item_id']?.toString(),
        userId: json['user_id']?.toString() ?? 'unknown',
        assignedTechnicianId: json['assigned_technician_id']?.toString(),
        environmentId: json['environment_id']?.toString(),
        title: json['title']?.toString() ?? 'Sin título',
        description: json['description']?.toString() ?? 'Sin descripción',
        priority: json['priority']?.toString() ?? 'medium',
        status: json['status']?.toString() ?? 'pending',
        category: json['category']?.toString(),
        location: json['location']?.toString(),
        estimatedCompletion: json['estimated_completion'] != null 
            ? DateTime.tryParse(json['estimated_completion'].toString())
            : null,
        actualCompletion: json['actual_completion'] != null 
            ? DateTime.tryParse(json['actual_completion'].toString())
            : null,
        cost: json['cost'] != null 
            ? double.tryParse(json['cost'].toString())
            : null,
        notes: json['notes']?.toString(),
        imagesUrls: json['images_urls'] != null
            ? List<String>.from(json['images_urls'])
            : null,
        quantityAffected: json['quantity_affected'] != null 
            ? int.tryParse(json['quantity_affected'].toString()) ?? 1
            : 1,
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }
  }
  
  Map<String, dynamic> toJson() => _$MaintenanceRequestModelToJson(this);

  // Helper methods for UI
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String get priorityDisplayName {
    switch (priority.toLowerCase()) {
      case 'low':
      case 'baja':
        return 'Baja';
      case 'medium':
      case 'media':
        return 'Media';
      case 'high':
      case 'alta':
        return 'Alta';
      case 'urgent':
      case 'urgente':
        return 'Urgente';
      default:
        return 'Media';
    }
  }

  String get categoryDisplayName {
    switch (category?.toLowerCase()) {
      case 'equipos':
        return 'Equipos';
      case 'mobiliario':
        return 'Mobiliario';
      case 'infraestructura':
        return 'Infraestructura';
      case 'sistemas':
        return 'Sistemas';
      case 'otros':
        return 'Otros';
      default:
        return category ?? 'Sin categoría';
    }
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
