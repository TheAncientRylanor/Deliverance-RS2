import 'package:deliverance_desktop/utils/date_json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation.g.dart';

/// A chatbot conversation, as listed in the user's chat history.
@JsonSerializable()
class Conversation {
  final int id;
  final String? userUUID;
  final String? title;
  @JsonKey(fromJson: nullableDateFromJson, toJson: nullableDateToJson)
  final DateTime? createdAt;

  Conversation({
    required this.id,
    this.userUUID,
    this.title,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
