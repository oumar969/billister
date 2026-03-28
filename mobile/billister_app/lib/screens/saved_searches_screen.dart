import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'login_screen.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  bool _loading = false;
  String? _error;
  List<SavedSearch> _items = const <SavedSearch>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) return;

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

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gem søgning'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Navn på søgeagent',
            hintText: 'F.eks. VW Golf under 200.000 kr',
          ),
          textCapitalization: TextCapitalization.sentences,
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

    if (confirmed != true || !mounted) return;

    final name = controller.text.trim();
    if (name.isEmpty) return;

    // TODO: accept ListingFilterCriteria from the search screen so that
    // saved searches capture real filter criteria rather than an empty object.
    try {
      await widget.api.createSavedSearch(name: name, criteriaJson: '{}');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke gemme søgning: $e')),
      );
    }
  }

  Future<void> _ensureLoggedInThenLoad() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Søgeagenter')),
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Søgeagenter'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ny søgeagent'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ingen søgeagenter endnu.\nTryk + for at gemme en søgning og få besked om nye biler.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
