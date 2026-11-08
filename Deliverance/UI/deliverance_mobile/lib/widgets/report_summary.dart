import 'package:deliverance_mobile/models/answer_enum.dart';
import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class ReportSummary extends StatefulWidget {
  final TextEditingController locationController;
  final TextEditingController devicesController;
  final TextEditingController dateController;
  final List<ReportOccurrence> selectedOccurrence;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final double? severity;
  final IssueEnum? issueType;

  const ReportSummary({
    super.key,
    required this.locationController,
    required this.devicesController,
    required this.dateController,
    required this.selectedOccurrence,
    required this.titleController,
    required this.descriptionController,
    required this.severity,
    required this.issueType,
  });

  @override
  State<ReportSummary> createState() => _ReportSummaryState();
}

class _ReportSummaryState extends State<ReportSummary> {
  int _currentQuestionIndex = 0;

  void _goToPreviousQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex - 1).clamp(
        0,
        widget.selectedOccurrence.length - 1,
      );
    });
  }

  void _goToNextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1).clamp(
        0,
        widget.selectedOccurrence.length - 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    final subtitleStyle = Theme.of(context).textTheme.headlineSmall;
    final severity = widget.severity;

    return Column(
      spacing: 40,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            _buildOccurrenceSlideshow(context, style),
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
                text: severity == null
                    ? '-'
                    : SeverityEnum.fromValue(severity.round()).label,
              ),
            ),
            CustomTextField(
              labelText: "Issue type",
              textStyle: style,
              readOnly: true,
              controller: TextEditingController(
                text: widget.issueType?.label ?? '-',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOccurrenceSlideshow(BuildContext context, TextStyle? style) {
    final hasOccurrences = widget.selectedOccurrence.isNotEmpty;
    final currentOccurrence = hasOccurrences
        ? widget.selectedOccurrence[_currentQuestionIndex]
        : null;
    final questionText = currentOccurrence?.question ?? '-';
    final answerText = currentOccurrence?.answer != null
        ? AnswerEnum.fromValue(currentOccurrence!.answer!).label
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
                onPressed: hasOccurrences && _currentQuestionIndex > 0
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
                  hasOccurrences &&
                      _currentQuestionIndex <
                          widget.selectedOccurrence.length - 1
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
