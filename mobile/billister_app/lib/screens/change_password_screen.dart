import 'package:flutter/material.dart';

import '../api/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ApiClient api;

  const ChangePasswordScreen({super.key, required this.api});

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
    });

    try {
      await widget.api.changePassword(
        _currentPasswordCtrl.text,
        _newPasswordCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adgangskode er ændret')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ny adgangskode er påkrævet';
    }
    if (value.length < 8) {
      return 'Adgangskode skal være mindst 8 tegn';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Adgangskode skal indeholde mindst et stort bogstav';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Adgangskode skal indeholde mindst et tal';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skift Adgangskode')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _currentPasswordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nuværende adgangskode',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _showCurrentPassword = !_showCurrentPassword,
                      ),
                    ),
                  ),
                  obscureText: !_showCurrentPassword,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Nuværende adgangskode er påkrævet'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ny adgangskode',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _showNewPassword = !_showNewPassword,
                      ),
                    ),
                  ),
                  obscureText: !_showNewPassword,
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 8),
                Text(
                  'Krav: mindst 8 tegn, med stort bogstav og tal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  decoration: InputDecoration(
                    labelText: 'Bekræft ny adgangskode',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                  ),
                  obscureText: !_showConfirmPassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Bekræftelse af adgangskode er påkrævet';
                    }
                    if (v != _newPasswordCtrl.text) {
                      return 'Adgangskoderne matcher ikke';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _isSubmitting ? 'Skifter…' : 'Skift adgangskode',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
