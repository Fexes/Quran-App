import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/prayer_times/data/services/adhan_prayer_calculation_service.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';

void main() {
  group('AdhanPrayerCalculationService', () {
    test('calculates six daily prayer entries and next prayer', () {
      const service = AdhanPrayerCalculationService();

      final dailyTimes = service.calculate(
        date: DateTime(2026, 4, 26),
        location: const PrayerLocation(
          name: 'Karachi',
          latitude: 24.8607,
          longitude: 67.0011,
        ),
        settings: const PrayerCalculationSettings.karachi(),
        now: DateTime(2026, 4, 26, 8),
      );

      expect(dailyTimes.entries, hasLength(6));
      expect(
        dailyTimes.entries.map((entry) => entry.name),
        containsAll(PrayerTimeName.values),
      );
      expect(dailyTimes.nextPrayer.name, PrayerTimeName.dhuhr);
    });
  });
}
