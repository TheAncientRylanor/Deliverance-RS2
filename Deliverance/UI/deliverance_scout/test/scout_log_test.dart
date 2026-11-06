import 'package:deliverance_scout/models/scout_log.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/scout_log_collector.dart';
import 'package:deliverance_scout/utils/scout_log_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

WindowsEvent event(
  String key,
  String date, {
  String source = 'disk',
  int eventId = 7,
  String message = 'bad block',
}) => WindowsEvent(
  key: key,
  date: DateTime.parse(date),
  source: source,
  eventId: eventId,
  message: message,
);

ScoutLogEntry entry(int i) => ScoutLogEntry(
  eventKey: 'System-$i',
  dateLogged: DateTime.utc(2026, 11, 4),
  source: 'disk',
  eventId: 7,
  message: 'bad block',
);

void main() {
  group('mergeEvents', () {
    test('merges repeats of an event on the same day', () {
      final logs = ScoutLogCollector.mergeEvents([
        event('System-3', '2026-11-04T12:00:00Z', message: 'newest'),
        event('System-1', '2026-11-04T08:00:00Z', message: 'oldest'),
        event('System-2', '2026-11-04T10:00:00Z'),
      ]);

      expect(logs, hasLength(1));
      expect(logs.single.count, 3);
      expect(logs.single.eventKey, 'System-1');
      expect(logs.single.message, 'newest');
      expect(logs.single.dateLogged, DateTime.utc(2026, 11, 4, 12));
    });

    test('keeps other events and other days apart', () {
      final logs = ScoutLogCollector.mergeEvents([
        event('System-1', '2026-11-03T08:00:00Z'),
        event('System-2', '2026-11-04T08:00:00Z'),
        event('System-3', '2026-11-04T09:00:00Z', eventId: 51),
        event('System-4', '2026-11-04T10:00:00Z', source: 'Ntfs'),
      ]);

      expect(logs, hasLength(4));
    });

    test('keeps the key when the same period gains newer events', () {
      final first = [event('System-1', '2026-11-04T08:00:00Z')];
      final retry = [...first, event('System-2', '2026-11-04T09:00:00Z')];

      expect(
        ScoutLogCollector.mergeEvents(retry).single.eventKey,
        ScoutLogCollector.mergeEvents(first).single.eventKey,
      );
    });

    test('always has a message, and cuts long ones', () {
      final logs = ScoutLogCollector.mergeEvents([
        event('System-1', '2026-11-04T08:00:00Z', message: '  '),
        event(
          'System-2',
          '2026-11-04T08:00:00Z',
          eventId: 51,
          message: 'x' * 5000,
        ),
      ]);

      expect(logs.first.message, 'Event 7');
      expect(logs.last.message, hasLength(900));
    });
  });

  group('usageEntries', () {
    final now = DateTime.utc(2026, 11, 4, 14, 20);

    test('needs high memory on two checks in a row', () {
      final collector = ScoutLogCollector();

      expect(collector.usageEntries(95, 50, now), isEmpty);
      expect(
        collector.usageEntries(95, 50, now).single.eventKey,
        'Scout-Memory-2026-11-04T14',
      );
    });

    test('a normal check resets high memory', () {
      final collector = ScoutLogCollector();

      collector.usageEntries(95, 50, now);
      collector.usageEntries(40, 50, now);

      expect(collector.usageEntries(95, 50, now), isEmpty);
    });

    test('reports low disk space once a day', () {
      expect(
        ScoutLogCollector().usageEntries(40, 5, now).single.eventKey,
        'Scout-Disk-2026-11-04',
      );
    });
  });

  group('ScoutLogReporter', () {
    late List<int> batchSizes;
    late List<DateTime> checkpoints;
    late List<String> statuses;
    DateTime? since;

    ScoutLogReporter reporter({
      DateTime? checkpoint,
      List<ScoutLogEntry>? logs,
      Future<void> Function()? onSend,
    }) => ScoutLogReporter(
      collect: (from, _) async {
        since = from;
        return logs ?? [];
      },
      send: (batch) async {
        await onSend?.call();
        batchSizes.add(batch.length);
      },
      readCheckpoint: () async => checkpoint,
      writeCheckpoint: (value) async => checkpoints.add(value),
      onStatus: statuses.add,
    );

    setUp(() {
      batchSizes = [];
      checkpoints = [];
      statuses = [];
      since = null;
    });

    test('splits logs into batches, then moves the checkpoint', () async {
      await reporter(logs: List.generate(250, entry)).report();

      expect(batchSizes, [100, 100, 50]);
      expect(checkpoints, hasLength(1));
      expect(statuses.single, 'Logs: 250 sent');
    });

    test('keeps the checkpoint when a batch fails', () async {
      var calls = 0;
      await reporter(
        logs: List.generate(150, entry),
        onSend: () async {
          if (++calls == 2) throw ApiClientException('Server down');
        },
      ).report();

      expect(checkpoints, isEmpty);
      expect(statuses.single, contains('Server down'));
    });

    test('keeps the checkpoint when the event log cannot be read', () async {
      await ScoutLogReporter(
        collect: (_, _) async => throw Exception('no access'),
        send: (_) async {},
        readCheckpoint: () async => null,
        writeCheckpoint: (value) async => checkpoints.add(value),
        onStatus: statuses.add,
      ).report();

      expect(checkpoints, isEmpty);
      expect(statuses.single, contains('no access'));
    });

    test('continues from the checkpoint', () async {
      final checkpoint = DateTime.utc(2026, 11, 4, 10);

      await reporter(checkpoint: checkpoint).report();

      expect(since, checkpoint);
      expect(statuses.single, 'Logs: no new faults');
    });

    test('a new scout starts 7 days back', () async {
      await reporter().report();

      final age = DateTime.now().toUtc().difference(since!);
      expect(age.inDays, 7);
    });
  });
}
