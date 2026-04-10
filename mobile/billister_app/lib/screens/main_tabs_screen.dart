import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'favorites_screen.dart';
import 'listings_screen.dart';
import 'menu_screen.dart';
import 'saved_searches_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _index = 0;

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ListingsScreen(
        api: widget.api,
        onAuthChanged: _onAuthChanged,
        title: 'Hjem',
        showFilters: false,
      ),
      FavoritesScreen(api: widget.api),
      ListingsScreen(
        api: widget.api,
        onAuthChanged: _onAuthChanged,
        title: 'Søg',
        showFilters: true,
      ),
      SavedSearchesScreen(api: widget.api),
      MenuScreen(api: widget.api, onAuthChanged: _onAuthChanged),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildTeslaNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeslaNavigationBar() {
    const teslaBlue = Color(0xFF3E6AE1);
    const carbonDark = Color(0xFF171A20);
    const silverFog = Color(0xFF8E8E8E);
    const cloudGray = Color(0xFFEEEEEE);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cloudGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final isActive = _index == index;
            final items = [
              {'icon': Icons.home_outlined, 'label': 'Hjem'},
              {'icon': Icons.favorite_border, 'label': 'Favoritter'},
              {'icon': Icons.search, 'label': 'Søg'},
              {'icon': Icons.notifications_none, 'label': 'Søgeagent'},
              {'icon': Icons.menu, 'label': 'Menu'},
            ];

            return GestureDetector(
              onTap: () => setState(() => _index = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isActive
                      ? teslaBlue.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isActive
                      ? Border.all(color: teslaBlue.withOpacity(0.3), width: 1)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index]['icon'] as IconData,
                      color: isActive ? teslaBlue : silverFog,
                      size: 24,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isActive ? carbonDark : silverFog,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
