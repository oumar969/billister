import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;

  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.api.login(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log ind')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwCtrl,
                decoration: const InputDecoration(labelText: 'Adgangskode'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Adgangskode er påkrævet';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Logger ind…' : 'Log ind'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterScreen(api: widget.api),
                          ),
                        );
                        if (ok == true && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                child: const Text('Ny bruger? Opret konto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
