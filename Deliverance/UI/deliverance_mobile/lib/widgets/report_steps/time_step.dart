import 'package:deliverance_mobile/models/answer_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/occurance_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_date_time_picker.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../custom_buttons.dart';

// ignore: must_be_immutable
class TimeStep extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final TextEditingController dateController;
  final ValueChanged<List<ReportOccurance>> onDataChanged;
  List<ReportOccurance> selectedOccurance;
  final GlobalKey<FormState> timeKey;
  TimeStep({
    required this.timeKey,
    super.key,
    this.onBack,
    this.onNext,
    required this.dateController,
    required this.selectedOccurance,
    required this.onDataChanged,
  });

  @override
  State<TimeStep> createState() => _TimeStepState();
}

class _TimeStepState extends State<TimeStep> {
  String? selectedLocation;
  bool isChecked = false;
  DateTime? _selectedDate;
  bool isLoading = true;
  late OccuranceProvider _occuranceProvider;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _occuranceProvider = context.read<OccuranceProvider>();
    loadValues();
  }

  Future<void> loadValues() async {
    isLoading = true;
    try {
      var result = await _occuranceProvider.get();
      if (result.items != null) {
        mapOccurances(
          result.items!
              .map(
                (x) => ReportOccurance(occuranceId: x.id, question: x.question),
              )
              .toList(),
        );
        _currentQuestionIndex = 0;
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: loadValues);
    }
  }

  void mapOccurances(List<ReportOccurance> occurances) {
    for (var occ in occurances) {
      occ.answer = widget.selectedOccurance
          .firstWhere(
            (x) => occ.occuranceId != null
                ? x.occuranceId == occ.occuranceId
                : x.question == occ.question,
            orElse: () => ReportOccurance(),
          )
          .answer;
    }
    widget.onDataChanged(occurances);
  }

  void _goToPreviousQuestion() {
    if (widget.selectedOccurance.isEmpty) return;
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex - 1).clamp(
        0,
        widget.selectedOccurance.length - 1,
      );
    });
  }

  void _goToNextQuestion() {
    if (widget.selectedOccurance.isEmpty) return;
    setState(() {
      _currentQuestionIndex = (_currentQuestionIndex + 1).clamp(
        0,
        widget.selectedOccurance.length - 1,
      );
    });
  }

  String? _validateDate(dynamic value) {
    if (value == null || (value as String).isEmpty) {
      return "Please choose a date";
    }
    return null;
  }

  void _handleNext() {
    final isFormValid = widget.timeKey.currentState!.validate();
    final errors = <String>[];
    final dateError = _validateDate(widget.dateController.text);
    if (dateError != null) errors.add(dateError);
    if (!widget.selectedOccurance.any((o) => o.answer != null)) {
      errors.add("Please answer at least one occurrence question");
    }

    if (isFormValid && errors.isEmpty) {
      widget.onNext?.call();
    } else {
      alertBox(
        context,
        "Incomplete form",
        errors.join("\n"),
        mode: AlertBoxMode.ok,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: isLoading
          ? globalLoadingSpinner()
          : Form(
              key: widget.timeKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      labelText: "1. Date and time",
                      controller: widget.dateController,
                      textStyle: Theme.of(context).textTheme.titleSmall,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: _validateDate,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      "2. Occurance",
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: widget.selectedOccurance.isEmpty
                                        ? Text(
                                            "No occurances available",
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelMedium,
                                          )
                                        : Material(
                                            type: MaterialType.transparency,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  widget
                                                          .selectedOccurance[_currentQuestionIndex]
                                                          .question ??
                                                      "",
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelMedium,
                                                ),
                                                const SizedBox(height: 10),
                                                RadioGroup<int>(
                                                  groupValue: widget
                                                      .selectedOccurance[_currentQuestionIndex]
                                                      .answer,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      widget
                                                              .selectedOccurance[_currentQuestionIndex]
                                                              .answer =
                                                          value;
                                                    });
                                                  },
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      for (var ans
                                                          in AnswerEnum.values)
                                                        RadioListTile<int>(
                                                          title: Text(
                                                            ans.label,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                          value: ans.value,
                                                          activeColor:
                                                              Colors.white,
                                                        ),
                                                    ],
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
                          onPressed:
                              _currentQuestionIndex <
                                  widget.selectedOccurance.length - 1
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
                        SecondaryButton(
                          label: 'Back',
                          onPressed: widget.onBack,
                        ),
                        PrimaryButton(label: 'Next', onPressed: _handleNext),
                      ],
                    ),
                  ],
                ),
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
      widget.dateController.text = _selectedDate.toString();
    });
  }
}
