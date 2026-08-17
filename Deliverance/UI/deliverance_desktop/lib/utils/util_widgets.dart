import 'dart:convert';

import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

dynamic dateEncode(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  }
  return item;
}

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

Future<bool?> alertBox(BuildContext context, String title, String content) {
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

void alertBoxMoveBack(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}

Image imageFromBase64String(String base64Image) {
  return Image.memory(
    base64Decode(base64Image),
    height: 400,
    width: 400,
    fit: BoxFit.cover,
  );
}

const String mField = "This filed is mandatory";

const String numericField = "This filed is numeric";
