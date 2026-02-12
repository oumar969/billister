import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'listing_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = false;
  String? _error;
  List<FavoriteListing> _items = const <FavoriteListing>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.fetchFavorites();
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

  Future<void> _remove(String listingId) async {
    try {
      await widget.api.removeFavorite(listingId);
      setState(() {
        _items = _items.where((x) => x.id != listingId).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke fjerne favorit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;

    if (token == null || token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoritter')),
        body: const Center(child: Text('Login for at se favoritter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritter'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
          ? const Center(child: Text('Ingen favoritter endnu'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(
                          Icons.directions_car,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(_subtitle(item)),
                    trailing: IconButton(
                      tooltip: 'Fjern favorit',
                      onPressed: () => _remove(item.id),
                      icon: Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailsScreen(
                            api: widget.api,
                            listingId: item.id,
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

  static String _subtitle(FavoriteListing item) {
    final parts = <String>[];
    if (item.year != null) parts.add(item.year.toString());
    if (item.mileageKm != null) parts.add('${item.mileageKm} km');
    return parts.join(' · ');
  }
}
