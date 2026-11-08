import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/models/severity_enum.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_paginator.dart';
import 'package:deliverance_desktop/widgets/help_button.dart';
import 'package:deliverance_desktop/widgets/report_card.dart';
import 'package:deliverance_desktop/widgets/search_sort_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreen();
}

class _ReportsScreen extends State<ReportsScreen> {
  late ReportProvider _reportProvider;
  SearchResult<Report> _reportList = SearchResult();
  final ReportSearchObject _reportSearchObject = ReportSearchObject(
    page: 1,
    pageSize: 4,
    includeTotalCount: true,
    status: ReportStatusFilter.active,
  );
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _reportProvider = context.read<ReportProvider>();
    initValues();
  }

  int get _totalPages {
    final totalCount = _reportList.totalCount ?? 0;
    final pageSize = _reportSearchObject.pageSize ?? 4;
    if (totalCount == 0 || pageSize == 0) return totalCount == 0 ? 0 : 1;
    return (totalCount / pageSize).ceil();
  }

  Future<void> initValues() async {
    try {
      _reportList = await _reportProvider.get(
        filter: _reportSearchObject.toJson(),
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initValues);
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
    return Stack(
      children: [
        Positioned.fill(child: _buildReports()),
        const Positioned(
          right: 92,
          bottom: 20,
          child: HelpButton(title: "Active Reports", sections: _helpSections),
        ),
      ],
    );
  }

  Widget _buildReports() {
    return SingleChildScrollView(
      child: isLoading
          ? globalLoadingSpinner()
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  SearchSortHeader(
                    searchHint: "Search reports by name...",
                    sortDialogTitle: "Sort reports",
                    sortColumns: const {
                      'ReportName': 'Report Name',
                      'Status': 'Status',
                      'DateReported': 'Date Reported',
                      'IssueType': 'Issue Type',
                    },
                    currentSortBy: _reportSearchObject.sortBy,
                    currentDescending: _reportSearchObject.descending ?? true,
                    onSearch: (value) {
                      _reportSearchObject.reportName = value;
                      _reportSearchObject.page = 1;
                      initValues();
                    },
                    onSort: (sortBy, descending) {
                      _reportSearchObject.sortBy = sortBy;
                      _reportSearchObject.descending = descending;
                      _reportSearchObject.page = 1;
                      initValues();
                    },
                  ),
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Wrap(
                      spacing: 40,
                      runSpacing: 30,
                      children: [
                        for (var report in _reportList.items ?? [])
                          RepaintBoundary(
                            key: ValueKey(report.id),
                            child: ReportCard(report: report),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomPaginator(
                    currentPage: _reportSearchObject.page ?? 1,
                    totalPages: _totalPages,
                    pageSize: _reportSearchObject.pageSize ?? 4,
                    searchObject: _reportSearchObject,
                    onChanged: initValues,
                  ),
                ],
              ),
            ),
    );
  }
}

const _helpSections = [
  HelpSection(
    icon: Icons.visibility_outlined,
    title: "Seen or unseen",
    text:
        "New reports nobody has opened yet have a thick border and a dot in "
        "the top-right corner. Opening a report marks it as seen, and from "
        "then on the user can no longer edit it.",
    example: _SeenUnseenExample(),
  ),
  HelpSection(
    icon: Icons.warning_amber_rounded,
    title: "Severity",
    text:
        "Severity is picked by the user who sent the report. It is their own "
        "guess of how bad the problem is, so check the details before "
        "deciding what to fix first.",
    example: _SeverityGuide(),
  ),
];

class _SeenUnseenExample extends StatelessWidget {
  const _SeenUnseenExample();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 48,
        children: [
          _MiniReportCard(label: "Unseen", isUnseen: true),
          _MiniReportCard(label: "Seen", isUnseen: false),
        ],
      ),
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  final String label;
  final bool isUnseen;

  const _MiniReportCard({required this.label, required this.isUnseen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 6,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 76,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: colorScheme.primary,
                  width: isUnseen ? 4 : 1,
                ),
              ),
            ),
            if (isUnseen)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _SeverityGuide extends StatelessWidget {
  const _SeverityGuide();

  static const _meanings = {
    SeverityEnum.none: "No real impact, just letting you know.",
    SeverityEnum.mild: "A small annoyance, work goes on.",
    SeverityEnum.medium: "Slows work down, needs a look soon.",
    SeverityEnum.danger: "The device barely works.",
    SeverityEnum.extreme: "The device can't be used, work has stopped.",
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final entry in _meanings.entries)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 6),
                child: Text(
                  entry.key.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(entry.value, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
      ],
    );
  }
}
