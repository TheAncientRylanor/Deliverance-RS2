import 'package:deliverance_desktop/models/app_notification.dart';
import 'package:deliverance_desktop/models/notification_type_enum.dart';
import 'package:deliverance_desktop/providers/notification_provider.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Shows the latest notifications under the bell. Returns the one the admin
/// clicked, so the caller can open what it points to.
Future<AppNotification?> showNotificationPanel(BuildContext context) {
  context.read<NotificationProvider>().load();
  return showDialog<AppNotification>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => const NotificationPanel(),
  );
}

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      await context.read<NotificationProvider>().markAllAsRead();
    } catch (_) {
      if (context.mounted) _showUpdateError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();

    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.primary),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Notifications",
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (provider.unreadCount > 0)
                    TextButton(
                      onPressed: () => _markAllAsRead(context),
                      child: const Text("Mark all as read"),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.primary),
            Flexible(child: _buildBody(theme, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, NotificationProvider provider) {
    if (provider.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          provider.hasLoadError
              ? "We couldn't load your notifications right now."
              : "No notifications yet.",
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: provider.items.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: theme.colorScheme.surfaceContainer),
      itemBuilder: (_, index) =>
          _NotificationTile(notification: provider.items[index]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon => switch (notification.type) {
    NotificationTypeEnum.reportSent => Icons.description,
    NotificationTypeEnum.reportSeen => Icons.visibility,
    NotificationTypeEnum.reportCleared => Icons.check_circle,
    NotificationTypeEnum.userRegistered => Icons.person_add,
  };

  Future<void> _markAsRead(BuildContext context) async {
    try {
      await context.read<NotificationProvider>().markAsRead(notification.id);
    } catch (_) {
      if (context.mounted) _showUpdateError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = notification.isRead;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt);

    return Material(
      color: isRead ? Colors.transparent : theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => Navigator.pop(context, notification),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Icon(_icon, color: theme.colorScheme.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.bold,
                      ),
                    ),
                    Text(notification.text, style: theme.textTheme.labelSmall),
                    Text(
                      "$date · ${isRead ? "Read" : "Unread"}",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                IconButton(
                  onPressed: () => _markAsRead(context),
                  tooltip: "Mark as read",
                  icon: Icon(Icons.done, color: theme.colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showUpdateError(BuildContext context) {
  alertBox(
    context,
    "Couldn't update",
    "We couldn't update your notifications right now. Please try again in a moment.",
  );
}
