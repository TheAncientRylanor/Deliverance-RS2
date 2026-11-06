import 'package:deliverance_scout/models/scout_command.dart';
import 'package:deliverance_scout/utils/api_constants.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// Receives the commands an admin queues for this scout. The server adds the
/// connection to the scout's group on every (re)connect, so there is nothing
/// to join from here.
class ScoutHubClient {
  static const _hubPath = "hubs/scout";
  static const _commandEvent = "CommandQueued";

  /// Usually [ScoutAuthProvider.getAccessToken], which renews expired tokens.
  final Future<String> Function() accessTokenFactory;
  final void Function(ScoutCommand command) onCommandQueued;

  /// Called once automatic reconnecting gave up; [start] has to be called again.
  final void Function()? onClosed;

  ScoutHubClient({
    required this.accessTokenFactory,
    required this.onCommandQueued,
    this.onClosed,
  });

  HubConnection? _connection;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> start() async {
    await stop();
    final connection = HubConnectionBuilder()
        .withUrl(
          "${ApiConstants.baseUrl}$_hubPath",
          options: HttpConnectionOptions(accessTokenFactory: accessTokenFactory),
        )
        .withAutomaticReconnect()
        .build();

    connection.on(_commandEvent, (arguments) {
      final data = arguments?.firstOrNull;
      if (data is Map) {
        onCommandQueued(ScoutCommand.fromJson(Map<String, dynamic>.from(data)));
      }
    });
    connection.onclose(({error}) => onClosed?.call());

    _connection = connection;
    await connection.start();
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    await connection?.stop();
  }
}
