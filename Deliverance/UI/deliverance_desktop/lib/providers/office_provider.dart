import 'dart:convert';

import 'package:deliverance_desktop/models/base_search_object.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class OfficeProvider extends BaseProvider<Office> {
  OfficeProvider() : super("Office");
  @override
  Office fromJson(data) {
    return Office.fromJson(data);
  }

  /// Fetches every office. The API pages results (10 per page by default),
  /// so this walks the pages until all offices are loaded.
  Future<List<Office>> getAll() async {
    const pageSize = 100;
    final offices = <Office>[];
    var page = 1;
    while (true) {
      final result = await get(
        // Sorted so pages don't overlap; the API has no default order.
        filter: BaseSearchObject(
          page: page,
          pageSize: pageSize,
          sortBy: 'Id',
        ).toJson(),
      );
      final items = result.items ?? [];
      offices.addAll(items);
      final total = result.totalCount ?? offices.length;
      if (items.length < pageSize || offices.length >= total) break;
      page++;
    }
    return offices;
  }

  Future<Office> getFromReport(int officeReportId, int id) async {
    var url = "${BaseProvider.baseUrl}$endpoint/FromReport";
    var queryString = getQueryString({
      "officeReportId": officeReportId,
      "id": id,
    });
    url = "$url?$queryString";
    final uri = Uri.parse(url);
    final response = await sendWithRetry(() async {
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }
}
