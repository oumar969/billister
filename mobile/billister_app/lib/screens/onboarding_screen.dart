import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.api,
    required this.onComplete,
    required this.onAuthChanged,
  });

  final ApiClient api;

  /// Called when the user finishes onboarding (login, register, or guest).
  final VoidCallback onComplete;

  /// Called when the authentication state changes.
  final VoidCallback onAuthChanged;

  Future<void> _goRegister(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RegisterScreen(api: api)),
    );
    if (ok == true) {
      onAuthChanged();
      onComplete();
    }
  }

  Future<void> _goLogin(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: api)),
    );
    if (ok == true) {
      onAuthChanged();
      onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.directions_car,
                size: 96,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Velkommen til Billister',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Find din næste bil til den rigtige pris',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              FilledButton.icon(
                onPressed: () => _goRegister(context),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Opret konto'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _goLogin(context),
                icon: const Icon(Icons.login),
                label: const Text('Log ind'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onComplete,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Fortsæt som gæst',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
