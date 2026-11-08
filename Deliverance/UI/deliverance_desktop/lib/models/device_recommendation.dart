import 'package:deliverance_desktop/utils/date_json.dart';

class DeviceRecommendation {
  final int deviceId;
  final String deviceName;
  final String officeName;
  final double needsFixProbability;
  final int likelyIssue;
  final int reportsLast30Days;

  DeviceRecommendation({
    required this.deviceId,
    required this.deviceName,
    required this.officeName,
    required this.needsFixProbability,
    required this.likelyIssue,
    required this.reportsLast30Days,
  });

  String get probabilityLabel =>
      '${(needsFixProbability * 100).toStringAsFixed(0)}%';

  factory DeviceRecommendation.fromJson(Map<String, dynamic> json) =>
      DeviceRecommendation(
        deviceId: json['deviceId'] as int,
        deviceName: json['deviceName'] as String,
        officeName: json['officeName'] as String,
        needsFixProbability: (json['needsFixProbability'] as num).toDouble(),
        likelyIssue: json['likelyIssue'] as int,
        reportsLast30Days: (json['reportsLast30Days'] as num).toInt(),
      );
}

class DeviceEvidence {
  final DeviceRecommendation recommendation;
  final List<DeviceEvidenceLog> logs;
  final List<DeviceEvidenceReport> reports;

  DeviceEvidence({
    required this.recommendation,
    required this.logs,
    required this.reports,
  });

  factory DeviceEvidence.fromJson(Map<String, dynamic> json) => DeviceEvidence(
    recommendation: DeviceRecommendation.fromJson(
      json['recommendation'] as Map<String, dynamic>,
    ),
    logs: (json['logs'] as List)
        .map((e) => DeviceEvidenceLog.fromJson(e as Map<String, dynamic>))
        .toList(),
    reports: (json['reports'] as List)
        .map((e) => DeviceEvidenceReport.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class DeviceEvidenceLog {
  final DateTime dateLogged;
  final String log;

  DeviceEvidenceLog({required this.dateLogged, required this.log});

  factory DeviceEvidenceLog.fromJson(Map<String, dynamic> json) =>
      DeviceEvidenceLog(
        dateLogged: dateFromJson(json['dateLogged'] as String),
        log: json['log'] as String,
      );
}

class DeviceEvidenceReport {
  final int reportId;
  final String reportName;
  final DateTime dateReported;
  final String? status;
  final int? severity;
  final int? issueType;
  final String? detail;
  final String? comment;

  DeviceEvidenceReport({
    required this.reportId,
    required this.reportName,
    required this.dateReported,
    this.status,
    this.severity,
    this.issueType,
    this.detail,
    this.comment,
  });

  factory DeviceEvidenceReport.fromJson(Map<String, dynamic> json) =>
      DeviceEvidenceReport(
        reportId: json['reportId'] as int,
        reportName: json['reportName'] as String,
        dateReported: dateFromJson(json['dateReported'] as String),
        status: json['status'] as String?,
        severity: json['severity'] as int?,
        issueType: json['issueType'] as int?,
        detail: json['detail'] as String?,
        comment: json['comment'] as String?,
      );
}
