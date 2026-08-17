import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/office_provider.dart';
import 'package:deliverance_mobile/providers/report_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_toast.dart';
import 'package:deliverance_mobile/widgets/report_steps/details_step.dart';
import 'package:deliverance_mobile/widgets/report_steps/final_step.dart';
import 'package:deliverance_mobile/widgets/report_steps/time_step.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/report_steps/location_step.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

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
  final TextEditingController _issueType = TextEditingController();
  List<OfficeReport> _officeReports = [];
  double _severity = 1.0;
  final List<String> _selectedOccurances = [];
  List<EasyStep> stepList() => [
    EasyStep(icon: Icon(Icons.location_on), title: '1. Where?'),
    EasyStep(icon: Icon(Icons.av_timer_outlined), title: '2. When?'),
    EasyStep(icon: Icon(Icons.fact_check_rounded), title: '3. Details'),
    EasyStep(icon: Icon(Icons.check), title: '4. Final'),
  ];
  late ReportProvider _reportProvider;
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: EasyStepper(
                activeStep: activeStep,
                steps: stepList(),
                onStepReached: (index) => setState(() => activeStep = index),
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
            if (activeStep == 0)
              Expanded(
                child: LocationStep(
                  onBack: () => setState(() => activeStep--),
                  onNext: () => setState(() => activeStep++),
                  locationController: _locationController,
                  devicesController: _devicesController,
                  officeReports: _officeReports,
                ),
              )
            else if (activeStep == 1)
              Expanded(
                child: TimeStep(
                  onBack: () => setState(() => activeStep--),
                  onNext: () => setState(() => activeStep++),
                  dateController: _dateController,
                  selectedOccurance: _selectedOccurances,
                ),
              )
            else if (activeStep == 2)
              Expanded(
                child: DetailsStep(
                  onBack: () => setState(() => activeStep--),
                  onNext: () => setState(() => activeStep++),
                  title: _titleController,
                  description: _detailsController,
                  severity: _severity,
                  issueType: _issueType,
                ),
              )
            else if (activeStep == 3)
              Expanded(
                child: FinalStep(
                  onBack: () => setState(() => activeStep--),
                  onSubmit: () async {
                    final report = Report(
                      reportName: _titleController.text,
                      dateReported: DateTime.tryParse(_dateController.text),
                      severity: _severity.round(),
                      detail: _detailsController.text,
                    );
                    try {
                      await _reportProvider.insert(report.toJson());
                      if (!context.mounted) return;
                      showCustomToast(context, "Office saved successfully");
                      await Future.delayed(const Duration(milliseconds: 200));
                      Navigator.of(context).pop();
                    } on ApiClientException catch (e) {
                      if (!context.mounted) return;
                      alertBox(context, "Error", e.message);
                    }
                  },
                  locationController: _locationController,
                  devicesController: _devicesController,
                  dateController: _dateController,
                  selectedOccurance: _selectedOccurances,
                  titleController: _titleController,
                  descriptionController: _detailsController,
                  severity: _severity,
                  issueTypeController: _issueType,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
