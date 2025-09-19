import 'package:json_annotation/json_annotation.dart';

part 'inventory_check_model.g.dart';

@JsonSerializable()
class InventoryCheckModel {
  final String id;
  @JsonKey(name: 'environment_id')
  final String environmentId;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'instructor_id')
  final String? instructorId;
  @JsonKey(name: 'supervisor_id')
  final String? supervisorId;
  @JsonKey(name: 'schedule_id')
  final String? scheduleId;
  @JsonKey(name: 'check_date')
  final DateTime checkDate;
  @JsonKey(name: 'check_time')
  final String checkTime;
  final String status;
  @JsonKey(name: 'total_items')
  final int? totalItems;
  @JsonKey(name: 'items_good')
  final int? itemsGood;
  @JsonKey(name: 'items_damaged')
  final int? itemsDamaged;
  @JsonKey(name: 'items_missing')
  final int? itemsMissing;
  @JsonKey(name: 'is_clean')
  final bool? isClean;
  @JsonKey(name: 'is_organized')
  final bool? isOrganized;
  @JsonKey(name: 'inventory_complete')
  final bool? inventoryComplete;
  @JsonKey(name: 'cleaning_notes')
  final String? cleaningNotes;
  final String? comments;
  @JsonKey(name: 'instructor_comments')
  final String? instructorComments;
  @JsonKey(name: 'supervisor_comments')
  final String? supervisorComments;
  @JsonKey(name: 'student_confirmed_at')
  final DateTime? studentConfirmedAt;
  @JsonKey(name: 'instructor_confirmed_at')
  final DateTime? instructorConfirmedAt;
  @JsonKey(name: 'supervisor_confirmed_at')
  final DateTime? supervisorConfirmedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const InventoryCheckModel({
    required this.id,
    required this.environmentId,
    required this.studentId,
    this.instructorId,
    this.supervisorId,
    this.scheduleId,
    required this.checkDate,
    required this.checkTime,
    required this.status,
    this.totalItems,
    this.itemsGood,
    this.itemsDamaged,
    this.itemsMissing,
    this.isClean,
    this.isOrganized,
    this.inventoryComplete,
    this.cleaningNotes,
    this.comments,
    this.instructorComments,
    this.supervisorComments,
    this.studentConfirmedAt,
    this.instructorConfirmedAt,
    this.supervisorConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryCheckModel.fromJson(Map<String, dynamic> json) {
    try {
      return _$InventoryCheckModelFromJson(json);
    } catch (e) {
      print('Error parsing InventoryCheckModel from JSON: $e');
      return InventoryCheckModel(
        id: json['id']?.toString() ?? 'unknown',
        environmentId: json['environment_id']?.toString() ?? 'unknown',
        studentId: json['student_id']?.toString() ?? 'unknown',
        instructorId: json['instructor_id']?.toString(),
        supervisorId: json['supervisor_id']?.toString(),
        scheduleId: json['schedule_id']?.toString(),
        checkDate: json['check_date'] != null 
            ? DateTime.tryParse(json['check_date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        checkTime: json['check_time']?.toString() ?? '00:00',
        status: json['status']?.toString() ?? 'student_pending',
        totalItems: json['total_items'] != null 
            ? int.tryParse(json['total_items'].toString())
            : null,
        itemsGood: json['items_good'] != null 
            ? int.tryParse(json['items_good'].toString())
            : null,
        itemsDamaged: json['items_damaged'] != null 
            ? int.tryParse(json['items_damaged'].toString())
            : null,
        itemsMissing: json['items_missing'] != null 
            ? int.tryParse(json['items_missing'].toString())
            : null,
        isClean: json['is_clean'] as bool?,
        isOrganized: json['is_organized'] as bool?,
        inventoryComplete: json['inventory_complete'] as bool?,
        cleaningNotes: json['cleaning_notes']?.toString(),
        comments: json['comments']?.toString(),
        instructorComments: json['instructor_comments']?.toString(),
        supervisorComments: json['supervisor_comments']?.toString(),
        studentConfirmedAt: json['student_confirmed_at'] != null 
            ? DateTime.tryParse(json['student_confirmed_at'].toString())
            : null,
        instructorConfirmedAt: json['instructor_confirmed_at'] != null 
            ? DateTime.tryParse(json['instructor_confirmed_at'].toString())
            : null,
        supervisorConfirmedAt: json['supervisor_confirmed_at'] != null 
            ? DateTime.tryParse(json['supervisor_confirmed_at'].toString())
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

  Map<String, dynamic> toJson() => _$InventoryCheckModelToJson(this);

  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'student_pending':
        return 'Pendiente Estudiante';
      case 'instructor_review':
        return 'Revisión Instructor';
      case 'supervisor_review':
        return 'Revisión Supervisor';
      case 'complete':
        return 'Completado';
      case 'issues':
        return 'Con Problemas';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  bool get isComplete => status.toLowerCase() == 'complete';
  bool get hasIssues => (itemsDamaged ?? 0) > 0 || (itemsMissing ?? 0) > 0;
  bool get allChecksComplete => isClean == true && isOrganized == true && inventoryComplete == true;
}
