import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../../prayer_times/domain/entities/prayer_location.dart';

class OfflinePrayerCityDataSource {
  OfflinePrayerCityDataSource({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;
  Future<List<OfflinePrayerCity>>? _citiesFuture;

  static const _assetPath = 'assets/data/cities15000.tsv.gz';
  static const _featuredNames = [
    'Makkah',
    'Madinah',
    'Jerusalem',
    'Istanbul',
    'Cairo',
    'Dubai',
    'Jakarta',
    'Kuala Lumpur',
    'Dhaka',
    'London',
    'New York',
    'Toronto',
    'Paris',
    'Berlin',
    'Sydney',
    'Lagos',
  ];

  Future<List<OfflinePrayerCity>> search(String query, {int limit = 40}) async {
    final cities = await _loadCities();
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return _featuredCities(cities, limit: limit);
    }

    final matches = <_CitySearchResult>[];
    for (final city in cities) {
      final score = city.score(normalized);
      if (score == null) {
        continue;
      }
      matches.add(_CitySearchResult(city, score));
    }

    matches.sort((a, b) {
      final scoreCompare = a.score.compareTo(b.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return b.city.population.compareTo(a.city.population);
    });

    return matches.take(limit).map((match) => match.city).toList();
  }

  Future<OfflinePrayerCity?> nearest(double latitude, double longitude) async {
    final cities = await _loadCities();
    if (cities.isEmpty) {
      return null;
    }

    OfflinePrayerCity? nearestCity;
    var nearestDistance = double.infinity;
    for (final city in cities) {
      final distance = _distanceKm(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestCity = city;
      }
    }
    return nearestCity;
  }

  Future<List<OfflinePrayerCity>> _loadCities() {
    return _citiesFuture ??= _readCities();
  }

  Future<List<OfflinePrayerCity>> _readCities() async {
    final data = await _assetBundle.load(_assetPath);
    final text = utf8.decode(gzip.decode(data.buffer.asUint8List()));
    final cities = <OfflinePrayerCity>[];

    for (final line in const LineSplitter().convert(text)) {
      if (line.trim().isEmpty) {
        continue;
      }
      final fields = line.split('\t');
      if (fields.length < 8) {
        continue;
      }
      final latitude = double.tryParse(fields[4]);
      final longitude = double.tryParse(fields[5]);
      final population = int.tryParse(fields[7]) ?? 0;
      if (latitude == null || longitude == null) {
        continue;
      }
      cities.add(
        OfflinePrayerCity(
          name: fields[0],
          asciiName: fields[1],
          countryCode: fields[2],
          countryName: fields[3],
          latitude: latitude,
          longitude: longitude,
          timeZone: fields[6].isEmpty ? 'Etc/UTC' : fields[6],
          population: population,
        ),
      );
    }
    return cities;
  }

  List<OfflinePrayerCity> _featuredCities(
    List<OfflinePrayerCity> cities, {
    required int limit,
  }) {
    final featured = <OfflinePrayerCity>[];
    for (final name in _featuredNames) {
      final normalizedName = _normalize(name);
      for (final city in cities) {
        if (city.normalizedName == normalizedName ||
            city.normalizedAsciiName == normalizedName) {
          featured.add(city);
          break;
        }
      }
    }

    if (featured.length >= limit) {
      return featured.take(limit).toList();
    }

    for (final city in cities) {
      if (featured.contains(city)) {
        continue;
      }
      featured.add(city);
      if (featured.length >= limit) {
        break;
      }
    }
    return featured;
  }

  double _distanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(startLatitude);
    final lat2 = _toRadians(endLatitude);
    final deltaLat = _toRadians(endLatitude - startLatitude);
    final deltaLng = _toRadians(endLongitude - startLongitude);
    final haversine =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class OfflinePrayerCity {
  OfflinePrayerCity({
    required this.name,
    required this.asciiName,
    required this.countryCode,
    required this.countryName,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.population,
  }) : normalizedName = _normalize(name),
       normalizedAsciiName = _normalize(asciiName),
       normalizedCountry = _normalize(countryName),
       normalizedCountryCode = _normalize(countryCode);

  final String name;
  final String asciiName;
  final String countryCode;
  final String countryName;
  final double latitude;
  final double longitude;
  final String timeZone;
  final int population;
  final String normalizedName;
  final String normalizedAsciiName;
  final String normalizedCountry;
  final String normalizedCountryCode;

  String get subtitle => '$countryName • $timeZone';

  PrayerLocation toPrayerLocation() {
    return PrayerLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
    );
  }

  int? score(String query) {
    if (normalizedName == query || normalizedAsciiName == query) {
      return 0;
    }
    if (normalizedName.startsWith(query) ||
        normalizedAsciiName.startsWith(query)) {
      return 1;
    }
    if (normalizedCountry.startsWith(query) || normalizedCountryCode == query) {
      return 2;
    }
    if (normalizedName.contains(query) || normalizedAsciiName.contains(query)) {
      return 3;
    }
    if (normalizedCountry.contains(query)) {
      return 4;
    }
    return null;
  }
}

class _CitySearchResult {
  const _CitySearchResult(this.city, this.score);

  final OfflinePrayerCity city;
  final int score;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
