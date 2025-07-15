// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String?,
  role: json['role'] as String,
  phone: json['phone'] as String?,
  program: json['program'] as String?,
  ficha: json['ficha'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'role': instance.role,
  'phone': instance.phone,
  'program': instance.program,
  'ficha': instance.ficha,
  'avatarUrl': instance.avatarUrl,
  'isActive': instance.isActive,
};
