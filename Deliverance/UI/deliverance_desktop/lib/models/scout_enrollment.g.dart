part of 'scout_enrollment.dart';

ScoutEnrollment _$ScoutEnrollmentFromJson(Map<String, dynamic> json) =>
    ScoutEnrollment(
      id: json['id'] as int,
      status: ScoutEnrollmentStatusEnum.fromValue(json['status'] as int),
      ipAddress: json['ipAddress'] as String?,
      macAddress: json['macAddress'] as String?,
      subnetMask: json['subnetMask'] as String?,
      vlanID: json['vlanID'] as String?,
      os: json['os'] as String?,
      manufacturer: json['manufacturer'] as String?,
      hostname: json['hostname'] as String?,
    );

ScoutEnrollmentToken _$ScoutEnrollmentTokenFromJson(
  Map<String, dynamic> json,
) => ScoutEnrollmentToken(
  enrollmentId: json['enrollmentId'] as int,
  token: json['token'] as String,
  expiresAt: dateFromJson(json['expiresAt'] as String),
);
