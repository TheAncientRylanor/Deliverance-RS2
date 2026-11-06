import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/models/issue_enum.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/severity_enum.dart';
import 'package:deliverance_desktop/providers/recommendation_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/selected_report_provider.dart';
import 'package:deliverance_desktop/screens/single_report_screen.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CriticalDeviceScreen extends StatefulWidget {
  final DeviceRecommendation device;

  const CriticalDeviceScreen({super.key, required this.device});

  @override
  State<CriticalDeviceScreen> createState() => _CriticalDeviceScreenState();
}

class _CriticalDeviceScreenState extends State<CriticalDeviceScreen> {
  static const _containerHeight = 280.0;

  late RecommendationProvider _recommendationProvider;
  late ReportProvider _reportProvider;
  final ScrollController _logsController = ScrollController();
  final ScrollController _reportsController = ScrollController();
  DeviceEvidence? _evidence;
  bool _isLoading = true;
  int? _openingReportId;

  @override
  void initState() {
    super.initState();
    _recommendationProvider = context.read<RecommendationProvider>();
    _reportProvider = context.read<ReportProvider>();
    _loadEvidence();
  }

  @override
  void dispose() {
    _logsController.dispose();
    _reportsController.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    try {
      _evidence = await _recommendationProvider.getEvidence(
        widget.device.deviceId,
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: _loadEvidence);
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openReport(int reportId) async {
    if (_openingReportId != null) return;
    setState(() => _openingReportId = reportId);

    Report? report;
    try {
      report = await _reportProvider.getById(reportId);
    } on ApiClientException catch (e) {
      if (mounted) alertBox(context, "Error", e.message);
    } finally {
      if (mounted) setState(() => _openingReportId = null);
    }
    if (report == null || !mounted) return;

    final opened = report;
    context.read<SelectedReportProvider>().select(opened);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MasterScreen(
          title: "Single report",
          child: SingleReportScreen(report: opened, showBackButton: true),
        ),
      ),
    );

    // The report may have been cleared, which changes its status and the score.
    if (mounted) await _loadEvidence();
  }

  Widget _buildValueRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// A fixed height box whose content scrolls, or [emptyMessage] without items.
  Widget _buildScrollContainer(
    ThemeData theme, {
    required ScrollController controller,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required String emptyMessage,
  }) {
    return Container(
      width: double.infinity,
      height: _containerHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: _isLoading
          ? globalLoadingSpinner()
          : itemCount == 0
          ? Center(child: Text(emptyMessage, style: theme.textTheme.labelMedium))
          : Scrollbar(
              controller: controller,
              thumbVisibility: true,
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.all(12),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
                separatorBuilder: (context, index) =>
                    Divider(color: theme.colorScheme.primary, height: 16),
              ),
            ),
    );
  }

  Widget _buildLog(ThemeData theme, DeviceEvidenceLog log) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          DateFormat('dd.MM.yyyy HH:mm').format(log.dateLogged),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(child: Text(log.log, style: theme.textTheme.labelSmall)),
      ],
    );
  }

  Widget _buildReport(ThemeData theme, DeviceEvidenceReport report) {
    final facts = [
      if (report.severity != null)
        "Severity: ${SeverityEnum.fromValue(report.severity!).label}",
      if (report.issueType != null)
        "Issue: ${IssueEnum.fromValue(report.issueType!).label}",
      if (report.status != null)
        "Status: ${report.status!.replaceAll('ReportState', '')}",
    ];

    // The box's background would otherwise hide the hover and click highlight.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _openReport(report.reportId),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: Text(
                      report.reportName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd.MM.yyyy').format(report.dateReported),
                    style: theme.textTheme.labelSmall,
                  ),
                  _openingReportId == report.reportId
                      ? globalLoadingSpinner(size: 20)
                      : Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                ],
              ),
              Text(facts.join("  |  "), style: theme.textTheme.labelSmall),
              if (report.detail != null)
                Text(report.detail!, style: theme.textTheme.labelSmall),
              if (report.comment != null)
                Text(
                  "Admin comment: ${report.comment}",
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = _evidence?.recommendation ?? widget.device;
    final logs = _evidence?.logs ?? [];
    final reports = _evidence?.reports ?? [];

    return SingleChildScrollView(
      child: Padding(
        // The extra space at the bottom lets the page scroll clear of the chat button.
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Center(
              child: Column(
                spacing: 4,
                children: [
                  Text(device.deviceName, style: theme.textTheme.displayLarge),
                  Text(
                    device.officeName,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                _buildValueRow(
                  theme,
                  "Fix probability:",
                  device.probabilityLabel,
                ),
                _buildValueRow(
                  theme,
                  "Likely issue:",
                  IssueEnum.fromValue(device.likelyIssue).label,
                ),
              ],
            ),
            Text("Logs", style: theme.textTheme.headlineMedium),
            _buildScrollContainer(
              theme,
              controller: _logsController,
              itemCount: logs.length,
              itemBuilder: (context, index) => _buildLog(theme, logs[index]),
              emptyMessage: "No logs in the last 7 days.",
            ),
            Text(
              "Reports (${device.reportsLast30Days} in last 30 days)",
              style: theme.textTheme.headlineMedium,
            ),
            _buildScrollContainer(
              theme,
              controller: _reportsController,
              itemCount: reports.length,
              itemBuilder: (context, index) =>
                  _buildReport(theme, reports[index]),
              emptyMessage: "No reports in the last 90 days.",
            ),
          ],
        ),
      ),
    );
  }
}
