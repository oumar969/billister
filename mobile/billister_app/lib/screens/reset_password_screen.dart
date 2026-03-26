import 'package:flutter/material.dart';

import '../api/api_client.dart';

/// Screen for entering the password-reset token and choosing a new password.
class ResetPasswordScreen extends StatefulWidget {
  final ApiClient api;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.api,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _isSubmitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.api.resetPassword(
        email: widget.email,
        resetToken: _tokenCtrl.text.trim(),
        newPassword: _pwCtrl.text,
      );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nulstil kodeord')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _done ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konto: ${widget.email}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenCtrl,
            decoration: const InputDecoration(
              labelText: 'Nulstillingstoken',
              helperText: 'Kopiér token fra den email du modtog',
            ),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Token er påkrævet';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pwCtrl,
            decoration: const InputDecoration(labelText: 'Nyt kodeord'),
            obscureText: true,
            validator: (v) {
              if ((v ?? '').length < 8) return 'Mindst 8 tegn';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pw2Ctrl,
            decoration: const InputDecoration(labelText: 'Gentag nyt kodeord'),
            obscureText: true,
            validator: (v) {
              if (v != _pwCtrl.text) return 'Kodeordene stemmer ikke overens';
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
            child: Text(_isSubmitting ? 'Nulstiller…' : 'Nulstil kodeord'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Dit kodeord er blevet nulstillet. Du kan nu logge ind med dit nye kodeord.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            // Pop back to root (login or menu)
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
          child: const Text('Gå til forsiden'),
        ),
      ],
    );
  }
}
