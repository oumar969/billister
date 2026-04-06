import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  List<SearchHistory> _searchHistory = [];
  bool _loading = true;
  static const String _searchHistoryKey = 'search_history';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_searchHistoryKey) ?? [];
      final history = jsonList
          .map(
            (json) => SearchHistory.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            ),
          )
          .toList();
      setState(() {
        _searchHistory = history;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load search history: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _clearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet historik?'),
        content: const Text(
          'Er du sikker på at du vil slette hele søgehistoriken?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slet'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      setState(() => _searchHistory = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Søgehistorik slettet')),
        );
      }
    } catch (e) {
      debugPrint('Failed to clear search history: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final searchDate = DateTime(date.year, date.month, date.day);

    if (searchDate == today) {
      return 'I dag kl. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (searchDate == yesterday) {
      return 'I går kl. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}. ${_monthName(date.month)} ${date.year}';
    }
  }

  String _monthName(int month) {
    const months = [
      'januar',
      'februar',
      'marts',
      'april',
      'maj',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'december',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seneste søgninger'),
        actions: [
          if (_searchHistory.isNotEmpty)
            IconButton(
              tooltip: 'Slet historik',
              onPressed: _clearSearchHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _searchHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ingen søgehistorik',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Søgninger efter nummerplader gemmes her',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _searchHistory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = _searchHistory[index];
                    return ListTile(
                      leading: Icon(
                        Icons.car_rental_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(entry.displayTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            entry.licensePlate.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(entry.searchedAtUtc.toLocal()),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    );
                  },
                ),
    );
  }
}
