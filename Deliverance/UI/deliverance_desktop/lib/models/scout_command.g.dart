part of 'scout_command.dart';

ScoutCommand _$ScoutCommandFromJson(Map<String, dynamic> json) => ScoutCommand(
  id: json['id'] as int,
  scoutId: json['scoutId'] as int,
  deviceId: json['deviceId'] as int,
  executionCommandId: ExecutionCommandEnum.fromValue(
    json['executionCommandId'] as int,
  ),
  commandText: json['commandText'] as String,
  status: ScoutCommandStatusEnum.fromValue(json['status'] as int),
  output: json['output'] as String?,
  exitCode: json['exitCode'] as int?,
  createdByUserUUID: json['createdByUserUUID'] as String?,
  createdAt: dateFromJson(json['createdAt'] as String),
  completedAt: nullableDateFromJson(json['completedAt'] as String?),
);

Map<String, dynamic> _$ScoutCommandInsertRequestToJson(
  ScoutCommandInsertRequest instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'executionCommandId': instance.executionCommandId.value,
  'commandText': instance.commandText,
};
