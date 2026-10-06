import 'package:deliverance_mobile/models/answer_enum.dart';
import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class FinalStep extends StatefulWidget {
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
  State<FinalStep> createState() => _FinalStepState();
}

class _FinalStepState extends State<FinalStep> {
  int _currentQuestionIndex = 0;

  void _goToPreviousQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex - 1).clamp(
        0,
        widget.selectedOccurance.length - 1,
      );
    });
  }

  void _goToNextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1).clamp(
        0,
        widget.selectedOccurance.length - 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    final subtitleStyle = Theme.of(context).textTheme.headlineSmall;

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
            Column(
              spacing: 40,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("1.1 Where?", style: subtitleStyle),
                CustomTextField(
                  labelText: "Location",
                  textStyle: style,
                  readOnly: true,
                  controller: widget.locationController,
                ),
                CustomTextField(
                  labelText: "Devices affected",
                  textStyle: style,
                  readOnly: true,
                  minLines: 2,
                  maxLines: 6,
                  controller: widget.devicesController,
                ),
              ],
            ),
            Column(
              spacing: 40,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("1.2 When?", style: subtitleStyle),
                CustomTextField(
                  labelText: "Date and time",
                  textStyle: style,
                  readOnly: true,
                  controller: widget.dateController,
                ),
                _buildOccuranceSlideshow(context, style),
              ],
            ),
            Column(
              spacing: 40,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("1.3 Details", style: subtitleStyle),
                CustomTextField(
                  labelText: "Report title",
                  textStyle: style,
                  readOnly: true,
                  controller: widget.titleController,
                ),
                CustomTextField(
                  labelText: "Description",
                  textStyle: style,
                  readOnly: true,
                  minLines: 4,
                  maxLines: 20,
                  controller: widget.descriptionController,
                ),
                CustomTextField(
                  labelText: "Severity",
                  textStyle: style,
                  readOnly: true,
                  controller: TextEditingController(
                    text: SeverityEnum.fromValue(widget.severity.round()).label,
                  ),
                ),
                CustomTextField(
                  labelText: "Issue type",
                  textStyle: style,
                  readOnly: true,
                  controller: TextEditingController(
                    text: widget.issueType.label,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Back',
                  onPressed: widget.isSubmitting ? null : widget.onBack,
                ),
                PrimaryButton(
                  label: 'Submit',
                  onPressed: widget.onSubmit,
                  isLoading: widget.isSubmitting,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccuranceSlideshow(BuildContext context, TextStyle? style) {
    final hasOccurances = widget.selectedOccurance.isNotEmpty;
    final currentOccurance = hasOccurances
        ? widget.selectedOccurance[_currentQuestionIndex]
        : null;
    final questionText = currentOccurance?.question ?? '-';
    final answerText = currentOccurance?.answer != null
        ? AnswerEnum.fromValue(currentOccurance!.answer!).label
        : '-';

    return Column(
      children: [
        Text("Occurrence", style: style),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotatedBox(
              quarterTurns: 2,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                color: Theme.of(context).colorScheme.primary,
                onPressed: hasOccurances && _currentQuestionIndex > 0
                    ? _goToPreviousQuestion
                    : null,
                iconSize: 20,
              ),
            ),
            Expanded(
              child: Container(
                height: 150,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          questionText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          answerText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              color: Theme.of(context).colorScheme.primary,
              onPressed:
                  hasOccurances &&
                      _currentQuestionIndex <
                          widget.selectedOccurance.length - 1
                  ? _goToNextQuestion
                  : null,
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }
}
