import 'package:flutter/material.dart';

import '../api/models.dart';

class SellerRatingDisplay extends StatelessWidget {
  final SellerRating rating;
  final bool compact;

  const SellerRatingDisplay({
    super.key,
    required this.rating,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StarDisplay(rating: rating.averageRating, size: 16),
          const SizedBox(width: 4),
          Text(
            '${rating.averageRating.toStringAsFixed(1)} (${rating.totalReviews})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sælgers Bedømmelse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _StarDisplay(rating: rating.averageRating),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${rating.averageRating.toStringAsFixed(1)} af 5.0 • ${rating.totalReviews} anmeldelse${rating.totalReviews != 1 ? 'r' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ..._buildStarDistribution(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStarDistribution(BuildContext context) {
    if (rating.totalReviews == 0) return [];

    return [
      const Divider(),
      const SizedBox(height: 8),
      ..._starCounts(context),
    ];
  }

  List<Widget> _starCounts(BuildContext context) {
    return [
      _StarCountBar(count: rating.fiveStarCount, total: rating.totalReviews),
      _StarCountBar(
        count: rating.fourStarCount,
        total: rating.totalReviews,
        stars: 4,
      ),
      _StarCountBar(
        count: rating.threeStarCount,
        total: rating.totalReviews,
        stars: 3,
      ),
      _StarCountBar(
        count: rating.twoStarCount,
        total: rating.totalReviews,
        stars: 2,
      ),
      _StarCountBar(
        count: rating.oneStarCount,
        total: rating.totalReviews,
        stars: 1,
      ),
    ];
  }
}

class _StarDisplay extends StatelessWidget {
  final double rating;
  final double size;

  const _StarDisplay({required this.rating, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: size, color: Colors.amber);
        }
      }),
    );
  }
}

class _StarCountBar extends StatelessWidget {
  final int count;
  final int total;
  final int stars;

  const _StarCountBar({
    required this.count,
    required this.total,
    this.stars = 5,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$stars ⭐',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForStars(stars),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForStars(int stars) {
    switch (stars) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// FutureBuilder wrapper for loading and displaying seller rating
class SellerRatingFutureBuilder extends StatelessWidget {
  final Future<SellerRating> ratingFuture;
  final bool compact;

  const SellerRatingFutureBuilder({
    super.key,
    required this.ratingFuture,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SellerRating>(
      future: ratingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Kunne ikke indlæse bedømmelse',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          );
        }

        final rating = snapshot.data;
        if (rating == null) {
          return Text(
            'Ingen bedømmelser',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          );
        }

        return SellerRatingDisplay(rating: rating, compact: compact);
      },
    );
  }
}
