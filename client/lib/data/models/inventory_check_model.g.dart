// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_check_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryCheckModel _$InventoryCheckModelFromJson(Map<String, dynamic> json) =>
    InventoryCheckModel(
      id: json['id'] as String,
      environmentId: json['environment_id'] as String,
      studentId: json['student_id'] as String,
      instructorId: json['instructor_id'] as String?,
      supervisorId: json['supervisor_id'] as String?,
      scheduleId: json['schedule_id'] as String?,
      checkDate: DateTime.parse(json['check_date'] as String),
      checkTime: json['check_time'] as String,
      status: json['status'] as String,
      totalItems: (json['total_items'] as num?)?.toInt(),
      itemsGood: (json['items_good'] as num?)?.toInt(),
      itemsDamaged: (json['items_damaged'] as num?)?.toInt(),
      itemsMissing: (json['items_missing'] as num?)?.toInt(),
      isClean: json['is_clean'] as bool?,
      isOrganized: json['is_organized'] as bool?,
      inventoryComplete: json['inventory_complete'] as bool?,
      cleaningNotes: json['cleaning_notes'] as String?,
      comments: json['comments'] as String?,
      instructorComments: json['instructor_comments'] as String?,
      supervisorComments: json['supervisor_comments'] as String?,
      studentConfirmedAt: json['student_confirmed_at'] == null
          ? null
          : DateTime.parse(json['student_confirmed_at'] as String),
      instructorConfirmedAt: json['instructor_confirmed_at'] == null
          ? null
          : DateTime.parse(json['instructor_confirmed_at'] as String),
      supervisorConfirmedAt: json['supervisor_confirmed_at'] == null
          ? null
          : DateTime.parse(json['supervisor_confirmed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InventoryCheckModelToJson(
  InventoryCheckModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'environment_id': instance.environmentId,
  'student_id': instance.studentId,
  'instructor_id': instance.instructorId,
  'supervisor_id': instance.supervisorId,
  'schedule_id': instance.scheduleId,
  'check_date': instance.checkDate.toIso8601String(),
  'check_time': instance.checkTime,
  'status': instance.status,
  'total_items': instance.totalItems,
  'items_good': instance.itemsGood,
  'items_damaged': instance.itemsDamaged,
  'items_missing': instance.itemsMissing,
  'is_clean': instance.isClean,
  'is_organized': instance.isOrganized,
  'inventory_complete': instance.inventoryComplete,
  'cleaning_notes': instance.cleaningNotes,
  'comments': instance.comments,
  'instructor_comments': instance.instructorComments,
  'supervisor_comments': instance.supervisorComments,
  'student_confirmed_at': instance.studentConfirmedAt?.toIso8601String(),
  'instructor_confirmed_at': instance.instructorConfirmedAt?.toIso8601String(),
  'supervisor_confirmed_at': instance.supervisorConfirmedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
