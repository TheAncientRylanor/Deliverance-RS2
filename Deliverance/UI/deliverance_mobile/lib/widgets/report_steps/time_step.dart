import 'package:deliverance_mobile/widgets/custom_date_time_picker.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

import '../custom_buttons.dart';
import '../custom_drop_down.dart';

class TimeStep extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final TextEditingController _dateController;
  final List<String> _selectedOccurance;
  const TimeStep({
    super.key,
    this.onBack,
    this.onNext,
    required this._dateController,
    required this._selectedOccurance,
  });

  @override
  State<TimeStep> createState() => _TimeStepState();
}

class _TimeStepState extends State<TimeStep> {
  String? selectedLocation;
  bool isChecked = false;
  DateTime? _selectedDate;

  final Map<String, List<String>> _questions = const {
    'Was this a one-time occurrence?': ['Yes', 'No'],
    'Has this happened before?': ['Yes', 'No', 'Not sure'],
    'Did it occur during business hours?': ['Yes', 'No'],
    'Was anyone else present when it happened?': ['Yes', 'No', 'Not sure'],
  };

  int _currentQuestionIndex = 0;

  List<String> get _questionKeys => _questions.keys.toList();

  @override
  void initState() {
    super.initState();
    while (widget._selectedOccurance.length < _questions.length) {
      widget._selectedOccurance.add('');
    }
  }

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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              labelText: "1. Date and time",
              controller: widget._dateController,
              textStyle: Theme.of(context).textTheme.titleSmall,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 50),
            Text(
              "2. Device affected",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 2,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _currentQuestionIndex > 0
                        ? _goToPreviousQuestion
                        : null,
                    iconSize: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 250,
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
                            child: Material(
                              type: MaterialType.transparency,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _questionKeys[_currentQuestionIndex],
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  RadioGroup<String>(
                                    groupValue:
                                        widget
                                            ._selectedOccurance[_currentQuestionIndex]
                                            .isEmpty
                                        ? null
                                        : widget
                                              ._selectedOccurance[_currentQuestionIndex],
                                    onChanged: (value) {
                                      setState(() {
                                        widget._selectedOccurance[_currentQuestionIndex] =
                                            value ?? '';
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          (_questions[_questionKeys[_currentQuestionIndex]] ??
                                                  [])
                                              .map(
                                                (option) =>
                                                    RadioListTile<String>(
                                                      title: Text(option),
                                                      value: option,
                                                    ),
                                              )
                                              .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Answer the questions presented before you",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _currentQuestionIndex < _questions.length - 1
                      ? _goToNextQuestion
                      : null,
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SecondaryButton(label: 'Back', onPressed: widget.onBack),
                PrimaryButton(label: 'Next', onPressed: widget.onNext),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDateTime = await pickDateAndTime(
      context,
      initialDate: _selectedDate,
    );

    if (pickedDateTime == null) return;

    setState(() {
      _selectedDate = pickedDateTime;
      widget._dateController.text = _selectedDate.toString();
    });
  }
}
