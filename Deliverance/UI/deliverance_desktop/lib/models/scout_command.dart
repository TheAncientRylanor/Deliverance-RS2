import 'package:deliverance_desktop/models/execution_command_enum.dart';
import 'package:deliverance_desktop/models/scout_command_status_enum.dart';
import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scout_command.g.dart';

@JsonSerializable()
class ScoutCommand {
  final int id;
  final int scoutId;
  final int deviceId;
  final ExecutionCommandEnum executionCommandId;
  final String commandText;
  final ScoutCommandStatusEnum status;
  final String? output;
  final int? exitCode;
  final String? createdByUserUUID;
  @JsonKey(fromJson: dateFromJson, toJson: dateToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: nullableDateFromJson, toJson: nullableDateToJson)
  final DateTime? completedAt;

  ScoutCommand({
    required this.id,
    required this.scoutId,
    required this.deviceId,
    required this.executionCommandId,
    required this.commandText,
    required this.status,
    this.output,
    this.exitCode,
    this.createdByUserUUID,
    required this.createdAt,
    this.completedAt,
  });

  factory ScoutCommand.fromJson(Map<String, dynamic> json) =>
      _$ScoutCommandFromJson(json);
}

@JsonSerializable()
class ScoutCommandInsertRequest {
  final int deviceId;
  final ExecutionCommandEnum executionCommandId;
  final String commandText;

  ScoutCommandInsertRequest({
    required this.deviceId,
    required this.executionCommandId,
    required this.commandText,
  });

  Map<String, dynamic> toJson() => _$ScoutCommandInsertRequestToJson(this);
}
