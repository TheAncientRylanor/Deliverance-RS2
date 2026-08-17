import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int? id;
  final String? reportName;
  final int? status;
  final DateTime? dateReported;
  final int? severity;
  final String? detail;
  final String? userUUID;
  final String? reportClearedBy;
  final List<OfficeReport>? officeReports;

  Report({
    this.id,
    this.reportName,
    this.status,
    this.dateReported,
    this.severity,
    this.detail,
    this.userUUID,
    this.reportClearedBy,
    this.officeReports,
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
  final List<DeviceReport>? deviceReports;

  OfficeReport({
    this.id,
    this.reportId,
    this.officeId,
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
  final String? occurance;
  final String? detail;
  final int? officeReportId;
  final int? deviceId;

  DeviceReport({
    this.id,
    this.occurance,
    this.detail,
    this.officeReportId,
    this.deviceId,
  });

  factory DeviceReport.fromJson(Map<String, dynamic> json) =>
      _$DeviceReportFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReportToJson(this);
}
