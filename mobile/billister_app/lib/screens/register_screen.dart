import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePw = true;
  bool _obscurePw2 = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Re-validate the confirm field whenever the primary password changes.
    _pwCtrl.addListener(() {
      if (_pw2Ctrl.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
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
      await widget.api.register(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Adgangskode er påkrævet';
    if (value.length < 8) return 'Mindst 8 tegn';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Mindst ét stort bogstav';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Mindst ét lille bogstav';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Mindst ét tal';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opret konto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Email er påkrævet';
                  if (!value.contains('@')) return 'Ugyldig email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwCtrl,
                obscureText: _obscurePw,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Adgangskode',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePw = !_obscurePw),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw2Ctrl,
                obscureText: _obscurePw2,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Bekræft adgangskode',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePw2 = !_obscurePw2),
                  ),
                ),
                validator: (v) {
                  if ((v ?? '') != _pwCtrl.text) {
                    return 'Adgangskoderne stemmer ikke overens';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting ? 'Opretter konto…' : 'Opret konto',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(api: widget.api),
                          ),
                        );
                        if (ok == true && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: const Text('Har du allerede en konto? Log ind'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
