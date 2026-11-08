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
import 'package:deliverance_desktop/widgets/device_log_tile.dart';
import 'package:deliverance_desktop/widgets/scroll_list_box.dart';
import 'package:deliverance_desktop/widgets/screen_back_button.dart';
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
  late RecommendationProvider _recommendationProvider;
  late ReportProvider _reportProvider;
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

  Future<void> _loadEvidence() async {
    try {
      _evidence = await _recommendationProvider.getEvidence(
        widget.device.deviceId,
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: _loadEvidence);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          child: SingleReportScreen(report: opened),
        ),
      ),
    );

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

  Widget _buildReport(ThemeData theme, DeviceEvidenceReport report) {
    final facts = [
      if (report.severity != null)
        "Severity: ${SeverityEnum.fromValue(report.severity!).label}",
      if (report.issueType != null)
        "Issue: ${IssueEnum.fromValue(report.issueType!).label}",
      if (report.status != null)
        "Status: ${report.status!.replaceAll('ReportState', '')}",
    ];

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
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            const ScreenBackButton(),
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
            ScrollListBox(
              isLoading: _isLoading,
              itemCount: logs.length,
              itemBuilder: (context, index) => DeviceLogTile(log: logs[index]),
              emptyMessage: "No logs in the last 7 days.",
            ),
            Text(
              "Reports (${device.reportsLast30Days} in last 30 days)",
              style: theme.textTheme.headlineMedium,
            ),
            ScrollListBox(
              isLoading: _isLoading,
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
