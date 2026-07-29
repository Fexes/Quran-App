import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../library/data/stores/library_user_data_store.dart';
import '../../domain/entities/mosque_place.dart';
import '../../domain/repositories/mosque_locator_repository.dart';

class OpenStreetMapMosqueRepository implements MosqueLocatorRepository {
  const OpenStreetMapMosqueRepository({
    required LibraryUserDataStore userDataStore,
  }) : _userDataStore = userDataStore;

  static const _cacheDuration = Duration(hours: 24);
  static const _maxResults = 50;

  final LibraryUserDataStore _userDataStore;

  @override
  Future<List<MosquePlace>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    bool refresh = false,
  }) async {
    final radius = radiusMeters.clamp(1000, 15000);
    final cacheKey = _cacheKey(latitude, longitude, radius);
    if (!refresh) {
      final cached = _readCache(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    final query =
        '''[out:json][timeout:20];(
node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$latitude,$longitude);
);out center $_maxResults;''';
    final uri = Uri.https('overpass-api.de', '/api/interpreter', {
      'data': query,
    });
    final client = HttpClient()..userAgent = 'QuranApp/1.0 mosque-locator';
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'OpenStreetMap search returned ${response.statusCode}.',
        );
      }
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = <MosquePlace>[];
      for (final raw in json['elements'] as List? ?? const []) {
        final item = Map<String, dynamic>.from(raw as Map);
        final center = item['center'] is Map
            ? Map<String, dynamic>.from(item['center'] as Map)
            : item;
        final lat = (center['lat'] as num?)?.toDouble();
        final lon = (center['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) {
          continue;
        }
        final tags = item['tags'] is Map
            ? Map<String, dynamic>.from(item['tags'] as Map)
            : const <String, dynamic>{};
        results.add(
          MosquePlace(
            id: '${item['type']}:${item['id']}',
            name:
                tags['name:en'] as String? ??
                tags['name'] as String? ??
                'Unnamed mosque',
            latitude: lat,
            longitude: lon,
            distanceMeters: _distance(latitude, longitude, lat, lon),
          ),
        );
      }
      results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      final limited = results.take(_maxResults).toList(growable: false);
      await _userDataStore.saveNote(
        cacheKey,
        jsonEncode({
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'results': limited.map((item) => item.toJson()).toList(),
        }),
      );
      return limited;
    } finally {
      client.close(force: true);
    }
  }

  List<MosquePlace>? _readCache(String cacheKey) {
    final raw = _userDataStore.noteFor(cacheKey);
    if (raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
      if (createdAt == null ||
          DateTime.now().toUtc().difference(createdAt) > _cacheDuration) {
        return null;
      }
      return [
        for (final item in json['results'] as List? ?? const [])
          MosquePlace.fromJson(item as Map),
      ];
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(double latitude, double longitude, int radius) {
    return 'mosque-cache:${latitude.toStringAsFixed(2)}:'
        '${longitude.toStringAsFixed(2)}:$radius';
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    double radians(double degrees) => degrees * pi / 180;
    final dLat = radians(lat2 - lat1);
    final dLon = radians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
