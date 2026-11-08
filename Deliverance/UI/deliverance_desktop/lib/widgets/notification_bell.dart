import 'package:deliverance_desktop/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback onPressed;

  const NotificationBell({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unreadCount = context.select<NotificationProvider, int>(
      (provider) => provider.unreadCount,
    );

    return Material(
      color: colors.surfaceContainer,
      shape: const CircleBorder(),
      elevation: 5,
      child: IconButton(
        onPressed: onPressed,
        tooltip: "Notifications",
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(unreadCount > 99 ? "99+" : "$unreadCount"),
          backgroundColor: colors.primary,
          textColor: colors.onPrimary,
          child: Icon(Icons.notifications, color: colors.primary, size: 32),
        ),
      ),
    );
  }
}
