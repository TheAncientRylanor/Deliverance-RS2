import 'dart:convert';

import 'package:deliverance_desktop/models/report_statistics.dart';
import 'package:deliverance_desktop/models/search_models/report_statistics_search_object.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ReportStatisticsProvider extends BaseProvider<ReportStatistics> {
  ReportStatisticsProvider() : super("ReportStatistics");
  @override
  ReportStatistics fromJson(data) {
    return ReportStatistics.fromJson(data);
  }

  Future<ReportStatistics> getStatistics([
    ReportStatisticsSearchObject? search,
  ]) async {
    final response = await sendWithRetry(() async {
      var url = "${BaseProvider.baseUrl}$endpoint/GetStatistics";
      if (search != null) {
        var queryString = getQueryString(search.toJson());
        url = "$url?$queryString";
      }
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });

    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }
}
