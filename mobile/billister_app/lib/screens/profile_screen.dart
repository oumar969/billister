import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api, this.onAuthChanged});

  final ApiClient api;
  final VoidCallback? onAuthChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _minPasswordLength = 8;
  // Profile form
  final _profileFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Password form
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _loadingProfile = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _profileError;
  String? _profileSuccess;
  String? _passwordError;
  String? _passwordSuccess;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await widget.api.fetchProfile();
      if (!mounted) return;
      setState(() {
        _email = profile.email;
        _nameCtrl.text = profile.displayName ?? '';
        _phoneCtrl.text = profile.phoneNumber ?? '';
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _loadingProfile = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _savingProfile = true;
      _profileError = null;
      _profileSuccess = null;
    });

    try {
      await widget.api.updateProfile(
        displayName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      widget.onAuthChanged?.call();
      if (!mounted) return;
      setState(() {
        _profileSuccess = 'Oplysninger er opdateret';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _savingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await widget.api.changePassword(
        currentPassword: _currentPwCtrl.text,
        newPassword: _newPwCtrl.text,
      );
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() {
        _passwordSuccess = 'Adgangskode er ændret';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Min profil')),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader(context, 'Mine oplysninger'),
                const SizedBox(height: 8),
                Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: _email,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha(80),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Navn'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _sectionHeader(context, 'Kontaktinfo'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Telefonnummer'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      if (_profileError != null) ...[
                        Text(
                          _profileError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_profileSuccess != null) ...[
                        Text(
                          _profileSuccess!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        child: Text(
                          _savingProfile ? 'Gemmer…' : 'Gem oplysninger',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _sectionHeader(context, 'Indstillinger'),
                const SizedBox(height: 4),
                Text(
                  'Skift adgangskode',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _currentPwCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nuværende adgangskode',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Påkrævet';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPwCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ny adgangskode',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'Påkrævet';
                          if ((v ?? '').length < _minPasswordLength) {
                            return 'Mindst $_minPasswordLength tegn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPwCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bekræft ny adgangskode',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if ((v ?? '') != _newPwCtrl.text) {
                            return 'Adgangskoderne stemmer ikke overens';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_passwordError != null) ...[
                        Text(
                          _passwordError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_passwordSuccess != null) ...[
                        Text(
                          _passwordSuccess!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FilledButton(
                        onPressed: _savingPassword ? null : _changePassword,
                        child: Text(
                          _savingPassword ? 'Gemmer…' : 'Skift adgangskode',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
