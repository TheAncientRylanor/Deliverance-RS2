import 'package:deliverance_mobile/models/chat_bot_message.dart';
import 'package:deliverance_mobile/models/conversation.dart';
import 'package:deliverance_mobile/providers/chat_bot_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  late ChatBotProvider _chatBotProvider;
  final List<ChatBotMessage> _chatBotList = [];
  final TextEditingController _chatBotMessageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Conversation> _chatBotConversationList = <Conversation>[];
  int? _conversationId;
  bool _isSending = false;
  bool _showConversations = false;
  static const _pageSize = 10;
  bool _isLoadingMore = false;
  // Only true for a conversation opened from the history. A new conversation
  // has nothing older on the server, and its messages added here have id 0,
  // which can't be used as beforeId.
  bool _hasMore = false;

  // The first page of an opened conversation is loading. Sending now would
  // mix the new message into the page that is about to arrive.
  bool get _isOpeningConversation => _isLoadingMore && _chatBotList.isEmpty;

  @override
  void initState() {
    super.initState();
    _chatBotProvider = context.read<ChatBotProvider>();
    _scrollController.addListener(_loadMoreIfNeeded);
    _loadConversations();
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Near the top of the chat (the end of the reversed list), or the
    // messages don't fill the screen yet, so there's nothing to scroll.
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadOlderMessages();
    }
  }

  /// Loads the page of messages older than the oldest one shown, or the
  /// latest page when the list is empty. [_chatBotList] is newest first.
  Future<void> _loadOlderMessages() async {
    if (_isLoadingMore || !_hasMore || _conversationId == null) return;
    final conversationId = _conversationId!;
    setState(() => _isLoadingMore = true);
    try {
      final older = await _chatBotProvider.getConversationMessages(
        conversationId,
        _chatBotList.isEmpty ? null : _chatBotList.last.id,
        _pageSize,
      );
      if (!mounted) return;
      // Skip the page if the user opened another conversation meanwhile.
      if (conversationId == _conversationId) {
        setState(() {
          _chatBotList.addAll(older);
          _hasMore = older.length == _pageSize;
        });
      }
    } on ApiClientException catch (e) {
      if (!mounted) return;
      if (conversationId == _conversationId) {
        alertBox(context, "Error", e.message, mode: AlertBoxMode.ok);
        // The user retries by scrolling, instead of failing again in a loop.
        return;
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
    // The new messages are laid out after the next frame. If they still don't
    // fill the screen, or another conversation was opened, load the next page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreIfNeeded();
    });
  }

  @override
  void dispose() {
    _chatBotMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // The list is reversed, so offset 0 is the newest message.
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleConversations() {
    setState(() {
      _showConversations = !_showConversations;
    });
    // Reload every time, so a conversation started since then shows up.
    if (_showConversations) _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      var list = await _chatBotProvider.getConversations();
      if (!mounted) return;
      setState(() {
        _chatBotConversationList
          ..clear()
          ..addAll(list);
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Error", e.message, mode: AlertBoxMode.ok);
    }
  }

  void _openConversation(Conversation conversation) {
    if (_isSending) return;
    if (conversation.id == _conversationId) {
      setState(() => _showConversations = false);
      return;
    }
    setState(() {
      _showConversations = false;
      _conversationId = conversation.id;
      _chatBotList.clear();
      _hasMore = true;
    });
    _loadOlderMessages();
  }

  void _newConversation() {
    if (_isSending) return;
    setState(() {
      _chatBotList.clear();
      _conversationId = null;
      _hasMore = false;
    });
  }

  Future<void> _send() async {
    final text = _chatBotMessageController.text.trim();
    if (text.isEmpty || _isSending || _isOpeningConversation) return;

    final userMessage = ChatBotMessage(
      id: 0,
      conversationId: _conversationId ?? 0,
      isFromBot: false,
      content: text,
    );
    final typingMessage = ChatBotMessage(
      id: 0,
      conversationId: _conversationId ?? 0,
      isFromBot: true,
      content: "Typing...",
    );
    // The list is newest first, so new messages go to the front.
    setState(() {
      _isSending = true;
      _chatBotList.insert(0, userMessage);
      _chatBotList.insert(0, typingMessage);
    });
    _chatBotMessageController.clear();
    _scrollToBottom();

    try {
      final reply = await _chatBotProvider.sendMessage(
        ChatBotMessageInsertRequest(
          content: text,
          conversationId: _conversationId,
        ),
      );
      if (!mounted) return;
      setState(() {
        _conversationId ??= reply.conversationId;
        _chatBotList.remove(typingMessage);
        _chatBotList.insert(0, reply);
      });
      _scrollToBottom();
    } on ApiClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _chatBotList.remove(typingMessage);
        _chatBotList.remove(userMessage);
      });
      _chatBotMessageController.text = text;
      alertBox(context, "Error", e.message, mode: AlertBoxMode.ok);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        automaticallyImplyActions: false,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _toggleConversations,
                  icon: Icon(
                    Icons.timelapse,
                    color: Theme.of(context).primaryColor,
                    size: 40,
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _newConversation,
                  icon: Icon(
                    Icons.add_comment_sharp,
                    color: Theme.of(context).primaryColor,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _chatBotList.length + (_isLoadingMore ? 1 : 0),
                  reverse: true,
                  separatorBuilder: (_, _) => const SizedBox(height: 30),
                  itemBuilder: (context, index) {
                    // The extra item past the last message, shown at the top.
                    if (index == _chatBotList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final chat = _chatBotList[index];
                    final isFromBot = chat.isFromBot == true;
                    return ChatCard(
                      alignment: isFromBot
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      content: chat.content ?? "",
                      chatColor: isFromBot
                          ? Theme.of(context).colorScheme.surfaceContainer
                          : Theme.of(context).colorScheme.primary,
                      textColor: isFromBot
                          ? Colors.white
                          : Theme.of(context).colorScheme.secondary,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 100,
                  left: 20,
                  right: 20,
                ),
                child: CustomTextField(
                  controller: _chatBotMessageController,
                  maxLines: 5,
                  suffixIcon: IconButton(
                    onPressed: _isSending || _isOpeningConversation
                        ? null
                        : _send,
                    icon: Icon(
                      Icons.arrow_circle_right,
                      size: 40,
                      color: _isSending || _isOpeningConversation
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          _showConversations
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: BoxBorder.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _chatBotConversationList.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      itemBuilder: (context, index) {
                        final conversation = _chatBotConversationList[index];
                        return InkWell(
                          // A reply still on its way would end up in the
                          // wrong conversation.
                          onTap: _isSending
                              ? null
                              : () => _openConversation(conversation),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                // Expanded gives the text a width, so the
                                // ellipsis works instead of overflowing.
                                Expanded(
                                  child: Text(
                                    conversation.title ?? "Untitled",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final MainAxisAlignment alignment;
  final String content;
  final Color chatColor;
  final Color? textColor;
  const ChatCard({
    super.key,
    required this.alignment,
    required this.content,
    required this.chatColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: chatColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor ?? Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
