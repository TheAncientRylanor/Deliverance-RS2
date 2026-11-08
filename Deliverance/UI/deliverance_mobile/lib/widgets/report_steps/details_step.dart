import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_drop_down.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:flutter/material.dart';

class DetailsStep extends StatefulWidget {
  final TextEditingController title;
  final TextEditingController description;
  final double severity;
  final ValueChanged<double> onSeverityChanged;
  final IssueEnum issueType;
  final ValueChanged<IssueEnum> onIssueTypeChanged;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final GlobalKey<FormState> detailsKey;
  const DetailsStep({
    super.key,
    required this.detailsKey,
    required this.title,
    required this.description,
    required this.severity,
    required this.onSeverityChanged,
    required this.issueType,
    required this.onIssueTypeChanged,
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

  final FieldValidator _validateTitle = maxLength(
    'Report title',
    FieldLimits.reportTitleMax,
    required: true,
  );
  final FieldValidator _validateDescription = maxLength(
    'Description',
    FieldLimits.reportDetailMax,
    required: true,
  );

  void _handleNext() {
    if (widget.detailsKey.currentState!.validate()) {
      widget.onNext?.call();
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
                controller: widget.title,
                maxLength: FieldLimits.reportTitleMax,
                validator: _validateTitle,
              ),
              Column(
                children: [
                  CustomTextField(
                    labelText: "2. Description",
                    textStyle: style,
                    minLines: 4,
                    maxLines: 20,
                    maxLength: FieldLimits.reportDetailMax,
                    controller: widget.description,
                    validator: _validateDescription,
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
                      value: widget.severity,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      label: SeverityEnum.fromValue(
                        widget.severity.round(),
                      ).label,
                      onChanged: widget.onSeverityChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: SeverityEnum.values.map((severity) {
                        final isSelected =
                            widget.severity.round() == severity.value;
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
                initialValue: widget.issueType,
                textStyle: style,
                onChanged: (value) {
                  if (value != null) widget.onIssueTypeChanged(value);
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
