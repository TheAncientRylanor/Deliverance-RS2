import 'package:deliverance_desktop/models/scout_enrollment.dart';
import 'package:deliverance_desktop/models/scout_enrollment_status_enum.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Listens on the API's EnrollmentHub for one enrollment and reports when the
/// scout has claimed its token. Server side: Deliverance.WebAPI/Hubs/EnrollmentHub.cs.
class EnrollmentHubClient {
  // Names must match EnrollmentHub on the server.
  static const _hubPath = "hubs/enrollment";
  static const _joinMethod = "JoinEnrollment";
  static const _claimedEvent = "EnrollmentClaimed";

  final int enrollmentId;
  final void Function(ScoutEnrollment enrollment) onClaimed;

  HubConnection? _connection;
  bool _claimHandled = false;

  EnrollmentHubClient({required this.enrollmentId, required this.onClaimed});

  Future<void> start() async {
    final connection = HubConnectionBuilder()
        .withUrl(
          "${ApiConstants.baseUrl}$_hubPath",
          options: HttpConnectionOptions(accessTokenFactory: _accessToken),
        )
        .withAutomaticReconnect()
        .build();

    connection.on(_claimedEvent, (arguments) {
      final data = arguments?.firstOrNull;
      if (data is Map) {
        _handle(ScoutEnrollment.fromJson(Map<String, dynamic>.from(data)));
      }
    });
    // A reconnect gets a new connection id, which isn't in the group any more.
    connection.onreconnected(({connectionId}) async {
      try {
        await _join();
      } catch (_) {
        // Rejoining is best effort; the dialog stays usable without it.
      }
    });

    _connection = connection;
    await connection.start();
    await _join();
  }

  Future<void> stop() async {
    final connection = _connection;
    _connection = null;
    await connection?.stop();
  }

  /// Joins the enrollment's group. The server answers with the current state,
  /// which covers a claim that happened before we joined.
  Future<void> _join() async {
    final result = await _connection?.invoke(_joinMethod, args: [enrollmentId]);
    if (result is Map) {
      _handle(ScoutEnrollment.fromJson(Map<String, dynamic>.from(result)));
    }
  }

  void _handle(ScoutEnrollment enrollment) {
    // The claim can arrive both as the event and as the join result.
    if (_claimHandled ||
        enrollment.id != enrollmentId ||
        enrollment.status != ScoutEnrollmentStatusEnum.claimed) {
      return;
    }
    _claimHandled = true;
    onClaimed(enrollment);
  }

  /// SignalR asks for the token on every (re)connect, so refresh it first if
  /// it has expired; there is no 401 retry like in BaseProvider here.
  static Future<String> _accessToken() async {
    final token = AuthProvider.accesstoken;
    if (token == null || JwtDecoder.isExpired(token)) {
      await AuthProvider.instance.refreshToken();
    }
    return AuthProvider.accesstoken ?? "";
  }
}
