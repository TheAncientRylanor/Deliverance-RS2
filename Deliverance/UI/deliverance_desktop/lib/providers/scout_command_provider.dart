import 'package:deliverance_desktop/models/scout_command.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';

class ScoutCommandProvider extends BaseProvider<ScoutCommand> {
  ScoutCommandProvider() : super("Device/ScoutCommand");

  @override
  ScoutCommand fromJson(data) {
    return ScoutCommand.fromJson(data);
  }

  /// Queues the command on the scout of [request]'s device. The returned
  /// command is Pending; later status changes arrive through the device hub.
  Future<ScoutCommand> sendCommand(ScoutCommandInsertRequest request) =>
      insert(request);
}
