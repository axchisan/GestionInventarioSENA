// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoanModel _$LoanModelFromJson(Map<String, dynamic> json) => LoanModel(
  id: json['id'] as String,
  instructorId: json['instructor_id'] as String,
  itemId: json['item_id'] as String?,
  adminId: json['admin_id'] as String?,
  environmentId: json['environment_id'] as String,
  program: json['program'] as String,
  purpose: json['purpose'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  actualReturnDate: json['actual_return_date'] as String?,
  status: json['status'] as String,
  rejectionReason: json['rejection_reason'] as String?,
  itemName: json['item_name'] as String?,
  itemDescription: json['item_description'] as String?,
  isRegisteredItem: json['is_registered_item'] as bool,
  quantityRequested: (json['quantity_requested'] as num).toInt(),
  priority: json['priority'] as String,
  actaPdfPath: json['acta_pdf_path'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  instructorName: json['instructor_name'] as String?,
  adminName: json['admin_name'] as String?,
  itemDetails: json['item_details'] as Map<String, dynamic>?,
  environmentName: json['environment_name'] as String?,
);

Map<String, dynamic> _$LoanModelToJson(LoanModel instance) => <String, dynamic>{
  'id': instance.id,
  'instructor_id': instance.instructorId,
  'item_id': instance.itemId,
  'admin_id': instance.adminId,
  'environment_id': instance.environmentId,
  'program': instance.program,
  'purpose': instance.purpose,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'actual_return_date': instance.actualReturnDate,
  'status': instance.status,
  'rejection_reason': instance.rejectionReason,
  'item_name': instance.itemName,
  'item_description': instance.itemDescription,
  'is_registered_item': instance.isRegisteredItem,
  'quantity_requested': instance.quantityRequested,
  'priority': instance.priority,
  'acta_pdf_path': instance.actaPdfPath,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'instructor_name': instance.instructorName,
  'admin_name': instance.adminName,
  'item_details': instance.itemDetails,
  'environment_name': instance.environmentName,
};

LoanStatsModel _$LoanStatsModelFromJson(Map<String, dynamic> json) =>
    LoanStatsModel(
      totalLoans: (json['total_loans'] as num).toInt(),
      pendingLoans: (json['pending_loans'] as num).toInt(),
      approvedLoans: (json['approved_loans'] as num).toInt(),
      activeLoans: (json['active_loans'] as num).toInt(),
      overdueLoans: (json['overdue_loans'] as num).toInt(),
      returnedLoans: (json['returned_loans'] as num).toInt(),
      rejectedLoans: (json['rejected_loans'] as num).toInt(),
    );

Map<String, dynamic> _$LoanStatsModelToJson(LoanStatsModel instance) =>
    <String, dynamic>{
      'total_loans': instance.totalLoans,
      'pending_loans': instance.pendingLoans,
      'approved_loans': instance.approvedLoans,
      'active_loans': instance.activeLoans,
      'overdue_loans': instance.overdueLoans,
      'returned_loans': instance.returnedLoans,
      'rejected_loans': instance.rejectedLoans,
    };

CreateLoanRequest _$CreateLoanRequestFromJson(Map<String, dynamic> json) =>
    CreateLoanRequest(
      program: json['program'] as String,
      purpose: json['purpose'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      priority: json['priority'] as String,
      quantityRequested: (json['quantity_requested'] as num).toInt(),
      environmentId: json['environment_id'] as String,
      itemId: json['item_id'] as String?,
      isRegisteredItem: json['is_registered_item'] as bool,
      itemName: json['item_name'] as String?,
      itemDescription: json['item_description'] as String?,
    );

Map<String, dynamic> _$CreateLoanRequestToJson(CreateLoanRequest instance) =>
    <String, dynamic>{
      'program': instance.program,
      'purpose': instance.purpose,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'priority': instance.priority,
      'quantity_requested': instance.quantityRequested,
      'environment_id': instance.environmentId,
      'item_id': instance.itemId,
      'is_registered_item': instance.isRegisteredItem,
      'item_name': instance.itemName,
      'item_description': instance.itemDescription,
    };
