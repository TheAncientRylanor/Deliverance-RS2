part of 'report.dart';

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as int?,
  reportName: json['reportName'] as String?,
  status: json['status'] as int?,
  dateReported: json['dateReported'] == null
      ? null
      : DateTime.parse(json['dateReported'] as String),
  severity: json['severity'] as int?,
  detail: json['detail'] as String?,
  userUUID: json['userUUID'] as String?,
  reportClearedBy: json['reportClearedBy'] as String?,
  officeReports: (json['officeReports'] as List<dynamic>?)
      ?.map((e) => OfficeReport.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'reportName': instance.reportName,
  'status': instance.status,
  'dateReported': instance.dateReported?.toIso8601String(),
  'severity': instance.severity,
  'detail': instance.detail,
  'userUUID': instance.userUUID,
  'reportClearedBy': instance.reportClearedBy,
  'officeReports': instance.officeReports?.map((e) => e.toJson()).toList(),
};

OfficeReport _$OfficeReportFromJson(Map<String, dynamic> json) =>
    OfficeReport(
      id: json['id'] as int?,
      reportId: json['reportId'] as int?,
      officeId: json['officeId'] as int?,
      numReportedDevices: json['numReportedDevices'] as int?,
      deviceReports: (json['deviceReports'] as List<dynamic>?)
          ?.map((e) => DeviceReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OfficeReportToJson(OfficeReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportId': instance.reportId,
      'officeId': instance.officeId,
      'numReportedDevices': instance.numReportedDevices,
      'deviceReports': instance.deviceReports
          ?.map((e) => e.toJson())
          .toList(),
    };

DeviceReport _$DeviceReportFromJson(Map<String, dynamic> json) =>
    DeviceReport(
      id: json['id'] as int?,
      severity: json['severity'] as int?,
      detail: json['detail'] as String?,
      officeReportId: json['officeReportId'] as int?,
      deviceId: json['deviceId'] as int?,
    );

Map<String, dynamic> _$DeviceReportToJson(DeviceReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'severity': instance.severity,
      'detail': instance.detail,
      'officeReportId': instance.officeReportId,
      'deviceId': instance.deviceId,
    };
