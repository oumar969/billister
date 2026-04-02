import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import '../services/signalr_chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final ApiClient api;
  final String threadId;
  final String buyerId;
  final String sellerId;

  const ChatRoomScreen({
    Key? key,
    required this.api,
    required this.threadId,
    required this.buyerId,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  late ScrollController _scrollController;
  late SignalRChatService _signalRService;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeSignalR();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Don't dispose _signalRService here, it's managed by Provider
    super.dispose();
  }

  Future<void> _initializeSignalR() async {
    try {
      _signalRService = context.read<SignalRChatService>();

      // Load initial messages
      await _loadMessages();

      // Join the chat thread
      await _signalRService.joinThread(widget.threadId);

      // Listen to real-time updates
      _signalRService.addListener(_onSignalRUpdate);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fejl ved verbindelse: $e';
          _loading = false;
        });
      }
    }
  }

  void _onSignalRUpdate() {
    if (!mounted) return;

    setState(() {
      _messages = _signalRService.messages;
    });

    // Auto-scroll to bottom when new message arrives
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await widget.api.getMessages(
        threadId: widget.threadId,
        page: 1,
        pageSize: 50,
      );

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _loading = false;
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

      // Mark all as read
      await widget.api.markThreadAsRead(threadId: widget.threadId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    _messageController.clear();
    _typingTimer?.cancel();

    try {
      // Send via SignalR for real-time delivery
      await _signalRService.sendMessage(
        threadId: widget.threadId,
        content: content,
      );

      setState(() => _sending = false);
    } catch (e) {
      setState(() => _sending = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fejl: $e')));
      }
    }
  }

  void _handleTyping() {
    // Cancel previous timer
    _typingTimer?.cancel();

    if (!_isTyping && _messageController.text.isNotEmpty) {
      _isTyping = true;
      _signalRService.startTyping(widget.threadId);
    }

    // Set timer to stop typing after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping && _messageController.text.isEmpty) {
        _isTyping = false;
        _signalRService.stopTyping(widget.threadId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Leave thread when navigating back
        await _signalRService.leaveThread(widget.threadId);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _loadMessages,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_signalRService.isTyping &&
                _signalRService.typingUserId != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  'Skriver...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Fejl: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Ingen beskeder endnu'),
            SizedBox(height: 8),
            Text(
              'Start en samtale!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isOwn = message.senderId == widget.api.currentUser?.id;

        return _buildMessageBubble(message, isOwn);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOwn) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            CircleAvatar(
              radius: 16,
              child: Text(message.senderUsername[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isOwn
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isOwn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderUsername,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isOwn ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      if (isOwn && (message.readByUserIds?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '✓ læst',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.createdAtUtc),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Skriv en besked...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () {},
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              enabled: !_sending,
              onChanged: (_) => _handleTyping(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _sending ? null : _sendMessage,
            tooltip: 'Send',
            child: _sending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'lige nu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}t';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
