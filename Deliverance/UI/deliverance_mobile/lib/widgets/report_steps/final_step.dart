import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class FinalStep extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final TextEditingController locationController;
  final TextEditingController devicesController;
  final TextEditingController dateController;
  final List<String> selectedOccurance;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final double severity;
  final TextEditingController issueTypeController;

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
    required this.issueTypeController,
  });

  @override
  State<FinalStep> createState() => _FinalStepState();
}

class _FinalStepState extends State<FinalStep> {
  static const Map<String, List<String>> _questions = {
    'Was this a one-time occurrence?': ['Yes', 'No'],
    'Has this happened before?': ['Yes', 'No', 'Not sure'],
    'Did it occur during business hours?': ['Yes', 'No'],
    'Was anyone else present when it happened?': ['Yes', 'No', 'Not sure'],
  };

  int _currentQuestionIndex = 0;

  List<String> get _questionKeys => _questions.keys.toList();

  void _goToPreviousQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex - 1).clamp(
        0,
        _questions.length - 1,
      );
    });
  }

  void _goToNextQuestion() {
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1).clamp(
        0,
        _questions.length - 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;
    final subtitleStyle = Theme.of(context).textTheme.titleMedium;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          spacing: 40,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Final report",
              style: Theme.of(context).textTheme.headlineSmall,
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
                    text: widget.severity.round().toString(),
                  ),
                ),
                CustomTextField(
                  labelText: "Issue type",
                  textStyle: style,
                  readOnly: true,
                  controller: widget.issueTypeController,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SecondaryButton(label: 'Back', onPressed: widget.onBack),
                PrimaryButton(label: 'Submit', onPressed: widget.onSubmit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccuranceSlideshow(BuildContext context, TextStyle? style) {
    final selectedAnswer =
        _currentQuestionIndex < widget.selectedOccurance.length
        ? widget.selectedOccurance[_currentQuestionIndex]
        : '';

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
                onPressed: _currentQuestionIndex > 0
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
                          _questionKeys[_currentQuestionIndex],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          selectedAnswer.isEmpty ? '-' : selectedAnswer,
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
              onPressed: _currentQuestionIndex < _questions.length - 1
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
