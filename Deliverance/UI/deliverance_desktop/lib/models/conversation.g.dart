part of 'conversation.dart';

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as int,
  userUUID: json['userUUID'] as String?,
  title: json['title'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);
