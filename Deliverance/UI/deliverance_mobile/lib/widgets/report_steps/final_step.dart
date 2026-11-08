import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/report_summary.dart';
import 'package:flutter/material.dart';

class FinalStep extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final TextEditingController locationController;
  final TextEditingController devicesController;
  final TextEditingController dateController;
  final List<ReportOccurance> selectedOccurance;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final double severity;
  final IssueEnum issueType;
  final bool isSubmitting;

  const FinalStep({
    super.key,
    this.onBack,
    this.onSubmit,
    required this.locationController,
    required this.devicesController,
    required this.dateController,
    required this.selectedOccurance,
    required this.titleController,
    required this.descriptionController,
    required this.severity,
    required this.issueType,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          spacing: 40,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Final report",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            ReportSummary(
              locationController: locationController,
              devicesController: devicesController,
              dateController: dateController,
              selectedOccurance: selectedOccurance,
              titleController: titleController,
              descriptionController: descriptionController,
              severity: severity,
              issueType: issueType,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Back',
                  onPressed: isSubmitting ? null : onBack,
                ),
                PrimaryButton(
                  label: 'Submit',
                  onPressed: onSubmit,
                  isLoading: isSubmitting,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
