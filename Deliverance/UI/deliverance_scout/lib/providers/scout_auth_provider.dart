import 'dart:async';
import 'dart:convert';

import 'package:deliverance_scout/models/scout_token.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/api_constants.dart';
import 'package:deliverance_scout/utils/scout_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum ScoutState {
  loading,

  unenrolled,

  awaitingApproval,

  active,

  disabled,
}

class ScoutRevokedException implements Exception {}

class ScoutAuthProvider with ChangeNotifier {
  static const _tokenEndpoint = "Scout/Auth/Token";
  static const _pollInterval = Duration(seconds: 5);
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

  String? get message => _message;

  Future<void> initialize() async {
    _secret = await ScoutStorage.readSecret();
    if (_secret == null) {
      _setState(ScoutState.unenrolled);
      return;
    }
    await _checkCredentials();
  }

  Future<void> onEnrolled(String secret) async {
    await ScoutStorage.writeSecret(secret);
    _secret = secret;
    _message = null;
    _setState(ScoutState.awaitingApproval);
    _startPolling();
  }

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

  Future<void> refresh() => _checkCredentials();

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
