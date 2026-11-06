import 'dart:convert';

import 'package:deliverance_desktop/models/chat_bot_message.dart';
import 'package:deliverance_desktop/models/conversation.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class ChatBotProvider extends BaseProvider<ChatBotMessage> {
  ChatBotProvider() : super("ChatBot");
  @override
  ChatBotMessage fromJson(data) {
    return ChatBotMessage.fromJson(data);
  }

  /// Sends the user's message and returns the bot's reply. The reply's
  /// conversationId is the new conversation when [request] had none.
  Future<ChatBotMessage> sendMessage(ChatBotMessageInsertRequest request) =>
      insert(request);

  Future<List<Conversation>> getConversations() async {
    final response = await sendWithRetry(() async {
      var uri = Uri.parse("${BaseProvider.baseUrl}$endpoint/Conversations");
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });
    var data = jsonDecode(response.body) as List;
    return data.map((e) => Conversation.fromJson(e)).toList();
  }

  /// Returns up to [take] messages of the conversation, newest first.
  /// With [beforeId], returns the messages older than that one.
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
