import 'package:deliverance_desktop/models/base_search_object.dart';

class ChatBotMessageSearchObject extends BaseSearchObject {
  int? conversationId;
  bool? isFromBot;
  String? content;
  ChatBotMessageSearchObject({
    this.conversationId,
    this.isFromBot,
    this.content,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.sortBy = "CreatedAt",
    super.descending = false,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (conversationId != null) map['ConversationId'] = conversationId;
    if (isFromBot != null) map['IsFromBot'] = isFromBot;
    if (content != null && content!.isNotEmpty) map['Content'] = content;
    return map;
  }
}
