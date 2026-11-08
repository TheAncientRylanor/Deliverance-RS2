import 'dart:convert';

import 'package:deliverance_scout/models/scout.dart';
import 'package:deliverance_scout/models/scout_command.dart';
import 'package:deliverance_scout/models/scout_log.dart';
import 'package:deliverance_scout/models/system_info.dart';
import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScoutProvider with ChangeNotifier {
  static const _meEndpoint = "Scout/Me";
  static const _commandsEndpoint = "Scout/Commands";
  static const _logsEndpoint = "Scout/Logs";
  static const _systemInfoEndpoint = "Scout/Me/SystemInfo";

  final ScoutAuthProvider _auth;

  ScoutProvider(this._auth);

  Future<Scout> getMe() async {
    final uri = Uri.parse("${ApiConstants.baseUrl}$_meEndpoint");
    final response = await _sendAuthorized(
      (token) => http.get(uri, headers: {"Authorization": "Bearer $token"}),
    );
    return Scout.fromJson(jsonDecode(response.body));
  }

  Future<void> reportCommandResult(
    int commandId,
    ScoutCommandResult result,
  ) async {
    final uri = Uri.parse(
      "${ApiConstants.baseUrl}$_commandsEndpoint/$commandId/Result",
    );
    await _sendAuthorized(
      (token) => http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(result.toJson()),
      ),
    );
  }

  Future<void> sendLogs(List<ScoutLogEntry> logs) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}$_logsEndpoint");
    await _sendAuthorized(
      (token) => http.post(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"logs": logs.map((x) => x.toJson()).toList()}),
      ),
    );
  }

  Future<void> sendSystemInfo(SystemInfo info) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}$_systemInfoEndpoint");
    await _sendAuthorized(
      (token) => http.put(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(info.toJson()),
      ),
    );
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String accessToken) send,
  ) async {
    http.Response response;
    try {
      response = await send(await _auth.getAccessToken());
      if (response.statusCode == 401) {
        response = await send(await _auth.getAccessToken(forceRefresh: true));
      }
    } on ApiClientException {
      rethrow;
    } on Exception {
      throw ApiClientException(
        "Could not reach the server at ${ApiConstants.baseUrl}.",
      );
    }

    if (response.statusCode >= 300) {
      throw ApiClientException(
        ApiErrorParser.messageFromBody(response.body) ??
            "Request failed. Please try again.",
      );
    }
    return response;
  }
}
