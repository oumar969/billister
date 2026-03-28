import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'login_screen.dart';
import 'my_listings_screen.dart';
import 'saved_searches_screen.dart';
import 'sell_car_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.api, this.onAuthChanged});

  final ApiClient api;
  final VoidCallback? onAuthChanged;

  Future<void> _logout(BuildContext context) async {
    await api.clearSession();
    if (!context.mounted) return;
    onAuthChanged?.call();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logget ud')));
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kommer snart')));
  }

  Future<bool> _ensureLoggedIn(BuildContext context) async {
    final token = api.token;
    if (token != null && token.isNotEmpty) return true;

    final ok = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => LoginScreen(api: api)));

    if (ok == true) {
      onAuthChanged?.call();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = api.currentUser;
    final loggedIn = user != null;

    final displayName = user?.username ?? 'Gæst';
    final email = user?.email ?? '';
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Text(
                            loggedIn ? ' ' : 'Ikke logget ind',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (isAdmin) ...[
                          const SizedBox(height: 2),
                          Chip(label: const Text('Admin')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _menuTile(
              context,
              icon: Icons.directions_car_filled_outlined,
              title: 'Mine annoncer',
              onTap: () async {
                final ok = await _ensureLoggedIn(context);
                if (!ok || !context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MyListingsScreen(api: api)),
                );
              },
            ),
            _menuTile(
              context,
              icon: Icons.sell_outlined,
              title: 'Sælg din bil',
              onTap: () async {
                final ok = await _ensureLoggedIn(context);
                if (!ok || !context.mounted) return;
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => SellCarScreen(api: api)),
                );
              },
            ),
            _menuTile(
              context,
              icon: Icons.manage_search_outlined,
              title: 'Søgeagenter',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SavedSearchesScreen(api: api),
                  ),
                );
              },
            ),
            _menuTile(
              context,
              icon: Icons.article_outlined,
              title: 'Bilbasen blog',
              onTap: () => _comingSoon(context),
            ),
            _menuTile(
              context,
              icon: Icons.settings_outlined,
              title: 'Kontoindstillinger',
              onTap: () => _comingSoon(context),
            ),
            _menuTile(
              context,
              icon: Icons.lock_outline,
              title: 'Log ud',
              onTap: loggedIn
                  ? () => _logout(context)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Du er ikke logget ind')),
                      );
                    },
            ),
            const Divider(height: 1),
            _menuTile(
              context,
              icon: Icons.phone_outlined,
              title: 'Kontakt kundeservice',
              onTap: () => _comingSoon(context),
            ),
            _menuTile(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Send en idé',
              onTap: () => _comingSoon(context),
            ),
            _menuTile(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Giv feedback',
              onTap: () => _comingSoon(context),
            ),
            const Divider(height: 1),
            _menuTile(
              context,
              icon: Icons.info_outline,
              title: 'Om Billister appen',
              onTap: () => _comingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
