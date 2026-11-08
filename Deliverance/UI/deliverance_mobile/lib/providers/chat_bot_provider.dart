import 'dart:convert';

import 'package:deliverance_mobile/models/chat_bot_message.dart';
import 'package:deliverance_mobile/models/conversation.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ChatBotProvider extends BaseProvider<ChatBotMessage> {
  ChatBotProvider() : super("ChatBot");
  @override
  ChatBotMessage fromJson(data) {
    return ChatBotMessage.fromJson(data);
  }

  Future<ChatBotMessage> sendMessage(ChatBotMessageInsertRequest request) =>
      insert(request);

  Future<List<Conversation>> getConversations() async {
    const pageSize = 50;
    final conversations = <Conversation>[];
    var page = 1;
    while (true) {
      final response = await sendWithRetry(() async {
        var uri = Uri.parse(
          "${BaseProvider.baseUrl}$endpoint/Conversations",
        ).replace(queryParameters: {'page': '$page', 'pageSize': '$pageSize'});
        var headers = createHeaders();
        return await http.get(uri, headers: headers);
      });
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Conversation.fromJson(e))
          .toList();
      conversations.addAll(items);
      final total = data['totalCount'] as int? ?? conversations.length;
      if (items.length < pageSize || conversations.length >= total) break;
      page++;
    }
    return conversations;
  }

  Future<List<ChatBotMessage>> getConversationMessages(
    int conversationId,
    int? beforeId,
    int take,
  ) async {
    final response = await sendWithRetry(() async {
      var uri =
          Uri.parse(
            "${BaseProvider.baseUrl}$endpoint/Conversations/$conversationId/Messages",
          ).replace(
            queryParameters: {
              'take': '$take',
              if (beforeId != null) 'beforeId': '$beforeId',
            },
          );
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });
    var data = jsonDecode(response.body) as List;
    return data.map((e) => ChatBotMessage.fromJson(e)).toList();
  }
}
