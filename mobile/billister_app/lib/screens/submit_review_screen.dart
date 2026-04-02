import 'package:flutter/material.dart';

import '../api/api_client.dart';

class SubmitReviewScreen extends StatefulWidget {
  final ApiClient api;
  final String listingId;
  final String sellerId;
  final String carTitle;

  const SubmitReviewScreen({
    super.key,
    required this.api,
    required this.listingId,
    required this.sellerId,
    required this.carTitle,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  int _selectedRating = 0;
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      setState(() => _error = 'Vælg venligst en stjernebedømmelse');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.api.submitReview(
        listingId: widget.listingId,
        sellerId: widget.sellerId,
        rating: _selectedRating,
        title: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
        comment: _commentCtrl.text.isEmpty ? null : _commentCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tak for din anmeldelse!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bedøm Købet')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Hvordan var dit køb?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.carTitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Star rating
              Text(
                'Giv stjerner',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final rating = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRating = rating),
                      child: Icon(
                        _selectedRating >= rating
                            ? Icons.star
                            : Icons.star_border,
                        size: 40,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
              if (_selectedRating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _getRatingText(_selectedRating),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kort sammenfatning (valgfrit)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Comment
              TextFormField(
                controller: _commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Din bedømmelse (valgfrit)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              // Error
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Submit button
              FilledButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _isSubmitting ? 'Indsender…' : 'Indsend Bedømmelse',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Dårlig 😞';
      case 2:
        return 'Acceptabel 😐';
      case 3:
        return 'God 🙂';
      case 4:
        return 'Meget god 😊';
      case 5:
        return 'Fremragende! 😍';
      default:
        return '';
    }
  }
}
