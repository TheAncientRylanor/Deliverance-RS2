import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/models/report_status_filter.dart';
import 'package:deliverance_mobile/models/search_models/report_search_object.dart';
import 'package:deliverance_mobile/models/search_result.dart';
import 'package:deliverance_mobile/providers/report_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_paginator.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/report_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late ReportProvider _reportProvider;
  SearchResult<Report> _reportList = SearchResult();
  final ReportSearchObject _reportSearchObject = ReportSearchObject(
    page: 1,
    pageSize: 4,
    includeTotalCount: true,
    status: ReportStatusFilter.active,
  );
  final TextEditingController _reportNameController = TextEditingController();
  bool isLoading = true;
  bool _isSearchVisible = false;
  static const double _buttonsAreaHeight = 90;
  static const double _searchFieldHeight = 56;
  static const double _searchFieldGap = 20;

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
      final data = await _reportProvider.get(
        filter: _reportSearchObject.toJson(),
      );
      if (!mounted) return;
      setState(() {
        _reportList = data;
      });
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
  void dispose() {
    _reportNameController.dispose();
    super.dispose();
  }

  void _onStatusChanged(Set<ReportStatusFilter> selection) {
    setState(() {
      _reportSearchObject.status = selection.first;
      _reportSearchObject.page = 1;
      isLoading = true;
    });
    initValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: globalLoadingSpinner(
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      height: _isSearchVisible
                          ? _buttonsAreaHeight +
                                _searchFieldGap +
                                _searchFieldHeight
                          : _buttonsAreaHeight,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 20,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  setState(() {
                                    _isSearchVisible = !_isSearchVisible;
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  shape: CircleBorder(),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  padding: EdgeInsets.all(20),
                                ),
                                child: Icon(Icons.search, size: 40),
                              ),
                              FilledButton(
                                onPressed: () {
                                  showSortDialog(
                                    context,
                                    title: "Sort reports",
                                    columnNames: const {
                                      'ReportName': 'Report Name',
                                      'Status': 'Status',
                                      'DateReported': 'Date Reported',
                                      'IssueType': 'Issue Type',
                                    },
                                    currentSortBy: _reportSearchObject.sortBy,
                                    currentDescending:
                                        _reportSearchObject.descending ?? true,
                                    onApply: (sortBy, descending) {
                                      setState(() {
                                        _reportSearchObject.sortBy = sortBy;
                                        _reportSearchObject.descending =
                                            descending;
                                        _reportSearchObject.page = 1;
                                      });
                                      initValues();
                                    },
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  shape: CircleBorder(),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  padding: EdgeInsets.all(20),
                                ),
                                child: Icon(Icons.sort, size: 40),
                              ),
                            ],
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeInOutCubic,
                            top: _isSearchVisible
                                ? _buttonsAreaHeight + _searchFieldGap
                                : -_searchFieldHeight,
                            left: 20,
                            right: 20,
                            child: AnimatedOpacity(
                              duration: Duration(
                                milliseconds: _isSearchVisible ? 600 : 200,
                              ),
                              opacity: _isSearchVisible ? 1.0 : 0.0,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(8),
                                child: CustomTextField(
                                  controller: _reportNameController,
                                  hintText: "Search reports by name...",
                                  onSubmited: (value) => {
                                    setState(() {
                                      _reportSearchObject.reportName = value;
                                      _reportSearchObject.page = 1;
                                    }),
                                    initValues(),
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SegmentedButton<ReportStatusFilter>(
                        segments: const [
                          ButtonSegment(
                            value: ReportStatusFilter.active,
                            label: Text("Active"),
                          ),
                          ButtonSegment(
                            value: ReportStatusFilter.cleared,
                            label: Text("Cleared"),
                          ),
                          ButtonSegment(
                            value: ReportStatusFilter.draft,
                            label: Text("Drafts"),
                          ),
                        ],
                        selected: {_reportSearchObject.status!},
                        onSelectionChanged: _onStatusChanged,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        spacing: 20,
                        children: [
                          for (var report in _reportList.items ?? [])
                            ReportCard(
                              report: report,
                              initFunction: initValues,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomPaginator(
                      currentPage: _reportSearchObject.page ?? 1,
                      totalPages: _totalPages,
                      pageSize: _reportSearchObject.pageSize ?? 4,
                      searchObject: _reportSearchObject,
                      onChanged: initValues,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}
