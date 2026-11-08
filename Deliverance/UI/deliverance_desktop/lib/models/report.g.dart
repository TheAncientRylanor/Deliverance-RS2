part of 'report.dart';

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as int?,
  reportName: json['reportName'] as String?,
  status: json['status'] as String?,
  dateReported: nullableDateFromJson(json['dateReported'] as String?),
  severity: json['severity'] as int?,
  issueType: json['issueType'] as int?,
  detail: json['detail'] as String?,
  userUUID: json['userUUID'] as String?,
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  reportClearedBy: json['reportClearedBy'] as String?,
  comment: json['comment'] as String?,
  officeReports: (json['officeReports'] as List<dynamic>?)
      ?.map((e) => OfficeReport.fromJson(e as Map<String, dynamic>))
      .toList(),
  reportOccurances: (json['reportOccurances'] as List<dynamic>?)
      ?.map((e) => ReportOccurance.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'reportName': instance.reportName,
  'status': instance.status,
  'dateReported': nullableDateToJson(instance.dateReported),
  'severity': instance.severity,
  'issueType': instance.issueType,
  'detail': instance.detail,
  'userUUID': instance.userUUID,
  'user': instance.user?.toJson(),
  'reportClearedBy': instance.reportClearedBy,
  'comment': instance.comment,
  'officeReports': instance.officeReports?.map((e) => e.toJson()).toList(),
  'reportOccurances': instance.reportOccurances
      ?.map((e) => e.toJson())
      .toList(),
};

OfficeReport _$OfficeReportFromJson(Map<String, dynamic> json) => OfficeReport(
  id: json['id'] as int,
  reportId: json['reportId'] as int,
  officeId: json['officeId'] as int,
  name: json['name'] as String?,
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
      'name': instance.name,
      'numReportedDevices': instance.numReportedDevices,
      'deviceReports': instance.deviceReports?.map((e) => e.toJson()).toList(),
    };

DeviceReport _$DeviceReportFromJson(Map<String, dynamic> json) => DeviceReport(
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

ReportOccurance _$ReportOccuranceFromJson(Map<String, dynamic> json) =>
    ReportOccurance(
      question: json['question'] as String?,
      answer: json['answer'] as int?,
    );

Map<String, dynamic> _$ReportOccuranceToJson(ReportOccurance instance) =>
    <String, dynamic>{'question': instance.question, 'answer': instance.answer};
