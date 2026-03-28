class ListingFilterCriteria {
  final String? q;
  final String? make;
  final String? model;

  final List<String>? makes;
  final List<String>? models;

  final List<String>? fuelTypes;
  final List<String>? transmissions;

  final int? yearMin;
  final int? yearMax;

  final int? mileageMin;
  final int? mileageMax;

  final num? priceMin;
  final num? priceMax;

  final int? horsepowerMin;
  final int? horsepowerMax;

  final int? kilowattsMin;
  final int? kilowattsMax;

  final int? rangeMin;
  final int? rangeMax;

  final bool? hasFourWheelDrive;
  final bool? hasTowHook;

  final List<String>? requiredFeatures;

  // Sorting: newest (default), price_asc, price_desc, mileage_asc, mileage_desc, year_desc, year_asc
  final String? sortBy;

  const ListingFilterCriteria({
    this.q,
    this.make,
    this.model,
    this.makes,
    this.models,
    this.fuelTypes,
    this.transmissions,
    this.yearMin,
    this.yearMax,
    this.mileageMin,
    this.mileageMax,
    this.priceMin,
    this.priceMax,
    this.horsepowerMin,
    this.horsepowerMax,
    this.kilowattsMin,
    this.kilowattsMax,
    this.rangeMin,
    this.rangeMax,
    this.hasFourWheelDrive,
    this.hasTowHook,
    this.requiredFeatures,
    this.sortBy,
  });

  bool get isEmpty {
    bool isBlank(String? s) => s == null || s.trim().isEmpty;
    bool isEmptyList(List<dynamic>? l) => l == null || l.isEmpty;

    return isBlank(q) &&
        isBlank(make) &&
        isBlank(model) &&
        isEmptyList(makes) &&
        isEmptyList(models) &&
        isEmptyList(fuelTypes) &&
        isEmptyList(transmissions) &&
        yearMin == null &&
        yearMax == null &&
        mileageMin == null &&
        mileageMax == null &&
        priceMin == null &&
        priceMax == null &&
        horsepowerMin == null &&
        horsepowerMax == null &&
        kilowattsMin == null &&
        kilowattsMax == null &&
        rangeMin == null &&
        rangeMax == null &&
        hasFourWheelDrive == null &&
        hasTowHook == null &&
        isEmptyList(requiredFeatures) &&
        isBlank(sortBy);
  }

  static List<String>? _normalizeList(List<String>? values) {
    if (values == null) return null;

    final cleaned = values
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toSet()
        .toList();

    if (cleaned.isEmpty) return null;
    cleaned.sort();
    return cleaned;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    final qv = q?.trim();
    if (qv != null && qv.isNotEmpty) map['q'] = qv;

    final makesv = _normalizeList(makes);
    if (makesv != null) {
      map['makes'] = makesv;
    } else {
      final makev = make?.trim();
      if (makev != null && makev.isNotEmpty) map['makes'] = [makev];
    }

    final modelsV = _normalizeList(models);
    if (modelsV != null) {
      map['models'] = modelsV;
    } else {
      final modelv = model?.trim();
      if (modelv != null && modelv.isNotEmpty) map['models'] = [modelv];
    }

    final fuels = _normalizeList(fuelTypes);
    if (fuels != null) map['fuelTypes'] = fuels;

    final trans = _normalizeList(transmissions);
    if (trans != null) map['transmissions'] = trans;

    if (yearMin != null) map['yearMin'] = yearMin;
    if (yearMax != null) map['yearMax'] = yearMax;

    if (mileageMin != null) map['mileageMin'] = mileageMin;
    if (mileageMax != null) map['mileageMax'] = mileageMax;

    if (priceMin != null) map['priceMin'] = priceMin;
    if (priceMax != null) map['priceMax'] = priceMax;

    if (horsepowerMin != null) map['horsepowerMin'] = horsepowerMin;
    if (horsepowerMax != null) map['horsepowerMax'] = horsepowerMax;

    if (kilowattsMin != null) map['kilowattsMin'] = kilowattsMin;
    if (kilowattsMax != null) map['kilowattsMax'] = kilowattsMax;

    if (rangeMin != null) map['rangeMin'] = rangeMin;
    if (rangeMax != null) map['rangeMax'] = rangeMax;

    if (hasFourWheelDrive != null) map['hasFourWheelDrive'] = hasFourWheelDrive;
    if (hasTowHook != null) map['hasTowHook'] = hasTowHook;

    final features = _normalizeList(requiredFeatures);
    if (features != null) map['requiredFeatures'] = features;

    if (sortBy != null) map['sortBy'] = sortBy;

    return map;
  }
}
