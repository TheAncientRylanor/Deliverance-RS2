import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

class HelpSection {
  final IconData icon;
  final String title;
  final String text;
  final Widget? example;

  const HelpSection({
    required this.icon,
    required this.title,
    required this.text,
    this.example,
  });
}

class HelpButton extends StatelessWidget {
  final String title;
  final List<HelpSection> sections;

  const HelpButton({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: null,
      tooltip: "Help",
      shape: CircleBorder(
        side: BorderSide(color: colorScheme.primary, width: 2),
      ),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.primary,
      onPressed: () => showHelpDialog(context, title, sections),
      child: const Icon(Icons.question_mark),
    );
  }
}

Future<void> showHelpDialog(
  BuildContext context,
  String title,
  List<HelpSection> sections,
) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.center,
      title: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Icon(Icons.help_outline, color: theme.colorScheme.primary),
            Text(title, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              for (final section in sections) _HelpSectionView(section),
            ],
          ),
        ),
      ),
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          label: "OK",
        ),
      ],
    ),
  );
}

class _HelpSectionView extends StatelessWidget {
  final HelpSection section;

  const _HelpSectionView(this.section);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(section.icon, size: 20, color: theme.colorScheme.primary),
            Text(
              section.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(section.text, style: theme.textTheme.bodyMedium),
        if (section.example != null) section.example!,
      ],
    );
  }
}
