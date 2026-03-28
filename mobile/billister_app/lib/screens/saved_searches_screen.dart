import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/criteria.dart';
import '../api/models.dart';
import 'listings_screen.dart';
import 'login_screen.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  List<SavedSearch> _items = const <SavedSearch>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  void _openSearch(SavedSearch saved) {
    final criteria = _parseCriteria(saved.criteriaJson);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingsScreen(
          api: widget.api,
          title: saved.name,
          showFilters: true,
          initialCriteria: criteria,
        ),
      ),
    );
  }

  ListingFilterCriteria? _parseCriteria(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;

      List<String>? strList(String key) {
        final v = map[key];
        if (v is List) return v.map((e) => e.toString()).toList();
        return null;
      }

      num? numVal(String key) {
        final v = map[key];
        if (v is num) return v;
        if (v is String) return num.tryParse(v);
        return null;
      }

      int? intVal(String key) => numVal(key)?.toInt();

      return ListingFilterCriteria(
        q: map['q'] as String?,
        makes: strList('makes'),
        models: strList('models'),
        fuelTypes: strList('fuelTypes'),
        transmissions: strList('transmissions'),
        yearMin: intVal('yearMin'),
        yearMax: intVal('yearMax'),
        mileageMin: intVal('mileageMin'),
        mileageMax: intVal('mileageMax'),
        priceMin: numVal('priceMin'),
        priceMax: numVal('priceMax'),
        requiredFeatures: strList('requiredFeatures'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gem søgeagent'),
        content: TextField(
          controller: nameCtrl,
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

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.api.createSavedSearch(
        name: name,
        criteria: const ListingFilterCriteria(),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke gemme søgeagent: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Søgeagenter'),
        actions: [
          if (loggedIn)
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: !loggedIn
          ? _buildNotLoggedIn()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _items.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
      floatingActionButton: loggedIn
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ny søgeagent'),
            )
          : null,
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Log ind for at gemme dine søgeagenter og modtage notifikationer om nye biler.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(api: widget.api),
                  ),
                );
                if (ok == true) _load();
              },
              child: const Text('Log ind'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
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
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Ingen søgeagenter endnu.\nTryk + for at gemme en søgning og få besked om nye biler.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
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
              subtitle: item.lastNotifiedAtUtc != null
                  ? Text(
                      'Seneste match: ${_formatDate(item.lastNotifiedAtUtc!)}',
                    )
                  : Text('Oprettet ${_formatDate(item.createdAtUtc)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Slet søgeagent',
                onPressed: () => _confirmDelete(item),
              ),
              onTap: () => _openSearch(item),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(SavedSearch item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Slet søgeagent'),
        content: Text('Er du sikker på, at du vil slette "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Slet'),
          ),
        ],
      ),
    );

    if (ok == true) _delete(item.id);
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
