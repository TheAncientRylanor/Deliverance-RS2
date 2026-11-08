import 'package:deliverance_desktop/models/scout_command.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';

class ScoutCommandProvider extends BaseProvider<ScoutCommand> {
  ScoutCommandProvider() : super("Device/ScoutCommand");

  @override
  ScoutCommand fromJson(data) {
    return ScoutCommand.fromJson(data);
  }

  Future<ScoutCommand> sendCommand(ScoutCommandInsertRequest request) =>
      insert(request);
}
