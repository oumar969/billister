class ListingImage {
  final String url;
  final int sortOrder;
  final int? width;
  final int? height;

  const ListingImage({
    required this.url,
    required this.sortOrder,
    this.width,
    this.height,
  });

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      url: json['url'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }
}

class ListingSummary {
  final String id;
  final String make;
  final String model;
  final String? variant;
  final num priceDkk;
  final int? year;
  final int? mileageKm;
  final String fuelType;
  final String transmission;
  final int? electricRangeKm;
  final String? city;
  final List<ListingImage> images;

  const ListingSummary({
    required this.id,
    required this.make,
    required this.model,
    required this.variant,
    required this.priceDkk,
    required this.year,
    required this.mileageKm,
    required this.fuelType,
    required this.transmission,
    required this.electricRangeKm,
    required this.city,
    required this.images,
  });

  factory ListingSummary.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as List<dynamic>?;

    return ListingSummary(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      variant: json['variant'] as String?,
      priceDkk: json['priceDkk'] as num,
      year: (json['year'] as num?)?.toInt(),
      mileageKm: (json['mileageKm'] as num?)?.toInt(),
      fuelType: (json['fuelType'] as String?) ?? '',
      transmission: (json['transmission'] as String?) ?? '',
      electricRangeKm: (json['electricRangeKm'] as num?)?.toInt(),
      city: json['city'] as String?,
      images:
          imagesJson
              ?.map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ListingImage>[],
    );
  }

  String get title {
    final v = variant;
    if (v == null || v.trim().isEmpty) return '$make $model';
    return '$make $model $v';
  }
}

class ListingsPage {
  final int total;
  final int page;
  final int pageSize;
  final List<ListingSummary> items;

  const ListingsPage({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  factory ListingsPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;

    return ListingsPage(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      items:
          itemsJson
              ?.map((e) => ListingSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ListingSummary>[],
    );
  }
}

class ListingDetails {
  final String id;
  final String make;
  final String model;
  final String? variant;
  final num priceDkk;
  final String fuelType;
  final String transmission;
  final int? year;
  final int? mileageKm;
  final int? electricRangeKm;
  final num? batteryKwh;
  final bool? isPlugInHybrid;
  final String? bodyType;
  final String? color;
  final int? doors;
  final int? seats;
  final int? horsepower;
  final int? kilowatts;
  final num? engineLiters;
  final int? cylinders;
  final bool? hasTowHook;
  final bool? hasFourWheelDrive;
  final String? postalCode;
  final String? city;
  final String? title;
  final String? description;
  final List<String> features;
  final Map<String, dynamic> extraAttributes;
  final int viewCount;
  final int favoriteCount;
  final List<ListingImage> images;

  const ListingDetails({
    required this.id,
    required this.make,
    required this.model,
    required this.variant,
    required this.priceDkk,
    required this.fuelType,
    required this.transmission,
    required this.year,
    required this.mileageKm,
    required this.electricRangeKm,
    required this.batteryKwh,
    required this.isPlugInHybrid,
    required this.bodyType,
    required this.color,
    required this.doors,
    required this.seats,
    required this.horsepower,
    required this.kilowatts,
    required this.engineLiters,
    required this.cylinders,
    required this.hasTowHook,
    required this.hasFourWheelDrive,
    required this.postalCode,
    required this.city,
    required this.title,
    required this.description,
    required this.features,
    required this.extraAttributes,
    required this.viewCount,
    required this.favoriteCount,
    required this.images,
  });

  factory ListingDetails.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as List<dynamic>?;
    final extraJson = json['extraAttributes'] as Map<String, dynamic>?;
    final imagesJson = json['images'] as List<dynamic>?;

    return ListingDetails(
      id: json['id'] as String,
      make: (json['make'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      variant: json['variant'] as String?,
      priceDkk: (json['priceDkk'] as num?) ?? 0,
      fuelType: (json['fuelType'] as String?) ?? '',
      transmission: (json['transmission'] as String?) ?? '',
      year: (json['year'] as num?)?.toInt(),
      mileageKm: (json['mileageKm'] as num?)?.toInt(),
      electricRangeKm: (json['electricRangeKm'] as num?)?.toInt(),
      batteryKwh: json['batteryKwh'] as num?,
      isPlugInHybrid: json['isPlugInHybrid'] as bool?,
      bodyType: json['bodyType'] as String?,
      color: json['color'] as String?,
      doors: (json['doors'] as num?)?.toInt(),
      seats: (json['seats'] as num?)?.toInt(),
      horsepower: (json['horsepower'] as num?)?.toInt(),
      kilowatts: (json['kilowatts'] as num?)?.toInt(),
      engineLiters: json['engineLiters'] as num?,
      cylinders: (json['cylinders'] as num?)?.toInt(),
      hasTowHook: json['hasTowHook'] as bool?,
      hasFourWheelDrive: json['hasFourWheelDrive'] as bool?,
      postalCode: json['postalCode'] as String?,
      city: json['city'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      features:
          featuresJson?.map((e) => e.toString()).toList() ?? const <String>[],
      extraAttributes: extraJson ?? const <String, dynamic>{},
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      images:
          imagesJson
              ?.map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ListingImage>[],
    );
  }

  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;

    final v = variant;
    if (v == null || v.trim().isEmpty) return '$make $model';
    return '$make $model $v';
  }
}

class FavoriteListing {
  final String id;
  final String make;
  final String model;
  final String? variant;
  final num priceDkk;
  final String fuelType;
  final String transmission;
  final int? year;
  final int? mileageKm;
  final DateTime? createdAtUtc;
  final DateTime? favoritedAtUtc;

  const FavoriteListing({
    required this.id,
    required this.make,
    required this.model,
    required this.variant,
    required this.priceDkk,
    required this.fuelType,
    required this.transmission,
    required this.year,
    required this.mileageKm,
    required this.createdAtUtc,
    required this.favoritedAtUtc,
  });

  factory FavoriteListing.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return FavoriteListing(
      id: json['id'] as String,
      make: (json['make'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      variant: json['variant'] as String?,
      priceDkk: (json['priceDkk'] as num?) ?? 0,
      fuelType: (json['fuelType'] as String?) ?? '',
      transmission: (json['transmission'] as String?) ?? '',
      year: (json['year'] as num?)?.toInt(),
      mileageKm: (json['mileageKm'] as num?)?.toInt(),
      createdAtUtc: tryDate('createdAtUtc'),
      favoritedAtUtc: tryDate('favoritedAtUtc'),
    );
  }

  String get title {
    final v = variant;
    if (v == null || v.trim().isEmpty) return '$make $model';
    return '$make $model $v';
  }
}

class VehicleMake {
  final String id;
  final String name;

  const VehicleMake({required this.id, required this.name});

  factory VehicleMake.fromJson(Map<String, dynamic> json) {
    return VehicleMake(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class VehicleModel {
  final String id;
  final String makeId;
  final String name;

  const VehicleModel({
    required this.id,
    required this.makeId,
    required this.name,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      makeId: json['makeId'] as String,
      name: (json['name'] as String?) ?? '',
    );
  }
}
