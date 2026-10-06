part of 'report_statistics.dart';

OfficeReportCount _$OfficeReportCountFromJson(Map<String, dynamic> json) =>
    OfficeReportCount(
      officeId: json['officeId'] as int?,
      officeName: json['officeName'] as String?,
      reportCount: json['reportCount'] as int?,
    );

Map<String, dynamic> _$OfficeReportCountToJson(OfficeReportCount instance) =>
    <String, dynamic>{
      'officeId': instance.officeId,
      'officeName': instance.officeName,
      'reportCount': instance.reportCount,
    };

DeviceReportCount _$DeviceReportCountFromJson(Map<String, dynamic> json) =>
    DeviceReportCount(
      deviceId: json['deviceId'] as int?,
      deviceName: json['deviceName'] as String?,
      reportCount: json['reportCount'] as int?,
    );

Map<String, dynamic> _$DeviceReportCountToJson(DeviceReportCount instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'reportCount': instance.reportCount,
    };

UserReportCount _$UserReportCountFromJson(Map<String, dynamic> json) =>
    UserReportCount(
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      reportCount: json['reportCount'] as int?,
    );

Map<String, dynamic> _$UserReportCountToJson(UserReportCount instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'reportCount': instance.reportCount,
    };

TimeReportBreakdown _$TimeReportBreakdownFromJson(Map<String, dynamic> json) =>
    TimeReportBreakdown(
      month: json['month'] == null
          ? null
          : DateTime.parse(json['month'] as String),
      reportsByDay: (json['reportsByDay'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as int),
      ),
    );

Map<String, dynamic> _$TimeReportBreakdownToJson(
  TimeReportBreakdown instance,
) => <String, dynamic>{
  'month': instance.month?.toIso8601String(),
  'reportsByDay': instance.reportsByDay?.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
};

ReportStatistics _$ReportStatisticsFromJson(Map<String, dynamic> json) =>
    ReportStatistics(
      id: json['id'] as int?,
      timePeriodWithMostRep: json['timePeriodWithMostRep'] == null
          ? null
          : DateTime.parse(json['timePeriodWithMostRep'] as String),
      officeWithMostRep: json['officeWithMostRep'] == null
          ? null
          : OfficeReportCount.fromJson(
              json['officeWithMostRep'] as Map<String, dynamic>,
            ),
      deviceWithMostRep: json['deviceWithMostRep'] == null
          ? null
          : DeviceReportCount.fromJson(
              json['deviceWithMostRep'] as Map<String, dynamic>,
            ),
      userWithMostRep: json['userWithMostRep'] == null
          ? null
          : UserReportCount.fromJson(
              json['userWithMostRep'] as Map<String, dynamic>,
            ),
      timeBreakdown: json['timeBreakdown'] == null
          ? null
          : TimeReportBreakdown.fromJson(
              json['timeBreakdown'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ReportStatisticsToJson(
  ReportStatistics instance,
) => <String, dynamic>{
  'id': instance.id,
  'timePeriodWithMostRep': instance.timePeriodWithMostRep?.toIso8601String(),
  'officeWithMostRep': instance.officeWithMostRep,
  'deviceWithMostRep': instance.deviceWithMostRep,
  'userWithMostRep': instance.userWithMostRep,
  'timeBreakdown': instance.timeBreakdown,
};
