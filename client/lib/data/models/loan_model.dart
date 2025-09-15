import 'package:json_annotation/json_annotation.dart';

part 'loan_model.g.dart';

@JsonSerializable()
class LoanModel {
  final String id;
  @JsonKey(name: 'instructor_id')
  final String instructorId;
  @JsonKey(name: 'item_id')
  final String? itemId;
  @JsonKey(name: 'admin_id')
  final String? adminId;
  @JsonKey(name: 'environment_id')
  final String environmentId;
  final String program;
  final String purpose;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'actual_return_date')
  final String? actualReturnDate;
  final String status;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  @JsonKey(name: 'is_registered_item')
  final bool isRegisteredItem;
  @JsonKey(name: 'quantity_requested')
  final int quantityRequested;
  final String priority;
  @JsonKey(name: 'acta_pdf_path')
  final String? actaPdfPath;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // Related data
  @JsonKey(name: 'instructor_name')
  final String? instructorName;
  @JsonKey(name: 'admin_name')
  final String? adminName;
  @JsonKey(name: 'item_details')
  final Map<String, dynamic>? itemDetails;
  @JsonKey(name: 'environment_name')
  final String? environmentName;

  LoanModel({
    required this.id,
    required this.instructorId,
    this.itemId,
    this.adminId,
    required this.environmentId,
    required this.program,
    required this.purpose,
    required this.startDate,
    required this.endDate,
    this.actualReturnDate,
    required this.status,
    this.rejectionReason,
    this.itemName,
    this.itemDescription,
    required this.isRegisteredItem,
    required this.quantityRequested,
    required this.priority,
    this.actaPdfPath,
    required this.createdAt,
    required this.updatedAt,
    this.instructorName,
    this.adminName,
    this.itemDetails,
    this.environmentName,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) => _$LoanModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoanModelToJson(this);

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'active':
        return 'Activo';
      case 'returned':
        return 'Devuelto';
      case 'overdue':
        return 'Vencido';
      default:
        return status;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'baja':
        return 'Baja';
      default:
        return priority;
    }
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isActive => status == 'active';
  bool get isReturned => status == 'returned';
  bool get isOverdue => status == 'overdue';

  String get userId => instructorId;
}

@JsonSerializable()
class LoanStatsModel {
  @JsonKey(name: 'total_loans')
  final int totalLoans;
  @JsonKey(name: 'pending_loans')
  final int pendingLoans;
  @JsonKey(name: 'approved_loans')
  final int approvedLoans;
  @JsonKey(name: 'active_loans')
  final int activeLoans;
  @JsonKey(name: 'overdue_loans')
  final int overdueLoans;
  @JsonKey(name: 'returned_loans')
  final int returnedLoans;
  @JsonKey(name: 'rejected_loans')
  final int rejectedLoans;

  LoanStatsModel({
    required this.totalLoans,
    required this.pendingLoans,
    required this.approvedLoans,
    required this.activeLoans,
    required this.overdueLoans,
    required this.returnedLoans,
    required this.rejectedLoans,
  });

  factory LoanStatsModel.fromJson(Map<String, dynamic> json) => _$LoanStatsModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoanStatsModelToJson(this);
}

@JsonSerializable()
class CreateLoanRequest {
  final String program;
  final String purpose;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  final String priority;
  @JsonKey(name: 'quantity_requested')
  final int quantityRequested;
  @JsonKey(name: 'environment_id')
  final String environmentId;
  
  // For registered items
  @JsonKey(name: 'item_id')
  final String? itemId;
  @JsonKey(name: 'is_registered_item')
  final bool isRegisteredItem;
  
  // For custom items
  @JsonKey(name: 'item_name')
  final String? itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;

  CreateLoanRequest({
    required this.program,
    required this.purpose,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.quantityRequested,
    required this.environmentId,
    this.itemId,
    required this.isRegisteredItem,
    this.itemName,
    this.itemDescription,
  });

  factory CreateLoanRequest.fromJson(Map<String, dynamic> json) => _$CreateLoanRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateLoanRequestToJson(this);
}
