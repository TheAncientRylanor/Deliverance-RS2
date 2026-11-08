import 'package:deliverance_desktop/models/chat_bot_message.dart';
import 'package:deliverance_desktop/models/conversation.dart';
import 'package:deliverance_desktop/providers/chat_bot_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/form_validators.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBotButton extends StatefulWidget {
  const ChatBotButton({super.key});

  @override
  State<ChatBotButton> createState() => _ChatBotButtonState();
}

class _ChatBotButtonState extends State<ChatBotButton> {
  late ChatBotProvider _chatBotProvider;
  final List<ChatBotMessage> _chatBotList = [];
  final TextEditingController _chatBotMessageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Conversation> _chatBotConversationList = <Conversation>[];
  int? _conversationId;
  bool _isOpen = false;
  bool _isSending = false;
  bool _showConversations = false;
  static const _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  bool get _isOpeningConversation => _isLoadingMore && _chatBotList.isEmpty;

  bool get _canSend => !_isSending && !_isOpeningConversation;

  @override
  void initState() {
    super.initState();
    _chatBotProvider = context.read<ChatBotProvider>();
    _scrollController.addListener(_loadMoreIfNeeded);
  }

  @override
  void dispose() {
    _chatBotMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMoreIfNeeded();
      });
    }
  }

  void _loadMoreIfNeeded() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadOlderMessages();
    }
  }

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
        return;
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMoreIfNeeded();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
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
      _showConversations = false;
    });
  }

  Future<void> _send() async {
    final text = _chatBotMessageController.text.trim();
    if (text.isEmpty || !_canSend) return;

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
    final windowSize = MediaQuery.sizeOf(context);
    final panelSize = Size(windowSize.width / 2, windowSize.height / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          SizedBox.fromSize(size: panelSize, child: _buildPanel(panelSize)),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: null,
          tooltip: _isOpen ? "Minimize chat" : "Chat with the assistant",
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: _toggleOpen,
          child: const Icon(Icons.message),
        ),
      ],
    );
  }

  Widget _buildPanel(Size panelSize) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.primary),
      ),
      child: Column(
        children: [
          Container(
            color: colorScheme.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: "Conversations",
                  onPressed: _toggleConversations,
                  icon: Icon(
                    Icons.timelapse,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
                IconButton(
                  tooltip: "New chat",
                  onPressed: _isSending ? null : _newConversation,
                  icon: Icon(
                    Icons.add_comment_sharp,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.primary),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: _buildMessageList(panelSize)),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomTextField(
                        controller: _chatBotMessageController,
                        hintText: "Describe your problem...",
                        maxLines: 5,
                        maxLength: FieldLimits.chatMessageMax,
                        onSubmited: (_) => _send(),
                        suffixIcon: IconButton(
                          onPressed: _canSend ? _send : null,
                          icon: Icon(
                            Icons.arrow_circle_right,
                            size: 32,
                            color: _canSend ? colorScheme.primary : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showConversations)
                  Positioned(
                    top: 0,
                    left: 10,
                    bottom: 10,
                    width: 300,
                    child: _buildConversationList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(Size panelSize) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _chatBotList.length + (_isLoadingMore ? 1 : 0),
      reverse: true,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _chatBotList.length) {
          return const Padding(
            padding: EdgeInsets.all(10),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final chat = _chatBotList[index];
        final isFromBot = chat.isFromBot == true;
        return _ChatCard(
          alignment: isFromBot ? MainAxisAlignment.start : MainAxisAlignment.end,
          content: chat.content ?? "",
          maxWidth: panelSize.width * 0.75,
          chatColor: isFromBot
              ? colorScheme.surfaceContainer
              : colorScheme.primary,
          textColor: isFromBot ? colorScheme.onSurface : colorScheme.onPrimary,
        );
      },
    );
  }

  Widget _buildConversationList() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _chatBotConversationList.isEmpty
          ? Center(
              child: Text(
                "No conversations yet",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _chatBotConversationList.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colorScheme.primary),
              itemBuilder: (context, index) {
                final conversation = _chatBotConversationList[index];
                return InkWell(
                  onTap: _isSending
                      ? null
                      : () => _openConversation(conversation),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      conversation.title ?? "Untitled",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final MainAxisAlignment alignment;
  final String content;
  final double maxWidth;
  final Color chatColor;
  final Color textColor;
  const _ChatCard({
    required this.alignment,
    required this.content,
    required this.maxWidth,
    required this.chatColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: chatColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        ),
      ],
    );
  }
}
