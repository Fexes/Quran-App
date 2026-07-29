import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_day_progress.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';

void main() {
  group('PrayerDayProgress', () {
    test('starts at zero before Fajr', () {
      final entries = _entries();

      final progress = PrayerDayProgress.calculate(
        entries: entries,
        now: DateTime(2026, 5, 5, 4, 30),
      );

      expect(progress.progress, 0);
      expect(progress.phasePrayer?.name, PrayerTimeName.fajr);
      expect(progress.nextPrayer.name, PrayerTimeName.fajr);
    });

    test('moves proportionally between Fajr and Isha', () {
      final entries = _entries();

      final progress = PrayerDayProgress.calculate(
        entries: entries,
        now: DateTime(2026, 5, 5, 12),
      );

      expect(progress.progress, closeTo(7 / 15, 0.001));
      expect(progress.phasePrayer?.name, PrayerTimeName.fajr);
      expect(progress.nextPrayer.name, PrayerTimeName.dhuhr);
    });

    test('ends at one after Isha', () {
      final entries = _entries();

      final progress = PrayerDayProgress.calculate(
        entries: entries,
        now: DateTime(2026, 5, 5, 21),
      );

      expect(progress.progress, 1);
      expect(progress.phasePrayer?.name, PrayerTimeName.isha);
      expect(progress.nextPrayer.name, PrayerTimeName.fajr);
    });

    test('wraps remaining time to tomorrow Fajr after Isha', () {
      final entries = _entries();

      final progress = PrayerDayProgress.calculate(
        entries: entries,
        now: DateTime(2026, 5, 5, 21),
      );

      expect(progress.remaining, const Duration(hours: 8));
      expect(progress.remainingLabel, '8h 0m remaining');
    });
  });
}

List<PrayerTimeEntry> _entries() {
  return [
    PrayerTimeEntry(name: PrayerTimeName.fajr, time: DateTime(2026, 5, 5, 5)),
    PrayerTimeEntry(
      name: PrayerTimeName.sunrise,
      time: DateTime(2026, 5, 5, 6),
    ),
    PrayerTimeEntry(name: PrayerTimeName.dhuhr, time: DateTime(2026, 5, 5, 13)),
    PrayerTimeEntry(name: PrayerTimeName.asr, time: DateTime(2026, 5, 5, 16)),
    PrayerTimeEntry(
      name: PrayerTimeName.maghrib,
      time: DateTime(2026, 5, 5, 18),
    ),
    PrayerTimeEntry(name: PrayerTimeName.isha, time: DateTime(2026, 5, 5, 20)),
  ];
}
