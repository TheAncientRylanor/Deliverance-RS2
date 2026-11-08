import 'dart:typed_data';

import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class PdfReportProvider extends ApiProvider {
  PdfReportProvider() : super("PdfReport");

  Future<Uint8List> getReportActivity({DateTime? from, DateTime? to}) =>
      _download("Activity", {'from': from, 'to': to});

  Future<Uint8List> getDeviceHealth({int? officeId}) =>
      _download("DeviceHealth", {'officeId': officeId});

  Future<Uint8List> _download(String path, Map<String, dynamic> filter) async {
    final response = await sendWithRetry(() async {
      final queryString = getQueryString(filter);
      final uri = Uri.parse(
        "${BaseProvider.baseUrl}$endpoint/$path?$queryString",
      );
      return await http.get(uri, headers: createHeaders());
    });
    return response.bodyBytes;
  }
}
