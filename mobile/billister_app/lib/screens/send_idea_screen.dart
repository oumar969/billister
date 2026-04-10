import 'package:flutter/material.dart';

import '../api/api_client.dart';

class SendIdeaScreen extends StatefulWidget {
  const SendIdeaScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SendIdeaScreen> createState() => _SendIdeaScreenState();
}

class _SendIdeaScreenState extends State<SendIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ideaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    final user = widget.api.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
      _success = null;
    });

    try {
      // Send feedback via email service
      await widget.api.submitFeedback(
        idea: _ideaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      setState(() {
        _success = 'Tak for din idé! Vi modtog den og vil læse den.';
        _ideaCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Idé sendt succesfuldt'),
            backgroundColor: Colors.green,
          ),
        );

        // Vend tilbage efter 2 sekunder
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Fejl ved indsendelse: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send en idé')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Send os din feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ideaCtrl,
              decoration: InputDecoration(
                hintText: 'Fortæl os hvad du tænker...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 8,
              minLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Skriv venligst en idé eller feedback';
                }
                if (value.length < 10) {
                  return 'Idéen skal være mindst 10 tegn';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email address',
                hintText: 'Indtast din email adresse',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email er påkrævet';
                }
                if (!value.contains('@')) {
                  return 'Indtast en gyldig email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_success != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _success!,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Sender...' : 'Næste'),
            ),
          ],
        ),
      ),
    );
  }
}
