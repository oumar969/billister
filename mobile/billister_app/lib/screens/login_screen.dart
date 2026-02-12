import 'package:flutter/material.dart';

import '../api/api_client.dart';

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
      appBar: AppBar(title: const Text('Login')),
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
                  if (value.isEmpty) return 'Email is required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pwCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Password is required';
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
                child: Text(_isSubmitting ? 'Logging in…' : 'Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
