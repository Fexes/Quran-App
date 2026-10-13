import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/storage/settings_store.dart';
import '../datasources/offline_prayer_city_data_source.dart';

class PrayerLocationRefreshService with WidgetsBindingObserver {
  PrayerLocationRefreshService(this._settings, this._cities) {
    _settings.beforePersonalDataErase.add(_invalidate);
  }
  final SettingsStore _settings;
  final OfflinePrayerCityDataSource _cities;
  Future<void>? _pending;
  DateTime? _lastAttempt;
  int _revision = 0;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  Future<void> _invalidate() async {
    _revision++;
    await _pending;
    _lastAttempt = DateTime.now();
  }

  Future<void> refresh() {
    if (_pending != null) return _pending!;
    if (!_settings.prayerLocationUsesDevice ||
        (_lastAttempt != null &&
            DateTime.now().difference(_lastAttempt!) <
                const Duration(minutes: 5))) {
      return Future.value();
    }
    _lastAttempt = DateTime.now();
    final revision = _revision;
    final locationRevision = _settings.prayerLocationChanges.value;
    return _pending = _refresh(
      revision,
      locationRevision,
    ).whenComplete(() => _pending = null);
  }

  Future<void> _refresh(int revision, int locationRevision) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      final city = await _cities.nearest(position.latitude, position.longitude);
      if (city == null ||
          revision != _revision ||
          locationRevision != _settings.prayerLocationChanges.value ||
          !_settings.prayerLocationUsesDevice) {
        return;
      }
      final distance = Geolocator.distanceBetween(
        _settings.prayerLatitude,
        _settings.prayerLongitude,
        position.latitude,
        position.longitude,
      );
      if (distance < 1000 && city.timeZone == _settings.prayerTimeZone) return;
      await _settings.setPrayerLocation(
        name: city.name,
        latitude: position.latitude,
        longitude: position.longitude,
        timeZone: city.timeZone,
        usesDeviceLocation: true,
      );
    } catch (_) {
      // Keep the last usable location offline or when permission is revoked.
    }
  }
}
