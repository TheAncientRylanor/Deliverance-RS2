import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int? id;
  final String? reportName;
  final String? status;
  final DateTime dateReported;
  final int? severity;
  final String? detail;
  final String? userUUID;
  final String? reportClearedBy;
  final List<OfficeReport>? officeReports;
  final List<ReportOccurance>? reportOccurances;
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
    this.officeReports,
    this.reportOccurances,
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
  final String? occurance;
  final String? detail;
  final int? officeReportId;
  final int? deviceId;
  final String? name;
  DeviceReport({
    this.id,
    this.occurance,
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
class ReportOccurance {
  final int? occuranceId;
  final String? question;
  int? answer;

  ReportOccurance({this.occuranceId, this.question, this.answer});

  factory ReportOccurance.fromJson(Map<String, dynamic> json) =>
      _$ReportOccuranceFromJson(json);

  Map<String, dynamic> toJson() => _$ReportOccuranceToJson(this);
}
