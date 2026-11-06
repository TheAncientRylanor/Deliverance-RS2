import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deliverance_scout/models/scout_log.dart';
import 'package:flutter/foundation.dart';

/// A Windows event, as the script in [ScoutLogCollector] reports it.
class WindowsEvent {
  final String key;
  final DateTime date;
  final String source;
  final int eventId;
  final String message;

  WindowsEvent({
    required this.key,
    required this.date,
    required this.source,
    required this.eventId,
    required this.message,
  });

  factory WindowsEvent.fromJson(Map<String, dynamic> json) => WindowsEvent(
    key: json['key'] as String,
    date: DateTime.parse(json['date'] as String),
    source: json['source'] as String,
    eventId: json['eventId'] as int,
    message: json['message'] as String? ?? '',
  );
}

/// Reads the events and usage levels that point at a fault on this PC.
class ScoutLogCollector {
  // The recommender only reads a device's newest lines, so routine events
  // would push out the ones that matter. Only these are sent.
  static const _watchedEvents = {
    'Microsoft-Windows-Resource-Exhaustion-Detector': [2004],
    'disk': [7, 11, 51, 153],
    'Ntfs': [55],
    'Microsoft-Windows-Ntfs': [55],
    'Display': [4101],
    'Microsoft-Windows-WindowsUpdateClient': [20],
    'Service Control Manager': [7031, 7034],
    'Microsoft-Windows-WER-SystemErrorReporting': [1001],
    'Microsoft-Windows-Kernel-Power': [41],
  };

  // Newest first, so a flood of events costs the oldest ones.
  static const _script = r'''
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
$events = @(Get-WinEvent -LogName System -FilterXPath "__XPATH__" -MaxEvents 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  [pscustomobject]@{
    key = "$($_.LogName)-$($_.RecordId)"
    date = $_.TimeCreated.ToUniversalTime().ToString('o')
    source = $_.ProviderName -replace '^Microsoft-Windows-', ''
    eventId = $_.Id
    message = "$($_.Message)" -replace '\s+', ' '
  }
})
$os = Get-CimInstance Win32_OperatingSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
[pscustomobject]@{
  events = $events
  memoryUsedPercent = [int](100 - 100 * $os.FreePhysicalMemory / $os.TotalVisibleMemorySize)
  diskFreePercent = [int](100 * $disk.FreeSpace / $disk.Size)
} | ConvertTo-Json -Compress -Depth 3
''';

  static const _timeout = Duration(minutes: 2);
  // Leaves room in DeviceLog.Log for the source and event id the server adds.
  static const _maxMessageLength = 900;
  static const _highMemoryPercent = 90;
  static const _lowDiskPercent = 10;
  // One check can catch a short spike. Two in a row means it lasted.
  static const _highMemoryChecksNeeded = 2;
  static const _usageSource = 'Scout';
  static const _memoryEventId = 1;
  static const _diskEventId = 2;

  int _highMemoryChecks = 0;

  /// The faults logged from [since] up to [until], plus current usage problems.
  Future<List<ScoutLogEntry>> collect(DateTime since, DateTime until) async {
    final script = _script.replaceFirst('__XPATH__', _xPath(since, until));
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ], stdoutEncoding: utf8).timeout(_timeout);
    if (result.exitCode != 0) {
      throw Exception("Could not read the event log: ${result.stderr}");
    }

    final data = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final events = (data['events'] as List)
        .map((x) => WindowsEvent.fromJson(x as Map<String, dynamic>))
        .toList();
    return [
      ...mergeEvents(events),
      ...usageEntries(
        data['memoryUsedPercent'] as int,
        data['diskFreePercent'] as int,
        until,
      ),
    ];
  }

  static String _xPath(DateTime since, DateTime until) {
    final providers = _watchedEvents.entries
        .map((x) {
          final ids = x.value.map((id) => 'EventID=$id').join(' or ');
          return "(Provider[@Name='${x.key}'] and ($ids))";
        })
        .join(' or ');
    return "*[System[($providers) and TimeCreated["
        "@SystemTime>='${_xPathDate(since)}' and "
        "@SystemTime<'${_xPathDate(until)}']]]";
  }

  // The event log only compares times down to the millisecond.
  static String _xPathDate(DateTime date) =>
      date.toUtc().copyWith(microsecond: 0).toIso8601String();

  /// One line per source, event id and day, so a repeating event takes up one
  /// of the lines the recommender reads. The key comes from the oldest event,
  /// which stays the same when a failed send collects the same period again.
  @visibleForTesting
  static List<ScoutLogEntry> mergeEvents(List<WindowsEvent> events) {
    final groups = <String, List<WindowsEvent>>{};
    final oldestFirst = [...events]..sort((a, b) => a.date.compareTo(b.date));
    for (final event in oldestFirst) {
      final day = event.date.toUtc().toIso8601String().substring(0, 10);
      groups
          .putIfAbsent('${event.source}|${event.eventId}|$day', () => [])
          .add(event);
    }

    return groups.values.map((group) {
      final newest = group.last;
      return ScoutLogEntry(
        eventKey: group.first.key,
        dateLogged: newest.date,
        source: newest.source,
        eventId: newest.eventId,
        count: group.length,
        message: _message(newest),
      );
    }).toList();
  }

  // Not every provider's message text is installed, and the API requires one.
  static String _message(WindowsEvent event) {
    final message = event.message.trim();
    if (message.isEmpty) return 'Event ${event.eventId}';
    return message.length <= _maxMessageLength
        ? message
        : message.substring(0, _maxMessageLength);
  }

  /// Words rather than numbers, because the model reads the lines as text.
  /// The keys allow one memory line an hour and one disk line a day.
  @visibleForTesting
  List<ScoutLogEntry> usageEntries(
    int memoryUsedPercent,
    int diskFreePercent,
    DateTime now,
  ) {
    final time = now.toUtc().toIso8601String();
    _highMemoryChecks = memoryUsedPercent >= _highMemoryPercent
        ? _highMemoryChecks + 1
        : 0;

    return [
      if (_highMemoryChecks >= _highMemoryChecksNeeded)
        ScoutLogEntry(
          eventKey: '$_usageSource-Memory-${time.substring(0, 13)}',
          dateLogged: now,
          source: _usageSource,
          eventId: _memoryEventId,
          message: 'memory usage high for at least 15 minutes',
        ),
      if (diskFreePercent < _lowDiskPercent)
        ScoutLogEntry(
          eventKey: '$_usageSource-Disk-${time.substring(0, 10)}',
          dateLogged: now,
          source: _usageSource,
          eventId: _diskEventId,
          message: 'low disk space on the system drive',
        ),
    ];
  }
}
