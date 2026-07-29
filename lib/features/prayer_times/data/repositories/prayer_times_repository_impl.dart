import '../../../../core/storage/settings_store.dart';
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_calculation_settings.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../services/adhan_prayer_calculation_service.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl({
    required AdhanPrayerCalculationService calculationService,
    required SettingsStore settingsStore,
  }) : _calculationService = calculationService,
       _settingsStore = settingsStore;

  final AdhanPrayerCalculationService _calculationService;
  final SettingsStore _settingsStore;

  static const defaultLocation = PrayerLocation(
    name: 'Karachi',
    latitude: 24.8607,
    longitude: 67.0011,
    timeZone: 'Asia/Karachi',
  );

  @override
  Future<DailyPrayerTimes> getDailyPrayerTimes({
    required DateTime date,
    PrayerLocation? location,
    PrayerCalculationSettings? settings,
  }) async {
    return _calculationService.calculate(
      date: date,
      location: location ?? _savedLocation(),
      settings: settings ?? _savedSettings(),
    );
  }

  @override
  Future<void> saveSettings(PrayerCalculationSettings settings) async {
    await _settingsStore.setPrayerMethod(settings.method.name);
    await _settingsStore.setPrayerAsrMadhab(settings.asrMadhab.name);
  }

  @override
  Future<void> saveLocation(PrayerLocation location) {
    return _settingsStore.setPrayerLocation(
      name: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      timeZone: location.timeZone,
    );
  }

  PrayerLocation _savedLocation() {
    return PrayerLocation(
      name: _settingsStore.prayerLocationName,
      latitude: _settingsStore.prayerLatitude,
      longitude: _settingsStore.prayerLongitude,
      timeZone: _settingsStore.prayerTimeZone,
    );
  }

  PrayerCalculationSettings _savedSettings() {
    return PrayerCalculationSettings(
      method: _methodFromName(_settingsStore.prayerMethod),
      asrMadhab: _madhabFromName(_settingsStore.prayerAsrMadhab),
    );
  }

  PrayerCalculationMethod _methodFromName(String name) {
    for (final method in PrayerCalculationMethod.values) {
      if (method.name == name) {
        return method;
      }
    }
    return PrayerCalculationMethod.karachi;
  }

  PrayerAsrMadhab _madhabFromName(String name) {
    for (final madhab in PrayerAsrMadhab.values) {
      if (madhab.name == name) {
        return madhab;
      }
    }
    return PrayerAsrMadhab.hanafi;
  }
}
