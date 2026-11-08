import 'dart:convert';

import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  static String? _accesstoken;
  static String? _refreshtoken;
  static const _storage = FlutterSecureStorage();
  static String? get accesstoken => _accesstoken;
  String? get refreshtoken => _refreshtoken;
  final String _baseUrl = ApiConstants.baseUrl;
  static final AuthProvider instance = AuthProvider._internal();
  Future<bool>? _refreshFuture;
  factory AuthProvider() {
    return instance;
  }

  AuthProvider._internal();
  Future login(String username, String password) async {
    var url = "${_baseUrl}Access/Login";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var body = jsonEncode({"username": username, "password": password});

    var response = await http.post(uri, headers: headers, body: body);

    validateResponse(response);
    var data = jsonDecode(response.body);
    _accesstoken = data['accesstoken'];
    _refreshtoken = data['refreshtoken'];
    await saveToken();
    notifyListeners();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    var uri = Uri.parse("${_baseUrl}Access/ChangePassword");
    var body = jsonEncode({
      "oldPassword": oldPassword,
      "newPassword": newPassword,
    });

    Future<http.Response> send() => http.post(
      uri,
      headers: {
        ...createHeaders(),
        "Authorization": "Bearer ${_accesstoken ?? ''}",
      },
      body: body,
    );

    var response = await send();
    if (response.statusCode == 401 && await refreshToken()) {
      response = await send();
    }

    validateResponse(response);
    await _clearSession();
  }

  Future<void> logout() async {
    try {
      var response = await _postLogout();
      if (response.statusCode == 401 && await refreshToken()) {
        response = await _postLogout();
      }
    } catch (_) {}
    await _clearSession();
  }

  Future<http.Response> _postLogout() {
    final token = _accesstoken;
    if (token == null || token.isEmpty) {
      return Future.value(http.Response('', 401));
    }
    return http
        .post(
          Uri.parse("${_baseUrl}Access/Logout"),
          headers: {...createHeaders(), "Authorization": "Bearer $token"},
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<void> _clearSession() async {
    _accesstoken = null;
    _refreshtoken = null;
    await deleteToken();
    notifyListeners();
  }

  void validateResponse(http.Response response) {
    if (response.statusCode < 299) {
      return;
    }
    if (response.statusCode == 401) {
      throw ApiClientException(
        'Your session has expired. Please sign in again.',
      );
    }

    final parsed = ApiErrorParser.messageFromBody(response.body);
    if (response.statusCode >= 500) {
      throw ApiClientException(
        parsed ?? 'Server error. Please try again later.',
      );
    }

    throw ApiClientException(
      parsed ?? 'Request could not be completed. Please try again.',
      fieldErrors: ApiErrorParser.fieldErrorsFromBody(response.body),
      statusCode: response.statusCode,
    );
  }

  Map<String, String> createHeaders() {
    var headers = {"Content-Type": "application/json"};

    return headers;
  }

  Future<AuthStatus> tryAutoLogin() async {
    final storedAccess = await _storage.read(key: "jwt_token");
    final storedRefresh = await _storage.read(key: "refresh_token");
    if (storedAccess == null || storedAccess.isEmpty) {
      return AuthStatus.unauthenticated;
    }

    if (!checkIfTokenExpired(storedAccess)) {
      _accesstoken = storedAccess;
      _refreshtoken = storedRefresh;
      notifyListeners();
      return AuthStatus.authenticated;
    }

    if (storedRefresh == null || storedRefresh.isEmpty) {
      await deleteToken();
      return AuthStatus.unauthenticated;
    }

    _refreshtoken = storedRefresh;
    try {
      await loginWithRefreshToken();
      return AuthStatus.authenticated;
    } catch (_) {
      await deleteToken();
      return AuthStatus.unauthenticated;
    }
  }

  Future<bool> loginWithRefreshToken() async {
    var url = "${_baseUrl}Access/LoginWithRefreshToken";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var body = jsonEncode({"refreshToken": refreshtoken});

    http.Response response = await http
        .post(uri, headers: headers, body: body)
        .timeout(ApiConstants.authRequestTimeout);

    validateResponse(response);
    var data = jsonDecode(response.body);
    _accesstoken = data['accesstoken'];
    _refreshtoken = data['refreshtoken'];
    await saveToken();
    notifyListeners();
    return true;
  }

  Future<bool> refreshToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    _refreshFuture = _executeRefreshProcess();

    try {
      final success = await _refreshFuture!;
      return success;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _executeRefreshProcess() async {
    final storedRefresh = _refreshtoken;
    if (storedRefresh == null || storedRefresh.isEmpty) {
      await _clearSession();
      return false;
    }
    try {
      await loginWithRefreshToken();
      return true;
    } catch (_) {
      await _clearSession();
      return false;
    }
  }

  static bool checkIfTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveToken() async {
    await Future.wait([
      _storage.write(key: "jwt_token", value: _accesstoken),
      _storage.write(key: "refresh_token", value: _refreshtoken),
    ]);
  }

  Future<void> deleteToken() async {
    await Future.wait([
      _storage.delete(key: "jwt_token"),
      _storage.delete(key: "refresh_token"),
    ]);
  }
}
