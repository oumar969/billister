import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../api/models.dart';

class SignalRChatService extends ChangeNotifier {
  late HubConnection _hubConnection;
  bool _isConnected = false;
  String? _userId;
  String? _connectionId;
  List<ChatMessage> _messages = [];
  Map<String, dynamic> _threadUsers = {};
  String? _typingUserId;

  // Getters
  bool get isConnected => _isConnected;
  List<ChatMessage> get messages => _messages;
  String? get connectionId => _connectionId;
  bool get isTyping => _typingUserId != null && _typingUserId != _userId;
  String? get typingUserId => _typingUserId;

  /// Initialize SignalR connection
  Future<void> connect({
    required String baseUrl,
    required String userId,
    required String? authToken,
  }) async {
    _userId = userId;

    try {
      final url = baseUrl.endsWith('/')
          ? '${baseUrl}hubs/chat'
          : '$baseUrl/hubs/chat';

      _hubConnection = HubConnectionBuilder()
          .withUrl(url)
          .withAutomaticReconnect()
          .build();

      // Handle incoming messages
      _hubConnection.on('ReceiveMessage', _handleReceiveMessage);
      _hubConnection.on('UserConnected', _handleUserConnected);
      _hubConnection.on('UserDisconnected', _handleUserDisconnected);
      _hubConnection.on('UserTyping', _handleUserTyping);
      _hubConnection.on('UserStoppedTyping', _handleUserStoppedTyping);
      _hubConnection.on('MessageRead', _handleMessageRead);

      // Start connection
      await _hubConnection.start();

      _isConnected = true;
      _connectionId = _hubConnection.connectionId;
      debugPrint('SignalR Connected. ConnectionId: $_connectionId');
      notifyListeners();
    } catch (e) {
      debugPrint('SignalR Connection Error: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect from SignalR
  Future<void> disconnect() async {
    try {
      await _hubConnection.stop();
      _isConnected = false;
      _messages.clear();
      _threadUsers.clear();
      _typingUserId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('SignalR Disconnect Error: $e');
    }
  }

  /// Join a chat thread
  Future<void> joinThread(String threadId) async {
    if (!_isConnected) throw Exception('SignalR not connected');

    try {
      await _hubConnection.invoke('JoinThread', args: [threadId]);
      _messages.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to join thread: $e');
      rethrow;
    }
  }

  /// Leave current chat thread
  Future<void> leaveThread(String threadId) async {
    if (!_isConnected) return;
    try {
      await _hubConnection.invoke('LeaveThread', args: [threadId]);
    } catch (e) {
      debugPrint('Failed to leave thread: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String threadId,
    required String content,
  }) async {
    if (!_isConnected) throw Exception('SignalR not connected');

    try {
      await _hubConnection.invoke('SendMessage', args: [threadId, content]);
      _typingUserId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow;
    }
  }

  /// Notify others that user is typing
  Future<void> startTyping(String threadId) async {
    if (!_isConnected) return;
    try {
      await _hubConnection.invoke('UserIsTyping', args: [threadId]);
    } catch (e) {
      debugPrint('Failed to notify typing: $e');
    }
  }

  /// Notify others that user stopped typing
  Future<void> stopTyping(String threadId) async {
    if (!_isConnected) return;
    try {
      await _hubConnection.invoke('UserStoppedTyping', args: [threadId]);
    } catch (e) {
      debugPrint('Failed to notify stop typing: $e');
    }
  }

  /// Send read receipt for a message
  Future<void> markMessageAsRead({
    required String messageId,
    required String threadId,
  }) async {
    if (!_isConnected) return;
    try {
      await _hubConnection.invoke(
        'MarkMessageAsRead',
        args: [messageId, threadId],
      );
    } catch (e) {
      debugPrint('Failed to mark message as read: $e');
    }
  }

  // ============= SignalR Event Handlers =============

  void _handleReceiveMessage(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;

    try {
      final data = parameters[0] as Map<String, dynamic>;
      final message = ChatMessage.fromJson(data);
      _messages.add(message);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing received message: $e');
    }
  }

  void _handleUserConnected(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final userId = parameters[0] as String?;
      if (userId != null) {
        _threadUsers[userId] = {'status': 'connected'};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling user connected: $e');
    }
  }

  void _handleUserDisconnected(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final userId = parameters[0] as String?;
      if (userId != null) {
        _threadUsers.remove(userId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling user disconnected: $e');
    }
  }

  void _handleUserTyping(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final userId = parameters[0] as String?;
      if (userId != null && userId != _userId) {
        _typingUserId = userId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling user typing: $e');
    }
  }

  void _handleUserStoppedTyping(List<dynamic>? parameters) {
    if (parameters == null || parameters.isEmpty) return;
    try {
      final userId = parameters[0] as String?;
      if (userId != null && _typingUserId == userId) {
        _typingUserId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling user stopped typing: $e');
    }
  }

  void _handleMessageRead(List<dynamic>? parameters) {
    try {
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling message read: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
