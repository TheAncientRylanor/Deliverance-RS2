part of 'chat_bot_message.dart';

ChatBotMessage _$ChatBotMessageFromJson(Map<String, dynamic> json) =>
    ChatBotMessage(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      userUUID: json['userUUID'] as String?,
      isFromBot: json['isFromBot'] as bool?,
      content: json['content'] as String?,
      createdAt: nullableDateFromJson(json['createdAt'] as String?),
    );

Map<String, dynamic> _$ChatBotMessageInsertRequestToJson(
  ChatBotMessageInsertRequest instance,
) => <String, dynamic>{
  'conversationId': instance.conversationId,
  'content': instance.content,
};

Map<String, dynamic> _$ChatBotMessageUpdateRequestToJson(
  ChatBotMessageUpdateRequest instance,
) => <String, dynamic>{'content': instance.content};
