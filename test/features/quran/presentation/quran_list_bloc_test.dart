import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran/domain/repositories/quran_translation_repository.dart';
import 'package:quran/features/quran/presentation/bloc/quran_list_bloc.dart';
import 'package:quran/features/quran/presentation/bloc/quran_list_event.dart';
import 'package:quran/features/quran/presentation/bloc/quran_list_state.dart';
import 'package:quran/features/quran/presentation/bloc/quran_reader_bloc.dart';
import 'package:quran/features/quran/presentation/bloc/quran_reader_event.dart';
import 'package:quran/features/quran/presentation/bloc/quran_reader_state.dart';

void main() {
  group('QuranListBloc', () {
    test('loads and filters surahs', () async {
      final bloc = QuranListBloc(repository: _FakeQuranRepository());

      bloc.add(const QuranListStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuranListState>().having(
            (state) => state.status,
            'status',
            QuranListStatus.loading,
          ),
          isA<QuranListState>()
              .having(
                (state) => state.status,
                'status',
                QuranListStatus.success,
              )
              .having(
                (state) => state.visibleSurahs,
                'visibleSurahs',
                hasLength(2),
              ),
        ]),
      );

      bloc.add(const QuranListQueryChanged('baq'));

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranListState>()
              .having((state) => state.query, 'query', 'baq')
              .having(
                (state) => state.visibleSurahs.single.englishName,
                'result',
                'Al-Baqarah',
              ),
        ),
      );

      await bloc.close();
    });
  });

  group('QuranReaderBloc', () {
    test(
      'loads an ayah-scoped reader with separated layout by default',
      () async {
        final repository = _FakeQuranRepository();
        final bloc = QuranReaderBloc(repository: repository);

        bloc.add(const QuranReaderStarted(surahNumber: 1));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<QuranReaderState>().having(
              (state) => state.status,
              'status',
              QuranReaderStatus.loading,
            ),
            isA<QuranReaderState>()
                .having(
                  (state) => state.status,
                  'status',
                  QuranReaderStatus.success,
                )
                .having((state) => state.surah?.number, 'surah', 1)
                .having((state) => state.ayahs, 'ayahs', hasLength(2))
                .having((state) => state.showTranslation, 'translation', false)
                .having(
                  (state) => state.ayahTextLayout,
                  'ayahTextLayout',
                  QuranAyahTextLayout.separated,
                )
                .having(
                  (state) => state.currentVerseKey,
                  'currentVerseKey',
                  '1:1',
                ),
          ]),
        );

        expect(repository.savedLastRead, '1:1');
        await bloc.close();
      },
    );

    test('restores and saves ayah combined layout', () async {
      final repository = _FakeQuranRepository(
        ayahTextLayout: QuranAyahTextLayout.combined,
      );
      final bloc = QuranReaderBloc(repository: repository);

      bloc.add(const QuranReaderStarted(surahNumber: 1));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<QuranReaderState>()
              .having(
                (state) => state.status,
                'status',
                QuranReaderStatus.success,
              )
              .having(
                (state) => state.ayahTextLayout,
                'ayahTextLayout',
                QuranAyahTextLayout.combined,
              ),
        ),
      );

      bloc.add(
        const QuranReaderAyahTextLayoutChanged(QuranAyahTextLayout.separated),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>().having(
            (state) => state.ayahTextLayout,
            'ayahTextLayout',
            QuranAyahTextLayout.separated,
          ),
        ),
      );
      expect(repository.ayahTextLayout, QuranAyahTextLayout.separated);
      await bloc.close();
    });

    test(
      'activates cached selected translation and preloads current surah',
      () async {
        final translationRepository = _FakeTranslationRepository(
          selected: _englishTranslation,
          cachedBySurah: const {
            1: {
              '1:1': 'In the name of Allah.',
              '1:2': 'All praise is for Allah.',
            },
          },
        );
        final bloc = QuranReaderBloc(
          repository: _FakeQuranRepository(),
          translationRepository: translationRepository,
        );

        bloc.add(const QuranReaderStarted(surahNumber: 1));

        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<QuranReaderState>()
                .having(
                  (state) => state.status,
                  'status',
                  QuranReaderStatus.success,
                )
                .having((state) => state.showTranslation, 'translation', true)
                .having(
                  (state) => state.translationsByVerse['1:2'],
                  'translation',
                  'All praise is for Allah.',
                ),
          ),
        );

        expect(translationRepository.cachedSurahRequests, [1]);
        await bloc.close();
      },
    );

    test('selects ayah, saves last read, and toggles bookmark', () async {
      final repository = _FakeQuranRepository();
      final bloc = QuranReaderBloc(repository: repository);

      bloc.add(const QuranReaderStarted(surahNumber: 1));
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<QuranReaderState>().having(
            (state) => state.status,
            'status',
            QuranReaderStatus.success,
          ),
        ),
      );

      bloc.add(const QuranReaderAyahSelected(surahNumber: 1, ayahNumber: 2));
      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>()
              .having(
                (state) => state.selectedVerseKey,
                'selectedVerseKey',
                '1:2',
              )
              .having(
                (state) => state.currentVerseKey,
                'currentVerseKey',
                '1:2',
              ),
        ),
      );
      expect(repository.savedLastRead, '1:2');

      bloc.add(const QuranReaderSelectionCleared());
      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>().having(
            (state) => state.selectedVerseKey,
            'selectedVerseKey',
            isNull,
          ),
        ),
      );

      bloc.add(const QuranReaderAudioVerseFocused('1:3'));
      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>()
              .having(
                (state) => state.activeAudioVerseKey,
                'activeAudioVerseKey',
                '1:3',
              )
              .having(
                (state) => state.selectedVerseKey,
                'selectedVerseKey',
                '1:3',
              ),
        ),
      );

      bloc.add(const QuranReaderBookmarkToggled(surahNumber: 1, ayahNumber: 2));
      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>().having(
            (state) => state.bookmarkedVerseKeys,
            'bookmarkedVerseKeys',
            contains('1:2'),
          ),
        ),
      );

      await bloc.close();
    });

    test('restores and saves selected audio reciter', () async {
      final repository = _FakeQuranRepository(
        selectedAudioReciterId: 'test:sudais',
      );
      final bloc = QuranReaderBloc(repository: repository);

      bloc.add(const QuranReaderStarted(surahNumber: 1));

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<QuranReaderState>().having(
            (state) => state.selectedAudioReciter?.id,
            'selectedAudioReciter',
            'test:sudais',
          ),
        ),
      );

      bloc.add(const QuranReaderAudioReciterSelected('test:alafasy'));

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranReaderState>().having(
            (state) => state.selectedAudioReciter?.id,
            'selectedAudioReciter',
            'test:alafasy',
          ),
        ),
      );
      expect(repository.selectedAudioReciterId, 'test:alafasy');
      await bloc.close();
    });
  });
}

class _FakeQuranRepository implements QuranRepository {
  _FakeQuranRepository({
    this.selectedAudioReciterId,
    this.ayahTextLayout = QuranAyahTextLayout.separated,
  });

  final Set<String> _bookmarks = {};
  String? savedLastRead;
  String? selectedAudioReciterId;
  QuranAyahTextLayout ayahTextLayout;

  @override
  Future<List<ContentSource>> getContentSources() async {
    return const [
      ContentSource(
        id: 'test',
        name: 'Test Source',
        attribution: 'Used by Quran reader bloc tests.',
      ),
    ];
  }

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async {
    return const [
      QuranAudioReciter(
        id: 'test:alafasy',
        name: 'Test Alafasy',
        provider: QuranAudioProvider.everyAyah,
        identifier: 'Alafasy_128kbps',
      ),
      QuranAudioReciter(
        id: 'test:sudais',
        name: 'Test Sudais',
        provider: QuranAudioProvider.everyAyah,
        identifier: 'Abdurrahmaan_As-Sudais_192kbps',
      ),
    ];
  }

  @override
  Future<String?> getSelectedAudioReciterId() async => selectedAudioReciterId;

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) async {
    selectedAudioReciterId = reciterId;
  }

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async => ayahTextLayout;

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) async {
    ayahTextLayout = layout;
  }

  @override
  Future<List<QuranSurah>> getSurahs() async => _surahs;

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    return _surahs.firstWhere((surah) => surah.number == surahNumber);
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async {
    return _ayahs
        .where((ayah) => ayah.surahNumber == surahNumber)
        .toList(growable: false);
  }

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async {
    return _ayahs
        .where((ayah) => ayah.page == pageNumber.clamp(1, 604))
        .toList(growable: false);
  }

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _ayahs
        .firstWhere(
          (ayah) =>
              ayah.surahNumber == surahNumber && ayah.number == ayahNumber,
        )
        .page;
  }

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async {
    return const [];
  }

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    savedLastRead = '$surahNumber:$ayahNumber';
  }

  @override
  Future<List<QuranBookmark>> getBookmarks() async {
    return _bookmarks
        .map((verseKey) {
          final parts = verseKey.split(':');
          return QuranBookmark(
            surahNumber: int.parse(parts[0]),
            ayahNumber: int.parse(parts[1]),
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _bookmarks.contains('$surahNumber:$ayahNumber');
  }

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final verseKey = '$surahNumber:$ayahNumber';
    if (_bookmarks.remove(verseKey)) {
      return false;
    }
    _bookmarks.add(verseKey);
    return true;
  }

  static const _surahs = [
    QuranSurah(
      number: 1,
      englishName: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      ayahCount: 7,
      revelationType: 'Meccan',
    ),
    QuranSurah(
      number: 2,
      englishName: 'Al-Baqarah',
      arabicName: 'البقرة',
      ayahCount: 286,
      revelationType: 'Medinan',
    ),
  ];

  static const _ayahs = [
    QuranAyah(
      surahNumber: 1,
      number: 1,
      text: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 1,
      number: 2,
      text: 'الحمد لله رب العالمين',
      translation: 'All praise is for Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 2,
      number: 1,
      text: 'الم',
      translation: 'Alif, Lam, Meem.',
      page: 2,
      juz: 1,
      isSajda: false,
    ),
  ];
}

const _englishTranslation = QuranTranslationResource(
  id: 85,
  languageName: 'english',
  name: 'M.A.S. Abdel Haleem',
  authorName: 'Abdul Haleem',
  slug: 'en-haleem',
);

class _FakeTranslationRepository implements QuranTranslationRepository {
  _FakeTranslationRepository({this.selected, this.cachedBySurah = const {}});

  QuranTranslationResource? selected;
  final Map<int, Map<String, String>> cachedBySurah;
  final cachedSurahRequests = <int>[];

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async {
    return const [
      QuranTranslationLanguage(
        languageName: 'english',
        displayName: 'English',
        resourceCount: 1,
        defaultResource: _englishTranslation,
      ),
    ];
  }

  @override
  Future<QuranTranslationResource?> selectedTranslation() async => selected;

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {
    selected = resourceId == null ? null : _englishTranslation;
  }

  @override
  Future<bool> hasFullTranslation(int resourceId) async => true;

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {}

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async {
    for (final translations in cachedBySurah.values) {
      if (translations.containsKey(verseKey)) {
        return translations[verseKey];
      }
    }
    return null;
  }

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async {
    cachedSurahRequests.add(surahNumber);
    return cachedBySurah[surahNumber] ?? const {};
  }
}
