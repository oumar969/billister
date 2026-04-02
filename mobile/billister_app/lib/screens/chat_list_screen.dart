import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final ApiClient api;

  const ChatListScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<dynamic> _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  void _loadInquiries() {
    _inquiriesFuture = _fetchSellerInquiries();
  }

  Future<dynamic> _fetchSellerInquiries() async {
    try {
      final response = await widget.api.fetchSellerInquiries();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beskeder'), elevation: 0),
      body: FutureBuilder<dynamic>(
        future: _inquiriesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Fejl: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadInquiries()),
                    child: const Text('Prøv igen'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null || data is! Map) {
            return const Center(child: Text('Ingen data tilgængelig'));
          }

          final items = data['items'] as List<dynamic>? ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Ingen beskeder endnu'),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final listingId = item['listingId'] as String? ?? '';
              final threadCount = (item['threadCount'] as num?)?.toInt() ?? 0;
              final lastInquiryAtUtc =
                  item['lastInquiryAtUtc'] as String? ?? '';

              return ListTile(
                title: Text('Annonce: $listingId'),
                subtitle: Text(
                  '$threadCount samtaler • ${_formatDate(lastInquiryAtUtc)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to chat threads for this listing
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatListingThreadsScreen(
                        api: widget.api,
                        listingId: listingId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class ChatListingThreadsScreen extends StatefulWidget {
  final ApiClient api;
  final String listingId;

  const ChatListingThreadsScreen({
    Key? key,
    required this.api,
    required this.listingId,
  }) : super(key: key);

  @override
  State<ChatListingThreadsScreen> createState() =>
      _ChatListingThreadsScreenState();
}

class _ChatListingThreadsScreenState extends State<ChatListingThreadsScreen> {
  List<ChatThread> _threads = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch seller inquiries and filter by listing ID
      await widget.api.fetchSellerInquiries();

      // In a real app, you'd fetch the actual ChatThread objects
      // For now, we'll just show a simplified view
      setState(() {
        _threads = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - Annonce ${widget.listingId.substring(0, 8)}'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadThreads,
              child: const Text('Prøv igen'),
            ),
          ],
        ),
      );
    }

    if (_threads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Ingen samtaler'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index];
        return ListTile(
          title: Text('Køber: ${thread.buyerId.substring(0, 8)}'),
          subtitle: Text('Oprettet: ${_formatDate(thread.createdAtUtc)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(
                  api: widget.api,
                  threadId: thread.id,
                  buyerId: thread.buyerId,
                  sellerId: thread.sellerId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
