import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../widgets/seller_rating_display.dart';
import 'sell_car_screen.dart';
import 'submit_review_screen.dart';

class ListingDetailsScreen extends StatefulWidget {
  const ListingDetailsScreen({
    super.key,
    required this.api,
    required this.listingId,
  });

  final ApiClient api;
  final String listingId;

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  late final Future<ListingDetails> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchListingDetails(widget.listingId);
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kunne ikke åbne appen')));
      }
    }
  }

  Future<void> _submitReview(ListingDetails listing) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitReviewScreen(
          api: widget.api,
          listingId: listing.id,
          sellerId: listing.sellerId,
          carTitle: listing.displayTitle,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tak for din bedømmelse!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();
    final reasons = [
      'Forkert pris',
      'Forkert billeder',
      'Duplikat annoncer',
      'Svindel/Ulovligt',
      'Dårlig tilstand',
      'Andet',
    ];
    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anmeld annonce'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: selectedReason,
              isExpanded: true,
              items: reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  selectedReason = v;
                  (context as Element).markNeedsBuild();
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Yderligere oplysninger (valgfrit)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuller'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tak! Annoncen er blevet anmeldt.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Anmeld'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonce'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Del annonce',
            onPressed: () {
              final link = 'billister://listings/${widget.listingId}';
              SharePlus.instance.share(ShareParams(uri: Uri.parse(link)));
            },
          ),
        ],
      ),
      body: FutureBuilder<ListingDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Kunne ikke hente annonce: ${snapshot.error}'),
              ),
            );
          }

          final d = snapshot.data;
          if (d == null) {
            return const Center(child: Text('Ingen data'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (d.images.isNotEmpty) ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      d.images.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Billede kunne ikke hentes'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (d.images.length > 1) ...[
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: d.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final img = d.images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 96,
                            height: 72,
                            child: Image.network(
                              img.url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (d.images.isEmpty) ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          const Text('Ingen billeder'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                d.displayTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${d.priceDkk.toStringAsFixed(0)} kr.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Seller rating
              _SellerRatingSection(api: widget.api, sellerId: d.sellerId),
              const SizedBox(height: 16),
              _ContactButtons(
                sellerPhone: d.sellerPhone,
                onSell: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SellCarScreen(api: widget.api),
                  ),
                ),
                onCall: d.sellerPhone != null
                    ? () => _launch(Uri(scheme: 'tel', path: d.sellerPhone))
                    : null,
                onSms: d.sellerPhone != null
                    ? () => _launch(Uri(scheme: 'sms', path: d.sellerPhone))
                    : null,
                onReview: () => _submitReview(d),
              ),
              const SizedBox(height: 16),
              _kv('Brændstof', d.fuelType),
              _kv('Gear', d.transmission),
              if (d.year != null) _kv('År', '${d.year}'),
              if (d.mileageKm != null) _kv('Km', '${d.mileageKm}'),
              if (d.city != null || d.postalCode != null)
                _kv(
                  'Lokation',
                  [
                    if (d.postalCode != null) d.postalCode!,
                    if (d.city != null) d.city!,
                  ].join(' '),
                ),
              const SizedBox(height: 12),
              if ((d.description ?? '').trim().isNotEmpty) ...[
                Text(
                  'Beskrivelse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(d.description!.trim()),
                const SizedBox(height: 12),
              ],
              if (d.features.isNotEmpty) ...[
                Text('Udstyr', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.features
                      .map((f) => Chip(label: Text(f)))
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
              ],
              _kv('Visninger', '${d.viewCount}'),
              _kv('Favoritter', '${d.favoriteCount}'),
              const SizedBox(height: 24),
              // Lignende biler
              _SimilarListingsSection(
                api: widget.api,
                make: d.make,
                model: d.model,
                currentListingId: d.id,
              ),
              const SizedBox(height: 24),
              // Anmeld annonce
              OutlinedButton.icon(
                icon: const Icon(Icons.report_outlined),
                label: const Text('Anmeld annonce'),
                onPressed: () => _showReportDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[500],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({
    required this.sellerPhone,
    required this.onSell,
    required this.onCall,
    required this.onSms,
    required this.onReview,
  });

  final String? sellerPhone;
  final VoidCallback onSell;
  final VoidCallback? onCall;
  final VoidCallback? onSms;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone),
                label: const Text('Ring'),
                style: onCall == null
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSms,
                icon: const Icon(Icons.sms),
                label: const Text('SMS'),
                style: onSms == null
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      )
                    : null,
              ),
            ),
          ],
        ),
        if (sellerPhone == null) ...[
          const SizedBox(height: 4),
          Text(
            'Sælger har ikke angivet telefonnummer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onSell,
          icon: const Icon(Icons.sell_outlined),
          label: const Text('Sælg din bil'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onReview,
          icon: const Icon(Icons.star_outline),
          label: const Text('Bedøm'),
        ),
      ],
    );
  }
}

class _SellerRatingSection extends StatelessWidget {
  final ApiClient api;
  final String sellerId;

  const _SellerRatingSection({required this.api, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return SellerRatingFutureBuilder(
      ratingFuture: api.getSellerRating(sellerId),
      compact: false,
    );
  }
}

class _SimilarListingsSection extends StatelessWidget {
  final ApiClient api;
  final String make;
  final String model;
  final String currentListingId;

  const _SimilarListingsSection({
    required this.api,
    required this.make,
    required this.model,
    required this.currentListingId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ListingsPage>(
      future: api.fetchListings(page: 1, pageSize: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final allListings = snapshot.data!.items;

        // Filtrer lignende biler (samme mærke og model, ekskluder nuværende)
        final similarListings = allListings
            .where(
              (l) =>
                  l.make == make &&
                  l.model == model &&
                  l.id != currentListingId,
            )
            .take(6)
            .toList();

        if (similarListings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lignende ${make} $model',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: similarListings.length,
              itemBuilder: (context, index) {
                final listing = similarListings[index];
                return _SimilarListingCard(
                  listing: listing,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailsScreen(
                          api: api,
                          listingId: listing.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SimilarListingCard extends StatelessWidget {
  final ListingSummary listing;
  final VoidCallback onTap;

  const _SimilarListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Billede
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: listing.images.isNotEmpty
                    ? Image.network(
                        listing.images.first.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: const Icon(Icons.directions_car),
                          );
                        },
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: const Icon(Icons.directions_car),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${listing.make} ${listing.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (listing.year != null)
                    Text(
                      '${listing.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.priceDkk.toStringAsFixed(0)} kr.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
