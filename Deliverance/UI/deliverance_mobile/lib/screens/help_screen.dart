import 'package:deliverance_mobile/widgets/help_button.dart';
import 'package:deliverance_mobile/widgets/report_help_content.dart';
import 'package:flutter/material.dart';

const _reportTips = [
  HelpSection(
    icon: Icons.self_improvement,
    title: "Stay calm",
    text:
        "Most problems can be fixed. Take a breath and write down what you "
        "see. A calm, clear report gets fixed faster than an urgent one.",
  ),
  HelpSection(
    icon: Icons.title,
    title: "A short, clear title",
    text:
        "Say what is wrong in a few words, for example \"Printer won't "
        "print\" instead of \"HELP!!!\".",
  ),
  HelpSection(
    icon: Icons.notes,
    title: "Describe what happened",
    text:
        "What were you doing, what did you expect and what happened "
        "instead? Mention when it started and whether it keeps happening.",
  ),
  HelpSection(
    icon: Icons.error_outline,
    title: "Copy error messages",
    text:
        "If an error appears, write it down exactly as it is shown. Even a "
        "short code helps the admin find the cause.",
  ),
  HelpSection(
    icon: Icons.filter_1,
    title: "One problem per report",
    text:
        "If two things are broken, send two reports. That way each one can "
        "be fixed and closed on its own.",
  ),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Text(
            "How to write a good report",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            "A clear report helps the admin understand and fix your problem "
            "quickly.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          for (final section in _reportTips) HelpSectionView(section),
          const _HelpHeading("Severity"),
          for (final section in severityHelpSections) HelpSectionView(section),
          const _HelpHeading("Selecting a device"),
          for (final section in deviceHelpSections) HelpSectionView(section),
        ],
      ),
    );
  }
}

class _HelpHeading extends StatelessWidget {
  final String title;

  const _HelpHeading(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        const SizedBox(height: 10),
        Divider(color: theme.colorScheme.primary),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
