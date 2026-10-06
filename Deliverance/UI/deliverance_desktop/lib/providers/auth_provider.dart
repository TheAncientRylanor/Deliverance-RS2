// ignore_for_file: non_constant_identifier_names, prefer_final_fields

import 'dart:convert';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

enum AuthStatus { authenticated, unauthenticated }

const _adminRoleId = '2';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  static String? _accesstoken;
  static String? _refreshtoken;
  static const _storage = FlutterSecureStorage();
  static String? get accesstoken => _accesstoken;
  String? get refreshtoken => _refreshtoken;
  String _baseUrl = ApiConstants.baseUrl;
  static final AuthProvider instance = AuthProvider._internal();
  Future<bool>? _refreshFuture;
  factory AuthProvider() {
    return instance;
  }

  AuthProvider._internal();

  bool get isAuthenticated => _isAuthenticated;

  bool _isAdminToken(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded['role']?.toString() == _adminRoleId;
    } catch (_) {
      return false;
    }
  }

  Future login(String username, String password) async {
    var url = "${_baseUrl}Access/AdminLogin";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var body = jsonEncode({"username": username, "password": password});
    var response = await http.post(uri, headers: headers, body: body);

    validateResponse(response);
    var data = jsonDecode(response.body);
    final accessToken = data['accesstoken'] as String?;
    if (!_isAdminToken(accessToken)) {
      throw ApiClientException(
        'Only admin accounts can access this application.',
      );
    }
    _accesstoken = accessToken;
    _refreshtoken = data['refreshtoken'];
    await saveToken();
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Changes the current user's password. The backend revokes every refresh
  /// token of the user, so the local session is cleared afterwards.
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
    await logout();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
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
    );
  }

  Map<String, String> createHeaders() {
    var headers = {"Content-Type": "application/json"};

    return headers;
  }

  static void setToken(Token tkn) {
    _accesstoken = tkn.jwtToken;
    _refreshtoken = tkn.refreshToken;
  }

  Future<AuthStatus> tryAutoLogin() async {
    final storedAccess = await _storage.read(key: "jwt_token");
    final storedRefresh = await _storage.read(key: "refresh_token");
    if (storedAccess == null || storedAccess.isEmpty) {
      return AuthStatus.unauthenticated;
    }

    if (!checkIfTokenExpired(storedAccess)) {
      if (!_isAdminToken(storedAccess)) {
        await deleteToken();
        return AuthStatus.unauthenticated;
      }
      _accesstoken = storedAccess;
      _refreshtoken = storedRefresh;
      _isAuthenticated = true;
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
    var url = "${_baseUrl}Access/AdminLoginWithRefreshToken";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    var body = jsonEncode({"refreshToken": refreshtoken});

    http.Response response = await http.post(uri, headers: headers, body: body);

    validateResponse(response);
    var data = jsonDecode(response.body);
    final accessToken = data['accesstoken'] as String?;
    if (!_isAdminToken(accessToken)) {
      await deleteToken();
      throw ApiClientException(
        'Only admin accounts can access this application.',
      );
    }
    _accesstoken = accessToken;
    _refreshtoken = data['refreshtoken'];
    await saveToken();
    _isAuthenticated = true;
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
      await logout();
      return false;
    }
    try {
      await loginWithRefreshToken();
      return true;
    } catch (_) {
      await logout();
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

  static Future<Token?> getToken() async {
    Token tkn = Token();
    tkn.jwtToken = await _storage.read(key: "jwt_token") ?? '';
    tkn.refreshToken = await _storage.read(key: "refresh_token") ?? '';
    return tkn;
  }

  Future<void> deleteToken() async {
    await Future.wait([
      _storage.delete(key: "jwt_token"),
      _storage.delete(key: "refresh_token"),
    ]);
  }
}

class Token {
  String jwtToken = '';
  String refreshToken = '';
}
