import 'dart:typed_data';

import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

/// Downloads the PDF reports. They are files, not JSON, so fromJson is unused.
class PdfReportProvider extends BaseProvider<Uint8List> {
  PdfReportProvider() : super("PdfReport");

  /// Without [from] or [to], the API covers the 30 days up to now.
  Future<Uint8List> getReportActivity({DateTime? from, DateTime? to}) =>
      _download("Activity", {'from': from, 'to': to});

  /// Without [officeId], the API covers every office.
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
