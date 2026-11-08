import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeviceLogTile extends StatelessWidget {
  final DeviceEvidenceLog log;

  const DeviceLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          DateFormat('dd.MM.yyyy HH:mm').format(log.dateLogged),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(child: Text(log.log, style: theme.textTheme.labelSmall)),
      ],
    );
  }
}
