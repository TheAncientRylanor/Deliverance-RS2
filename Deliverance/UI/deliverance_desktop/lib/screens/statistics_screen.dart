import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/models/report_statistics.dart';
import 'package:deliverance_desktop/models/search_models/report_statistics_search_object.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/providers/recommendation_provider.dart';
import 'package:deliverance_desktop/providers/report_statistics_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/critical_device_card.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_month_year_picker.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/dialogs/pdf_report_dialogs.dart';
import 'package:deliverance_desktop/widgets/statistics_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const _criticalDevicesCount = 5;
  // A device below this is more likely fine than not, so it isn't critical.
  static const _criticalMinProbability = 0.5;

  late ReportStatisticsProvider _statisticsProvider;
  late OfficeProvider _officeProvider;
  late RecommendationProvider _recommendationProvider;
  // Kept here so the Location and Time period filters don't score every device again.
  List<DeviceRecommendation> _criticalDevices = [];
  bool _isLoadingCritical = true;
  String? _criticalError;
  ReportStatistics? _reportStatistics;
  DateTime? _selectedDate;
  TextEditingController dateController = TextEditingController();
  final Map<int?, String> _offices = {-1: "All"};
  ReportStatisticsSearchObject reportStatisticsSearchObject =
      ReportStatisticsSearchObject();
  int selectedKey = -1;
  bool isLoading = true;
  double currentMonthDays = 0;
  @override
  void initState() {
    super.initState();
    _statisticsProvider = context.read<ReportStatisticsProvider>();
    _officeProvider = context.read<OfficeProvider>();
    _recommendationProvider = context.read<RecommendationProvider>();
    initOffices();
    initCriticalDevices();
  }

  /// A failure only affects this section, so the statistics stay usable.
  Future<void> initCriticalDevices() async {
    try {
      _criticalDevices = await _recommendationProvider.getCriticalDevices(
        top: _criticalDevicesCount,
        minProbability: _criticalMinProbability,
      );
    } on ApiClientException catch (e) {
      _criticalError = e.message;
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _isLoadingCritical = false;
      });
    }
  }

  Future<void> initOffices() async {
    try {
      final offices = await _officeProvider.getAll();
      _offices.addAll(
        Map.fromEntries(
          offices.map(
            (office) => MapEntry(office.id as int, office.name as String),
          ),
        ),
      );
      initValues();
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initOffices);
    }
  }

  Future<void> initValues() async {
    try {
      _reportStatistics = await _statisticsProvider.getStatistics(
        reportStatisticsSearchObject,
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(
        context,
        "Statistics error",
        e.message,
        onRetry: initValues,
      );
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Expanded _buildRowContainers(
    ThemeData theme,
    String title,
    String name,
    String detail,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(8.0),
        ),
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 15,
            children: [
              Text(title, style: theme.textTheme.labelLarge),
              Text(
                name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight(1000),
                ),
              ),
              Text(
                detail,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight(1000),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalDevices(ThemeData theme) {
    if (_isLoadingCritical) return globalLoadingSpinner();

    final message =
        _criticalError ??
        (_criticalDevices.isEmpty ? "No critical devices right now." : null);
    if (message != null) {
      return Text(message, style: theme.textTheme.labelMedium);
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 20,
      children: _criticalDevices
          .map((device) => CriticalDeviceCard(device: device))
          .toList(),
    );
  }

  Widget _buildPdfButton(
    ThemeData theme, {
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        Icons.picture_as_pdf,
        size: 40,
        color: theme.colorScheme.primary,
      ),
    );
  }

  String _reportCountLabel(int? count) => "Reports: ${count ?? 0}";

  /// The API sends DateTime's default (year 1) when there are no reports.
  String get _busiestDayLabel {
    final day = _reportStatistics?.timePeriodWithMostRep;
    if (day == null || day.year <= 1) return "-";
    return DateFormat('dd.MM.yyyy').format(day);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return SingleChildScrollView(
      child: isLoading
          ? globalLoadingSpinner()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Column(
                spacing: 20,
                children: [
                  Text("Critical devices", style: theme.textTheme.displayLarge),
                  _buildPdfButton(
                    theme,
                    tooltip: "Device health PDF",
                    onPressed: () =>
                        showDeviceHealthPdfDialog(context, _offices),
                  ),
                  _buildCriticalDevices(theme),
                  const SizedBox(height: 40),
                  Text(
                    "Visual representation",
                    style: theme.textTheme.displayLarge,
                  ),
                  _buildPdfButton(
                    theme,
                    tooltip: "Report activity PDF",
                    onPressed: () => showReportActivityPdfDialog(context),
                  ),
                  Row(
                    spacing: 50,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomDropDown(
                        items: _offices,
                        label: "Location",
                        initialValue: selectedKey,
                        onChanged: (value) {
                          setState(() {
                            selectedKey = value ?? -1;
                            if (selectedKey == -1) {
                              reportStatisticsSearchObject.officeId = null;
                            } else {
                              reportStatisticsSearchObject.officeId =
                                  selectedKey;
                            }

                            isLoading = true;
                          });
                          initValues();
                        },
                      ),
                      SizedBox(
                        width: 300,
                        child: CustomTextField(
                          prefixIcon: Icon(
                            Icons.av_timer,
                            size: 30,
                            color: Colors.white,
                          ),
                          suffixIcon: _selectedDate == null
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      dateController.text = "";
                                      _selectedDate = null;
                                      reportStatisticsSearchObject.reportDate =
                                          null;
                                    });
                                    initValues();
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                          readOnly: true,
                          controller: dateController,
                          onTap: () async {
                            var result = await pickMonthYear(context);
                            if (result != null) {
                              setState(() {
                                dateController.text = DateFormat(
                                  'yyyy-MM',
                                ).format(result);
                                _selectedDate = result;
                                reportStatisticsSearchObject.reportDate =
                                    result;
                              });
                              initValues();
                            }
                          },
                          labelText: "Time period",
                        ),
                      ),
                    ],
                  ),

                  StatisticsLineChart(
                    reportsByDay:
                        _reportStatistics?.timeBreakdown?.reportsByDay,
                    maxX: _selectedDate == null
                        ? DateUtils.getDaysInMonth(
                                DateTime.now().year,
                                DateTime.now().month,
                              ) +
                              0.0
                        : DateUtils.getDaysInMonth(
                                _selectedDate!.year,
                                _selectedDate!.month,
                              ) +
                              0.0,
                    fullMonthName: _selectedDate == null
                        ? DateFormat('MMMM').format(DateTime.now())
                        : DateFormat('MMMM').format(_selectedDate!),
                  ),
                  const SizedBox(height: 40),
                  Text("Extreme ends", style: theme.textTheme.displayLarge),
                  Column(
                    spacing: 20,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 20,
                        children: [
                          _buildRowContainers(
                            theme,
                            "Office with most reports",
                            _reportStatistics?.officeWithMostRep?.officeName ??
                                "-",
                            _reportCountLabel(
                              _reportStatistics?.officeWithMostRep?.reportCount,
                            ),
                          ),
                          _buildRowContainers(
                            theme,
                            "Device with most reports",
                            _reportStatistics?.deviceWithMostRep?.deviceName ??
                                "-",
                            _reportCountLabel(
                              _reportStatistics?.deviceWithMostRep?.reportCount,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 20,
                        children: [
                          _buildRowContainers(
                            theme,
                            "User with most reports",
                            _reportStatistics?.userWithMostRep?.username ?? "-",
                            _reportCountLabel(
                              _reportStatistics?.userWithMostRep?.reportCount,
                            ),
                          ),
                          _buildRowContainers(
                            theme,
                            "Day with most reports",
                            _busiestDayLabel,
                            "",
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
