import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class DeviceProvider extends BaseProvider<Devices> {
  DeviceProvider() : super("Device");
  @override
  Devices fromJson(data) {
    return Devices.fromJson(data);
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
