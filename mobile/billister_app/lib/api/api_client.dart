import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import 'criteria.dart';
import 'models.dart';
import 'io_shim.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'ApiException: $message'
      : 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  static const Duration _requestTimeout = Duration(seconds: 8);

  String? token;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Future<http.Response> _send(Future<http.Response> Function() fn) async {
    try {
      return await fn().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'Forbindelsen til serveren tog for lang tid ($baseUrl). Er backenden startet?',
      );
    } catch (e) {
      if (isSocketException(e)) {
        throw ApiException(
          'Kan ikke forbinde til serveren ($baseUrl). Start backenden og prøv igen.',
        );
      }

      if (e is http.ClientException) {
        throw ApiException('Netværksfejl: ${e.message}');
      }

      throw ApiException('Netværksfejl: $e');
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final full = '$normalizedBase$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _jsonHeaders({bool includeAuth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/auth/login'),
        headers: _jsonHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final t = json['token'] as String?;
      if (t == null || t.isEmpty) {
        throw const ApiException('Login response missing token');
      }
      token = t;
      return t;
    }

    if (res.statusCode == 401) {
      throw const ApiException(
        'Unauthorized: wrong email/password',
        statusCode: 401,
      );
    }

    throw ApiException(
      'Login failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<ListingsPage> fetchListings({int page = 1, int pageSize = 20}) async {
    final res = await _send(
      () => _http.get(
        _uri('/api/listings', {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        }),
        headers: _jsonHeaders(),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ListingsPage.fromJson(json);
    }

    throw ApiException(
      'Fetch listings failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<ListingsPage> searchListings({
    required ListingFilterCriteria criteria,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/listings/search'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'page': page,
          'pageSize': pageSize,
          'criteria': criteria.toJson(),
        }),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ListingsPage.fromJson(json);
    }

    throw ApiException(
      'Search listings failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<ListingDetails> fetchListingDetails(String id) async {
    final res = await _send(
      () => _http.get(_uri('/api/listings/$id'), headers: _jsonHeaders()),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ListingDetails.fromJson(json);
    }

    if (res.statusCode == 404) {
      throw const ApiException('Listing not found', statusCode: 404);
    }

    throw ApiException(
      'Fetch listing failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<List<FavoriteListing>> fetchFavorites() async {
    final res = await _send(
      () => _http.get(
        _uri('/api/favorites'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>?;
      if (items == null) return const <FavoriteListing>[];

      return items
          .map((e) => FavoriteListing.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Fetch favorites failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> addFavorite(String listingId) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/favorites/$listingId'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 404) {
      throw const ApiException('Listing not found', statusCode: 404);
    }
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Add favorite failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> removeFavorite(String listingId) async {
    final res = await _send(
      () => _http.delete(
        _uri('/api/favorites/$listingId'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Remove favorite failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<List<VehicleMake>> fetchVehicleMakes() async {
    final res = await _send(
      () => _http.get(_uri('/api/vehicles/makes'), headers: _jsonHeaders()),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as List<dynamic>;
      return json
          .map((e) => VehicleMake.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    throw ApiException(
      'Fetch vehicle makes failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<List<VehicleModel>> fetchVehicleModels(String makeId) async {
    final res = await _send(
      () => _http.get(
        _uri('/api/vehicles/makes/$makeId/models'),
        headers: _jsonHeaders(),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as List<dynamic>;
      return json
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    throw ApiException(
      'Fetch vehicle models failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<ListingsPage> fetchMyListings({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _send(
      () => _http.get(
        _uri('/api/listings/mine', {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        }),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ListingsPage.fromJson(json);
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Fetch my listings failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<List<SellerInquirySummary>> fetchSellerInquiries() async {
    final res = await _send(
      () => _http.get(
        _uri('/api/chats/seller-inquiries'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>?;
      if (items == null) return const <SellerInquirySummary>[];
      return items
          .map((e) => SellerInquirySummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Fetch inquiries failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> updateListing(
    String listingId, {
    num? priceDkk,
    int? mileageKm,
    String? title,
    String? description,
    bool? isSold,
  }) async {
    final res = await _send(
      () => _http.patch(
        _uri('/api/listings/$listingId'),
        headers: _jsonHeaders(includeAuth: true),
        body: jsonEncode({
          if (priceDkk != null) 'priceDkk': priceDkk,
          if (mileageKm != null) 'mileageKm': mileageKm,
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (isSold != null) 'isSold': isSold,
        }),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw const ApiException('Forbidden', statusCode: 403);
    }
    if (res.statusCode == 404) {
      throw const ApiException('Listing not found', statusCode: 404);
    }

    throw ApiException(
      'Update listing failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> deleteListing(String listingId) async {
    final res = await _send(
      () => _http.delete(
        _uri('/api/listings/$listingId'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }
    if (res.statusCode == 403) {
      throw const ApiException('Forbidden', statusCode: 403);
    }
    if (res.statusCode == 404) {
      throw const ApiException('Listing not found', statusCode: 404);
    }

    throw ApiException(
      'Delete listing failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<String> createListing({
    required String make,
    required String model,
    required num priceDkk,
    required String fuelType,
    required String transmission,
    int? year,
    int? mileageKm,
    String? city,
    String? title,
    String? description,
    String? sellerPhone,
    List<ListingImageCreate>? images,
  }) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/listings'),
        headers: _jsonHeaders(includeAuth: true),
        body: jsonEncode({
          'make': make,
          'model': model,
          'priceDkk': priceDkk,
          'fuelType': fuelType,
          'transmission': transmission,
          'year': year,
          'mileageKm': mileageKm,
          'city': (city == null || city.trim().isEmpty) ? null : city.trim(),
          'title': (title == null || title.trim().isEmpty)
              ? null
              : title.trim(),
          'description': (description == null || description.trim().isEmpty)
              ? null
              : description.trim(),
          'sellerPhone': (sellerPhone == null || sellerPhone.trim().isEmpty)
              ? null
              : sellerPhone.trim().replaceAll(RegExp(r'[^\d+\-\s()]'), ''),
          'images': images?.map((img) => img.toJson()).toList(),
        }),
      ),
    );

    if (res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) {
        throw const ApiException('Create listing response missing id');
      }
      return id;
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Create listing failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  /// Uploads a single image file to the server and returns its public URL.
  ///
  /// A longer timeout (60 s) is used because image transfers can be slow on
  /// mobile networks.
  Future<String> uploadImage(XFile imageFile) async {
    final request = http.MultipartRequest('POST', _uri('/api/images/upload'));

    if (token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // `MultipartFile.fromPath` relies on `dart:io` and fails on Flutter Web.
    // Using bytes works cross-platform (web + mobile + desktop).
    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      throw const ApiException('Billedfilen er tom');
    }

    MediaType inferMediaType() {
      final name = imageFile.name.trim().toLowerCase();
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        return MediaType('image', 'jpeg');
      }
      if (name.endsWith('.png')) return MediaType('image', 'png');
      if (name.endsWith('.webp')) return MediaType('image', 'webp');
      if (name.endsWith('.heic')) return MediaType('image', 'heic');
      if (name.endsWith('.heif')) return MediaType('image', 'heif');

      // Fall back to sniffing common signatures.
      if (bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return MediaType('image', 'jpeg');
      }
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A) {
        return MediaType('image', 'png');
      }
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return MediaType('image', 'webp');
      }

      return MediaType('image', 'jpeg');
    }

    String defaultFilenameFor(MediaType ct) {
      final subtype = ct.subtype.toLowerCase();
      return switch (subtype) {
        'png' => 'image.png',
        'webp' => 'image.webp',
        'heic' => 'image.heic',
        'heif' => 'image.heif',
        _ => 'image.jpg',
      };
    }

    final contentType = inferMediaType();
    final originalName = imageFile.name.trim();
    final filename = originalName.isEmpty
        ? defaultFilenameFor(contentType)
        : originalName;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    try {
      final streamed = await _http
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final url = json['url'] as String?;
        if (url == null || url.isEmpty) {
          throw const ApiException('Upload response missing url');
        }
        return url;
      }

      if (response.statusCode == 401) {
        throw const ApiException('Unauthorized', statusCode: 401);
      }

      if (response.statusCode == 400) {
        String? error;
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          error = (json['error'] as String?)?.trim();
        } catch (_) {
          error = null;
        }

        if (error != null && error.isNotEmpty) {
          throw ApiException('Billedupload fejlede: $error', statusCode: 400);
        }
      }

      throw ApiException(
        'Billedupload fejlede (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException(
        'Billedupload tog for lang tid. Prøv igen eller tjek din forbindelse.',
      );
    } catch (e) {
      if (isSocketException(e)) {
        throw ApiException(
          'Kan ikke forbinde til serveren ($baseUrl). Start backenden og prøv igen.',
        );
      }
      if (e is http.ClientException) {
        throw ApiException('Netværksfejl: ${e.message}');
      }
      rethrow;
    }
  }

  void dispose() {
    _http.close();
  }

  Future<List<SavedSearch>> fetchSavedSearches() async {
    final res = await _send(
      () => _http.get(
        _uri('/api/saved-searches'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>?;
      if (items == null) return const <SavedSearch>[];

      return items
          .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Fetch saved searches failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<String> createSavedSearch({
    required String name,
    required String criteriaJson,
  }) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/saved-searches'),
        headers: _jsonHeaders(includeAuth: true),
        body: jsonEncode({'name': name, 'criteriaJson': criteriaJson}),
      ),
    );

    if (res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) {
        throw const ApiException('Create saved search response missing id');
      }
      return id;
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Create saved search failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<String> createSavedSearchFromCriteria({
    required String name,
    required ListingFilterCriteria criteria,
  }) async {
    final res = await _send(
      () => _http.post(
        _uri('/api/saved-searches/from-criteria'),
        headers: _jsonHeaders(includeAuth: true),
        body: jsonEncode({'name': name, 'criteria': criteria.toJson()}),
      ),
    );

    if (res.statusCode == 201) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final id = json['id'] as String?;
      if (id == null || id.isEmpty) {
        throw const ApiException('Create saved search response missing id');
      }
      return id;
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Create saved search failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<List<SearchNotification>> fetchNotifications() async {
    final res = await _send(
      () => _http.get(
        _uri('/api/notifications'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>?;
      if (items == null) return const <SearchNotification>[];

      return items
          .map((e) => SearchNotification.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Fetch notifications failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> deleteNotification(String id) async {
    final res = await _send(
      () => _http.delete(
        _uri('/api/notifications/$id'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Delete notification failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> clearNotifications() async {
    final res = await _send(
      () => _http.delete(
        _uri('/api/notifications'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Clear notifications failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }

  Future<void> deleteSavedSearch(String id) async {
    final res = await _send(
      () => _http.delete(
        _uri('/api/saved-searches/$id'),
        headers: _jsonHeaders(includeAuth: true),
      ),
    );

    if (res.statusCode == 204) return;
    if (res.statusCode == 401) {
      throw const ApiException('Unauthorized', statusCode: 401);
    }

    throw ApiException(
      'Delete saved search failed (${res.statusCode})',
      statusCode: res.statusCode,
    );
  }
}
