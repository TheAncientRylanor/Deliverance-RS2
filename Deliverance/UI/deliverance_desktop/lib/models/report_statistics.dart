import 'package:json_annotation/json_annotation.dart';

part 'report_statistics.g.dart';

@JsonSerializable()
class OfficeReportCount {
  final int? officeId;
  final String? officeName;
  final int? reportCount;

  OfficeReportCount({this.officeId, this.officeName, this.reportCount});

  factory OfficeReportCount.fromJson(Map<String, dynamic> json) =>
      _$OfficeReportCountFromJson(json);

  Map<String, dynamic> toJson() => _$OfficeReportCountToJson(this);
}

@JsonSerializable()
class DeviceReportCount {
  final int? deviceId;
  final String? deviceName;
  final int? reportCount;

  DeviceReportCount({this.deviceId, this.deviceName, this.reportCount});

  factory DeviceReportCount.fromJson(Map<String, dynamic> json) =>
      _$DeviceReportCountFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReportCountToJson(this);
}

@JsonSerializable()
class UserReportCount {
  final String? userId;
  final String? username;
  final int? reportCount;

  UserReportCount({this.userId, this.username, this.reportCount});

  factory UserReportCount.fromJson(Map<String, dynamic> json) =>
      _$UserReportCountFromJson(json);

  Map<String, dynamic> toJson() => _$UserReportCountToJson(this);
}

@JsonSerializable()
class TimeReportBreakdown {
  final DateTime? month;
  final Map<int, int>? reportsByDay;

  TimeReportBreakdown({this.month, this.reportsByDay});

  factory TimeReportBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TimeReportBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$TimeReportBreakdownToJson(this);
}

@JsonSerializable()
class ReportStatistics {
  final int? id;
  final DateTime? timePeriodWithMostRep;
  final OfficeReportCount? officeWithMostRep;
  final DeviceReportCount? deviceWithMostRep;
  final UserReportCount? userWithMostRep;
  final TimeReportBreakdown? timeBreakdown;

  ReportStatistics({
    this.id,
    this.timePeriodWithMostRep,
    this.officeWithMostRep,
    this.deviceWithMostRep,
    this.userWithMostRep,
    this.timeBreakdown,
  });

  factory ReportStatistics.fromJson(Map<String, dynamic> json) =>
      _$ReportStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$ReportStatisticsToJson(this);
}
