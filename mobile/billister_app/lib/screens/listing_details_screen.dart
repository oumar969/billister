import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Annonce')),
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
              const SizedBox(height: 12),
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
