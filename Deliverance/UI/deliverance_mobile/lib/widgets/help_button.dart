import 'package:deliverance_mobile/widgets/custom_buttons.dart';
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
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        tooltip: "Help",
        padding: EdgeInsets.zero,
        iconSize: 20,
        style: IconButton.styleFrom(
          shape: CircleBorder(
            side: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          foregroundColor: colorScheme.primary,
        ),
        onPressed: () => showHelpSheet(context, title, sections),
        icon: const Icon(Icons.question_mark),
      ),
    );
  }
}

Future<void> showHelpSheet(
  BuildContext context,
  String title,
  List<HelpSection> sections,
) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: theme.colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Icon(Icons.help_outline, color: theme.colorScheme.primary),
                Flexible(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            for (final section in sections) HelpSectionView(section),
            PrimaryButton(
              width: null,
              onPressed: () => Navigator.of(context).pop(),
              label: "OK",
            ),
          ],
        ),
      ),
    ),
  );
}

class HelpSectionView extends StatelessWidget {
  final HelpSection section;

  const HelpSectionView(this.section, {super.key});

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
            Expanded(
              child: Text(
                section.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
