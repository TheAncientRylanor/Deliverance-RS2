import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/execution_command.dart';
import 'package:deliverance_desktop/models/execution_command_enum.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';
import 'package:deliverance_desktop/models/scout_command.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/device_provider.dart';
import 'package:deliverance_desktop/providers/execution_command_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/scout_command_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/form_validators.dart';
import 'package:deliverance_desktop/utils/device_hub_client.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/device_log_tile.dart';
import 'package:deliverance_desktop/widgets/reports_child.dart';
import 'package:deliverance_desktop/widgets/scroll_list_box.dart';
import 'package:deliverance_desktop/widgets/screen_back_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
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
  int? _clearedCount;
  List<ExecutionCommand> executionCommands = [];
  int? selectedExecutionCommandId;
  final GlobalKey<FormState> _commandFormKey = GlobalKey<FormState>();
  String? _executionModeError;
  bool isLoading = false;
  ScoutCommand? _scoutCommand;
  bool _isSending = false;
  final Map<int, ScoutCommand> _earlyUpdates = {};
  String? _hubError;
  DeviceHubClient? _deviceHubClient;
  final ValueNotifier<_PingStatus> _pingStatus = ValueNotifier(
    _PingStatus.unknown,
  );

  bool get _hasIpAddress => widget.device.ipAddress?.isNotEmpty ?? false;

  TableRow _buildRow(
    BuildContext context,
    String label,
    String value, {
    Widget? content,
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
            child: content ?? Text(value, style: style),
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
    if (_hasIpAddress) _checkStatus();
    if (widget.device.scout != null) _openConnection();
    MasterScreen.setLeaveGuard(context, _confirmLeave);
  }

  @override
  void dispose() {
    _deviceHubClient?.stop();
    _commandController.dispose();
    _outputController.dispose();
    _scrollController.dispose();
    _pingStatus.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_pingStatus.value == _PingStatus.checking) return;
    _pingStatus.value = _PingStatus.checking;
    try {
      final result = await context.read<DeviceProvider>().ping(
        widget.device.id,
      );
      if (!mounted) return;
      _pingStatus.value = result.isOnline
          ? _PingStatus.online
          : _PingStatus.offline;
    } on ApiClientException {
      if (mounted) _pingStatus.value = _PingStatus.offline;
    }
  }

  Widget _buildStatus(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return ValueListenableBuilder<_PingStatus>(
      valueListenable: _pingStatus,
      builder: (context, status, _) => Row(
        spacing: 8,
        children: [
          if (status.dotColor != null)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: status.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(child: Text(status.label, style: style)),
          PrimaryButton(
            width: 90,
            height: 36,
            label: "Check",
            onPressed: _hasIpAddress && status != _PingStatus.checking
                ? _checkStatus
                : null,
          ),
        ],
      ),
    );
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
      if (_isSending) _earlyUpdates[command.id] = command;
      return;
    }
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
    setState(() {
      _executionModeError = executionCommandId == null
          ? "Choose an execution mode: CMD or PowerShell"
          : null;
    });
    final isCommandValid = _commandFormKey.currentState!.validate();
    if (executionCommandId == null || !isCommandValid) return;

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
      _showCommand(_earlyUpdates[sent.id] ?? sent);
    } on ApiClientException catch (e) {
      if (mounted) await alertBox(context, "Error", e.message);
    } finally {
      _earlyUpdates.clear();
      if (mounted) setState(() => _isSending = false);
    }
  }

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
      final reports = _reportProvider.get(filter: searchObject.toJson());
      final commands = _executionCommandProvider.get();
      final cleared = _reportProvider.get(
        filter: ReportSearchObject(
          deviceId: widget.device.id,
          status: ReportStatusFilter.cleared,
          pageSize: 1,
          includeTotalCount: true,
        ).toJson(),
      );
      await Future.wait([reports, commands, cleared]);
      reportList = await reports;
      executionCommands = (await commands).items ?? [];
      _clearedCount = (await cleared).totalCount;
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

  String _countText(int? count) =>
      isLoading || count == null ? '-' : count.toString();

  Widget _buildInfoTable(BuildContext context, {bool expanded = false}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 500,
      child: Table(
        border: TableBorder.all(color: theme.colorScheme.primary),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: IntrinsicColumnWidth()},
        children: [
          _buildRow(context, 'Device name', widget.device.name ?? "-"),
          if (expanded) ...[
            _buildRow(context, 'Type', widget.device.type ?? "-"),
            _buildRow(
              context,
              'Manufacturer',
              widget.device.manufacturer ?? "-",
            ),
          ],
          _buildRow(context, 'IP address', widget.device.ipAddress ?? "-"),
          if (expanded) ...[
            _buildRow(context, 'MAC address', widget.device.macAddress ?? "-"),
            _buildRow(context, 'Subnet mask', widget.device.subnetMask ?? "-"),
            _buildRow(context, 'VLAN', widget.device.vlanID ?? "-"),
          ],
          _buildRow(context, 'Status', "", content: _buildStatus(context)),
          _buildRow(context, 'OS and version', widget.device.os ?? "-"),
          _buildRow(
            context,
            'Last OS update',
            widget.device.lastOsUpdate == null
                ? "-"
                : DateFormat('dd.MM.yyyy').format(widget.device.lastOsUpdate!),
          ),
          _buildRow(
            context,
            'Reported problems count',
            _countText(reportList.totalCount),
          ),
          if (expanded)
            _buildRow(
              context,
              'Cleared issue count',
              _countText(_clearedCount),
            ),
        ],
      ),
    );
  }

  void _showExpandedInfo() {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: Text(
            widget.device.name ?? "Device info",
            style: theme.textTheme.titleLarge,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        content: SingleChildScrollView(
          child: _buildInfoTable(dialogContext, expanded: true),
        ),
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            label: "OK",
          ),
        ],
      ),
    );
  }

  void _showRecentLogs() {
    showDialog<void>(
      context: context,
      builder: (_) => _RecentLogsDialog(deviceId: widget.device.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        spacing: 10,
        children: [
          ScreenBackButton(confirmLeave: _confirmLeave),
          Text(widget.officeName, style: theme.textTheme.displayLarge),
          const SizedBox(height: 100),
          _buildInfoTable(context),
          const SizedBox(height: 10),
          SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 10,
              children: [
                PrimaryButton(
                  onPressed: _showExpandedInfo,
                  label: "Expand info",
                ),
                Tooltip(
                  message: widget.device.scout == null
                      ? "Only devices with a scout send logs"
                      : "",
                  child: PrimaryButton(
                    onPressed: widget.device.scout == null
                        ? null
                        : _showRecentLogs,
                    label: "Show last logs",
                  ),
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
                              _executionModeError = null;
                            });
                          },
                        ),
                        if (_executionModeError != null)
                          Text(
                            _executionModeError!,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        Expanded(
                          child: Form(
                            key: _commandFormKey,
                            child: CustomTextField(
                              labelText: "Commands",
                              controller: _commandController,
                              readOnly: false,
                              onSubmited: (_) {
                                if (!_isSending) _sendCommand();
                              },
                              expands: true,
                              maxLength: FieldLimits.commandMax,
                              validator: maxLength(
                                'Command',
                                FieldLimits.commandMax,
                                required: true,
                              ),
                              textStyle: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w100,
                              ),
                            ),
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

enum _PingStatus {
  unknown("-", null),
  checking("Checking...", null),
  online("Online", Colors.green),
  offline("Offline", Colors.red);

  final String label;
  final Color? dotColor;
  const _PingStatus(this.label, this.dotColor);
}

class _RecentLogsDialog extends StatefulWidget {
  final int deviceId;

  const _RecentLogsDialog({required this.deviceId});

  @override
  State<_RecentLogsDialog> createState() => _RecentLogsDialogState();
}

class _RecentLogsDialogState extends State<_RecentLogsDialog> {
  List<DeviceEvidenceLog> _logs = [];
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<DeviceProvider>().getRecentLogs(
        widget.deviceId,
      );
      _logs = result.items ?? [];
      _totalCount = result.totalCount ?? _logs.length;
    } on ApiClientException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      actionsAlignment: MainAxisAlignment.center,
      title: Column(
        spacing: 4,
        children: [
          Text("Last logs", style: theme.textTheme.titleLarge),
          if (!_isLoading && _error == null && _logs.isNotEmpty)
            Text(
              "Newest ${_logs.length} of $_totalCount",
              style: theme.textTheme.labelSmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 700,
        child: ScrollListBox(
          height: 450,
          isLoading: _isLoading,
          itemCount: _logs.length,
          itemBuilder: (context, index) => DeviceLogTile(log: _logs[index]),
          emptyMessage: _error ?? "This scout hasn't sent any logs yet.",
        ),
      ),
      actions: [
        if (_error != null)
          SecondaryButton(onPressed: _loadLogs, label: "Retry"),
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          label: "OK",
        ),
      ],
    );
  }
}
