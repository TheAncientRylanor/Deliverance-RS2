import 'dart:async';
import 'dart:io';

import 'package:deliverance_scout/models/scout_command.dart';

/// Runs the commands an admin queued for this scout, one at a time.
class ScoutCommandRunner {
  // A command older than this was queued while the scout was offline. Running
  // it that late could surprise the admin, so it is reported as timed out.
  static const maxCommandAge = Duration(minutes: 5);
  static const timeout = Duration(minutes: 2);
  // Matches ScoutCommandResultValidator.OutputMaxLength on the server, minus
  // room for the notes appended below.
  static const _outputMaxLength = 100000 - 200;

  // A reconnect or a re-fetch can deliver the same command twice.
  final _handled = <int>{};
  Future<void> _queue = Future.value();

  /// Runs [command] after the ones before it. Returns null when it isn't
  /// pending or was already handled, so there is nothing to report.
  /// [onStarted] is awaited when the command's turn comes, right before its
  /// process starts; it is not called for a command that is too old to run.
  Future<ScoutCommandResult?> run(
    ScoutCommand command, {
    Future<void> Function()? onStarted,
  }) {
    if (command.status != ScoutCommandStatus.pending ||
        !_handled.add(command.id)) {
      return Future.value(null);
    }
    final result = _queue.then((_) => _execute(command, onStarted));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<ScoutCommandResult> _execute(
    ScoutCommand command,
    Future<void> Function()? onStarted,
  ) async {
    // Checked when the command's turn comes, not when it arrived.
    final age = DateTime.now().toUtc().difference(command.createdAt.toUtc());
    if (age > maxCommandAge) {
      return ScoutCommandResult(
        status: ScoutCommandStatus.timedOut,
        output: "Not run: the command was queued ${age.inMinutes} minutes ago.",
      );
    }
    await onStarted?.call();

    final (executable, arguments) = switch (command.executionCommandId) {
      ExecutionCommandType.cmd => ('cmd.exe', ['/c', command.commandText]),
      ExecutionCommandType.powerShell => (
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', command.commandText],
      ),
    };

    final Process process;
    try {
      process = await Process.start(executable, arguments);
    } on ProcessException catch (e) {
      return ScoutCommandResult(
        status: ScoutCommandStatus.failed,
        output: "Could not start $executable: ${e.message}",
      );
    }
    // Nobody can type into it: a command waiting for input gets EOF instead
    // of hanging until the timeout.
    unawaited(process.stdin.close());

    // stdout and stderr together, as the server stores them.
    final output = StringBuffer();
    var truncated = false;
    void append(String chunk) {
      final room = _outputMaxLength - output.length;
      if (chunk.length > room) {
        truncated = true;
        output.write(chunk.substring(0, room < 0 ? 0 : room));
      } else {
        output.write(chunk);
      }
    }

    final streamsDone = Future.wait([
      process.stdout.transform(systemEncoding.decoder).forEach(append),
      process.stderr.transform(systemEncoding.decoder).forEach(append),
    ]);

    int? exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      // Process.kill only ends cmd.exe/powershell.exe itself; anything it
      // started (e.g. ping -t) would keep running and keep the pipes open.
      await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
    }
    // A child that outlived the shell can still hold the pipes open.
    await streamsDone.timeout(const Duration(seconds: 5), onTimeout: () => []);

    if (truncated) output.write("\n[Output truncated]");
    if (exitCode == null) {
      output.write("\n[Killed after ${timeout.inMinutes} minutes]");
      return ScoutCommandResult(
        status: ScoutCommandStatus.timedOut,
        output: output.toString(),
      );
    }
    return ScoutCommandResult(
      status: ScoutCommandStatus.completed,
      output: output.toString(),
      exitCode: exitCode,
    );
  }
}
