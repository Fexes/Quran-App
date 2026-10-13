import 'package:flutter/foundation.dart';
import '../entities/daily_prayer_times.dart';
import '../entities/prayer_calculation_settings.dart';
import '../entities/prayer_location.dart';

abstract interface class PrayerTimesRepository {
  Future<DailyPrayerTimes> getDailyPrayerTimes({
    required DateTime date,
    PrayerLocation? location,
    PrayerCalculationSettings? settings,
  });

  Future<void> saveSettings(PrayerCalculationSettings settings);

  Future<void> saveLocation(PrayerLocation location);
}

abstract interface class PrayerLocationObservable {
  Listenable get locationChanges;
}
