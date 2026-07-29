import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran/features/prayer_times/data/services/adhan_prayer_calculation_service.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';

void main() {
  group('PrayerTimesRepositoryImpl', () {
    test('uses saved settings and location for calculation', () async {
      final settingsStore = SettingsStore.memory({
        'prayer_method': 'muslimWorldLeague',
        'prayer_asr_madhab': 'shafi',
        'prayer_location_name': 'Lahore',
        'prayer_latitude': 31.5204,
        'prayer_longitude': 74.3587,
      });
      final repository = PrayerTimesRepositoryImpl(
        calculationService: const AdhanPrayerCalculationService(),
        settingsStore: settingsStore,
      );

      final dailyTimes = await repository.getDailyPrayerTimes(
        date: DateTime(2026, 4, 26),
      );

      expect(dailyTimes.location.name, 'Lahore');
      expect(
        dailyTimes.settings.method,
        PrayerCalculationMethod.muslimWorldLeague,
      );
      expect(dailyTimes.settings.asrMadhab, PrayerAsrMadhab.shafi);
    });

    test('saves prayer settings and manual location', () async {
      final settingsStore = SettingsStore.memory();
      final repository = PrayerTimesRepositoryImpl(
        calculationService: const AdhanPrayerCalculationService(),
        settingsStore: settingsStore,
      );

      await repository.saveSettings(
        const PrayerCalculationSettings(
          method: PrayerCalculationMethod.ummAlQura,
          asrMadhab: PrayerAsrMadhab.hanafi,
        ),
      );
      await repository.saveLocation(
        const PrayerLocation(
          name: 'Makkah',
          latitude: 21.3891,
          longitude: 39.8579,
        ),
      );

      expect(settingsStore.prayerMethod, 'ummAlQura');
      expect(settingsStore.prayerAsrMadhab, 'hanafi');
      expect(settingsStore.prayerLocationName, 'Makkah');
      expect(settingsStore.prayerLatitude, 21.3891);
      expect(settingsStore.prayerLongitude, 39.8579);
    });
  });
}
