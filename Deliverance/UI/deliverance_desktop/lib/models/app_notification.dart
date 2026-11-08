import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:deliverance_desktop/models/notification_type_enum.dart';

/// Named AppNotification because Flutter already has a Notification class.
class AppNotification {
  final int id;
  final NotificationTypeEnum type;
  final String title;
  final String text;
  bool isRead;
  final DateTime createdAt;
  final int? reportId;

  /// The user the notification is about, such as a new registration.
  final String? relatedUserUUID;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.reportId,
    this.relatedUserUUID,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: NotificationTypeEnum.fromValue(json['type'] as int),
        title: json['title'] as String,
        text: json['text'] as String,
        isRead: json['isRead'] as bool,
        createdAt: dateFromJson(json['createdAt'] as String),
        reportId: json['reportId'] as int?,
        relatedUserUUID: json['relatedUserUUID'] as String?,
      );
}
