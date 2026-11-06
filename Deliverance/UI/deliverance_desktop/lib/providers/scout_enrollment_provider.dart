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

  /// Creates a pending enrollment. The returned token is shown to the admin,
  /// who pastes it into the scout app.
  Future<ScoutEnrollmentToken> generateToken() async {
    final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint");
    final response = await sendWithRetry(
      () => http.post(uri, headers: createHeaders()),
    );
    return ScoutEnrollmentToken.fromJson(jsonDecode(response.body));
  }

  /// Cancels an enrollment, so its token can no longer be claimed.
  Future<void> cancel(int id) => remove(id);
}
