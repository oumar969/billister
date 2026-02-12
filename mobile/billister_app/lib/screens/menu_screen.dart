import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'login_screen.dart';
import 'my_listings_screen.dart';
import 'sell_car_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.api, this.onAuthChanged});

  final ApiClient api;
  final VoidCallback? onAuthChanged;

  Map<String, dynamic>? _tryDecodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);

    try {
      final bytes = base64Url.decode(normalized);
      final json = jsonDecode(utf8.decode(bytes));
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  String? _firstNonEmpty(Map<String, dynamic>? payload, List<String> keys) {
    if (payload == null) return null;

    for (final k in keys) {
      final v = payload[k];
      if (v is String) {
        final s = v.trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  Future<void> _logout(BuildContext context) async {
    api.token = null;
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
    final token = api.token;
    final loggedIn = token != null && token.isNotEmpty;
    final payload = loggedIn ? _tryDecodeJwtPayload(token) : null;

    final name = _firstNonEmpty(payload, const [
      'name',
      'given_name',
      'unique_name',
      'sub',
    ]);
    final email = _firstNonEmpty(payload, const [
      'email',
      'preferred_username',
      'unique_name',
    ]);
    final phone = _firstNonEmpty(payload, const ['phone_number', 'phone']);

    final displayName = (name == null || name.isEmpty) ? 'Gæst' : name;

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
                    child: Icon(
                      Icons.person_outline,
                      size: 34,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        if (email != null && email.isNotEmpty)
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          Text(
                            loggedIn ? ' ' : 'Ikke logget ind',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
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
              title: 'Seneste søgninger',
              onTap: () => _comingSoon(context),
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
