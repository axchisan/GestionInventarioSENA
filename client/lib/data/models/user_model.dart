import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: 'id')
  final String? id;
  @JsonKey(name: 'email')
  final String? email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'role')
  final String? role;
  @JsonKey(name: 'phone')
  final String? phone;
  @JsonKey(name: 'program')
  final String? program;
  @JsonKey(name: 'ficha')
  final String? ficha;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'environment_id')
  final String? environmentId;

  UserModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.phone,
    this.program,
    this.ficha,
    this.avatarUrl,
    this.isActive,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.environmentId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}