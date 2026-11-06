import 'package:deliverance_desktop/models/execution_command.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';

class ExecutionCommandProvider extends BaseProvider<ExecutionCommand> {
  ExecutionCommandProvider() : super("ExecutionCommand");
  @override
  ExecutionCommand fromJson(data) {
    return ExecutionCommand.fromJson(data);
  }
}
