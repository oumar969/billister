import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/criteria.dart';
import '../api/models.dart';
import 'listing_details_screen.dart';
import 'login_screen.dart';

class ListingsScreen extends StatefulWidget {
  final ApiClient api;
  final VoidCallback? onAuthChanged;
  final String title;
  final bool showFilters;

  const ListingsScreen({
    super.key,
    required this.api,
    this.onAuthChanged,
    this.title = 'Billister',
    this.showFilters = true,
  });

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  ListingsPage? _page;
  String? _error;
  bool _loading = false;
  Set<String> _favoriteIds = <String>{};

  static const List<String> _fuelTypeOptions = <String>[
    'el',
    'benzin',
    'diesel',
    'hybrid',
  ];

  bool _catalogLoading = false;
  String? _catalogError;
  List<VehicleMake> _makes = const <VehicleMake>[];
  List<VehicleModel> _models = const <VehicleModel>[];
  String? _selectedMakeId;
  String? _selectedModelId;
  String? _activeMakeIdForModels;
  final List<VehicleMake> _selectedMakes = <VehicleMake>[];
  final List<VehicleModel> _selectedModels = <VehicleModel>[];

  String? _selectedFuelType;

  static const double _priceMinBound = 0;
  static const double _priceMaxBound = 1000000;
  static const double _yearMinBound = 1980;
  static const double _mileageMinBound = 0;
  static const double _mileageMaxBound = 500000;

  late final double _yearMaxBound;
  late RangeValues _priceRange;
  late RangeValues _yearRange;
  late RangeValues _mileageRange;

  bool _updatingRanges = false;

  final _qCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _priceMinCtrl = TextEditingController();
  final _priceMaxCtrl = TextEditingController();

  final _yearMinCtrl = TextEditingController();
  final _yearMaxCtrl = TextEditingController();
  final _mileageMinCtrl = TextEditingController();
  final _mileageMaxCtrl = TextEditingController();
  final _transmissionsCtrl = TextEditingController();
  final _requiredFeaturesCtrl = TextEditingController();

  ListingFilterCriteria get _criteria {
    if (!widget.showFilters) {
      return const ListingFilterCriteria();
    }

    num? tryNum(String s) => num.tryParse(s.trim());
    int? tryInt(String s) => int.tryParse(s.trim());

    List<String>? parseCsv(String s) {
      final parts = s
          .split(',')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts;
    }

    return ListingFilterCriteria(
      q: _qCtrl.text,
      makes: _selectedMakes.map((x) => x.name).toList(growable: false),
      models: _selectedModels.map((x) => x.name).toList(growable: false),
      fuelTypes: _selectedFuelType == null
          ? null
          : <String>[_selectedFuelType!],
      transmissions: parseCsv(_transmissionsCtrl.text),
      priceMin: _priceMinCtrl.text.trim().isEmpty
          ? null
          : tryNum(_priceMinCtrl.text),
      priceMax: _priceMaxCtrl.text.trim().isEmpty
          ? null
          : tryNum(_priceMaxCtrl.text),
      yearMin: _yearMinCtrl.text.trim().isEmpty
          ? null
          : tryInt(_yearMinCtrl.text),
      yearMax: _yearMaxCtrl.text.trim().isEmpty
          ? null
          : tryInt(_yearMaxCtrl.text),
      mileageMin: _mileageMinCtrl.text.trim().isEmpty
          ? null
          : tryInt(_mileageMinCtrl.text),
      mileageMax: _mileageMaxCtrl.text.trim().isEmpty
          ? null
          : tryInt(_mileageMaxCtrl.text),
      requiredFeatures: parseCsv(_requiredFeaturesCtrl.text),
    );
  }

  @override
  void initState() {
    super.initState();

    _yearMaxBound = DateTime.now().year.toDouble();
    _priceRange = const RangeValues(_priceMinBound, _priceMaxBound);
    _yearRange = RangeValues(_yearMinBound, _yearMaxBound);
    _mileageRange = const RangeValues(_mileageMinBound, _mileageMaxBound);

    if (widget.showFilters) {
      _loadVehicleCatalog();
    }
    _load();
  }

  void _syncPriceRangeFromText() {
    if (_updatingRanges) return;

    final min = double.tryParse(_priceMinCtrl.text.trim());
    final max = double.tryParse(_priceMaxCtrl.text.trim());

    final start = (min ?? _priceMinBound).clamp(_priceMinBound, _priceMaxBound);
    final end = (max ?? _priceMaxBound).clamp(_priceMinBound, _priceMaxBound);

    setState(() {
      _priceRange = start <= end
          ? RangeValues(start, end)
          : RangeValues(end, start);
    });
  }

  void _syncYearRangeFromText() {
    if (_updatingRanges) return;

    final min = double.tryParse(_yearMinCtrl.text.trim());
    final max = double.tryParse(_yearMaxCtrl.text.trim());

    final start = (min ?? _yearMinBound).clamp(_yearMinBound, _yearMaxBound);
    final end = (max ?? _yearMaxBound).clamp(_yearMinBound, _yearMaxBound);

    setState(() {
      _yearRange = start <= end
          ? RangeValues(start, end)
          : RangeValues(end, start);
    });
  }

  void _syncMileageRangeFromText() {
    if (_updatingRanges) return;

    final min = double.tryParse(_mileageMinCtrl.text.trim());
    final max = double.tryParse(_mileageMaxCtrl.text.trim());

    final start = (min ?? _mileageMinBound).clamp(
      _mileageMinBound,
      _mileageMaxBound,
    );
    final end = (max ?? _mileageMaxBound).clamp(
      _mileageMinBound,
      _mileageMaxBound,
    );

    setState(() {
      _mileageRange = start <= end
          ? RangeValues(start, end)
          : RangeValues(end, start);
    });
  }

  void _onPriceRangeChanged(RangeValues v) {
    setState(() {
      _priceRange = v;
    });

    _updatingRanges = true;
    _priceMinCtrl.text = v.start.round().toString();
    _priceMaxCtrl.text = v.end.round().toString();
    _updatingRanges = false;
  }

  void _finalizePriceRange(RangeValues v) {
    _updatingRanges = true;
    if (v.start <= _priceMinBound) _priceMinCtrl.clear();
    if (v.end >= _priceMaxBound) _priceMaxCtrl.clear();
    _updatingRanges = false;
    _syncPriceRangeFromText();
  }

  void _onYearRangeChanged(RangeValues v) {
    setState(() {
      _yearRange = v;
    });

    _updatingRanges = true;
    _yearMinCtrl.text = v.start.round().toString();
    _yearMaxCtrl.text = v.end.round().toString();
    _updatingRanges = false;
  }

  void _finalizeYearRange(RangeValues v) {
    _updatingRanges = true;
    if (v.start <= _yearMinBound) _yearMinCtrl.clear();
    if (v.end >= _yearMaxBound) _yearMaxCtrl.clear();
    _updatingRanges = false;
    _syncYearRangeFromText();
  }

  void _onMileageRangeChanged(RangeValues v) {
    setState(() {
      _mileageRange = v;
    });

    _updatingRanges = true;
    _mileageMinCtrl.text = v.start.round().toString();
    _mileageMaxCtrl.text = v.end.round().toString();
    _updatingRanges = false;
  }

  void _finalizeMileageRange(RangeValues v) {
    _updatingRanges = true;
    if (v.start <= _mileageMinBound) _mileageMinCtrl.clear();
    if (v.end >= _mileageMaxBound) _mileageMaxCtrl.clear();
    _updatingRanges = false;
    _syncMileageRangeFromText();
  }

  Future<void> _loadVehicleCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });

    try {
      final makes = await widget.api.fetchVehicleMakes();
      setState(() {
        _makes = makes;
      });
    } catch (e) {
      setState(() {
        _catalogError = e.toString();
      });
    } finally {
      setState(() {
        _catalogLoading = false;
      });
    }
  }

  Future<void> _loadModelsForMake(String makeId) async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
      _models = const <VehicleModel>[];
      _selectedModelId = null;
      _activeMakeIdForModels = makeId;
      _modelCtrl.clear();
    });

    try {
      final models = await widget.api.fetchVehicleModels(makeId);
      setState(() {
        _models = models;
      });
    } catch (e) {
      setState(() {
        _catalogError = e.toString();
      });
    } finally {
      setState(() {
        _catalogLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();

    _yearMinCtrl.dispose();
    _yearMaxCtrl.dispose();
    _mileageMinCtrl.dispose();
    _mileageMaxCtrl.dispose();
    _transmissionsCtrl.dispose();
    _requiredFeaturesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final criteria = _criteria;
      final page = criteria.isEmpty
          ? await widget.api.fetchListings(page: 1, pageSize: 20)
          : await widget.api.searchListings(
              criteria: criteria,
              page: 1,
              pageSize: 20,
            );

      Set<String> favoriteIds = _favoriteIds;
      final token = widget.api.token;
      if (token != null && token.isNotEmpty) {
        try {
          final favorites = await widget.api.fetchFavorites();
          favoriteIds = favorites.map((x) => x.id).toSet();
        } catch (_) {
          // Keep existing state if favorites fetch fails.
        }
      } else {
        favoriteIds = <String>{};
      }

      setState(() {
        _page = page;
        _favoriteIds = favoriteIds;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openLogin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
    );

    if (ok == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in')));
      widget.onAuthChanged?.call();
      setState(() {});
    }
  }

  Future<void> _toggleFavorite(String listingId) async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) return;

    final isFav = _favoriteIds.contains(listingId);

    setState(() {
      if (isFav) {
        _favoriteIds.remove(listingId);
      } else {
        _favoriteIds.add(listingId);
      }
    });

    try {
      if (isFav) {
        await widget.api.removeFavorite(listingId);
      } else {
        await widget.api.addFavorite(listingId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isFav) {
          _favoriteIds.add(listingId);
        } else {
          _favoriteIds.remove(listingId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke opdatere favorit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.token;
    final loggedIn = token != null && token.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!loggedIn)
            TextButton(onPressed: _openLogin, child: const Text('Login'))
          else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  widget.api.token = null;
                  _favoriteIds = <String>{};
                });
                widget.onAuthChanged?.call();
              },
              child: const Text('Logout'),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (widget.showFilters) ...[
              _filtersCard(context),
              const SizedBox(height: 12),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_page == null || _page!.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No listings yet')),
              )
            else
              ..._page!.items.map(
                (item) => Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: item.images.isEmpty
                            ? Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.directions_car,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : Image.network(
                                item.images.first.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.directions_car,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(_subtitle(item)),
                    trailing: loggedIn
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${item.priceDkk.toString()} kr'),
                              IconButton(
                                tooltip: _favoriteIds.contains(item.id)
                                    ? 'Fjern favorit'
                                    : 'Tilføj favorit',
                                onPressed: () => _toggleFavorite(item.id),
                                icon: Icon(
                                  _favoriteIds.contains(item.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          )
                        : Text('${item.priceDkk.toString()} kr'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListingDetailsScreen(
                            api: widget.api,
                            listingId: item.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filtersCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Advanced search'),
            const SizedBox(height: 8),
            TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(labelText: 'Søg'),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Make'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _selectedMakeId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tilføj mærke'),
                          ),
                          ..._makes.map(
                            (m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: _catalogLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                final make = _makes.firstWhere(
                                  (x) => x.id == value,
                                  orElse: () =>
                                      const VehicleMake(id: '', name: ''),
                                );
                                if (make.id.isNotEmpty) {
                                  setState(() {
                                    if (_selectedMakes.every(
                                      (x) => x.id != make.id,
                                    )) {
                                      _selectedMakes.add(make);
                                    }
                                    _selectedMakeId = null;
                                  });

                                  _loadModelsForMake(make.id);
                                }
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Model'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _selectedModelId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tilføj model'),
                          ),
                          ..._models.map(
                            (m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged:
                            _activeMakeIdForModels == null || _catalogLoading
                            ? null
                            : (value) {
                                if (value == null) return;

                                final model = _models.firstWhere(
                                  (x) => x.id == value,
                                  orElse: () => const VehicleModel(
                                    id: '',
                                    makeId: '',
                                    name: '',
                                  ),
                                );
                                if (model.id.isNotEmpty) {
                                  setState(() {
                                    if (_selectedModels.every(
                                      (x) => x.id != model.id,
                                    )) {
                                      _selectedModels.add(model);
                                    }
                                    _selectedModelId = null;
                                  });
                                }
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedMakes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMakes
                    .map(
                      (m) => InputChip(
                        label: Text(m.name),
                        onDeleted: () {
                          setState(() {
                            _selectedMakes.removeWhere((x) => x.id == m.id);
                            _selectedModels.removeWhere(
                              (x) => x.makeId == m.id,
                            );
                            if (_activeMakeIdForModels == m.id) {
                              _activeMakeIdForModels = null;
                              _models = const <VehicleModel>[];
                              _selectedModelId = null;
                            }
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (_selectedModels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedModels
                    .map(
                      (m) => InputChip(
                        label: Text(m.name),
                        onDeleted: () {
                          setState(() {
                            _selectedModels.removeWhere((x) => x.id == m.id);
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (_catalogError != null) ...[
              const SizedBox(height: 8),
              Text(
                _catalogError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price min'),
                    onChanged: (_) => _syncPriceRangeFromText(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price max'),
                    onChanged: (_) => _syncPriceRangeFromText(),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: _priceMinBound,
              max: _priceMaxBound,
              divisions: 200,
              labels: RangeLabels(
                _priceRange.start.round().toString(),
                _priceRange.end.round().toString(),
              ),
              onChanged: _loading ? null : _onPriceRangeChanged,
              onChangeEnd: _loading ? null : _finalizePriceRange,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year min'),
                    onChanged: (_) => _syncYearRangeFromText(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _yearMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year max'),
                    onChanged: (_) => _syncYearRangeFromText(),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _yearRange,
              min: _yearMinBound,
              max: _yearMaxBound,
              divisions: (_yearMaxBound - _yearMinBound).round().clamp(1, 200),
              labels: RangeLabels(
                _yearRange.start.round().toString(),
                _yearRange.end.round().toString(),
              ),
              onChanged: _loading ? null : _onYearRangeChanged,
              onChangeEnd: _loading ? null : _finalizeYearRange,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mileageMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mileage min'),
                    onChanged: (_) => _syncMileageRangeFromText(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mileageMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mileage max'),
                    onChanged: (_) => _syncMileageRangeFromText(),
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _mileageRange,
              min: _mileageMinBound,
              max: _mileageMaxBound,
              divisions: 100,
              labels: RangeLabels(
                _mileageRange.start.round().toString(),
                _mileageRange.end.round().toString(),
              ),
              onChanged: _loading ? null : _onMileageRangeChanged,
              onChangeEnd: _loading ? null : _finalizeMileageRange,
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Fuel type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _selectedFuelType,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Alle'),
                    ),
                    ..._fuelTypeOptions.map(
                      (x) =>
                          DropdownMenuItem<String?>(value: x, child: Text(x)),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) {
                          setState(() {
                            _selectedFuelType = v;
                          });
                        },
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transmissionsCtrl,
              decoration: const InputDecoration(
                labelText: 'Transmissions (comma-separated)',
                hintText: 'automat, manuel',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _requiredFeaturesCtrl,
              decoration: const InputDecoration(
                labelText: 'Required features (comma-separated)',
                hintText: 'navigation, adaptiv_fartpilot',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _load,
                    child: const Text('Search'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () {
                          _qCtrl.clear();
                          setState(() {
                            _selectedMakeId = null;
                            _selectedModelId = null;
                            _activeMakeIdForModels = null;
                            _models = const <VehicleModel>[];
                            _selectedMakes.clear();
                            _selectedModels.clear();
                          });
                          _priceMinCtrl.clear();
                          _priceMaxCtrl.clear();

                          _priceRange = const RangeValues(
                            _priceMinBound,
                            _priceMaxBound,
                          );

                          _yearMinCtrl.clear();
                          _yearMaxCtrl.clear();
                          _yearRange = RangeValues(
                            _yearMinBound,
                            _yearMaxBound,
                          );
                          _mileageMinCtrl.clear();
                          _mileageMaxCtrl.clear();
                          _mileageRange = const RangeValues(
                            _mileageMinBound,
                            _mileageMaxBound,
                          );
                          _selectedFuelType = null;
                          _transmissionsCtrl.clear();
                          _requiredFeaturesCtrl.clear();
                          _load();
                        },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(ListingSummary item) {
    final parts = <String>[];
    if (item.year != null) {
      parts.add(item.year.toString());
    }
    if (item.mileageKm != null) {
      parts.add('${item.mileageKm} km');
    }
    if (item.city != null && item.city!.trim().isNotEmpty) {
      parts.add(item.city!);
    }
    return parts.join(' · ');
  }
}
