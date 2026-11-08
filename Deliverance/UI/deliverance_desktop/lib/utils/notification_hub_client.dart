import 'package:deliverance_desktop/models/app_notification.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Receives the logged-in user's new notifications. There is nothing to join:
/// the server sends them to the user the token belongs to.
class NotificationHubClient {
  static const _hubPath = "hubs/notification";
  static const _createdEvent = "NotificationCreated";

  final void Function(AppNotification notification) onCreated;

  /// Anything sent while the connection was down has to be loaded again.
  final void Function() onReconnected;

  NotificationHubClient({required this.onCreated, required this.onReconnected});

  HubConnection? _connection;

  bool get isDisconnected =>
      _connection == null ||
      _connection?.state == HubConnectionState.Disconnected;

  Future<void> start() async {
    await stop();
    final connection = HubConnectionBuilder()
        .withUrl(
          "${ApiConstants.baseUrl}$_hubPath",
          options: HttpConnectionOptions(accessTokenFactory: _accessToken),
        )
        .withAutomaticReconnect()
        .build();

    connection.on(_createdEvent, (arguments) {
      final data = arguments?.firstOrNull;
      if (data is Map) {
        onCreated(AppNotification.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    connection.onreconnected(({connectionId}) => onReconnected());

    _connection = connection;
    await connection.start();
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    await connection?.stop();
  }

  static Future<String> _accessToken() async {
    final token = AuthProvider.accesstoken;
    if (token == null || JwtDecoder.isExpired(token)) {
      await AuthProvider.instance.refreshToken();
    }
    return AuthProvider.accesstoken ?? "";
  }
}
