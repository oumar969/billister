import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'reset_password_screen.dart';

/// Screen for requesting a password-reset email.
class ForgotPasswordScreen extends StatefulWidget {
  final ApiClient api;

  const ForgotPasswordScreen({super.key, required this.api});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.api.forgotPassword(email: _emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glemt kodeord')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _sent ? _buildConfirmation() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Indtast din email-adresse, og vi sender dig et link til at nulstille dit kodeord.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Email er påkrævet';
              if (!value.contains('@')) return 'Ugyldig email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(_isSubmitting ? 'Sender…' : 'Send nulstillingslink'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Hvis der er oprettet en konto med den email, har vi sendt instruktioner til at nulstille dit kodeord.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  api: widget.api,
                  email: _emailCtrl.text.trim(),
                ),
              ),
            );
          },
          child: const Text('Jeg har modtaget token – fortsæt'),
        ),
      ],
    );
  }
}
