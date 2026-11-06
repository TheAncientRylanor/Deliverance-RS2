import 'package:json_annotation/json_annotation.dart';

part 'execution_command.g.dart';

@JsonSerializable()
class ExecutionCommand {
  final int? id;
  final String? name;

  ExecutionCommand({this.id, this.name});

  factory ExecutionCommand.fromJson(Map<String, dynamic> json) =>
      _$ExecutionCommandFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionCommandToJson(this);
}
