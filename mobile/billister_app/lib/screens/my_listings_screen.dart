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
  Map<String, SellerInquirySummary> _inquiriesByListingId = const {};

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

      // Fetch inquiry counts in parallel-ish (best effort).
      Map<String, SellerInquirySummary> inquiries = const {};
      try {
        final list = await widget.api.fetchSellerInquiries();
        inquiries = {
          for (final x in list)
            if (x.listingId.isNotEmpty) x.listingId: x,
        };
      } catch (_) {
        inquiries = const {};
      }

      setState(() {
        _page = page;
        _inquiriesByListingId = inquiries;
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

    final inquiry = _inquiriesByListingId[item.id];
    final inquiryCount = inquiry?.threadCount ?? 0;

    String fmtDate(DateTime? dt) {
      if (dt == null) return '';
      final d = dt.toLocal();
      String p2(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${p2(d.month)}-${p2(d.day)}';
    }

    final updated = item.updatedAtUtc ?? item.createdAtUtc;
    final updatedText = fmtDate(updated);
    final lastInquiryText = fmtDate(inquiry?.lastInquiryAtUtc);

    return Card(
      child: ListTile(
        leading: _thumb(imgUrl),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitleParts.isNotEmpty) Text(subtitleParts.join(' · ')),
            if (item.isSold) const Text('Status: Solgt'),
            Text(
              'Visninger: ${item.viewCount} · Favoritter: ${item.favoriteCount}',
            ),
            Text(
              'Henvendelser: $inquiryCount'
              '${lastInquiryText.isEmpty ? '' : ' · Senest: $lastInquiryText'}',
            ),
            if (updatedText.isNotEmpty) Text('Sidst opdateret: $updatedText'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item.priceDkk.toStringAsFixed(0)} kr'),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  _editListing(item);
                } else if (v == 'sold') {
                  _markSold(item);
                } else if (v == 'delete') {
                  _deleteListing(item);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Rediger')),
                if (!item.isSold)
                  const PopupMenuItem(
                    value: 'sold',
                    child: Text('Markér som solgt'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('Slet')),
              ],
            ),
          ],
        ),
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

  Future<void> _editListing(ListingSummary item) async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) return;

    ListingDetails details;
    try {
      details = await widget.api.fetchListingDetails(item.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke hente annonce: $e')));
      return;
    }

    if (!mounted) return;

    final priceCtrl = TextEditingController(
      text: details.priceDkk.toStringAsFixed(0),
    );
    final mileageCtrl = TextEditingController(
      text: details.mileageKm?.toString() ?? '',
    );
    final titleCtrl = TextEditingController(text: details.title ?? '');
    final descCtrl = TextEditingController(text: details.description ?? '');

    Future<void> disposeCtrls() async {
      priceCtrl.dispose();
      mileageCtrl.dispose();
      titleCtrl.dispose();
      descCtrl.dispose();
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool saving = false;
        String? error;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Rediger annonce'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pris (kr)'),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: mileageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kilometer'),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titel'),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Beskrivelse',
                      ),
                      minLines: 3,
                      maxLines: 6,
                      enabled: !saving,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuller'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final price = num.tryParse(priceCtrl.text.trim());
                          if (price == null || price <= 0) {
                            setState(() => error = 'Ugyldig pris.');
                            return;
                          }
                          final mileageText = mileageCtrl.text.trim();
                          final mileage = mileageText.isEmpty
                              ? null
                              : int.tryParse(mileageText);
                          if (mileageText.isNotEmpty && mileage == null) {
                            setState(() => error = 'Ugyldigt kilometer-tal.');
                            return;
                          }

                          setState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await widget.api.updateListing(
                              item.id,
                              priceDkk: price,
                              mileageKm: mileage,
                              title: titleCtrl.text,
                              description: descCtrl.text,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          } catch (e) {
                            setState(() {
                              saving = false;
                              error = e.toString();
                            });
                          }
                        },
                  child: Text(saving ? 'Gemmer…' : 'Gem'),
                ),
              ],
            );
          },
        );
      },
    );

    await disposeCtrls();

    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Annonce opdateret')));
      await _load();
    }
  }

  Future<void> _deleteListing(ListingSummary item) async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Slet annonce?'),
          content: const Text('Dette kan ikke fortrydes.'),
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
        );
      },
    );

    if (ok != true) return;

    try {
      await widget.api.deleteListing(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Annonce slettet')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke slette: $e')));
    }
  }

  Future<void> _markSold(ListingSummary item) async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Markér som solgt?'),
          content: const Text(
            'Annoncen vil ikke længere vises i søgeresultater.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuller'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Markér som solgt'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await widget.api.updateListing(item.id, isSold: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annoncen er markeret som solgt')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke markere som solgt: $e')),
      );
    }
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
