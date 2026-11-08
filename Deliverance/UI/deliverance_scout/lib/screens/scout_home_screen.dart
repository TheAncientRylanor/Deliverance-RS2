import 'package:deliverance_scout/models/scout.dart';
import 'package:deliverance_scout/models/scout_command.dart';
import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/providers/scout_provider.dart';
import 'package:deliverance_scout/utils/api_client_exception.dart';
import 'package:deliverance_scout/utils/scout_command_runner.dart';
import 'package:deliverance_scout/utils/scout_hub_client.dart';
import 'package:deliverance_scout/utils/scout_log_collector.dart';
import 'package:deliverance_scout/utils/scout_log_reporter.dart';
import 'package:deliverance_scout/utils/scout_storage.dart';
import 'package:deliverance_scout/utils/util_widgets.dart';
import 'package:deliverance_scout/widgets/custom_buttons.dart';
import 'package:deliverance_scout/widgets/scout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScoutHomeScreen extends StatefulWidget {
  const ScoutHomeScreen({super.key});

  @override
  State<ScoutHomeScreen> createState() => _ScoutHomeScreenState();
}

class _ScoutHomeScreenState extends State<ScoutHomeScreen> {
  late Future<Scout> _scoutFuture;
  late final ScoutProvider _scoutProvider;
  late final ScoutHubClient _hubClient;
  late final ScoutLogReporter _logReporter;
  final _commandRunner = ScoutCommandRunner();
  String? _hubError;
  String? _lastCommandStatus;
  String? _lastLogStatus;

  @override
  void initState() {
    super.initState();
    _scoutProvider = context.read<ScoutProvider>();
    _scoutFuture = _scoutProvider.getMe();
    _hubClient = ScoutHubClient(
      accessTokenFactory: context.read<ScoutAuthProvider>().getAccessToken,
      onCommandQueued: _runCommand,
      onClosed: () {
        if (mounted) {
          setState(() => _hubError = "Disconnected from the server.");
        }
      },
    );
    _startHub();
    _logReporter = ScoutLogReporter(
      collect: ScoutLogCollector().collect,
      send: _scoutProvider.sendLogs,
      readCheckpoint: ScoutStorage.readLogCheckpoint,
      writeCheckpoint: ScoutStorage.writeLogCheckpoint,
      onStatus: (status) {
        if (mounted) setState(() => _lastLogStatus = status);
      },
    )..start();
  }

  @override
  void dispose() {
    _hubClient.stop();
    _logReporter.stop();
    super.dispose();
  }

  Future<void> _startHub() async {
    try {
      await _hubClient.start();
      if (mounted) setState(() => _hubError = null);
    } catch (e) {
      if (mounted) {
        setState(() => _hubError = "Could not connect for commands: $e");
      }
    }
  }

  Future<void> _runCommand(ScoutCommand command) async {
    final result = await _commandRunner.run(
      command,
      onStarted: () => _reportStarted(command),
    );
    if (result == null) return;

    String status =
        "Command #${command.id}: ${result.status.name}"
        "${result.exitCode == null ? '' : ' (exit code ${result.exitCode})'}";
    try {
      await _scoutProvider.reportCommandResult(command.id, result);
    } on ApiClientException catch (e) {
      status += "\nCould not report the result: ${e.message}";
    }
    if (mounted) setState(() => _lastCommandStatus = status);
  }

  Future<void> _reportStarted(ScoutCommand command) async {
    if (mounted) {
      setState(() => _lastCommandStatus = "Command #${command.id}: running");
    }
    try {
      await _scoutProvider.reportCommandResult(
        command.id,
        ScoutCommandResult(status: ScoutCommandStatus.running),
      );
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _lastCommandStatus =
              "Command #${command.id}: running\n"
              "Could not report that it started: ${e.message}";
        });
      }
    }
  }

  void _refresh() {
    setState(() {
      _scoutFuture = _scoutProvider.getMe();
    });
    if (!_hubClient.isConnected) _startHub();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<Scout>(
      future: _scoutFuture,
      builder: (context, snapshot) {
        final scout = snapshot.data;
        return ScoutPage(
          message: snapshot.hasError ? snapshot.error.toString() : _hubError,
          isError: true,
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              globalLoadingSpinner()
            else if (scout != null) ...[
              Text("Connected", style: textTheme.labelLarge),
              Text(
                "Device: ${scout.deviceName}\nOffice: ${scout.officeName}"
                "${scoutProfile == 'default' ? '' : '\nProfile: $scoutProfile'}",
                textAlign: TextAlign.center,
                style: textTheme.labelMedium,
              ),
              if (_lastCommandStatus != null)
                Text(
                  _lastCommandStatus!,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium,
                ),
              if (_lastLogStatus != null)
                Text(
                  _lastLogStatus!,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium,
                ),
            ],
            PrimaryButton(onPressed: _refresh, label: "Refresh"),
          ],
        );
      },
    );
  }
}
