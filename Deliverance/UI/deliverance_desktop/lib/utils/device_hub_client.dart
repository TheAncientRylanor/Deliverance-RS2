import 'package:deliverance_desktop/models/scout_command.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Receives the status changes of the commands sent to one device's scout.
/// Admins only: the server refuses [start] for other users.
class DeviceHubClient {
  static const _hubPath = "hubs/device";
  static const _joinMethod = "JoinDeviceHub";
  static const _commandEvent = "CommandExecuted";
  final int deviceId;

  /// Called for every command of [deviceId], not only the ones this admin sent.
  final void Function(ScoutCommand command) onStatusChanged;
  DeviceHubClient({required this.deviceId, required this.onStatusChanged});

  HubConnection? _connection;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> start() async {
    await stop();
    final connection = HubConnectionBuilder()
        .withUrl(
          "${ApiConstants.baseUrl}$_hubPath",
          options: HttpConnectionOptions(accessTokenFactory: _accessToken),
        )
        .withAutomaticReconnect()
        .build();

    connection.on(_commandEvent, (arguments) {
      final data = arguments?.firstOrNull;
      if (data is Map) {
        _handle(ScoutCommand.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    connection.onreconnected(({connectionId}) async {
      try {
        await _join();
      } catch (_) {}
    });
    _connection = connection;
    await connection.start();
    await _join();
  }

  /// Closing the connection also takes it out of the device's group.
  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    await connection?.stop();
  }

  void _handle(ScoutCommand command) {
    onStatusChanged(command);
  }

  Future<void> _join() async {
    await _connection?.invoke(_joinMethod, args: [deviceId]);
  }

  static Future<String> _accessToken() async {
    final token = AuthProvider.accesstoken;
    if (token == null || JwtDecoder.isExpired(token)) {
      await AuthProvider.instance.refreshToken();
    }
    return AuthProvider.accesstoken ?? "";
  }
}
