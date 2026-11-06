import 'package:deliverance_scout/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

Widget globalLoadingSpinner({double size = 36, Color? color}) {
  return Center(
    child: SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color.fromRGBO(255, 179, 0, 1.00),
        ),
      ),
    ),
  );
}

enum AlertBoxMode { choice, ok }

Future<bool?> alertBox(
  BuildContext context,
  String title,
  String content, {
  AlertBoxMode mode = AlertBoxMode.ok,
}) {
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.center,
      title: Center(
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        if (mode == AlertBoxMode.choice)
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  label: "No",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  label: "Yes",
                ),
              ),
            ],
          )
        else
          PrimaryButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            label: "OK",
          ),
      ],
    ),
  );
}
