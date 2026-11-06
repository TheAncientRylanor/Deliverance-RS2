import 'package:deliverance_desktop/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int? id;
  final String? reportName;
  final String? status;
  final DateTime? dateReported;
  final int? severity;
  final int? issueType;
  final String? detail;
  final String? userUUID;
  final User? user;
  final String? reportClearedBy;
  final String? comment;
  final List<OfficeReport>? officeReports;
  final List<ReportOccurance>? reportOccurances;

  Report({
    this.id,
    this.reportName,
    this.status,
    this.dateReported,
    this.severity,
    this.issueType,
    this.detail,
    this.userUUID,
    this.user,
    this.reportClearedBy,
    this.comment,
    this.officeReports,
    this.reportOccurances,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  Map<String, dynamic> toJson() => _$ReportToJson(this);
}

@JsonSerializable()
class OfficeReport {
  final int id;
  final int reportId;
  final int officeId;
  final String? name;
  final int? numReportedDevices;
  final List<DeviceReport>? deviceReports;

  OfficeReport({
    required this.id,
    required this.reportId,
    required this.officeId,
    this.name,
    this.numReportedDevices,
    this.deviceReports,
  });

  factory OfficeReport.fromJson(Map<String, dynamic> json) =>
      _$OfficeReportFromJson(json);

  Map<String, dynamic> toJson() => _$OfficeReportToJson(this);
}

@JsonSerializable()
class DeviceReport {
  final int? id;
  final int? severity;
  final String? detail;
  final int? officeReportId;
  final int? deviceId;

  DeviceReport({
    this.id,
    this.severity,
    this.detail,
    this.officeReportId,
    this.deviceId,
  });

  factory DeviceReport.fromJson(Map<String, dynamic> json) =>
      _$DeviceReportFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReportToJson(this);
}

@JsonSerializable()
class ReportOccurance {
  final String? question;
  final int? answer;

  ReportOccurance({this.question, this.answer});

  factory ReportOccurance.fromJson(Map<String, dynamic> json) =>
      _$ReportOccuranceFromJson(json);

  Map<String, dynamic> toJson() => _$ReportOccuranceToJson(this);
}
