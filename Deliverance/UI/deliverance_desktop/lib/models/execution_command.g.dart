part of 'execution_command.dart';

ExecutionCommand _$ExecutionCommandFromJson(Map<String, dynamic> json) =>
    ExecutionCommand(id: json['id'] as int?, name: json['name'] as String?);

Map<String, dynamic> _$ExecutionCommandToJson(ExecutionCommand instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
