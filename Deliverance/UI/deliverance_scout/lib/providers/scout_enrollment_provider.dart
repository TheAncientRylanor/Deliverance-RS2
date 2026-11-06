import 'dart:convert';

import 'package:deliverance_scout/models/device_info.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScoutEnrollmentProvider with ChangeNotifier {
  static const String _claimEndpoint = "Scout/Enrollment/Claim";

  /// Claims the token pasted from the admin app and sends this PC's details.
  /// The endpoint is anonymous: the token itself is the proof. Returns the
  /// scout's long-term secret, which the server never sends again.
  Future<String> claim(String token, DeviceInfo deviceInfo) async {
    final uri = Uri.parse("${ApiConstants.baseUrl}$_claimEndpoint");
    final body = jsonEncode({'token': token, ...deviceInfo.toJson()});

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
    } on Exception {
      throw ApiClientException(
        "Could not reach the server at ${ApiConstants.baseUrl}.",
      );
    }

    if (response.statusCode >= 300) {
      throw ApiClientException(
        ApiErrorParser.messageFromBody(response.body) ??
            "Enrollment failed. Please try again.",
      );
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['scoutSecret']
        as String;
  }
}
