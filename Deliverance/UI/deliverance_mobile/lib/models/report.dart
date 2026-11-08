import 'package:deliverance_mobile/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int? id;
  final String? reportName;
  final String? status;
  @JsonKey(fromJson: dateFromJson, toJson: dateToJson)
  final DateTime dateReported;
  final int? severity;
  final String? detail;
  final String? userUUID;
  final String? reportClearedBy;
  final String? comment;
  @JsonKey(fromJson: nullableDateFromJson, toJson: nullableDateToJson)
  final DateTime? dateCleared;
  final List<OfficeReport>? officeReports;
  final List<ReportOccurrence>? reportOccurrences;
  final int? issueType;
  final bool isDraft;
  Report({
    this.id,
    this.reportName,
    this.status,
    required this.dateReported,
    this.severity,
    this.detail,
    this.userUUID,
    this.reportClearedBy,
    this.comment,
    this.dateCleared,
    this.officeReports,
    this.reportOccurrences,
    this.issueType,
    this.isDraft = false,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  Map<String, dynamic> toJson() => _$ReportToJson(this);
}

@JsonSerializable()
class OfficeReport {
  final int? id;
  final int? reportId;
  final int? officeId;
  final int? numReportedDevices;
  final List<DeviceReport> deviceReports;
  final String? name;
  OfficeReport({
    this.id,
    this.reportId,
    this.officeId,
    this.numReportedDevices,
    this.name,
    List<DeviceReport>? deviceReports,
  }) : deviceReports = deviceReports ?? [];

  factory OfficeReport.fromJson(Map<String, dynamic> json) =>
      _$OfficeReportFromJson(json);

  Map<String, dynamic> toJson() => _$OfficeReportToJson(this);
}

@JsonSerializable()
class DeviceReport {
  final int? id;
  final String? occurrence;
  final String? detail;
  final int? officeReportId;
  final int? deviceId;
  final String? name;
  DeviceReport({
    this.id,
    this.occurrence,
    this.detail,
    this.officeReportId,
    this.deviceId,
    this.name,
  });

  factory DeviceReport.fromJson(Map<String, dynamic> json) =>
      _$DeviceReportFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReportToJson(this);
}

@JsonSerializable()
class ReportOccurrence {
  final int? occurrenceId;
  final String? question;
  int? answer;

  ReportOccurrence({this.occurrenceId, this.question, this.answer});

  factory ReportOccurrence.fromJson(Map<String, dynamic> json) =>
      _$ReportOccurrenceFromJson(json);

  Map<String, dynamic> toJson() => _$ReportOccurrenceToJson(this);
}
