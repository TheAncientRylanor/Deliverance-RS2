import 'dart:convert';

import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReportProvider extends BaseProvider<Report> {
  ReportProvider() : super("Report");
  @override
  Report fromJson(data) {
    return Report.fromJson(data);
  }

  Future<Report> seen(int id) async {
    final response = await sendWithRetry(() async {
      var uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/Seen/$id");
      var headers = createHeaders();
      return await http.put(uri, headers: headers);
    });
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }

  Future<Report> clear(int id, {String? comment, int? issueType}) async {
    final response = await sendWithRetry(() async {
      var uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/Clear/$id");
      var headers = createHeaders();
      var body = jsonEncode({'comment': comment, 'issueType': issueType});
      return await http.put(uri, headers: headers, body: body);
    });
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }
}
