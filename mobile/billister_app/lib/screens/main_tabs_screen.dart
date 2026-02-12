import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'favorites_screen.dart';
import 'listings_screen.dart';
import 'menu_screen.dart';

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
      const _PlaceholderTab(title: 'Søgeagent'),
      MenuScreen(api: widget.api, onAuthChanged: _onAuthChanged),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Hjem',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favoritter',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Søg'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Søgeagent',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Kommer snart')),
    );
  }
}
