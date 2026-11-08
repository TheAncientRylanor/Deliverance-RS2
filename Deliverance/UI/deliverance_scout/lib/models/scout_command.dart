enum ExecutionCommandType {
  cmd(1),
  powerShell(2);

  final int value;
  const ExecutionCommandType(this.value);

  static ExecutionCommandType fromValue(int value) =>
      ExecutionCommandType.values.firstWhere((e) => e.value == value);
}

enum ScoutCommandStatus {
  pending(1),
  running(2),
  completed(3),
  failed(4),
  timedOut(5);

  final int value;
  const ScoutCommandStatus(this.value);

  static ScoutCommandStatus fromValue(int value) =>
      ScoutCommandStatus.values.firstWhere((e) => e.value == value);
}

class ScoutCommand {
  final int id;
  final ExecutionCommandType executionCommandId;
  final String commandText;
  final ScoutCommandStatus status;
  final DateTime createdAt;

  ScoutCommand({
    required this.id,
    required this.executionCommandId,
    required this.commandText,
    required this.status,
    required this.createdAt,
  });

  factory ScoutCommand.fromJson(Map<String, dynamic> json) => ScoutCommand(
    id: json['id'] as int,
    executionCommandId: ExecutionCommandType.fromValue(
      json['executionCommandId'] as int,
    ),
    commandText: json['commandText'] as String,
    status: ScoutCommandStatus.fromValue(json['status'] as int),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class ScoutCommandResult {
  final ScoutCommandStatus status;
  final String? output;
  final int? exitCode;

  ScoutCommandResult({required this.status, this.output, this.exitCode});

  Map<String, dynamic> toJson() => {
    'status': status.value,
    'output': output,
    'exitCode': exitCode,
  };
}
