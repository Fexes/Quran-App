import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/search/deep_search_index_record.dart';
import 'package:quran/features/hadith/domain/entities/hadeeth_enc_item.dart';
import 'package:quran/features/hadith/domain/entities/hadith_book.dart';
import 'package:quran/features/hadith/domain/entities/hadith_chapter.dart';
import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:quran/features/hadith/presentation/bloc/hadith_library_cubit.dart';
import 'package:quran/features/hadith/presentation/bloc/hadith_library_state.dart';

void main() {
  group('HadithLibraryCubit', () {
    test('loads collections and source metadata', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.status,
            'status',
            HadithLibraryStatus.loading,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.status,
                'status',
                HadithLibraryStatus.success,
              )
              .having((state) => state.books, 'books', hasLength(1))
              .having(
                (state) => state.hadeethEncLanguages,
                'hadeethEncLanguages',
                isEmpty,
              )
              .having((state) => state.hadiths, 'hadiths', isEmpty)
              .having(
                (state) => state.contentSources,
                'contentSources',
                hasLength(1),
              ),
        ]),
      );

      await cubit.load();
      await expectation;
      await cubit.close();
    });

    test('loads HadeethEnc languages on demand', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());
      await cubit.load();

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.hadeethEncLoading,
            'hadeethEncLoading',
            isTrue,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.hadeethEncLoading,
                'hadeethEncLoading',
                isFalse,
              )
              .having(
                (state) => state.hadeethEncLanguages,
                'hadeethEncLanguages',
                hasLength(1),
              )
              .having(
                (state) => state.selectedHadeethEncLanguageCode,
                'selectedHadeethEncLanguageCode',
                'en',
              ),
        ]),
      );

      await cubit.loadHadeethEncLanguages();
      await expectation;
      await cubit.close();
    });

    test('opens a book and loads first hadith page', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());
      await cubit.load();

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.status,
            'status',
            HadithLibraryStatus.loading,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.status,
                'status',
                HadithLibraryStatus.success,
              )
              .having((state) => state.chapters, 'chapters', hasLength(1))
              .having((state) => state.hadiths, 'hadiths', hasLength(1)),
        ]),
      );

      await cubit.openBook('bukhari');
      await expectation;
      await cubit.close();
    });

    test('searches hadith text', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.status,
            'status',
            HadithLibraryStatus.loading,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.status,
                'status',
                HadithLibraryStatus.success,
              )
              .having((state) => state.query, 'query', 'intentions')
              .having((state) => state.hadiths, 'hadiths', hasLength(1)),
        ]),
      );

      await cubit.search('intentions');
      await expectation;
      await cubit.close();
    });

    test('looks up one hadith by number inside a selected book', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.status,
            'status',
            HadithLibraryStatus.loading,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.status,
                'status',
                HadithLibraryStatus.success,
              )
              .having((state) => state.query, 'query', '1')
              .having((state) => state.hadiths, 'hadiths', hasLength(1))
              .having(
                (state) => state.hadiths.single.id,
                'hadith id',
                'hadith:bukhari:1',
              ),
        ]),
      );

      await cubit.lookupHadith(bookId: 'bukhari', rawQuery: 'Bukhari 1');
      await expectation;
      await cubit.close();
    });

    test('downloads selected HadeethEnc language and exposes items', () async {
      final cubit = HadithLibraryCubit(repository: _FakeHadithRepository());
      await cubit.load();
      await cubit.loadHadeethEncLanguages();

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HadithLibraryState>().having(
            (state) => state.hadeethEncLoading,
            'hadeethEncLoading',
            isTrue,
          ),
          isA<HadithLibraryState>().having(
            (state) => state.hadeethEncLoading,
            'hadeethEncLoading',
            isTrue,
          ),
          isA<HadithLibraryState>().having(
            (state) => state.selectedHadeethEncLanguageDownloaded,
            'selectedHadeethEncLanguageDownloaded',
            isTrue,
          ),
          isA<HadithLibraryState>()
              .having(
                (state) => state.hadeethEncLoading,
                'hadeethEncLoading',
                isFalse,
              )
              .having(
                (state) => state.selectedHadeethEncLanguageDownloaded,
                'selectedHadeethEncLanguageDownloaded',
                isTrue,
              )
              .having(
                (state) => state.hadeethEncHadiths,
                'hadeethEncHadiths',
                hasLength(1),
              ),
        ]),
      );

      await cubit.downloadSelectedHadeethEncLanguage();
      await expectation;
      await cubit.close();
    });
  });
}

class _FakeHadithRepository implements HadithRepository {
  bool _hadeethEncDownloaded = false;

  static const _source = ContentSource(
    id: 'test_hadith_source',
    name: 'Test Hadith Source',
    attribution: 'Used by Hadith cubit tests.',
  );

  static const _book = HadithBook(
    id: 'bukhari',
    slug: 'sahih-bukhari',
    englishName: 'Sahih al-Bukhari',
    arabicName: 'صحيح البخاري',
    sourceId: 'test_hadith_source',
  );

  static const _chapter = HadithChapter(
    id: 'bukhari_1',
    bookId: 'bukhari',
    number: 1,
    englishTitle: 'Revelation',
    arabicTitle: 'بدء الوحي',
  );

  static const _hadith = HadithItem(
    id: 'hadith:bukhari:1',
    bookId: 'bukhari',
    chapterId: 'bukhari_1',
    hadithNumber: '1',
    arabic: 'إنما الأعمال بالنيات',
    translation: 'Actions are judged by intentions.',
    grade: 'Sahih',
    reference: 'Bukhari 1',
    sourceId: 'test_hadith_source',
  );

  @override
  Future<List<ContentSource>> getContentSources() async => const [_source];

  @override
  Future<List<HadithBook>> getBooks() async => const [_book];

  @override
  Future<HadithBook?> getBook(String bookId) async {
    return bookId == _book.id ? _book : null;
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    return bookId == _book.id ? const [_chapter] : const [];
  }

  @override
  Future<List<HadithItem>> getHadiths({
    String? bookId,
    String? chapterId,
    int offset = 0,
    int limit = 50,
  }) async {
    return bookId == null || bookId == _book.id ? const [_hadith] : const [];
  }

  @override
  Future<HadithItem?> getHadithById(String id) async {
    return id == _hadith.id ? _hadith : null;
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() async {
    return const [
      DeepSearchIndexRecord(
        id: 'hadith:bukhari_1_1',
        category: 'hadith',
        title: 'Bukhari 1',
        subtitle: 'Sahih',
        primaryPreview: 'إنما الأعمال بالنيات',
        secondaryPreview: 'Actions are judged by intentions.',
        normalizedText: 'bukhari 1 actions are judged by intentions',
        targetType: 'hadith',
        targetId: 'bukhari_1_1',
        bookId: 'bukhari',
      ),
    ];
  }

  @override
  Future<List<HadithItem>> search(String query, {int limit = 30}) async {
    if (_hadith.translation.toLowerCase().contains(query.toLowerCase())) {
      return const [_hadith];
    }
    return const [];
  }

  @override
  Future<List<HadeethEncLanguage>> getHadeethEncLanguages() async => const [
    HadeethEncLanguage(code: 'en', nativeName: 'English'),
  ];

  @override
  Future<bool> hasHadeethEncLanguage(String languageCode) async {
    return _hadeethEncDownloaded;
  }

  @override
  Stream<HadeethEncDownloadProgress> downloadHadeethEncLanguage(
    String languageCode,
  ) async* {
    yield HadeethEncDownloadProgress(
      languageCode: languageCode,
      completedItems: 0,
      totalItems: 1,
    );
    _hadeethEncDownloaded = true;
    yield HadeethEncDownloadProgress(
      languageCode: languageCode,
      completedItems: 1,
      totalItems: 1,
      isComplete: true,
    );
  }

  @override
  Future<List<HadeethEncItem>> getHadeethEncItems({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  }) async => const [
    HadeethEncItem(
      id: '1',
      languageCode: 'en',
      title: 'Intentions',
      titleArabic: '',
      hadithText: 'Actions are by intentions.',
      hadithTextArabic: '',
      explanation: '',
      explanationArabic: '',
      benefits: [],
      benefitsArabic: [],
      grade: 'Authentic',
      gradeArabic: '',
      attribution: 'Agreed upon',
      attributionArabic: '',
      link: '',
    ),
  ];

  @override
  Future<List<HadeethEncItem>> searchHadeethEnc({
    required String languageCode,
    required String query,
    int limit = 30,
  }) async => const [];
}
