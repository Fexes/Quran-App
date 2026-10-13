import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/datasources/local_hadith_data_source.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/search/deep_search_index_record.dart';
import 'package:quran/features/azkar/domain/entities/azkar_category.dart';
import 'package:quran/features/azkar/domain/entities/dhikr_item.dart';
import 'package:quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:quran/features/hadith/domain/entities/hadeeth_enc_item.dart';
import 'package:quran/features/hadith/domain/entities/hadith_book.dart';
import 'package:quran/features/hadith/domain/entities/hadith_chapter.dart';
import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:quran/features/quran/data/stores/quran_tafsir_store.dart';
import 'package:quran/features/quran/data/stores/quran_translation_store.dart';
import 'package:quran/features/quran/data/stores/quran_user_data_store.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_tafsir.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/search/data/repositories/local_deep_search_repository.dart';
import 'package:quran/features/search/data/utils/search_text_normalizer.dart';
import 'package:quran/features/search/domain/entities/deep_search_result.dart';

void main() {
  group('SearchTextNormalizer', () {
    test('matches Arabic text with diacritics and alef variants removed', () {
      expect(
        SearchTextNormalizer.normalize('ٱلْحَمْدُ لِلّٰهِ'),
        contains(SearchTextNormalizer.normalize('الحمد لله')),
      );
    });

    test('folds Latin-looking Quran transliteration characters', () {
      expect(SearchTextNormalizer.normalize('Allāh'), 'allah');
      expect(SearchTextNormalizer.normalize('Qurʾān'), 'quran');
      expect(SearchTextNormalizer.normalize('Mu’minūn'), 'muminun');
      expect(
        SearchTextNormalizer.normalize('Ṣirāṭ al-Mustaqīm'),
        contains('sirat'),
      );
      expect(SearchTextNormalizer.normalize('Ḥadīth'), 'hadith');
      expect(SearchTextNormalizer.normalize('Ａｌｌāｈ'), 'allah');
      expect(SearchTextNormalizer.normalize('Alla\u0304h'), 'allah');
      expect(
        SearchTextNormalizer.normalize('Allah &amp; mercy'),
        'allah mercy',
      );
    });
  });

  group('LocalDeepSearchRepository', () {
    test(
      'searches grouped local Islamic content without network fetches',
      () async {
        final translationStore = QuranTranslationStore.memory();
        await translationStore.saveCatalog(const [
          QuranTranslationResource(
            id: 20,
            languageName: 'english',
            name: 'Cached English',
            authorName: 'Tester',
            slug: 'cached-english',
          ),
        ]);
        await translationStore.saveVerseTranslations(
          resourceId: 20,
          translations: const {'2:255': 'Cached throne verse translation'},
        );
        await translationStore.markFullTranslationComplete(
          resource: const QuranTranslationResource(
            id: 20,
            languageName: 'english',
            name: 'Cached English',
            authorName: 'Tester',
            slug: 'cached-english',
          ),
          version: 'test',
          verseCount: 1,
        );

        final tafsirStore = QuranTafsirStore.memory();
        await tafsirStore.saveCatalog(const [
          QuranTafsirResource(
            id: 99,
            languageName: 'english',
            name: 'Cached Tafsir',
            authorName: 'Tester',
            slug: 'cached-tafsir',
          ),
        ]);
        await tafsirStore.saveVerseTafsir(
          resourceId: 99,
          verseKey: '2:255',
          tafsir: 'Cached explanation of the throne verse.',
        );

        final userDataStore = QuranUserDataStore.memory();
        await userDataStore.saveNote(
          text: 'Remember the throne verse lesson',
          now: DateTime.utc(2026, 5, 7),
        );

        final repository = LocalDeepSearchRepository(
          quranRepository: _FakeQuranRepository(),
          translationStore: translationStore,
          tafsirStore: tafsirStore,
          userDataStore: userDataStore,
          hadithRepository: _FakeHadithRepository(),
          azkarRepository: _FakeAzkarRepository(),
        );
        addTearDown(repository.dispose);

        final sections = await repository.search('throne');
        final categories = sections.map((section) => section.category).toSet();

        expect(categories, contains(DeepSearchCategory.translation));
        expect(categories, contains(DeepSearchCategory.tafsir));
        expect(categories, contains(DeepSearchCategory.notes));
        expect(categories, contains(DeepSearchCategory.hadith));
        expect(categories, contains(DeepSearchCategory.azkar));
        expect(
          sections
              .expand((section) => section.results)
              .where((result) => result.target.surahNumber == 2)
              .map((result) => result.target.ayahNumber)
              .toSet(),
          contains(255),
        );
      },
    );

    test('ranks exact verse key before body matches', () async {
      final repository = LocalDeepSearchRepository(
        quranRepository: _FakeQuranRepository(),
        translationStore: QuranTranslationStore.memory(),
        tafsirStore: QuranTafsirStore.memory(),
        userDataStore: QuranUserDataStore.memory(),
        hadithRepository: _FakeHadithRepository(),
        azkarRepository: _FakeAzkarRepository(),
      );
      addTearDown(repository.dispose);

      final sections = await repository.search('2:255');
      final first = sections.expand((section) => section.results).first;

      expect(first.category, DeepSearchCategory.quran);
      expect(first.target.surahNumber, 2);
      expect(first.target.ayahNumber, 255);
      expect(first.matchedField, 'verse key');
    });

    test('does not include reciter names in deep search results', () async {
      final repository = LocalDeepSearchRepository(
        quranRepository: _FakeQuranRepository(),
        translationStore: QuranTranslationStore.memory(),
        tafsirStore: QuranTafsirStore.memory(),
        userDataStore: QuranUserDataStore.memory(),
        hadithRepository: _FakeHadithRepository(),
        azkarRepository: _FakeAzkarRepository(),
      );
      addTearDown(repository.dispose);

      final sections = await repository.search('Mishary Alafasy');

      expect(sections, isEmpty);
    });

    test(
      'does not include transliteration or translation resource names',
      () async {
        final translationStore = QuranTranslationStore.memory();
        await translationStore.saveCatalog(const [
          QuranTranslationResource(
            id: 20,
            languageName: 'english',
            name: 'Cached English Author',
            authorName: 'Tester Author',
            slug: 'cached-english-author',
          ),
        ]);
        await translationStore.saveVerseTranslations(
          resourceId: 20,
          translations: const {'2:255': 'Cached throne verse translation'},
        );

        final repository = LocalDeepSearchRepository(
          quranRepository: _FakeQuranRepository(),
          translationStore: translationStore,
          tafsirStore: QuranTafsirStore.memory(),
          userDataStore: QuranUserDataStore.memory(),
          hadithRepository: _FakeHadithRepository(),
          azkarRepository: _FakeAzkarRepository(),
        );
        addTearDown(repository.dispose);

        expect(await repository.search('Cached English Author'), isEmpty);
        expect(await repository.search('Tester Author'), isEmpty);
        expect(await repository.search('SubhanAllahi'), isEmpty);
      },
    );

    test(
      'matches cached translation and tafsir with Latin folded query text',
      () async {
        final translationStore = QuranTranslationStore.memory();
        await translationStore.saveCatalog(const [
          QuranTranslationResource(
            id: 20,
            languageName: 'english',
            name: 'Cached English',
            authorName: 'Tester',
            slug: 'cached-english',
          ),
        ]);
        await translationStore.saveVerseTranslations(
          resourceId: 20,
          translations: const {'2:255': 'Allāh is Ever-Living.'},
        );

        final tafsirStore = QuranTafsirStore.memory();
        await tafsirStore.saveCatalog(const [
          QuranTafsirResource(
            id: 99,
            languageName: 'english',
            name: 'Cached Tafsir',
            authorName: 'Tester',
            slug: 'cached-tafsir',
          ),
        ]);
        await tafsirStore.saveVerseTafsir(
          resourceId: 99,
          verseKey: '2:255',
          tafsir: 'The Qurʾān explains Ayat al-Kursi.',
        );

        final repository = LocalDeepSearchRepository(
          quranRepository: _FakeQuranRepository(),
          translationStore: translationStore,
          tafsirStore: tafsirStore,
          userDataStore: QuranUserDataStore.memory(),
          hadithRepository: _FakeHadithRepository(),
          azkarRepository: _FakeAzkarRepository(),
        );
        addTearDown(repository.dispose);

        final allahSections = await repository.search('Allah');
        final quranSections = await repository.search('Quran');

        expect(
          allahSections
              .expand((section) => section.results)
              .map((result) => result.category),
          contains(DeepSearchCategory.translation),
        );
        expect(
          quranSections
              .expand((section) => section.results)
              .map((result) => result.category),
          contains(DeepSearchCategory.tafsir),
        );
      },
    );

    test(
      'uses compact hadith and azkar indexes instead of loading full content',
      () async {
        final hadithRepository = _FakeHadithRepository();
        final azkarRepository = _FakeAzkarRepository();
        final repository = LocalDeepSearchRepository(
          quranRepository: _FakeQuranRepository(),
          translationStore: QuranTranslationStore.memory(),
          tafsirStore: QuranTafsirStore.memory(),
          userDataStore: QuranUserDataStore.memory(),
          hadithRepository: hadithRepository,
          azkarRepository: azkarRepository,
        );
        addTearDown(repository.dispose);

        await repository.search('throne');
        await repository.search('mercy');

        expect(hadithRepository.getHadithsCalls, 0);
        expect(azkarRepository.getDhikrCalls, 0);
        expect(hadithRepository.searchCalls, 0);
        expect(azkarRepository.searchCalls, 0);
      },
    );

    test(
      'does not show hadith search hits hidden by the hadith repository',
      () async {
        final repository = LocalDeepSearchRepository(
          quranRepository: _FakeQuranRepository(),
          translationStore: QuranTranslationStore.memory(),
          tafsirStore: QuranTafsirStore.memory(),
          userDataStore: QuranUserDataStore.memory(),
          hadithRepository: _HiddenHadithRepository(),
          azkarRepository: _FakeAzkarRepository(),
        );
        addTearDown(repository.dispose);

        final sections = await repository.search('throne');

        expect(
          sections.map((section) => section.category),
          isNot(contains(DeepSearchCategory.hadith)),
        );
        expect(
          sections.map((section) => section.category),
          contains(DeepSearchCategory.azkar),
        );
      },
    );
  });
}

class _FakeQuranRepository implements QuranRepository {
  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async => const [
    QuranAudioReciter(
      id: 'everyayah:Alafasy_128kbps',
      name: 'Mishary Alafasy',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Alafasy_128kbps',
    ),
  ];

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
  Future<List<QuranSurah>> getSurahs() async => const [
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

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    return (await getSurahs()).firstWhere(
      (surah) => surah.number == surahNumber,
    );
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async {
    if (surahNumber == 2) {
      return const [
        QuranAyah(
          surahNumber: 2,
          number: 255,
          text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
          translation: 'Allah, there is no deity except Him, the Ever-Living.',
          page: 42,
          juz: 3,
          isSajda: false,
          tafsir: 'Bundled tafsir for Ayat al-Kursi.',
        ),
      ];
    }
    return const [
      QuranAyah(
        surahNumber: 1,
        number: 2,
        text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
        translation: 'All praise is for Allah.',
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
  }) async => const [];

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async => 1;

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async =>
      const [];

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {}

  @override
  Future<List<QuranBookmark>> getBookmarks() async => const [];

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async => false;

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async => false;
}

class _FakeHadithRepository implements HadithRepository {
  @override
  Future<List<String>> availableTranslationLanguagesForBook(
    String bookId,
  ) async => const ['en'];

  @override
  Future<bool> hasFullTranslation(String bookId, String languageCode) async =>
      languageCode == 'en';

  @override
  Stream<HadithTranslationDownloadProgress> downloadBookTranslation(
    String bookId,
    String languageCode,
  ) => Stream.error(UnsupportedError('This fixture only uses bundled English'));

  int getHadithsCalls = 0;
  int searchCalls = 0;

  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<HadithBook>> getBooks() async => const [];

  @override
  Future<HadithBook?> getBook(String bookId) async => null;

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async => const [];

  @override
  Future<List<HadithItem>> getHadiths({
    String? bookId,
    String? chapterId,
    String? languageCode,
    int offset = 0,
    int limit = 50,
  }) async {
    getHadithsCalls += 1;
    return const [_hadith];
  }

  @override
  Future<HadithItem?> getHadithById(String id, {String? languageCode}) async {
    return id == _hadith.id ? _hadith : null;
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() async {
    return const [
      DeepSearchIndexRecord(
        id: 'hadith:hadith-1',
        category: 'hadith',
        title: 'Hadith ref',
        subtitle: 'Sample',
        primaryPreview: 'حديث',
        secondaryPreview: 'A hadith mentioning throne.',
        normalizedText: 'hadith ref sample حديث a hadith mentioning throne',
        targetType: 'hadith',
        targetId: 'hadith-1',
        bookId: 'book',
      ),
    ];
  }

  @override
  Future<List<HadithItem>> search(String query, {int limit = 30}) async {
    searchCalls += 1;
    if (!query.toLowerCase().contains('throne')) {
      return const [];
    }
    return const [_hadith];
  }

  @override
  Future<List<HadeethEncLanguage>> getHadeethEncLanguages() async => const [];

  @override
  Future<bool> hasHadeethEncLanguage(String languageCode) async => false;

  @override
  Stream<HadeethEncDownloadProgress> downloadHadeethEncLanguage(
    String languageCode,
  ) async* {}

  @override
  Future<List<HadeethEncItem>> getHadeethEncItems({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  }) async => const [];

  @override
  Future<List<HadeethEncItem>> searchHadeethEnc({
    required String languageCode,
    required String query,
    int limit = 30,
  }) async => const [];

  static const _hadith = HadithItem(
    id: 'hadith-1',
    bookId: 'book',
    chapterId: 'chapter',
    hadithNumber: '1',
    arabic: 'حديث',
    translation: 'A hadith mentioning throne.',
    grade: 'Sample',
    reference: 'Hadith ref',
    sourceId: 'test',
  );
}

class _HiddenHadithRepository extends _FakeHadithRepository {
  final _source = LocalHadithDataSource(
    hadiths: const [
      HadithItem(
        id: 'hadith:hidden:1',
        bookId: 'hidden',
        chapterId: 'hidden_1',
        hadithNumber: '1',
        arabic: 'حَدَّثَنَا فُلَانٌ عَنْ فُلَانٍ',
        translation: 'Narrated: a weak report mentioning throne.',
        grade: 'Daif',
        reference: 'Hidden 1',
        sourceId: 'test',
      ),
    ],
  );

  @override
  Future<HadithItem?> getHadithById(String id, {String? languageCode}) =>
      _source.getHadithById(id);

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() =>
      _source.getSearchIndexRecords();
}

class _FakeAzkarRepository implements AzkarRepository {
  @override
  Future<List<String>> availableTranslationLanguages() async => const ['en'];

  @override
  Future<bool> hasFullTranslation(String languageCode) async =>
      languageCode == 'en';

  @override
  Stream<AzkarTranslationDownloadProgress> downloadTranslation(
    String languageCode,
  ) => Stream.error(UnsupportedError('This fixture only uses bundled English'));

  int getDhikrCalls = 0;
  int searchCalls = 0;

  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<AzkarCategory>> getCategories() async => const [];

  @override
  Future<List<DhikrItem>> getDhikr({
    String? categoryId,
    String? languageCode,
    int offset = 0,
    int limit = 100,
  }) async {
    getDhikrCalls += 1;
    return const [_dhikrTransliteration, _dhikr];
  }

  @override
  Future<DhikrItem?> getDhikrById(String id) async {
    if (id == _dhikr.id) {
      return _dhikr;
    }
    if (id == _dhikrTransliteration.id) {
      return _dhikrTransliteration;
    }
    return null;
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() async {
    return const [
      DeepSearchIndexRecord(
        id: 'azkar:dhikr-1',
        category: 'azkar',
        title: 'Azkar ref',
        subtitle: 'Repeat 3x',
        primaryPreview: 'ذكر',
        secondaryPreview: 'A dhikr mentioning throne.',
        normalizedText: 'azkar ref ذكر a dhikr mentioning throne',
        targetType: 'azkar',
        targetId: 'dhikr-1',
        categoryId: 'morning',
      ),
    ];
  }

  @override
  Future<List<DhikrItem>> search(String query, {int limit = 30}) async {
    searchCalls += 1;
    final normalized = query.toLowerCase();
    if (normalized.contains('subhanallahi')) {
      return const [
        DhikrItem(
          id: 'dhikr-transliteration',
          categoryId: 'morning',
          arabic: 'ذكر',
          translation: 'A remembrance phrase.',
          transliteration: 'SubhanAllahi wa bihamdihi',
          reference: 'Azkar ref',
          repeatCount: 3,
          sourceId: 'test',
        ),
      ];
    }
    if (!normalized.contains('throne')) {
      return const [];
    }
    return const [_dhikr];
  }

  static const _dhikrTransliteration = DhikrItem(
    id: 'dhikr-transliteration',
    categoryId: 'morning',
    arabic: 'ذكر',
    translation: 'A remembrance phrase.',
    transliteration: 'SubhanAllahi wa bihamdihi',
    reference: 'Azkar ref',
    repeatCount: 3,
    sourceId: 'test',
  );

  static const _dhikr = DhikrItem(
    id: 'dhikr-1',
    categoryId: 'morning',
    arabic: 'ذكر',
    translation: 'A dhikr mentioning throne.',
    transliteration: 'dhikr',
    reference: 'Azkar ref',
    repeatCount: 3,
    sourceId: 'test',
  );
}
