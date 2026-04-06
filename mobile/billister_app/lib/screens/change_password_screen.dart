import 'package:flutter/material.dart';

import '../api/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _error;
  String? _success;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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
      final response = await widget.api.changePassword(
        currentPassword: _currentPasswordCtrl.text.trim(),
        newPassword: _newPasswordCtrl.text.trim(),
      );

      if (response.statusCode == 200) {
        setState(() {
          _success = 'Kodeord skiftet succesfuldt';
          _currentPasswordCtrl.clear();
          _newPasswordCtrl.clear();
          _confirmPasswordCtrl.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Kodeord skiftet succesfuldt'),
              backgroundColor: Colors.green,
            ),
          );

          // Vend tilbage efter 2 sekunder
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
      } else if (response.statusCode == 401) {
        setState(() => _error = 'Nuværende kodeord er forkert');
      } else {
        setState(() => _error = 'Fejl ved skift af kodeord');
      }
    } catch (e) {
      setState(() => _error = 'Fejl: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Kodeord er påkrævet';
    if (value.length < 8) return 'Kodeord skal være mindst 8 tegn';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Kodeord skal indeholde stort bogstav';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Kodeord skal indeholde lille bogstav';
    if (!value.contains(RegExp(r'\d'))) return 'Kodeord skal indeholde tal';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skift kodeord')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Skift kodeord på din Schibsted konto',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentPasswordCtrl,
              obscureText: !_showCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Nuværende kodeord',
                hintText: 'Indtast dit nuværende kodeord',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                      () =>
                          _showCurrentPassword = !_showCurrentPassword,
                    );
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nuværende kodeord er påkrævet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordCtrl,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: 'Nyt kodeord',
                hintText: 'Mindst 8 tegn, stort/lille bogstav, tal',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _showNewPassword = !_showNewPassword);
                  },
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Bekræft nyt kodeord',
                hintText: 'Gentag dit nye kodeord',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(
                      () =>
                          _showConfirmPassword = !_showConfirmPassword,
                    );
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bekræftelse af kodeord er påkrævet';
                }
                if (value != _newPasswordCtrl.text) {
                  return 'Kodeordene stemmer ikke overens';
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
              child: Text(
                _isSubmitting ? 'Skifter...' : 'Skift kodeord',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
