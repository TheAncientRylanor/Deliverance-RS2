import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? username;
  final int? roleId;
  @JsonKey(fromJson: nullableDateFromJson, toJson: nullableDateToJson)
  final DateTime? createdAt;
  final String? imagePath;

  User({
    this.uuid,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
    this.roleId,
    this.createdAt,
    this.imagePath,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
