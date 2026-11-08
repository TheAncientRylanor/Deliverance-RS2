import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';
import 'package:deliverance_desktop/models/report_statistics.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/report_statistics_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/reports_child.dart';
import 'package:deliverance_desktop/widgets/statistics_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HomeScreen> {
  late ReportProvider _reportProvider;
  late ReportStatisticsProvider _reportStatisticsProvider;
  SearchResult<Report>? _reportList;
  ReportStatistics? _reportStatistics;
  bool isLoading = true;

  DateTime get _chartMonth =>
      _reportStatistics?.timeBreakdown?.month ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _reportProvider = context.read<ReportProvider>();
    _reportStatisticsProvider = context.read<ReportStatisticsProvider>();
    initValues();
  }

  Future<void> initValues() async {
    setState(() {
      isLoading = true;
    });
    try {
      final reports = _reportProvider.get(
        filter: ReportSearchObject(status: ReportStatusFilter.active).toJson(),
      );
      final statistics = _reportStatisticsProvider.getStatistics();
      await Future.wait([reports, statistics]);
      _reportList = await reports;
      _reportStatistics = await statistics;
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(
        context,
        "Error",
        e.message,
        onRetry: initValues,
        allowBack: false,
      );
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
    return MasterScreen(
      title: "Home",
      child: SingleChildScrollView(
        child: isLoading
            ? globalLoadingSpinner()
            : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      "Latest Reports",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight(400),
                      ),
                    ),
                    const SizedBox(height: 10),
                    (_reportList?.items?.isEmpty ?? true)
                        ? Center(
                            child: Text(
                              "No fresh reports found!",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          )
                        : ReportsChild(
                            reportList: _reportList ?? SearchResult(),
                          ),
                    const SizedBox(height: 50),
                    Text(
                      "Statistics",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight(400),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatisticsLineChart(
                      reportsByDay:
                          _reportStatistics?.timeBreakdown?.reportsByDay,
                      maxX: DateUtils.getDaysInMonth(
                        _chartMonth.year,
                        _chartMonth.month,
                      ).toDouble(),
                      fullMonthName: DateFormat('MMMM').format(_chartMonth),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
