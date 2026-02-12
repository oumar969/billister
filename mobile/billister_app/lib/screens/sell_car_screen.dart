import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';

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

  final _priceCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _yearCtrl.dispose();
    _mileageCtrl.dispose();
    _cityCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
    });

    try {
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
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
