import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_drop_down.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class DetailsStep extends StatefulWidget {
  TextEditingController _title;
  TextEditingController _description;
  double _severity;
  VoidCallback? onBack;
  VoidCallback? onNext;
  TextEditingController _issueType;

  DetailsStep({
    super.key,
    required this._title,
    required this._description,
    required this._severity,
    required this._issueType,
    this.onBack,
    this.onNext,
  });

  @override
  State<DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<DetailsStep> {
  @override
  Widget build(BuildContext context) {
    TextStyle? style = Theme.of(context).textTheme.titleSmall;
    return SingleChildScrollView(
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
                    label: widget._severity.round().toString(),
                    onChanged: (double newValue) {
                      setState(() {
                        widget._severity =
                            newValue; // 2. Update state to re-render
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final isSelected = widget._severity.round() == value;
                      return Text(
                        "$value",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            CustomDropDown(label: "4. Issue type", items: {}, textStyle: style),
            const SizedBox(height: 40),
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
