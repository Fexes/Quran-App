import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/prayer_times/domain/entities/daily_prayer_times.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';
import 'package:quran/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:quran/features/prayer_times/presentation/bloc/prayer_times_cubit.dart';
import 'package:quran/features/prayer_times/presentation/bloc/prayer_times_state.dart';

void main() {
  group('PrayerTimesCubit', () {
    test('loads daily prayer times', () async {
      final cubit = PrayerTimesCubit(repository: _FakePrayerTimesRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PrayerTimesState>().having(
            (state) => state.status,
            'status',
            PrayerTimesStatus.loading,
          ),
          isA<PrayerTimesState>()
              .having(
                (state) => state.status,
                'status',
                PrayerTimesStatus.success,
              )
              .having(
                (state) => state.dailyTimes?.nextPrayer.name,
                'nextPrayer',
                PrayerTimeName.dhuhr,
              ),
        ]),
      );

      await cubit.load(date: DateTime(2026, 4, 26));
      await expectation;
      await cubit.close();
    });

    test('saves settings and reloads daily prayer times', () async {
      final repository = _FakePrayerTimesRepository();
      final cubit = PrayerTimesCubit(repository: repository);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<PrayerTimesState>().having(
            (state) => state.status,
            'status',
            PrayerTimesStatus.loading,
          ),
          isA<PrayerTimesState>().having(
            (state) => state.status,
            'status',
            PrayerTimesStatus.success,
          ),
        ]),
      );

      await cubit.updateSettings(
        const PrayerCalculationSettings(
          method: PrayerCalculationMethod.muslimWorldLeague,
          asrMadhab: PrayerAsrMadhab.shafi,
        ),
      );
      await expectation;

      expect(
        repository.savedSettings?.method,
        PrayerCalculationMethod.muslimWorldLeague,
      );
      expect(repository.savedSettings?.asrMadhab, PrayerAsrMadhab.shafi);

      await cubit.close();
    });

    test('saves location and reloads daily prayer times', () async {
      final repository = _FakePrayerTimesRepository();
      final cubit = PrayerTimesCubit(repository: repository);

      await cubit.updateLocation(
        const PrayerLocation(
          name: 'Lahore',
          latitude: 31.5204,
          longitude: 74.3587,
        ),
      );

      expect(repository.savedLocation?.name, 'Lahore');
      expect(cubit.state.dailyTimes?.location.name, 'Lahore');

      await cubit.close();
    });
  });
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  PrayerCalculationSettings? savedSettings;
  PrayerLocation? savedLocation;

  @override
  Future<DailyPrayerTimes> getDailyPrayerTimes({
    required DateTime date,
    PrayerLocation? location,
    PrayerCalculationSettings? settings,
  }) async {
    final effectiveLocation =
        location ??
        savedLocation ??
        const PrayerLocation(
          name: 'Karachi',
          latitude: 24.8607,
          longitude: 67.0011,
        );
    final effectiveSettings =
        settings ?? savedSettings ?? const PrayerCalculationSettings.karachi();
    final entries = [
      PrayerTimeEntry(
        name: PrayerTimeName.fajr,
        time: DateTime(2026, 4, 26, 5),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.sunrise,
        time: DateTime(2026, 4, 26, 6),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.dhuhr,
        time: DateTime(2026, 4, 26, 12),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.asr,
        time: DateTime(2026, 4, 26, 16),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.maghrib,
        time: DateTime(2026, 4, 26, 19),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.isha,
        time: DateTime(2026, 4, 26, 20),
      ),
    ];
    return DailyPrayerTimes(
      date: date,
      location: effectiveLocation,
      settings: effectiveSettings,
      entries: entries,
      nextPrayer: entries[2],
    );
  }

  @override
  Future<void> saveLocation(PrayerLocation location) async {
    savedLocation = location;
  }

  @override
  Future<void> saveSettings(PrayerCalculationSettings settings) async {
    savedSettings = settings;
  }
}
