import 'dart:async';
import 'dart:convert';

import 'package:deliverance_scout/models/scout_token.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/api_constants.dart';
import 'package:deliverance_scout/utils/scout_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum ScoutState {
  /// Checking the stored secret with the server.
  loading,

  /// No secret: the token has to be pasted and claimed.
  unenrolled,

  /// Claimed, but the admin hasn't saved the device yet.
  awaitingApproval,

  /// Approved: the secret can be exchanged for access tokens.
  active,

  /// An admin disabled the scout: no access tokens until it is enabled again.
  disabled,
}

/// The server answered 401: the secret is unknown, the enrollment was
/// cancelled, or the device was deleted.
class ScoutRevokedException implements Exception {}

/// Owns the scout's credentials: the long-term secret (from claiming the
/// enrollment token) and the short-lived access token it is exchanged for.
class ScoutAuthProvider with ChangeNotifier {
  static const _tokenEndpoint = "Scout/Auth/Token";
  static const _pollInterval = Duration(seconds: 5);
  // Renew a little before expiry so a request doesn't race the deadline.
  static const _expiryMargin = Duration(minutes: 1);
  static const _revokedMessage =
      "This scout's enrollment was cancelled or its device was deleted. "
      "Enroll it again with a new token.";
  static const _disabledMessage = "This scout was disabled by an admin.";

  ScoutState _state;
  String? _secret;
  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  String? _message;
  Timer? _pollTimer;
  bool _checking = false;

  ScoutAuthProvider({@visibleForTesting ScoutState? initialState})
    : _state = initialState ?? ScoutState.loading;

  ScoutState get state => _state;

  /// Why the scout is back at enrollment, or a connection problem.
  String? get message => _message;

  Future<void> initialize() async {
    _secret = await ScoutStorage.readSecret();
    if (_secret == null) {
      _setState(ScoutState.unenrolled);
      return;
    }
    await _checkCredentials();
  }

  /// Called after the enrollment token was claimed successfully.
  Future<void> onEnrolled(String secret) async {
    await ScoutStorage.writeSecret(secret);
    _secret = secret;
    _message = null;
    _setState(ScoutState.awaitingApproval);
    _startPolling();
  }

  /// A valid access token for scout endpoints, exchanging the secret when the
  /// cached one is missing or about to expire.
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    final expiresAt = _accessTokenExpiresAt;
    if (!forceRefresh &&
        _accessToken != null &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt.subtract(_expiryMargin))) {
      return _accessToken!;
    }

    await _checkCredentials();
    final token = _accessToken;
    if (_state != ScoutState.active || token == null) {
      throw ApiClientException(
        _message ??
            (_state == ScoutState.disabled
                ? _disabledMessage
                : "This scout isn't approved by an admin yet."),
      );
    }
    return token;
  }

  /// Asks the server again right away, e.g. to see if the scout was enabled.
  Future<void> refresh() => _checkCredentials();

  /// Removes the credentials from this PC. The scout stays registered on the
  /// server until an admin deletes its device.
  Future<void> forget({String? message}) async {
    _stopPolling();
    await ScoutStorage.deleteSecret();
    await ScoutStorage.deleteLogCheckpoint();
    _secret = null;
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _message = message;
    _setState(ScoutState.unenrolled);
  }

  /// Exchanges the secret and moves to the state the server reports.
  Future<void> _checkCredentials() async {
    if (_checking) return;
    _checking = true;
    try {
      final token = await _requestToken();
      _message = null;
      if (token.status == ScoutTokenStatus.active) {
        _accessToken = token.accessToken;
        _accessTokenExpiresAt = token.expiresAt?.toLocal();
        _stopPolling();
        _setState(ScoutState.active);
      } else {
        // Pending approval or disabled: no token, keep polling until that changes.
        _accessToken = null;
        _accessTokenExpiresAt = null;
        _setState(
          token.status == ScoutTokenStatus.disabled
              ? ScoutState.disabled
              : ScoutState.awaitingApproval,
        );
        _startPolling();
      }
    } on ScoutRevokedException {
      await forget(message: _revokedMessage);
    } on ApiClientException catch (e) {
      // Server unreachable or failing: keep the secret and keep trying.
      _message = e.message;
      notifyListeners();
      _startPolling();
    } finally {
      _checking = false;
    }
  }

  Future<ScoutToken> _requestToken() async {
    final secret = _secret;
    if (secret == null) throw ScoutRevokedException();

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}$_tokenEndpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'secret': secret}),
      );
    } on Exception {
      throw ApiClientException(
        "Could not reach the server at ${ApiConstants.baseUrl}. Retrying...",
      );
    }

    if (response.statusCode == 401) throw ScoutRevokedException();
    if (response.statusCode >= 300) {
      throw ApiClientException(
        ApiErrorParser.messageFromBody(response.body) ??
            "Server error. Retrying...",
      );
    }
    return ScoutToken.fromJson(jsonDecode(response.body));
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(_pollInterval, (_) => _checkCredentials());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setState(ScoutState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
