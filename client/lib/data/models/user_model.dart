import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;  // Cambiado a String para UUID
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? program;
  final String? ficha;
  final String? avatarUrl;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.program,
    this.ficha,
    this.avatarUrl,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}