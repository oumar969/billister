class User {
  final String id;
  final String email;
  final String username;
  final List<String> roles;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      roles: List<String>.from((json['roles'] as List<dynamic>?) ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'roles': roles,
  };

  bool get isAdmin => roles.contains('Admin');
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final User user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

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

/// Lightweight DTO used when submitting images as part of a new/updated listing.
class ListingImageCreate {
  final String url;
  final int sortOrder;

  const ListingImageCreate({required this.url, required this.sortOrder});

  Map<String, dynamic> toJson() => {'url': url, 'sortOrder': sortOrder};
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
  final int viewCount;
  final int favoriteCount;
  final bool isSold;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;
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
    required this.viewCount,
    required this.favoriteCount,
    required this.isSold,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.images,
  });

  factory ListingSummary.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as List<dynamic>?;

    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String) {
        return DateTime.tryParse(v);
      }
      return null;
    }

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
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      isSold: (json['isSold'] as bool?) ?? false,
      createdAtUtc: tryDate('createdAtUtc'),
      updatedAtUtc: tryDate('updatedAtUtc'),
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

class SellerInquirySummary {
  final String listingId;
  final int threadCount;
  final DateTime? lastInquiryAtUtc;

  const SellerInquirySummary({
    required this.listingId,
    required this.threadCount,
    required this.lastInquiryAtUtc,
  });

  factory SellerInquirySummary.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return SellerInquirySummary(
      listingId: (json['listingId'] as String?) ?? '',
      threadCount: (json['threadCount'] as num?)?.toInt() ?? 0,
      lastInquiryAtUtc: tryDate('lastInquiryAtUtc'),
    );
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
  final String sellerId;
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
  final String? sellerPhone;
  final List<String> features;
  final Map<String, dynamic> extraAttributes;
  final int viewCount;
  final int favoriteCount;
  final bool isSold;
  final List<ListingImage> images;

  const ListingDetails({
    required this.id,
    required this.sellerId,
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
    required this.sellerPhone,
    required this.features,
    required this.extraAttributes,
    required this.viewCount,
    required this.favoriteCount,
    required this.isSold,
    required this.images,
  });

  factory ListingDetails.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as List<dynamic>?;
    final extraJson = json['extraAttributes'] as Map<String, dynamic>?;
    final imagesJson = json['images'] as List<dynamic>?;

    return ListingDetails(
      id: json['id'] as String,
      sellerId: json['sellerUserId'] as String? ?? '',
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
      sellerPhone: json['sellerPhone'] as String?,
      features:
          featuresJson?.map((e) => e.toString()).toList() ?? const <String>[],
      extraAttributes: extraJson ?? const <String, dynamic>{},
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      isSold: (json['isSold'] as bool?) ?? false,
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

class SavedSearch {
  final String id;
  final String name;
  final String criteriaJson;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.criteriaJson,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return SavedSearch(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      criteriaJson: (json['criteriaJson'] as String?) ?? '{}',
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAtUtc: tryDate('updatedAtUtc'),
    );
  }
}

class SearchNotification {
  final String id;
  final String savedSearchId;
  final String? savedSearchName;
  final String listingId;
  final String title;
  final String body;
  final DateTime createdAtUtc;

  const SearchNotification({
    required this.id,
    required this.savedSearchId,
    required this.savedSearchName,
    required this.listingId,
    required this.title,
    required this.body,
    required this.createdAtUtc,
  });

  factory SearchNotification.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return SearchNotification(
      id: json['id'] as String,
      savedSearchId: json['savedSearchId'] as String,
      savedSearchName: json['savedSearchName'] as String?,
      listingId: json['listingId'] as String,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class Review {
  final String id;
  final String listingId;
  final String buyerUserId;
  final String buyerUsername;
  final int rating; // 1-5
  final String? title;
  final String? comment;
  final DateTime createdAtUtc;

  const Review({
    required this.id,
    required this.listingId,
    required this.buyerUserId,
    required this.buyerUsername,
    required this.rating,
    this.title,
    this.comment,
    required this.createdAtUtc,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Review(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      buyerUserId: json['buyerUserId'] as String,
      buyerUsername: (json['buyerUsername'] as String?) ?? 'Anonym',
      rating: (json['rating'] as num).toInt(),
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SellerRating {
  final String sellerId;
  final int totalReviews;
  final double averageRating;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  const SellerRating({
    required this.sellerId,
    required this.totalReviews,
    required this.averageRating,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  factory SellerRating.fromJson(Map<String, dynamic> json) {
    return SellerRating(
      sellerId: json['sellerId'] as String,
      totalReviews: (json['totalReviews'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      fiveStarCount: (json['fiveStarCount'] as num).toInt(),
      fourStarCount: (json['fourStarCount'] as num).toInt(),
      threeStarCount: (json['threeStarCount'] as num).toInt(),
      twoStarCount: (json['twoStarCount'] as num).toInt(),
      oneStarCount: (json['oneStarCount'] as num).toInt(),
    );
  }
}

class Order {
  final String id;
  final String listingId;
  final String status; // pending, paid, shipped, completed
  final double amount;
  final DateTime createdAtUtc;
  final DateTime? paidAtUtc;
  final DateTime? updatedAtUtc;

  const Order({
    required this.id,
    required this.listingId,
    required this.status,
    required this.amount,
    required this.createdAtUtc,
    this.paidAtUtc,
    this.updatedAtUtc,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Order(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num).toDouble(),
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
      paidAtUtc: tryDate('paidAtUtc'),
      updatedAtUtc: tryDate('updatedAtUtc'),
    );
  }

  String get statusDanish {
    switch (status) {
      case 'pending':
        return 'Afventer betaling';
      case 'paid':
        return 'Betalt';
      case 'shipped':
        return 'Sendt';
      case 'completed':
        return 'Afsluttet';
      case 'cancelled':
        return 'Annulleret';
      default:
        return status;
    }
  }
}

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String status; // pending, processing, succeeded, failed
  final String provider; // stripe, mobilepay, etc
  final DateTime createdAtUtc;
  final DateTime? completedAtUtc;
  final String? stripe_clientSecret; // For Stripe PaymentIntent
  final String? stripe_paymentIntentId; // For Stripe PaymentIntent ID

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.provider,
    required this.createdAtUtc,
    this.completedAtUtc,
    this.stripe_clientSecret,
    this.stripe_paymentIntentId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return Payment(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      provider: json['provider'] as String? ?? 'stripe',
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
      completedAtUtc: tryDate('completedAtUtc'),
      stripe_clientSecret: json['clientSecret'] as String?,
      stripe_paymentIntentId: json['stripePaymentIntentId'] as String?,
    );
  }

  String get statusDanish {
    switch (status) {
      case 'pending':
        return 'Afventer';
      case 'processing':
        return 'Behandler';
      case 'succeeded':
        return 'Godkendt';
      default:
        return status;
    }
  }
}

class ChatThread {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final DateTime createdAtUtc;

  const ChatThread({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.createdAtUtc,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return ChatThread(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChatMessage {
  final String id;
  final String chatThreadId;
  final String senderId;
  final String senderUsername;
  final String content;
  final bool isRead;
  final DateTime createdAtUtc;
  final DateTime? readAtUtc;

  const ChatMessage({
    required this.id,
    required this.chatThreadId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.isRead,
    required this.createdAtUtc,
    this.readAtUtc,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? tryDate(String key) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return ChatMessage(
      id: json['id'] as String,
      chatThreadId: json['chatThreadId'] as String,
      senderId: json['senderId'] as String,
      senderUsername: (json['senderUsername'] as String?) ?? 'Ukendt',
      content: (json['content'] as String?) ?? '',
      isRead: (json['isRead'] as bool?) ?? false,
      createdAtUtc:
          tryDate('createdAtUtc') ?? DateTime.fromMillisecondsSinceEpoch(0),
      readAtUtc: tryDate('readAtUtc'),
    );
  }
}
