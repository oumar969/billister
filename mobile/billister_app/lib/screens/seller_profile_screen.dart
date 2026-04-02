import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/review_list_item.dart';
import '../widgets/seller_rating_display.dart';

class SellerProfileScreen extends StatefulWidget {
  final ApiClient api;
  final String sellerId;
  final String sellerName;

  const SellerProfileScreen({
    super.key,
    required this.api,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sellerName), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seller rating header
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: SellerRatingFutureBuilder(
                ratingFuture: widget.api.getSellerRating(widget.sellerId),
                compact: false,
              ),
            ),
            const SizedBox(height: 24),

            // Reviews section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anmeldelser fra Købere',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ReviewListFuture(
                    reviewsFuture: widget.api.getSellerReviews(widget.sellerId),
                    screenType: 'seller',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
