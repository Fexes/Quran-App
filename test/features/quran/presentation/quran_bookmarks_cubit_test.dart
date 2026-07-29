import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran/presentation/bloc/quran_bookmarks_cubit.dart';
import 'package:quran/features/quran/presentation/bloc/quran_bookmarks_state.dart';

void main() {
  group('QuranBookmarksCubit', () {
    test('loads bookmark summaries', () async {
      final cubit = QuranBookmarksCubit(repository: _FakeQuranRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<QuranBookmarksState>().having(
            (state) => state.status,
            'status',
            QuranBookmarksStatus.loading,
          ),
          isA<QuranBookmarksState>()
              .having(
                (state) => state.status,
                'status',
                QuranBookmarksStatus.success,
              )
              .having((state) => state.bookmarks, 'bookmarks', hasLength(1))
              .having(
                (state) => state.bookmarks.single.ayah.verseKey,
                'verseKey',
                '1:1',
              ),
        ]),
      );

      await cubit.load();
      await expectation;
      await cubit.close();
    });
  });
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
  Future<List<QuranBookmark>> getBookmarks() async {
    return [
      QuranBookmark(
        surahNumber: 1,
        ayahNumber: 1,
        createdAt: DateTime.utc(2026, 4, 25),
      ),
    ];
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async {
    return const [
      QuranAyah(
        surahNumber: 1,
        number: 1,
        text: 'بسم الله الرحمن الرحيم',
        translation: 'In the name of Allah.',
        page: 1,
        juz: 1,
        isSajda: false,
      ),
    ];
  }

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async => getAyahs(1);

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return 1;
  }

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    return const QuranSurah(
      number: 1,
      englishName: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      ayahCount: 7,
      revelationType: 'Meccan',
    );
  }

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<List<QuranSurah>> getSurahs() async => const [];

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return true;
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
