import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/criteria.dart';
import '../api/models.dart';
import 'listing_details_screen.dart';
import 'login_screen.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _savedKey = GlobalKey<_SavedSearchesTabState>();
  final _notifKey = GlobalKey<_NotificationsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOnSavedTab => _tabController.index == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Søgeagent'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Søgeagenter'),
            Tab(text: 'Notifikationer'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Opdater',
            onPressed: () {
              if (_isOnSavedTab) {
                _savedKey.currentState?.reload();
              } else {
                _notifKey.currentState?.reload();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
          if (!_isOnSavedTab)
            IconButton(
              tooltip: 'Ryd alle',
              onPressed: () => _notifKey.currentState?.clearAll(),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      floatingActionButton: _isOnSavedTab
          ? FloatingActionButton.extended(
              onPressed: () => _savedKey.currentState?.showCreateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ny søgeagent'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _SavedSearchesTab(key: _savedKey, api: widget.api),
          _NotificationsTab(key: _notifKey, api: widget.api),
        ],
      ),
    );
  }
}

class _SavedSearchesTab extends StatefulWidget {
  const _SavedSearchesTab({super.key, required this.api});

  final ApiClient api;

  @override
  State<_SavedSearchesTab> createState() => _SavedSearchesTabState();
}

class _SavedSearchesTabState extends State<_SavedSearchesTab> {
  bool _loading = false;
  String? _error;
  List<SavedSearch> _items = const <SavedSearch>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _items = const <SavedSearch>[];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.fetchSavedSearches();
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    try {
      await widget.api.deleteSavedSearch(id);
      setState(() {
        _items = _items.where((x) => x.id != id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette søgeagent: $e')),
      );
    }
  }

  Future<void> showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final qCtrl = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ny søgeagent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Navn',
                  hintText: 'F.eks. Golf tilbud',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qCtrl,
                decoration: const InputDecoration(
                  labelText: 'Søgetekst (valgfri)',
                  hintText: 'F.eks. VW Golf',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tip: For avancerede filtre, gem fra Søg-fanen (ikonet “Gem søgning”).',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuller'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Gem'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (confirmed != true) return;

      final token = widget.api.token;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log ind for at gemme en søgning.')),
        );
        return;
      }

      final name = nameCtrl.text.trim();
      if (name.isEmpty) return;

      final q = qCtrl.text.trim();
      final criteria = ListingFilterCriteria(q: q.isEmpty ? null : q);

      await widget.api.createSavedSearchFromCriteria(
        name: name,
        criteria: criteria,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke gemme søgning: $e')));
    } finally {
      nameCtrl.dispose();
      qCtrl.dispose();
    }
  }

  Future<void> _ensureLoggedInThenLoad() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );
    if (!mounted) return;
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    if (!loggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log ind for at se dine søgeagenter'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _ensureLoggedInThenLoad,
              child: const Text('Log ind'),
            ),
          ],
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ingen søgeagenter endnu.\nBrug “Gem søgning” i Søg-fanen for at gemme dine filtre.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(item.name),
              subtitle: Text(_formatDate(item.createdAtUtc)),
              trailing: IconButton(
                tooltip: 'Slet søgeagent',
                onPressed: () => _delete(item.id),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab({super.key, required this.api});

  final ApiClient api;

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool _loading = false;
  String? _error;
  List<SearchNotification> _items = const <SearchNotification>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _items = const <SearchNotification>[];
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.fetchNotifications();
      setState(() {
        _items = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    try {
      await widget.api.deleteNotification(id);
      setState(() {
        _items = _items.where((x) => x.id != id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette notifikation: $e')),
      );
    }
  }

  Future<void> clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ryd alle notifikationer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ryd'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok != true) return;

    try {
      await widget.api.clearNotifications();
      if (!mounted) return;
      setState(() {
        _items = const <SearchNotification>[];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke rydde: $e')));
    }
  }

  Future<void> _ensureLoggedInThenLoad() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );
    if (!mounted) return;
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    if (!loggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log ind for at se notifikationer'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _ensureLoggedInThenLoad,
              child: const Text('Log ind'),
            ),
          ],
        ),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ingen notifikationer endnu.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final when = _formatDateTime(item.createdAtUtc);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(item.title.isEmpty ? 'Notifikation' : item.title),
              subtitle: Text(
                [
                  if (item.savedSearchName != null &&
                      item.savedSearchName!.trim().isNotEmpty)
                    item.savedSearchName!,
                  if (item.body.trim().isNotEmpty) item.body.trim(),
                  when,
                ].join('\n'),
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Slet',
                onPressed: () => _delete(item.id),
                icon: const Icon(Icons.delete_outline),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailsScreen(
                      api: widget.api,
                      listingId: item.listingId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p2(d.month)}-${p2(d.day)} ${p2(d.hour)}:${p2(d.minute)}';
  }
}
