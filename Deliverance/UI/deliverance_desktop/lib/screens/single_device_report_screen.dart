import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/execution_command.dart';
import 'package:deliverance_desktop/models/execution_command_enum.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/scout_command.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/execution_command_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/scout_command_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/device_hub_client.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/reports_child.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_typing_indicator/simple_typing_indicator.dart';

class SingleDeviceReportScreen extends StatefulWidget {
  final Devices device;
  final String officeName;
  const SingleDeviceReportScreen({
    super.key,
    required this.device,
    required this.officeName,
  });

  @override
  State<SingleDeviceReportScreen> createState() =>
      _SingleDeviceReportScreenState();
}

class _SingleDeviceReportScreenState extends State<SingleDeviceReportScreen> {
  late ReportProvider _reportProvider;
  late ExecutionCommandProvider _executionCommandProvider;
  late ScoutCommandProvider _scoutCommandProvider;
  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ReportSearchObject searchObject = ReportSearchObject();
  SearchResult<Report> reportList = SearchResult();
  List<ExecutionCommand> executionCommands = [];
  int? selectedExecutionCommandId;
  bool isLoading = false;
  // The last command this admin sent, updated by the device hub.
  ScoutCommand? _scoutCommand;
  bool _isSending = false;
  // Hub updates that arrive while a Send is in flight, by command id: the
  // scout can start, or even finish, before the POST returns.
  final Map<int, ScoutCommand> _earlyUpdates = {};
  String? _hubError;
  DeviceHubClient? _deviceHubClient;
  TableRow _buildRow(
    BuildContext context,
    String label,
    String value, {
    PrimaryButton? button,
  }) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              right: 8,
              left: 20,
            ),
            child: Text(
              textDirection: TextDirection.rtl,
              label,
              style: style?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: button == null
                ? Text(value, style: style)
                : Align(alignment: Alignment.centerLeft, child: button),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _reportProvider = context.read<ReportProvider>();
    _executionCommandProvider = context.read<ExecutionCommandProvider>();
    _scoutCommandProvider = context.read<ScoutCommandProvider>();
    searchObject.deviceId = widget.device.id;
    searchObject.includeTotalCount = true;
    searchObject.pageSize = 4;
    isLoading = true;
    _initValues();
    if (widget.device.scout != null) _openConnection();
    MasterScreen.setLeaveGuard(context, _confirmLeave);
  }

  @override
  void dispose() {
    _deviceHubClient?.stop();
    _commandController.dispose();
    _outputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openConnection() async {
    final hubClient = DeviceHubClient(
      deviceId: widget.device.id,
      onStatusChanged: _onStatusChanged,
    );
    _deviceHubClient = hubClient;
    try {
      await hubClient.start();
      if (mounted) setState(() => _hubError = null);
    } catch (e) {
      if (mounted) {
        setState(() => _hubError = "Live command updates are unavailable: $e");
      }
    }
  }

  void _onStatusChanged(ScoutCommand command) {
    if (!mounted) return;
    final current = _scoutCommand;
    if (current == null || command.id != current.id) {
      // Other commands of this device (e.g. sent by another admin) are
      // ignored, except a possible reply to the Send still in flight.
      if (_isSending) _earlyUpdates[command.id] = command;
      return;
    }
    // A finished command never goes back to Pending or Running.
    if (current.status.isFinished && !command.status.isFinished) return;
    _showCommand(command);
  }

  void _showCommand(ScoutCommand command) {
    setState(() {
      _scoutCommand = command;
      _outputController.text = command.output ?? "";
    });
  }

  Future<void> _sendCommand() async {
    final executionCommandId = selectedExecutionCommandId;
    final commandText = _commandController.text;
    if (executionCommandId == null || commandText.trim().isEmpty) {
      await alertBox(
        context,
        "Missing input",
        "Choose an execution mode and enter a command.",
      );
      return;
    }

    setState(() {
      _isSending = true;
      _earlyUpdates.clear();
    });
    try {
      final sent = await _scoutCommandProvider.sendCommand(
        ScoutCommandInsertRequest(
          deviceId: widget.device.id,
          executionCommandId: ExecutionCommandEnum.fromValue(
            executionCommandId,
          ),
          commandText: commandText,
        ),
      );
      if (!mounted) return;
      // Hub updates arrive in order, so the one kept is the newest.
      _showCommand(_earlyUpdates[sent.id] ?? sent);
    } on ApiClientException catch (e) {
      if (mounted) await alertBox(context, "Error", e.message);
    } finally {
      _earlyUpdates.clear();
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Asks before leaving while the last command is still being sent, pending
  /// or running, since its output is only shown on this screen.
  Future<bool> _confirmLeave() async {
    final command = _scoutCommand;
    final inProgress =
        _isSending || (command != null && !command.status.isFinished);
    if (!inProgress) return true;
    final leave = await alertBox(
      context,
      "Command in progress",
      "The command is ${command?.status.label.toLowerCase() ?? "being sent"}. "
          "If you leave, you won't see its output here. Leave anyway?",
      mode: AlertBoxMode.choice,
    );
    return leave == true;
  }

  String _outputLabel() {
    final command = _scoutCommand;
    if (command == null) return "Output";
    final exitCode = command.exitCode == null
        ? ""
        : " (exit code ${command.exitCode})";
    return "Output - ${command.status.label}$exitCode";
  }

  Future<void> _initValues() async {
    try {
      reportList = await _reportProvider.get(filter: searchObject.toJson());
      final executionCommandResult = await _executionCommandProvider.get();
      executionCommands = executionCommandResult.items ?? [];
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: _initValues);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        spacing: 10,
        children: [
          Text(widget.officeName, style: theme.textTheme.displayLarge),
          const SizedBox(height: 100),
          SizedBox(
            width: 500,
            child: Table(
              border: TableBorder.all(color: theme.colorScheme.primary),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {0: IntrinsicColumnWidth()},
              children: [
                _buildRow(context, 'Device name', widget.device.name ?? "-"),
                _buildRow(
                  context,
                  'IP address',
                  widget.device.ipAddress ?? "-",
                ),
                _buildRow(context, 'OS and version', widget.device.os ?? "-"),
                _buildRow(context, 'Last OS update', "-"),
                _buildRow(
                  context,
                  'Reported problems count',
                  isLoading
                      ? '-'
                      : reportList.totalCount != null
                      ? reportList.totalCount.toString()
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Text(
            "Latest reports which have this device tagged",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),

          isLoading
              ? globalLoadingSpinner()
              : ReportsChild(size: 0.5, reportList: reportList),
          const SizedBox(height: 50),
          if (widget.device.scout != null) ...[
            Text(
              "Remote control",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            if (_hubError != null)
              Text(
                _hubError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 600,
              width: 1200,
              child: Row(
                spacing: 50,
                children: [
                  Expanded(
                    child: Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropDown<int>(
                          label: "Execution mode",
                          items: {
                            for (final command in executionCommands)
                              if (command.id != null)
                                command.id!: command.name ?? "-",
                          },
                          initialValue: selectedExecutionCommandId,
                          onChanged: (value) {
                            setState(() {
                              selectedExecutionCommandId = value;
                            });
                          },
                        ),
                        CustomTextField(
                          labelText: "Commands",
                          controller: _commandController,
                          readOnly: false,
                          onSubmited: (_) {
                            if (!_isSending) _sendCommand();
                          },
                          maxLines: 18,
                          minLines: 18,
                          textStyle: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PrimaryButton(
                              onPressed: _sendCommand,
                              label: "Send",
                              isLoading: _isSending,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomTextField(
                      hint:
                          _scoutCommand != null &&
                              !_scoutCommand!.status.isFinished
                          ? Row(
                              spacing: 5,
                              children: [
                                Text(
                                  _scoutCommand!.status.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                                SimpleTypingIndicator(
                                  dotSize: 6.0,
                                  duration: const Duration(milliseconds: 700),
                                  dotColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ],
                            )
                          : null,
                      labelText: _outputLabel(),
                      controller: _outputController,
                      scrollController: _scrollController,
                      readOnly: true,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textStyle: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ],
      ),
    );
  }
}
