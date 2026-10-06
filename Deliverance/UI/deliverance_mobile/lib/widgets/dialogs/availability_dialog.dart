import 'package:flutter/material.dart';

class AvailabilitySelection {
  final String day;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;

  const AvailabilitySelection({
    required this.day,
    required this.fromTime,
    required this.toTime,
  });
}

const _daysOfWeek = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

Future<AvailabilitySelection?> showAvailabilityDialog(
  BuildContext context, {
  required TimeOfDay initialTime,
  required String initialDay,
}) {
  String selectedDay = initialDay;
  TimeOfDay? pickedTimeFrom;
  TimeOfDay? pickedTimeTo;

  return showDialog<AvailabilitySelection>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime({required bool isFrom}) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              initialEntryMode: TimePickerEntryMode.input,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        hourMinuteColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        dayPeriodColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        dayPeriodTextColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                    child: child!,
                  ),
                );
              },
            );
            if (picked != null) {
              setDialogState(() {
                if (isFrom) {
                  pickedTimeFrom = picked;
                } else {
                  pickedTimeTo = picked;
                }
              });
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Text('Select availability'),
            titleTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day of week',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: _daysOfWeek.map((day) {
                    final isSelected = selectedDay == day;
                    return ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          selectedDay = day;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time from',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => pickTime(isFrom: true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      pickedTimeFrom?.format(context) ??
                          initialTime.format(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time to',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => pickTime(isFrom: false),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      pickedTimeTo?.format(context) ??
                          initialTime.format(context),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (pickedTimeFrom != null && pickedTimeTo != null) {
                    Navigator.pop(
                      dialogContext,
                      AvailabilitySelection(
                        day: selectedDay,
                        fromTime: pickedTimeFrom!,
                        toTime: pickedTimeTo!,
                      ),
                    );
                  } else {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
