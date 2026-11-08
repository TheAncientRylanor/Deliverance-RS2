import 'dart:async';

import 'package:deliverance_scout/models/system_info.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';

class SystemInfoReporter {
  static const interval = Duration(hours: 6);

  final Future<SystemInfo> Function() collect;
  final Future<void> Function(SystemInfo info) send;
  final void Function(String status) onStatus;

  SystemInfoReporter({
    required this.collect,
    required this.send,
    required this.onStatus,
  });

  Timer? _timer;
  bool _reporting = false;

  void start() {
    report();
    _timer ??= Timer.periodic(interval, (_) => report());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> report() async {
    if (_reporting) return;
    _reporting = true;
    try {
      final info = await collect();
      await send(info);
      final date = info.lastOsUpdate?.toLocal();
      onStatus(
        date == null
            ? "Last OS update: not found"
            : "Last OS update: ${date.day}.${date.month}.${date.year}",
      );
    } on ApiClientException catch (e) {
      onStatus("Could not send the system info: ${e.message}");
    } on Exception catch (e) {
      onStatus("Could not read the system info: $e");
    } finally {
      _reporting = false;
    }
  }
}
