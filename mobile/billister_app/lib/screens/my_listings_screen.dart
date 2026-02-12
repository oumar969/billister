import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'listing_details_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  ListingsPage? _page;
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
        _page = const ListingsPage(total: 0, page: 1, pageSize: 20, items: []);
        _error = 'Du skal være logget ind for at se dine annoncer.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await widget.api.fetchMyListings(page: 1, pageSize: 50);
      setState(() {
        _page = page;
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

  @override
  Widget build(BuildContext context) {
    final items = _page?.items ?? const <ListingSummary>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Mine annoncer')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Du har ingen annoncer endnu.'),
              )
            else
              ...items.map((x) => _listingTile(context, x)),
          ],
        ),
      ),
    );
  }

  Widget _listingTile(BuildContext context, ListingSummary item) {
    final title = [
      item.make,
      item.model,
      if (item.variant != null) item.variant,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');

    final subtitleParts = <String>[];
    if (item.year != null) subtitleParts.add(item.year.toString());
    if (item.mileageKm != null) subtitleParts.add('${item.mileageKm} km');
    if (item.city != null && item.city!.trim().isNotEmpty) {
      subtitleParts.add(item.city!);
    }

    final imgUrl = (item.images.isNotEmpty) ? item.images.first.url : null;

    return Card(
      child: ListTile(
        leading: _thumb(imgUrl),
        title: Text(title),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: Text('${item.priceDkk.toStringAsFixed(0)} kr'),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ListingDetailsScreen(api: widget.api, listingId: item.id),
            ),
          );
        },
      ),
    );
  }

  Widget _thumb(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Icon(Icons.directions_car_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}
