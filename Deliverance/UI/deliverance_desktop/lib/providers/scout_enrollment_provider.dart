import 'dart:convert';

import 'package:deliverance_desktop/models/scout_enrollment.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ScoutEnrollmentProvider extends BaseProvider<ScoutEnrollment> {
  ScoutEnrollmentProvider() : super("ScoutEnrollment");

  @override
  ScoutEnrollment fromJson(data) {
    return ScoutEnrollment.fromJson(data);
  }

  Future<ScoutEnrollmentToken> generateToken() async {
    final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint");
    final response = await sendWithRetry(
      () => http.post(uri, headers: createHeaders()),
    );
    return ScoutEnrollmentToken.fromJson(jsonDecode(response.body));
  }

  Future<void> cancel(int id) => remove(id);
}
