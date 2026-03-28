import 'package:cached_network_image/cached_network_image.dart';
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
  List<ListingSummary> _items = <ListingSummary>[];
  int _totalItems = 0;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _items = const <ListingSummary>[];
        _totalItems = 0;
        _currentPage = 1;
        _hasMore = false;
        _error = 'Du skal være logget ind for at se dine annoncer.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _items = <ListingSummary>[];
      _totalItems = 0;
      _currentPage = 1;
      _hasMore = false;
    });

    try {
      final page = await widget.api.fetchMyListings(page: 1, pageSize: 20);
      setState(() {
        _items = page.items;
        _totalItems = page.total;
        _currentPage = 1;
        _hasMore = page.items.length < page.total;
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;

    setState(() {
      _loadingMore = true;
    });

    final nextPage = _currentPage + 1;

    try {
      final page = await widget.api.fetchMyListings(
        page: nextPage,
        pageSize: 20,
      );
      setState(() {
        _items = <ListingSummary>[..._items, ...page.items];
        _currentPage = nextPage;
        _hasMore = _items.length < _totalItems;
      });
    } catch (_) {
      // Silently ignore load-more errors.
    } finally {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mine annoncer')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            _loadMore();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            controller: _scrollCtrl,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Du har ingen annoncer endnu.'),
                )
              else ...[
                ..._items.map((x) => _listingTile(context, x)),
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (!_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Alle $_totalItems annoncer vist',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ],
          ),
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
    final placeholder = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Icon(Icons.directions_car_outlined),
    );

    if (url == null || url.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
