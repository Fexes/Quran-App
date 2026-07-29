import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/features/home/presentation/cubit/home_cubit.dart';
import 'package:quran/features/home/presentation/cubit/home_state.dart';
import 'package:quran/features/prayer_times/domain/entities/daily_prayer_times.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_time_entry.dart';
import 'package:quran/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  group('HomeCubit', () {
    test('loads saved last read and surah metadata', () async {
      final cubit = HomeCubit(
        quranRepository: _FakeQuranRepository(),
        prayerTimesRepository: _FakePrayerTimesRepository(),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HomeState>().having(
            (state) => state.status,
            'status',
            HomeStatus.loading,
          ),
          isA<HomeState>()
              .having((state) => state.status, 'status', HomeStatus.success)
              .having((state) => state.hasLastRead, 'hasLastRead', true)
              .having(
                (state) => state.lastReadSurah?.englishName,
                'surah',
                'Al-Baqarah',
              )
              .having(
                (state) => state.dailyPrayerTimes?.nextPrayer.name,
                'nextPrayer',
                PrayerTimeName.dhuhr,
              ),
        ]),
      );

      await cubit.load();
      await expectation;
      await cubit.close();
    });
  });
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<DailyPrayerTimes> getDailyPrayerTimes({
    required DateTime date,
    PrayerLocation? location,
    PrayerCalculationSettings? settings,
  }) async {
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
    ];
    return DailyPrayerTimes(
      date: date,
      location: const PrayerLocation(
        name: 'Karachi',
        latitude: 24.8607,
        longitude: 67.0011,
      ),
      settings: const PrayerCalculationSettings.karachi(),
      entries: entries,
      nextPrayer: entries[2],
    );
  }

  @override
  Future<void> saveLocation(PrayerLocation location) async {}

  @override
  Future<void> saveSettings(PrayerCalculationSettings settings) async {}
}

class _FakeQuranRepository implements QuranRepository {
  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async => const [];

  @override
  Future<String?> getSelectedAudioReciterId() async => null;

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) async {}

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async =>
      QuranAyahTextLayout.separated;

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) async {}

  @override
  Future<QuranLastRead?> getLastRead() async {
    return QuranLastRead(
      surahNumber: 2,
      ayahNumber: 255,
      updatedAt: DateTime.utc(2026, 4, 25),
    );
  }

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    return const QuranSurah(
      number: 2,
      englishName: 'Al-Baqarah',
      arabicName: 'البقرة',
      ayahCount: 286,
      revelationType: 'Medinan',
    );
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async => const [];

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async => const [];

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return 1;
  }

  @override
  Future<List<QuranBookmark>> getBookmarks() async => const [];

  @override
  Future<List<QuranSurah>> getSurahs() async => const [];

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return false;
  }

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {}

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async {
    return const [];
  }

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return false;
  }
}
