// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String?,
  email: json['email'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  role: json['role'] as String?,
  phone: json['phone'] as String?,
  program: json['program'] as String?,
  ficha: json['ficha'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  isActive: json['is_active'] as bool?,
  lastLogin: json['last_login'] == null
      ? null
      : DateTime.parse(json['last_login'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  environmentId: json['environment_id'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'role': instance.role,
  'phone': instance.phone,
  'program': instance.program,
  'ficha': instance.ficha,
  'avatar_url': instance.avatarUrl,
  'is_active': instance.isActive,
  'last_login': instance.lastLogin?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'environment_id': instance.environmentId,
};
