import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'login_screen.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({
    super.key,
    required this.api,
    this.onAuthChanged,
  });

  final ApiClient api;
  final VoidCallback? onAuthChanged;

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

  Future<bool> _ensureLoggedIn() async {
    final token = widget.api.token;
    if (token != null && token.isNotEmpty) return true;

    if (!mounted) return false;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );

    if (ok == true) {
      widget.onAuthChanged?.call();
      return true;
    }
    return false;
  }

  Future<void> _load() async {
    final loggedIn = await _ensureLoggedIn();
    if (!loggedIn) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.fetchSavedSearches();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _create() async {
    final name = await _showNameDialog(
      title: 'Ny gemt søgning',
      confirmLabel: 'Gem',
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      await widget.api.createSavedSearch(name: name.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke oprette søgning: $e')),
      );
    }
  }

  Future<void> _rename(SavedSearch item) async {
    final name = await _showNameDialog(
      title: 'Omdøb søgning',
      initialValue: item.name,
      confirmLabel: 'Gem',
    );
    if (name == null || name.trim().isEmpty) return;
    if (name.trim() == item.name) return;

    try {
      await widget.api.updateSavedSearch(item.id, name: name.trim());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke omdøbe søgning: $e')),
      );
    }
  }

  Future<void> _toggleNotifications(SavedSearch item) async {
    final newValue = !item.notificationsEnabled;
    try {
      await widget.api.updateSavedSearch(
        item.id,
        notificationsEnabled: newValue,
      );
      if (!mounted) return;
      setState(() {
        _items = _items.map((s) {
          if (s.id != item.id) return s;
          return SavedSearch(
            id: s.id,
            name: s.name,
            criteriaJson: s.criteriaJson,
            notificationsEnabled: newValue,
            createdAtUtc: s.createdAtUtc,
            updatedAtUtc: s.updatedAtUtc,
            lastNotifiedAtUtc: s.lastNotifiedAtUtc,
          );
        }).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke ændre notifikationer: $e')),
      );
    }
  }

  Future<void> _delete(SavedSearch item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slet søgning'),
        content: Text('Er du sikker på, at du vil slette "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Slet'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.api.deleteSavedSearch(item.id);
      if (!mounted) return;
      setState(() {
        _items =
            _items.where((s) => s.id != item.id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette søgning: $e')),
      );
    }
  }

  Future<String?> _showNameDialog({
    required String title,
    String? initialValue,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Navn',
            hintText: 'F.eks. BMW under 300.000 kr',
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    if (!loggedIn && !_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gemte søgninger')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Log ind for at se dine gemte søgninger'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Log ind'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemte søgninger'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Opdater',
          ),
        ],
      ),
      floatingActionButton: loggedIn
          ? FloatingActionButton(
              onPressed: _create,
              tooltip: 'Ny gemt søgning',
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Prøv igen'),
                    ),
                  ],
                ),
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.manage_search_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen gemte søgninger endnu',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tryk + for at oprette en ny søgning',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(item.name),
                    subtitle: Row(
                      children: [
                        Icon(
                          item.notificationsEnabled
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_off_outlined,
                          size: 14,
                          color: item.notificationsEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.notificationsEnabled
                              ? 'Notifikationer til'
                              : 'Notifikationer fra',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<_ItemAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _ItemAction.rename:
                            _rename(item);
                          case _ItemAction.toggleNotifications:
                            _toggleNotifications(item);
                          case _ItemAction.delete:
                            _delete(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _ItemAction.rename,
                          child: const ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Omdøb'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _ItemAction.toggleNotifications,
                          child: ListTile(
                            leading: Icon(
                              item.notificationsEnabled
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_active_outlined,
                            ),
                            title: Text(
                              item.notificationsEnabled
                                  ? 'Slå notifikationer fra'
                                  : 'Slå notifikationer til',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _ItemAction.delete,
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Slet',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _ItemAction { rename, toggleNotifications, delete }
