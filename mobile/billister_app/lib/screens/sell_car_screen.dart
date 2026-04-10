import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../widgets/listing_images_picker.dart';

class SellCarScreen extends StatefulWidget {
  const SellCarScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<SellCarScreen> createState() => _SellCarScreenState();
}

class _SellCarScreenState extends State<SellCarScreen> {
  static const List<String> _fuelTypeOptions = <String>[
    'el',
    'benzin',
    'diesel',
    'hybrid',
  ];

  static const List<String> _transmissionOptions = <String>[
    'automat',
    'manuel',
  ];

  final _formKey = GlobalKey<FormState>();

  bool _catalogLoading = false;
  String? _catalogError;
  List<VehicleMake> _makes = const <VehicleMake>[];
  List<VehicleModel> _models = const <VehicleModel>[];

  String? _makeId;
  String? _modelId;

  String _fuelType = _fuelTypeOptions.first;
  String _transmission = _transmissionOptions.first;

  final _licensePlateCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cvrCtrl = TextEditingController();
  final _streetAddressCtrl = TextEditingController();
  final _streetNumberCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;
  String? _uploadStatus;

  List<XFile> _selectedImages = [];
  List<SearchHistory> _searchHistory = [];
  static const String _searchHistoryKey = 'search_history';
  static const int _maxSearchHistory = 10;

  @override
  void initState() {
    super.initState();
    _loadMakes();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _licensePlateCtrl.dispose();
    _priceCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _cityCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _cvrCtrl.dispose();
    _streetAddressCtrl.dispose();
    _streetNumberCtrl.dispose();
    _floorCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMakes() async {
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
      _modelId = null;
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

  VehicleMake? get _selectedMake =>
      _makes.where((x) => x.id == _makeId).firstOrNull;

  VehicleModel? get _selectedModel =>
      _models.where((x) => x.id == _modelId).firstOrNull;

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
      setState(() => _searchHistory = history);
    } catch (e) {
      debugPrint('Failed to load search history: $e');
    }
  }

  Future<void> _addToSearchHistory(SearchHistory entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newHistory = [
        entry,
        ..._searchHistory,
      ].take(_maxSearchHistory).toList();
      final jsonList = newHistory.map((h) => jsonEncode(h.toJson())).toList();
      await prefs.setStringList(_searchHistoryKey, jsonList);
      setState(() => _searchHistory = newHistory);
    } catch (e) {
      debugPrint('Failed to save search history: $e');
    }
  }

  void _restoreFromHistory(SearchHistory entry) {
    _licensePlateCtrl.text = entry.licensePlate;
    // Merge history entry data - don't refetch, just restore UI state
    setState(() {
      final year = entry.year;
      if (year != null) _yearCtrl.text = year.toString();
    });
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      setState(() => _searchHistory = []);
    } catch (e) {
      debugPrint('Failed to clear search history: $e');
    }
  }

  void _showImportLinkDialog() {
    final linkController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Indsæt link fra bilhjemmeside'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Indsæt link fra en bilhandlers hjemmeside (f.eks. DBA, Bilbasen, etc.). '
              'Vi vil forsøge at hente bilens oplysninger automatisk.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/bil/...',
                border: OutlineInputBorder(),
                labelText: 'Link',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () async {
              final url = linkController.text.trim();
              Navigator.pop(context);
              if (url.isNotEmpty) {
                await _importFromLink(url);
              }
            },
            child: const Text('Importér'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromLink(String url) async {
    if (!mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henter biloplysninger fra backend...')),
      );

      // Call backend to parse the URL (avoids CORS issues)
      final parseUrl = Uri.parse(
        '${widget.api.baseUrl}/api/urlparser/parse-listing',
      );
      final response = await http
          .post(
            parseUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Timeout ved hentning af siden'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        await _applyPrefillData(json);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biloplysninger indlæst! Gennemse og opdater efter behov.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = json['error'] ?? 'Ukendt fejl';
        throw Exception(error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyPrefillData(Map<String, dynamic> data) async {
    // Pre-fill all fields with imported data
    if (data.containsKey('licensePlate')) {
      _licensePlateCtrl.text = data['licensePlate'] ?? '';
    }
    if (data.containsKey('price')) {
      _priceCtrl.text = data['price']?.toString() ?? '';
    }
    if (data.containsKey('year')) {
      _yearCtrl.text = data['year']?.toString() ?? '';
    }
    if (data.containsKey('mileage')) {
      _mileageCtrl.text = data['mileage']?.toString() ?? '';
    }
    if (data.containsKey('city')) {
      _cityCtrl.text = data['city'] ?? '';
    }
    if (data.containsKey('title')) {
      _titleCtrl.text = data['title'] ?? '';
    }
    if (data.containsKey('description')) {
      _descCtrl.text = data['description'] ?? '';
    }

    // Try to match make (brand) from catalog
    if (data.containsKey('make')) {
      final makeName = data['make'] as String?;
      if (makeName != null && _makes.isNotEmpty) {
        VehicleMake? matchedMake;
        try {
          matchedMake = _makes.firstWhere(
            (m) =>
                m.name.toLowerCase().contains(makeName.toLowerCase()) ||
                makeName.toLowerCase().contains(m.name.toLowerCase()),
          );
        } catch (e) {
          // No match found
        }

        if (matchedMake != null) {
          final mId = matchedMake.id;
          setState(() => _makeId = mId);
          await _loadModelsForMake(mId);
        }
      }
    }

    // Try to match model after make is selected
    if (data.containsKey('model') && _makeId != null) {
      final modelName = data['model'] as String?;
      if (modelName != null && _models.isNotEmpty) {
        VehicleModel? matchedModel;
        try {
          matchedModel = _models.firstWhere(
            (m) =>
                m.name.toLowerCase().contains(modelName.toLowerCase()) ||
                modelName.toLowerCase().contains(m.name.toLowerCase()),
          );
        } catch (e) {
          // No match found
        }

        if (matchedModel != null) {
          final mId = matchedModel.id;
          setState(() => _modelId = mId);
        }
      }
    }

    if (data.containsKey('fuelType')) {
      final fuel = data['fuelType'] as String?;
      if (fuel != null && _fuelTypeOptions.contains(fuel)) {
        _fuelType = fuel;
      }
    }
    if (data.containsKey('transmission')) {
      final trans = data['transmission'] as String?;
      if (trans != null && _transmissionOptions.contains(trans)) {
        _transmission = trans;
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _showPlateSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Søg nummerpladen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _licensePlateCtrl,
              decoration: const InputDecoration(
                labelText: 'Nummerplade',
                hintText: 'f.eks. AB12345',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Søgningen tager 3-4 sekunder da den trækker data fra det danske motorregister.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _lookupPlateData();
            },
            child: const Text('Søg'),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupPlateData() async {
    final plate = _licensePlateCtrl.text.trim();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vend indtast en nummerplade')),
      );
      return;
    }

    try {
      setState(() => _error = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Søger efter nummerplade...')),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );

      // Call backend API to lookup vehicle
      final uri = Uri.parse(
        '${widget.api.baseUrl}/api/vehicles/plate/$plate',
      ).replace(scheme: 'http', host: 'localhost', port: 5012);

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout ved søgning'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as Map<String, dynamic>?;

        if (data != null) {
          // Find and select make
          final makeName = data['make'] as String?;
          if (makeName != null) {
            final make =
                _makes.firstWhere(
                      (m) => m.name.toLowerCase() == makeName.toLowerCase(),
                      orElse: () => null as dynamic,
                    )
                    as VehicleMake?;
            if (make != null) {
              setState(() => _makeId = make.id);
              await _loadModelsForMake(make.id);

              // Find and select model
              final modelName = data['model'] as String?;
              if (modelName != null) {
                // Wait a bit for models to load
                await Future.delayed(const Duration(milliseconds: 500));
                final model =
                    _models.firstWhere(
                          (m) =>
                              m.name.toLowerCase() == modelName.toLowerCase(),
                          orElse: () => null as dynamic,
                        )
                        as VehicleModel?;
                if (model != null) {
                  setState(() => _modelId = model.id);
                }
              }
            }
          }

          // Auto-fill other fields
          setState(() {
            final year = data['year'];
            if (year != null) _yearCtrl.text = year.toString();

            final km = data['kilometers'];
            if (km != null) _mileageCtrl.text = km.toString();

            final fuel = data['fuelType'];
            if (fuel != null &&
                _fuelTypeOptions.contains(fuel.toString().toLowerCase())) {
              _fuelType = fuel.toString().toLowerCase();
            }

            final trans = data['transmission'];
            if (trans != null) {
              final transLower = trans.toString().toLowerCase();
              if (transLower.contains('auto') ||
                  transLower.contains('automat')) {
                _transmission = 'automat';
              } else if (transLower.contains('manuel') ||
                  transLower.contains('manual')) {
                _transmission = 'manuel';
              }
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Fundet: ${data['make']} ${data['model']}'),
              backgroundColor: Colors.green,
            ),
          );

          // Save to search history
          await _addToSearchHistory(
            SearchHistory(
              licensePlate: plate,
              make: data['make'] as String?,
              model: data['model'] as String?,
              year: (data['year'] as num?)?.toInt(),
              searchedAtUtc: DateTime.now().toUtc(),
            ),
          );
        } else {
          setState(() => _error = 'Bil ikke fundet for nummerplade: $plate');
        }
      } else if (response.statusCode == 404) {
        setState(() => _error = 'Bil ikke fundet for nummerplade: $plate');
      } else {
        setState(() => _error = 'Fejl ved søgning: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Fejl ved søgning: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    final token = widget.api.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Du skal være logget ind for at oprette en annonce.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final make = _selectedMake;
    final model = _selectedModel;

    if (make == null || model == null) {
      setState(() {
        _error = 'Vælg mærke og model.';
      });
      return;
    }

    final price = num.tryParse(_priceCtrl.text.trim());
    if (price == null) {
      setState(() {
        _error = 'Ugyldig pris.';
      });
      return;
    }

    final year = int.tryParse(_yearCtrl.text.trim());
    final mileage = int.tryParse(_mileageCtrl.text.trim());

    setState(() {
      _submitting = true;
      _error = null;
      _uploadStatus = null;
    });

    try {
      // Upload images first (if any) and collect their URLs.
      final imageCreates = <ListingImageCreate>[];
      for (var i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus =
              'Uploader billede ${i + 1} af ${_selectedImages.length}…';
        });
        final url = await widget.api.uploadImage(_selectedImages[i]);
        imageCreates.add(ListingImageCreate(url: url, sortOrder: i));
      }

      if (imageCreates.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Opretter annonce…';
        });
      }

      await widget.api.createListing(
        make: make.name,
        model: model.name,
        priceDkk: price,
        fuelType: _fuelType,
        transmission: _transmission,
        year: _yearCtrl.text.trim().isEmpty ? null : year,
        mileageKm: _mileageCtrl.text.trim().isEmpty ? null : mileage,
        city: _cityCtrl.text,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        sellerPhone: _phoneCtrl.text,
        cvrNumber: _cvrCtrl.text.trim().isEmpty ? null : _cvrCtrl.text.trim(),
        streetAddress: _streetAddressCtrl.text.trim().isEmpty
            ? null
            : _streetAddressCtrl.text.trim(),
        streetNumber: _streetNumberCtrl.text.trim().isEmpty
            ? null
            : _streetNumberCtrl.text.trim(),
        floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
        website: _websiteCtrl.text.trim().isEmpty
            ? null
            : _websiteCtrl.text.trim(),
        images: imageCreates.isEmpty ? null : imageCreates,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Annonce oprettet')));
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sælg din bil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Indsæt link fra bilhjemmeside',
            onPressed: _showImportLinkDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_catalogError != null)
            Text(
              _catalogError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Mærke'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _makeId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Vælg mærke'),
                        ),
                        ..._makes.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        ),
                      ],
                      onChanged: _catalogLoading || _submitting
                          ? null
                          : (v) {
                              setState(() {
                                _makeId = v;
                              });
                              if (v != null) {
                                _loadModelsForMake(v);
                              } else {
                                setState(() {
                                  _models = const <VehicleModel>[];
                                  _modelId = null;
                                });
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Model'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _modelId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Vælg model'),
                        ),
                        ..._models.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text(m.name),
                          ),
                        ),
                      ],
                      onChanged:
                          (_makeId == null) || _catalogLoading || _submitting
                          ? null
                          : (v) {
                              setState(() {
                                _modelId = v;
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // License plate lookup section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Eller søg efter nummerplade',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _licensePlateCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'f.eks. AB12345',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _showPlateSearchDialog(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _showPlateSearchDialog,
                              child: const Text('Søg'),
                            ),
                          ],
                        ),
                        // Search history section
                        if (_searchHistory.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Seneste søgninger',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Slet historik?'),
                                      content: const Text(
                                        'Er du sikker på at du vil slette all søgehistorie?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Annuller'),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            _clearSearchHistory();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Slet'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  'Slet historik',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _searchHistory
                                .map(
                                  (entry) => Material(
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: InkWell(
                                        onTap: () => _restoreFromHistory(entry),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                entry.displayTitle,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                entry.licensePlate,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pris (kr)'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Pris er påkrævet';
                    if (num.tryParse(value) == null) return 'Ugyldig pris';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Årgang'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _mileageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Km'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Brændstof'),
                  isExpanded: true,
                  value: _fuelType,
                  items: _fuelTypeOptions
                      .map(
                        (x) =>
                            DropdownMenuItem<String>(value: x, child: Text(x)),
                      )
                      .toList(growable: false),
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _fuelType = v;
                          });
                        },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gearkasse'),
                  isExpanded: true,
                  value: _transmission,
                  items: _transmissionOptions
                      .map(
                        (x) =>
                            DropdownMenuItem<String>(value: x, child: Text(x)),
                      )
                      .toList(growable: false),
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _transmission = v;
                          });
                        },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'By'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titel'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Beskrivelse'),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefonnummer (vises for købere)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.replaceAll(RegExp(r'[\s\-+()]'), '');
                    if (!RegExp(r'^\d{6,15}$').hasMatch(digits)) {
                      return 'Ugyldigt telefonnummer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Seller Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Forhandlerinfo (frivilligt)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextFormField(
                  controller: _cvrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CVR-nr.',
                    hintText: 'f.eks. 12345678',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                    if (digits.length != 8) {
                      return 'CVR skal være 8 cifre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _streetAddressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gadeadresse',
                    hintText: 'f.eks. Strandvejen',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _streetNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Husnr.',
                          hintText: 'f.eks. 34',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _floorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Etage/enhed',
                          hintText: 'f.eks. st. th.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _websiteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Webadresse',
                    hintText: 'f.eks. https://example.dk',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    try {
                      Uri.parse(v.trim());
                      return null;
                    } catch (e) {
                      return 'Ugyldig webadresse';
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListingImagesPicker(
                  images: _selectedImages,
                  onChanged: (imgs) => setState(() => _selectedImages = imgs),
                  enabled: !_submitting,
                ),
                const SizedBox(height: 12),
                if (_uploadStatus != null) ...[
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_uploadStatus!)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Opretter…' : 'Opret annonce'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final i = iterator;
    if (!i.moveNext()) return null;
    return i.current;
  }
}
