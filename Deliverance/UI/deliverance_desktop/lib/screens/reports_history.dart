import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_paginator.dart';
import 'package:deliverance_desktop/widgets/report_card.dart';
import 'package:deliverance_desktop/widgets/search_sort_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsHistory extends StatefulWidget {
  const ReportsHistory({super.key});

  @override
  State<ReportsHistory> createState() => _ReportsHistory();
}

class _ReportsHistory extends State<ReportsHistory> {
  late ReportProvider _reportProvider;
  SearchResult<Report> _reportList = SearchResult();
  final ReportSearchObject _reportSearchObject = ReportSearchObject(
    page: 1,
    pageSize: 4,
    includeTotalCount: true,
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
                    totalPages: _reportList.totalPages ?? _totalPages,
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
