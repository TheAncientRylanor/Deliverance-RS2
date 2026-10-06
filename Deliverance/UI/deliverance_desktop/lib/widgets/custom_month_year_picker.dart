import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';

Future<DateTime?> pickMonthYear(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final DateTime? pickedDate = await showMonthYearPicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    builder: (context, child) => _ThemedPicker(child: child),
  );

  if (pickedDate == null) return null;

  return DateTime(pickedDate.year, pickedDate.month);
}

class _ThemedPicker extends StatelessWidget {
  final Widget? child;
  const _ThemedPicker({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme.copyWith(
          secondary: colorScheme.primary,
          onSecondary: colorScheme.onPrimary,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ),
      child: child!,
    );
  }
}
