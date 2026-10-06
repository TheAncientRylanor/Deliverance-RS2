import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_drop_down.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class DetailsStep extends StatefulWidget {
  final TextEditingController _title;
  final TextEditingController _description;
  double _severity;
  ValueChanged<double>? onSeverityChanged;
  VoidCallback? onBack;
  VoidCallback? onNext;
  IssueEnum _issueType;
  final GlobalKey<FormState> detailsKey;
  DetailsStep({
    super.key,
    required this.detailsKey,
    required this._title,
    required this._description,
    required this._severity,
    required this._issueType,
    this.onSeverityChanged,
    this.onBack,
    this.onNext,
  });

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  @override
  void initState() {
    super.initState();
  }

  String? _validateRequired(dynamic value) {
    if (value == null || (value as String).trim().isEmpty) {
      return mField;
    }
    return null;
  }

  void _handleNext() {
    if (widget.detailsKey.currentState!.validate()) {
      widget.onNext?.call();
    } else {
      final errors = <String>[];
      final titleError = _validateRequired(widget._title.text);
      if (titleError != null) {
        errors.add("Report title: $titleError");
      }
      final descriptionError = _validateRequired(widget._description.text);
      if (descriptionError != null) {
        errors.add("Description: $descriptionError");
      }
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
    TextStyle? style = Theme.of(context).textTheme.titleSmall;
    return SingleChildScrollView(
      child: Form(
        key: widget.detailsKey,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            spacing: 40,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                labelText: "1. Report title",
                textStyle: style,
                controller: widget._title,
                validator: _validateRequired,
              ),
              Column(
                children: [
                  CustomTextField(
                    labelText: "2. Description",
                    textStyle: style,
                    minLines: 4,
                    maxLines: 20,
                    maxLength: 255,
                    controller: widget._description,
                    validator: _validateRequired,
                  ),
                  Text(
                    "Please describe the problem in detail",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("3. Severity", style: style),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      tickMarkShape: const _VerticalLineSliderTickMarkShape(),
                    ),
                    child: Slider(
                      value: widget._severity,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      label: SeverityEnum.fromValue(
                        widget._severity.round(),
                      ).label,
                      onChanged: (double newValue) {
                        setState(() {
                          widget._severity = newValue;
                        });
                        widget.onSeverityChanged?.call(newValue);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: SeverityEnum.values.map((severity) {
                        final isSelected =
                            widget._severity.round() == severity.value;
                        return Text(
                          severity.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              CustomDropDown<IssueEnum>(
                label: "4. Issue type",
                items: {for (final e in IssueEnum.values) e: e.label},
                initialValue: widget._issueType,
                textStyle: style,
                onChanged: (value) {
                  setState(() {
                    widget._issueType = value!;
                  });
                },
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SecondaryButton(label: 'Back', onPressed: widget.onBack),
                  PrimaryButton(label: 'Next', onPressed: _handleNext),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalLineSliderTickMarkShape extends SliderTickMarkShape {
  const _VerticalLineSliderTickMarkShape();

  static const double tickHeight = 8.0;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return Size.fromHeight(tickHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool isEnabled = false,
    required TextDirection textDirection,
  }) {
    final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
    final Color color =
        (isTickMarkRightOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor) ??
        (isTickMarkRightOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor) ??
        Colors.white;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    context.canvas.drawLine(
      Offset(center.dx, center.dy - tickHeight / 2),
      Offset(center.dx, center.dy + tickHeight / 2),
      paint,
    );
  }
}
