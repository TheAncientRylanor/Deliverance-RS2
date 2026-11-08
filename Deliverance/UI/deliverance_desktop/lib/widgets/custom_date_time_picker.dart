import 'package:flutter/material.dart';

Future<DateTime?> pickDateAndTime(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    builder: (context, child) => _ThemedPicker(child: child),
  );

  if (pickedDate == null || !context.mounted) return null;

  final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
    builder: (context, child) => _ThemedPicker(child: child),
  );

  if (pickedTime == null) return null;

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

class _ThemedPicker extends StatelessWidget {
  final Widget? child;
  const _ThemedPicker({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme,
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: colorScheme.surface,
          headerBackgroundColor: colorScheme.surfaceContainer,
          headerForegroundColor: colorScheme.onSurface,
          weekdayStyle: TextStyle(color: colorScheme.onSurface),
          dayForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
          dayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colorScheme.primary
                : Colors.transparent,
          ),
          todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
          todayBorder: BorderSide(color: colorScheme.primary),
          yearForegroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
          yearBackgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colorScheme.primary
                : Colors.transparent,
          ),
          rangePickerBackgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: colorScheme.surface,
          dialBackgroundColor: colorScheme.surfaceContainer,
          dialHandColor: colorScheme.primary,
          dialTextColor: colorScheme.onSurface,
          hourMinuteColor: colorScheme.surfaceContainer,
          hourMinuteTextColor: colorScheme.onSurface,
          dayPeriodColor: colorScheme.surfaceContainer,
          dayPeriodTextColor: colorScheme.onSurface,
          entryModeIconColor: colorScheme.primary,
          helpTextStyle: TextStyle(color: colorScheme.onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: colorScheme.outline),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ),
      child: child!,
    );
  }
}
