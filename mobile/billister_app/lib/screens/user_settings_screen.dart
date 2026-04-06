import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'change_password_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _loading = false;

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kommer snart')),
    );
  }

  void _openChangePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(api: widget.api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.api.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontoindstillinger'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // User profile section
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '71 68 18 90',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Settings sections
                _settingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'E-mail og notifikationer',
                  subtitle: 'Tilmeld eller afmeld nyhedsbreve, push, m.m.',
                  onTap: _comingSoon,
                ),
                _settingsTile(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Skift kodeord',
                  subtitle: 'Skift kodeord på din Schibsted konto.',
                  onTap: _openChangePassword,
                ),
              ],
            ),
    );
  }

  static Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
