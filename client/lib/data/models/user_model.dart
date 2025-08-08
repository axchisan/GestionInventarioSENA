import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String? id; 
  final String? email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? phone;
  final String? program;
  final String? ficha;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.phone,
    this.program,
    this.ficha,
    this.avatarUrl,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}