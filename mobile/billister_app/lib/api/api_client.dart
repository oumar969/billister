import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'criteria.dart';
import 'models.dart';

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
    } on SocketException {
      throw ApiException(
        'Kan ikke forbinde til serveren ($baseUrl). Start backenden og prøv igen.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Netværksfejl: ${e.message}');
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

  void dispose() {
    _http.close();
  }
}
