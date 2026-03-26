import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'listing_details_screen.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  // Default to Copenhagen, Denmark
  static const LatLng _defaultCenter = LatLng(55.676, 12.568);
  static const double _defaultZoom = 9.0;
  static const double _markerZoom = 11.0;

  final MapController _mapController = MapController();

  List<NearbyListing> _listings = const [];
  bool _loading = false;
  String? _error;

  double _radiusKm = 25;
  LatLng? _searchCenter;

  static const List<double> _radiusOptions = [10, 25, 50, 100];

  Future<void> _findNearby() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _resolvePosition();
      if (!mounted) return;

      final center = LatLng(position.latitude, position.longitude);
      _mapController.move(center, _markerZoom);

      final listings = await widget.api.fetchNearbyListings(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: _radiusKm,
      );

      if (!mounted) return;
      setState(() {
        _searchCenter = center;
        _listings = listings;
        _loading = false;
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;
      setState(() {
        _error = 'Lokationstjeneste er deaktiveret. Aktiver den i indstillinger.';
        _loading = false;
      });
    } on PermissionDeniedException {
      if (!mounted) return;
      setState(() {
        _error = 'Adgang til lokation blev afvist.';
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kunne ikke hente placering: $e';
        _loading = false;
      });
    }
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw const LocationServiceDisabledException();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('denied');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  void _showListingSheet(NearbyListing listing) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _ListingBottomSheet(
        listing: listing,
        onOpen: () {
          Navigator.pop(ctx);
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailsScreen(
                api: widget.api,
                listingId: listing.id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(num price) {
    final p = price.toInt();
    if (p >= 1000000) {
      return '${(p / 1000000).toStringAsFixed(1)} mio. kr.';
    }
    if (p >= 1000) {
      final thousands = p ~/ 1000;
      final remainder = (p % 1000) ~/ 100;
      return remainder == 0
          ? '$thousands.000 kr.'
          : '$thousands.${remainder}00 kr.';
    }
    return '$p kr.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kort'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _radiusKm,
                icon: const Icon(Icons.tune),
                items: _radiusOptions
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.toInt()} km'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _radiusKm = v);
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.billister.billister_app',
              ),
              if (_listings.isNotEmpty)
                MarkerLayer(
                  markers: _listings
                      .map(
                        (l) => Marker(
                          point: LatLng(l.latitude, l.longitude),
                          width: 100,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showListingSheet(l),
                            child: _PriceMarker(
                              label: _formatPrice(l.priceDkk),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: theme.colorScheme.onErrorContainer,
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_listings.isNotEmpty)
            Positioned(
              bottom: 88,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      '${_listings.length} annonce${_listings.length == 1 ? '' : 'r'} inden for '
                      '${_radiusKm.toInt()} km',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _findNearby,
        icon: const Icon(Icons.my_location),
        label: const Text('I nærheden'),
      ),
    );
  }
}

class _PriceMarker extends StatelessWidget {
  const _PriceMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(theme.colorScheme.primary),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _ListingBottomSheet extends StatelessWidget {
  const _ListingBottomSheet({
    required this.listing,
    required this.onOpen,
  });

  final NearbyListing listing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formatPrice(num price) {
      final p = price.toInt();
      final formatted = p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return '$formatted kr.';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatPrice(listing.priceDkk),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Se annonce'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
