import 'package:deliverance_desktop/models/answer_enum.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

Future<void> showOccurrenceDialog(
  BuildContext context,
  List<ReportOccurrence> occurrences,
) {
  final theme = Theme.of(context);
  int currentIndex = 0;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final hasOccurrences = occurrences.isNotEmpty;
        final current = hasOccurrences ? occurrences[currentIndex] : null;
        final answerLabel = current?.answer == null
            ? '-'
            : AnswerEnum.fromValue(current!.answer!).label;

        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Text("Occurrences", style: theme.textTheme.headlineSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotatedBox(
                        quarterTurns: 2,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          color: theme.colorScheme.primary,
                          onPressed: currentIndex > 0
                              ? () => setDialogState(() => currentIndex--)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 250,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              child: Center(
                                child: SingleChildScrollView(
                                  child: hasOccurrences
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              current!.question ?? '-',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 15),
                                            Text(
                                              answerLabel,
                                              textAlign: TextAlign.center,
                                              style:
                                                  theme.textTheme.labelMedium,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          "No occurrences available",
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.labelMedium,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (hasOccurrences)
                              Text(
                                "Question ${currentIndex + 1} of ${occurrences.length}",
                                style: theme.textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        color: theme.colorScheme.primary,
                        onPressed: currentIndex < occurrences.length - 1
                            ? () => setDialogState(() => currentIndex++)
                            : null,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SecondaryButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        label: "Close",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
