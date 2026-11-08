import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/widgets/help_button.dart';
import 'package:flutter/material.dart';

const severityHelpSections = [
  HelpSection(
    icon: Icons.tune,
    title: "How bad is it?",
    text:
        "Slide to the level that best matches how much the problem gets in "
        "your way. It's your own estimate, and an admin will check it.",
    example: SeverityGuide(),
  ),
];

class SeverityGuide extends StatelessWidget {
  const SeverityGuide({super.key});

  static const _meanings = {
    SeverityEnum.none: "No real impact, just letting you know.",
    SeverityEnum.mild: "A small annoyance, you can keep working.",
    SeverityEnum.medium: "It slows you down.",
    SeverityEnum.danger: "The device barely works.",
    SeverityEnum.extreme: "The device can't be used at all.",
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final entry in _meanings.entries)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 8),
                child: Text(
                  entry.key.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(entry.value, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
      ],
    );
  }
}

const deviceHelpSections = [
  HelpSection(
    icon: Icons.touch_app_outlined,
    title: "Tap a device",
    text:
        "The map shows the devices in the selected location. Tap the one "
        "with the problem, describe what's wrong and press Report. You can "
        "report more than one device.",
  ),
  HelpSection(
    icon: Icons.swap_horiz,
    title: "More than one location",
    text:
        "If you picked several locations, use the arrows under the map to "
        "switch between them.",
  ),
  HelpSection(
    icon: Icons.fullscreen,
    title: "Bigger map",
    text: "Tap the corner button to open the map in full screen.",
  ),
  HelpSection(
    icon: Icons.check_box_outlined,
    title: "No specific device",
    text:
        "If the problem isn't about one device, tick the box under the map "
        "instead.",
  ),
];
