import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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

  bool _submitting = false;
  String? _error;
  String? _uploadStatus;

  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadMakes();
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
      appBar: AppBar(title: const Text('Sælg din bil')),
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
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Brændstof'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _fuelType,
                      items: _fuelTypeOptions
                          .map(
                            (x) => DropdownMenuItem<String>(
                              value: x,
                              child: Text(x),
                            ),
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
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Gearkasse'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _transmission,
                      items: _transmissionOptions
                          .map(
                            (x) => DropdownMenuItem<String>(
                              value: x,
                              child: Text(x),
                            ),
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
                  ),
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
