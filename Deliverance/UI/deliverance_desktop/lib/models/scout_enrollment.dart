import 'package:deliverance_desktop/models/scout_enrollment_status_enum.dart';
import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scout_enrollment.g.dart';

@JsonSerializable()
class ScoutEnrollment {
  final int id;
  final ScoutEnrollmentStatusEnum status;
  final String? ipAddress;
  final String? macAddress;
  final String? subnetMask;
  final String? vlanID;
  final String? os;
  final String? manufacturer;
  final String? hostname;

  ScoutEnrollment({
    required this.id,
    required this.status,
    this.ipAddress,
    this.macAddress,
    this.subnetMask,
    this.vlanID,
    this.os,
    this.manufacturer,
    this.hostname,
  });

  factory ScoutEnrollment.fromJson(Map<String, dynamic> json) =>
      _$ScoutEnrollmentFromJson(json);
}

@JsonSerializable()
class ScoutEnrollmentToken {
  final int enrollmentId;
  final String token;
  @JsonKey(fromJson: dateFromJson, toJson: dateToJson)
  final DateTime expiresAt;

  ScoutEnrollmentToken({
    required this.enrollmentId,
    required this.token,
    required this.expiresAt,
  });

  factory ScoutEnrollmentToken.fromJson(Map<String, dynamic> json) =>
      _$ScoutEnrollmentTokenFromJson(json);
}
