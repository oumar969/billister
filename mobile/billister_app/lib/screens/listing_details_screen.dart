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

          return Scaffold(
            appBar: AppBar(title: Text(d.displayTitle), elevation: 0),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    return isWide
                        ? _buildWideLayout(context, d)
                        : _buildMobileLayout(context, d);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ListingDetails d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Billeder
        _ImagesGallery(images: d.images),
        const SizedBox(height: 20),

        // Pris
        Text(
          '${d.priceDkk.toStringAsFixed(0)} kr.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Sælger info
        _SellerInfoCard(d: d),
        const SizedBox(height: 16),

        // Kontaktknapper
        _ContactButtons(
          sellerPhone: d.sellerPhone,
          onSell: () => Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => SellCarScreen(api: widget.api)),
          ),
          onCall: d.sellerPhone != null
              ? () => _launch(Uri(scheme: 'tel', path: d.sellerPhone))
              : null,
          onSms: d.sellerPhone != null
              ? () => _launch(Uri(scheme: 'sms', path: d.sellerPhone))
              : null,
          onReview: () => _submitReview(d),
        ),
        const SizedBox(height: 20),

        // Detaljer
        _Divider(),
        const SizedBox(height: 16),
        _DetailsList(d: d),
        const SizedBox(height: 20),

        // Lignende biler
        _SimilarListingsSection(
          api: widget.api,
          make: d.make,
          model: d.model,
          currentListingId: d.id,
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, ListingDetails d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Venstre: Billeder
        Expanded(flex: 2, child: _ImagesGallery(images: d.images)),
        const SizedBox(width: 24),

        // Højre: Info + detaljer
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pris
              Text(
                '${d.priceDkk.toStringAsFixed(0)} kr.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Sælger info
              _SellerInfoCard(d: d),
              const SizedBox(height: 16),

              // Kontaktknapper
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
              const SizedBox(height: 20),

              // Detaljer
              _Divider(),
              const SizedBox(height: 16),
              _DetailsList(d: d),
            ],
          ),
        ),
      ],
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

// Helper Widgets
class _ImagesGallery extends StatefulWidget {
  final List<ListingImage> images;

  const _ImagesGallery({required this.images});

  @override
  State<_ImagesGallery> createState() => _ImagesGalleryState();
}

class _ImagesGalleryState extends State<_ImagesGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 300,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
      );
    }

    return Column(
      children: [
        // Main carousel
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: widget.images.length,
                  itemBuilder: (_, i) {
                    return Image.network(
                      widget.images[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  },
                ),
                // Counter
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Thumbnails
        if (widget.images.length > 1)
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isSelected = i == _currentPage;
                return GestureDetector(
                  onTap: () => _pageController.jumpToPage(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 96,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        widget.images[i].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SellerInfoCard extends StatelessWidget {
  final ListingDetails d;

  const _SellerInfoCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sælger info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (d.cvrNumber != null && d.cvrNumber!.isNotEmpty) ...[
              _SellerInfoRow(label: 'CVR', value: d.cvrNumber!),
              const SizedBox(height: 12),
            ],
            if (d.streetAddress != null && d.streetAddress!.isNotEmpty) ...[
              _SellerInfoRow(
                label: 'Adresse',
                value: [
                  d.streetAddress,
                  if (d.streetNumber != null) d.streetNumber,
                  if (d.floor != null) d.floor,
                ].where((e) => e != null && (e as String).isNotEmpty).join(' '),
              ),
              const SizedBox(height: 12),
            ],
            if (d.city != null && d.city!.isNotEmpty) ...[
              _SellerInfoRow(
                label: 'By',
                value: [
                  if (d.postalCode != null) d.postalCode,
                  d.city,
                ].where((e) => e != null && (e as String).isNotEmpty).join(' '),
              ),
              const SizedBox(height: 12),
            ],
            if (d.website != null && d.website!.isNotEmpty) ...[
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(
                    d.website!.startsWith('http')
                        ? d.website!
                        : 'https://${d.website}',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: _SellerInfoRow(label: 'Hjemmeside', value: d.website!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SellerInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SellerInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _DetailsList extends StatelessWidget {
  final ListingDetails d;

  const _DetailsList({required this.d});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.year != null || d.mileageKm != null) ...[
          Row(
            children: [
              if (d.year != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'År',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${d.year}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (d.mileageKm != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Km',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      Text(
                        '${d.mileageKm}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brændstof',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Text(
              d.fuelType,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gear',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Text(
              d.transmission,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(color: Theme.of(context).colorScheme.outlineVariant);
  }
}
