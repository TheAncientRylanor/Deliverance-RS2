part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
  uuid: json['uuid'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String?,
  username: json['username'] as String?,
  roleId: json['roleId'] as int?,
  createdAt: nullableDateFromJson(json['createdAt'] as String?),
  imagePath: json['imagePath'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'uuid': instance.uuid,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'username': instance.username,
  'roleId': instance.roleId,
  'createdAt': nullableDateToJson(instance.createdAt),
  'imagePath': instance.imagePath,
};
