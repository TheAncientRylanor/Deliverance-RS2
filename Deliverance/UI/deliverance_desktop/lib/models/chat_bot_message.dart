import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_bot_message.g.dart';

@JsonSerializable()
class ChatBotMessage {
  final int id;
  final int conversationId;
  final String? userUUID;
  final bool? isFromBot;
  final String? content;
  @JsonKey(fromJson: nullableDateFromJson, toJson: nullableDateToJson)
  final DateTime? createdAt;

  ChatBotMessage({
    required this.id,
    required this.conversationId,
    this.userUUID,
    this.isFromBot,
    this.content,
    this.createdAt,
  });

  factory ChatBotMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatBotMessageFromJson(json);
}

@JsonSerializable()
class ChatBotMessageInsertRequest {
  final int? conversationId;
  final String content;

  ChatBotMessageInsertRequest({this.conversationId, required this.content});

  Map<String, dynamic> toJson() => _$ChatBotMessageInsertRequestToJson(this);
}

@JsonSerializable()
class ChatBotMessageUpdateRequest {
  final String content;

  ChatBotMessageUpdateRequest({required this.content});

  Map<String, dynamic> toJson() => _$ChatBotMessageUpdateRequestToJson(this);
}
