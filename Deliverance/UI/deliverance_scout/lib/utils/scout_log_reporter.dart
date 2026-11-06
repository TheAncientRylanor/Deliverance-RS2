import 'dart:async';
import 'dart:math';

import 'package:deliverance_scout/models/scout_log.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';

/// Sends this PC's logs to the server every [interval] while the scout runs.
class ScoutLogReporter {
  static const interval = Duration(minutes: 15);
  // The recommender reads the last 7 days, so a new scout is useful right away.
  static const firstRunLookback = Duration(days: 7);
  // Matches ScoutLogBatchValidator.MaxBatchSize on the server.
  static const batchSize = 100;

  final Future<List<ScoutLogEntry>> Function(DateTime since, DateTime until)
  collect;
  final Future<void> Function(List<ScoutLogEntry> logs) send;
  final Future<DateTime?> Function() readCheckpoint;
  final Future<void> Function(DateTime checkpoint) writeCheckpoint;
  final void Function(String status) onStatus;

  ScoutLogReporter({
    required this.collect,
    required this.send,
    required this.readCheckpoint,
    required this.writeCheckpoint,
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

  /// The checkpoint only moves once every batch is saved, so a failure means
  /// the same period is collected again. The server skips what it already has.
  Future<void> report() async {
    if (_reporting) return;
    _reporting = true;
    try {
      final until = DateTime.now().toUtc();
      final since = await readCheckpoint() ?? until.subtract(firstRunLookback);
      final logs = await collect(since, until);

      for (var i = 0; i < logs.length; i += batchSize) {
        await send(logs.sublist(i, min(i + batchSize, logs.length)));
      }
      await writeCheckpoint(until);
      onStatus(
        logs.isEmpty ? "Logs: no new faults" : "Logs: ${logs.length} sent",
      );
    } on ApiClientException catch (e) {
      onStatus("Could not send the logs: ${e.message}");
    } on Exception catch (e) {
      onStatus("Could not read the logs: $e");
    } finally {
      _reporting = false;
    }
  }
}
