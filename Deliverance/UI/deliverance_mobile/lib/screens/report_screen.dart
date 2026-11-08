import 'dart:convert';
import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/report_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_toast.dart';
import 'package:deliverance_mobile/widgets/report_steps/details_step.dart';
import 'package:deliverance_mobile/widgets/report_steps/final_step.dart';
import 'package:deliverance_mobile/widgets/report_steps/time_step.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/report_steps/location_step.dart';

class ReportScreen extends StatefulWidget {
  final Report? report;
  const ReportScreen({super.key, this.report});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int activeStep = 0;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _devicesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final _locationKey = GlobalKey<FormState>();
  final _timeKey = GlobalKey<FormState>();
  final _detailsKey = GlobalKey<FormState>();
  List<OfficeReport> _officeReports = [];
  double _severity = 1.0;
  IssueEnum _issueType = IssueEnum.hardware;
  List<ReportOccurrence> _selectedOccurrences = [];
  int? _reportId;
  bool _isSavingDraft = false;
  bool _isSubmittingReport = false;
  bool get _isSentReport => widget.report?.status == "UnseenReportState";
  List<EasyStep> stepList() => [
    EasyStep(icon: Icon(Icons.location_on), title: '1. Where?'),
    EasyStep(icon: Icon(Icons.av_timer_outlined), title: '2. When?'),
    EasyStep(icon: Icon(Icons.fact_check_rounded), title: '3. Details'),
    EasyStep(icon: Icon(Icons.check), title: '4. Final'),
  ];
  String getDevicesNames() {
    return _officeReports
        .map(
          (o) => "${o.name} - ${o.deviceReports.map((x) => x.name).join(",")}",
        )
        .join(";\n");
  }

  @override
  void initState() {
    super.initState();
    if (widget.report != null) {
      _reportId = widget.report!.id;
      initReport(widget.report!);
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final report = _buildReport();
    await prefs.setString('report_draft', jsonEncode(report.toJson()));
  }

  Future<void> _removeDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('report_draft');
  }

  bool checkKeys() {
    final isLocationValid = _locationKey.currentState!.validate();
    final isTimeValid = _timeKey.currentState!.validate();
    final isDetailsValid = _detailsKey.currentState!.validate();
    return isLocationValid && isTimeValid && isDetailsValid;
  }

  int? _firstInvalidStep() {
    if (!(_locationKey.currentState?.validate() ?? true)) return 0;
    if (!(_timeKey.currentState?.validate() ?? true)) return 1;
    if (!(_detailsKey.currentState?.validate() ?? true)) return 2;
    return null;
  }

  void initReport(Report report) {
    _officeReports = report.officeReports ?? [];
    _dateController.text = report.dateReported.toString();
    _titleController.text = report.reportName ?? "";
    _detailsController.text = report.detail ?? "";
    _selectedOccurrences = report.reportOccurrences ?? [];
    _issueType = IssueEnum.fromValue(report.issueType ?? 1);
    _severity = report.severity?.toDouble() ?? 1.0;
    _locationController.text =
        report.officeReports?.map((x) => x.name).join(";") ?? "";
    var temp = report.officeReports?.expand((x) => x.deviceReports);
    _devicesController.text = temp?.map((x) => x.name).join("; ") ?? '';
  }

  void updateTimeStep(List<ReportOccurrence> occurrence) {
    setState(() {
      _selectedOccurrences = occurrence;
    });
  }

  Report _buildReport({bool isDraft = false}) {
    return Report(
      reportName: _titleController.text,
      dateReported: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      severity: _severity.round(),
      detail: _detailsController.text,
      officeReports: _officeReports,
      reportOccurrences: _selectedOccurrences,
      issueType: _issueType.value,
      isDraft: isDraft,
    );
  }

  Future<void> _saveDraftToServer() async {
    final report = _buildReport(isDraft: true);
    setState(() => _isSavingDraft = true);
    try {
      final reportProvider = context.read<ReportProvider>();
      final result = _reportId == null
          ? await reportProvider.insert(report.toJson())
          : await reportProvider.update(_reportId!, report.toJson());
      _reportId = result.id;
      if (!mounted) return;
      showCustomToast(
        context,
        report.reportName?.trim().isNotEmpty == true
            ? "Draft \"${report.reportName!.trim()}\" saved. You can finish it later."
            : "Draft saved. You can finish it later.",
        type: ToastType.success,
      );
    } on ApiClientException catch (e) {
      if (!context.mounted) return;
      alertBox(context, "Error", e.message);
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SecondaryButton(
                    onPressed: () async {
                      final result = await alertBox(
                        context,
                        "Cancel report",
                        "Are you sure you want to cancel this report? Your progress will be lost.",
                      );
                      if (result != true) return;
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    label: "Cancel",
                  ),
                  if (!_isSentReport)
                    PrimaryButton(
                      onPressed: _saveDraftToServer,
                      label: "Save Draft",
                      isLoading: _isSavingDraft,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: EasyStepper(
                activeStep: activeStep,
                steps: stepList(),
                onStepReached: (index) async {
                  await _saveDraft();
                  setState(() => activeStep = index);
                },
                showLoadingAnimation: false,
                lineStyle: LineStyle(
                  lineType: LineType.normal,
                  defaultLineColor: Colors.white,
                  finishedLineColor: Theme.of(context).colorScheme.primary,
                ),
                defaultStepBorderType: BorderType.normal,
                titleTextStyle: Theme.of(context).textTheme.labelSmall,
                stepRadius: 30,
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: activeStep,
                children: [
                  LocationStep(
                    onBack: () => setState(() => Navigator.pop(context)),
                    onNext: () async {
                      await _saveDraft();
                      setState(() => activeStep++);
                    },
                    locationController: _locationController,
                    devicesController: _devicesController,
                    officeReports: _officeReports,
                    locationKey: _locationKey,
                  ),
                  TimeStep(
                    onBack: () => setState(() => activeStep--),
                    onNext: () async {
                      await _saveDraft();
                      setState(() => activeStep++);
                    },
                    dateController: _dateController,
                    selectedOccurrence: _selectedOccurrences,
                    onDataChanged: updateTimeStep,
                    timeKey: _timeKey,
                  ),
                  DetailsStep(
                    onBack: () => setState(() => activeStep--),
                    onNext: () async {
                      await _saveDraft();
                      setState(() => activeStep++);
                    },
                    title: _titleController,
                    description: _detailsController,
                    severity: _severity,
                    onSeverityChanged: (value) =>
                        setState(() => _severity = value),
                    issueType: _issueType,
                    onIssueTypeChanged: (value) =>
                        setState(() => _issueType = value),
                    detailsKey: _detailsKey,
                  ),
                  FinalStep(
                    onBack: () => setState(() => activeStep--),
                    onSubmit: () async {
                      if (checkKeys()) {
                        final report = _buildReport(isDraft: false);
                        setState(() => _isSubmittingReport = true);
                        try {
                          final reportProvider = context.read<ReportProvider>();
                          if (_reportId == null) {
                            await reportProvider.insert(report.toJson());
                          } else {
                            await reportProvider.update(
                              _reportId!,
                              report.toJson(),
                            );
                          }
                          if (!context.mounted) return;
                          showCustomToast(
                            context,
                            "Report \"${report.reportName}\" sent. An admin will review it.",
                            type: ToastType.success,
                          );
                          await _removeDraft();
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        } on ApiClientException catch (e) {
                          if (!context.mounted) return;
                          alertBox(
                            context,
                            "Error",
                            e.message,
                            mode: AlertBoxMode.ok,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmittingReport = false);
                          }
                        }
                      } else {
                        final step = _firstInvalidStep();
                        if (step != null) setState(() => activeStep = step);
                      }
                    },
                    isSubmitting: _isSubmittingReport,
                    locationController: _locationController,
                    devicesController: TextEditingController(
                      text: getDevicesNames(),
                    ),
                    dateController: _dateController,
                    selectedOccurrence: _selectedOccurrences,
                    titleController: _titleController,
                    descriptionController: _detailsController,
                    severity: _severity,
                    issueType: _issueType,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
