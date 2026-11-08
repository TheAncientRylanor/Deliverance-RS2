import 'dart:convert';

import 'package:deliverance_desktop/models/device_ping_result.dart';
import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class DeviceProvider extends BaseProvider<Devices> {
  DeviceProvider() : super("Device");
  @override
  Devices fromJson(data) {
    return Devices.fromJson(data);
  }

  Future<SearchResult<DeviceEvidenceLog>> getRecentLogs(int deviceId) async {
    final response = await sendWithRetry(() async {
      final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/$deviceId/Logs");
      return await http.get(uri, headers: createHeaders());
    });

    final data = jsonDecode(response.body);
    return SearchResult<DeviceEvidenceLog>()
      ..totalCount = data['totalCount']
      ..items = (data['items'] as List)
          .map((e) => DeviceEvidenceLog.fromJson(e))
          .toList();
  }

  Future<DevicePingResult> ping(int deviceId) async {
    final response = await sendWithRetry(() async {
      final uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/$deviceId/Ping");
      return await http.post(uri, headers: createHeaders());
    });
    return DevicePingResult.fromJson(jsonDecode(response.body));
  }

  Future<void> setDisableScout(int deviceId) =>
      _setScoutState(deviceId, "Disable");

  Future<void> setEnabledScout(int deviceId) =>
      _setScoutState(deviceId, "Enable");

  Future<void> _setScoutState(int deviceId, String action) async {
    await sendWithRetry(() async {
      var url = "${BaseProvider.baseUrl}$endpoint/$deviceId/Scout/$action";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.put(uri, headers: headers);
    });
    notifyListeners();
  }
}
