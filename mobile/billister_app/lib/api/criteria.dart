class ListingFilterCriteria {
  final String? q;
  
  // Sale type
  final bool? isLeasing;
  final List<String>? sellerTypes; // "private", "dealer"
  final List<String>? saleTypes; // "commission", "formidling"
  
  // Make / Model
  final String? make;
  final String? model;
  final List<String>? makes;
  final List<String>? models;
  
  // Body type
  final List<String>? bodyTypes;
  
  // Fuel & Transmission
  final List<String>? fuelTypes;
  final List<String>? transmissions;
  
  // Price
  final int? yearMin;
  final int? yearMax;
  final int? firstRegistrationYearMin;
  final int? firstRegistrationYearMax;
  final int? mileageMin;
  final int? mileageMax;
  
  final num? priceMin;
  final num? priceMax;
  
  // Performance
  final int? horsepowerMin;
  final int? horsepowerMax;
  final int? kilowattsMin;
  final int? kilowattsMax;
  final int? rangeMin;
  final int? rangeMax;
  
  // Features
  final bool? hasFourWheelDrive;
  final bool? hasTowHook;
  final List<String>? requiredFeatures;
  
  final String? sortBy;

  const ListingFilterCriteria({
    this.q,
    this.isLeasing,
    this.sellerTypes,
    this.saleTypes,
    this.make,
    this.model,
    this.makes,
    this.models,
    this.bodyTypes,
    this.fuelTypes,
    this.transmissions,
    this.yearMin,
    this.yearMax,
    this.firstRegistrationYearMin,
    this.firstRegistrationYearMax,
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
        isLeasing == null &&
        isEmptyList(sellerTypes) &&
        isEmptyList(saleTypes) &&
        isBlank(make) &&
        isBlank(model) &&
        isEmptyList(makes) &&
        isEmptyList(models) &&
        isEmptyList(bodyTypes) &&
        isEmptyList(fuelTypes) &&
        isEmptyList(transmissions) &&
        yearMin == null &&
        yearMax == null &&
        firstRegistrationYearMin == null &&
        firstRegistrationYearMax == null &&
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

    // Sale type
    if (isLeasing != null) map['isLeasing'] = isLeasing;
    final sellerTypesV = _normalizeList(sellerTypes);
    if (sellerTypesV != null) map['sellerTypes'] = sellerTypesV;
    final saleTypesV = _normalizeList(saleTypes);
    if (saleTypesV != null) map['saleTypes'] = saleTypesV;

    // Make / Model
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

    // Body type
    final bodyTypesV = _normalizeList(bodyTypes);
    if (bodyTypesV != null) map['bodyTypes'] = bodyTypesV;

    // Fuels & Transmission
    final fuels = _normalizeList(fuelTypes);
    if (fuels != null) map['fuelTypes'] = fuels;

    final trans = _normalizeList(transmissions);
    if (trans != null) map['transmissions'] = trans;

    // Year ranges
    if (yearMin != null) map['yearMin'] = yearMin;
    if (yearMax != null) map['yearMax'] = yearMax;
    if (firstRegistrationYearMin != null) map['firstRegistrationYearMin'] = firstRegistrationYearMin;
    if (firstRegistrationYearMax != null) map['firstRegistrationYearMax'] = firstRegistrationYearMax;

    // Mileage
    if (mileageMin != null) map['mileageMin'] = mileageMin;
    if (mileageMax != null) map['mileageMax'] = mileageMax;

    // Price
    if (priceMin != null) map['priceMin'] = priceMin;
    if (priceMax != null) map['priceMax'] = priceMax;

    // Performance
    if (horsepowerMin != null) map['horsepowerMin'] = horsepowerMin;
    if (horsepowerMax != null) map['horsepowerMax'] = horsepowerMax;
    if (kilowattsMin != null) map['kilowattsMin'] = kilowattsMin;
    if (kilowattsMax != null) map['kilowattsMax'] = kilowattsMax;
    if (rangeMin != null) map['rangeMin'] = rangeMin;
    if (rangeMax != null) map['rangeMax'] = rangeMax;

    // Features
    if (hasFourWheelDrive != null) map['hasFourWheelDrive'] = hasFourWheelDrive;
    if (hasTowHook != null) map['hasTowHook'] = hasTowHook;
    final features = _normalizeList(requiredFeatures);
    if (features != null) map['requiredFeatures'] = features;

    // Sorting
    if (sortBy != null && sortBy!.isNotEmpty) map['sortBy'] = sortBy;

    return map;
  }
}
