part of 'report.dart';

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: json['id'] as int?,
  reportName: json['reportName'] as String?,
  status: json['status'] as String?,
  dateReported: dateFromJson(json['dateReported'] as String),
  severity: json['severity'] as int?,
  detail: json['detail'] as String?,
  userUUID: json['userUUID'] as String?,
  reportClearedBy: json['reportClearedBy'] as String?,
  comment: json['comment'] as String?,
  dateCleared: nullableDateFromJson(json['dateCleared'] as String?),
  officeReports: (json['officeReports'] as List<dynamic>?)
      ?.map((e) => OfficeReport.fromJson(e as Map<String, dynamic>))
      .toList(),
  reportOccurrences: (json['reportOccurrences'] as List<dynamic>?)
      ?.map((e) => ReportOccurrence.fromJson(e as Map<String, dynamic>))
      .toList(),
  issueType: json['issueType'] as int?,
  isDraft: json['isDraft'] as bool? ?? false,
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'reportName': instance.reportName,
  'status': instance.status,
  'dateReported': dateToJson(instance.dateReported),
  'severity': instance.severity,
  'detail': instance.detail,
  'userUUID': instance.userUUID,
  'reportClearedBy': instance.reportClearedBy,
  'comment': instance.comment,
  'dateCleared': nullableDateToJson(instance.dateCleared),
  'officeReports': instance.officeReports?.map((e) => e.toJson()).toList(),
  'reportOccurrences': instance.reportOccurrences
      ?.map((e) => e.toJson())
      .toList(),
  'issueType': instance.issueType,
  'isDraft': instance.isDraft,
};

OfficeReport _$OfficeReportFromJson(Map<String, dynamic> json) => OfficeReport(
  id: json['id'] as int?,
  reportId: json['reportId'] as int?,
  officeId: json['officeId'] as int?,
  numReportedDevices: json['numReportedDevices'] as int?,
  deviceReports: (json['deviceReports'] as List<dynamic>?)
      ?.map((e) => DeviceReport.fromJson(e as Map<String, dynamic>))
      .toList(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$OfficeReportToJson(OfficeReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportId': instance.reportId,
      'officeId': instance.officeId,
      'numReportedDevices': instance.numReportedDevices,
      'deviceReports': instance.deviceReports.map((e) => e.toJson()).toList(),
      'name': instance.name,
    };

DeviceReport _$DeviceReportFromJson(Map<String, dynamic> json) => DeviceReport(
  id: json['id'] as int?,
  occurrence: json['occurrence'] as String?,
  detail: json['detail'] as String?,
  officeReportId: json['officeReportId'] as int?,
  deviceId: json['deviceId'] as int?,
  name: json['name'] as String,
);

Map<String, dynamic> _$DeviceReportToJson(DeviceReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'occurrence': instance.occurrence,
      'detail': instance.detail,
      'officeReportId': instance.officeReportId,
      'deviceId': instance.deviceId,
      'name': instance.name,
    };

ReportOccurrence _$ReportOccurrenceFromJson(Map<String, dynamic> json) =>
    ReportOccurrence(
      occurrenceId: json['occurrenceId'] as int?,
      question: json['question'] as String?,
      answer: json['answer'] as int?,
    );

Map<String, dynamic> _$ReportOccurrenceToJson(ReportOccurrence instance) =>
    <String, dynamic>{
      'occurrenceId': instance.occurrenceId,
      'question': instance.question,
      'answer': instance.answer,
    };
