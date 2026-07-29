import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/repositories/quran_interlinear_repository_impl.dart';
import 'package:quran/features/quran/data/stores/quran_interlinear_words_store.dart';
import 'package:quran/features/quran/domain/entities/quran_word.dart';

void main() {
  group('QuranInterlinearRepositoryImpl', () {
    test('parses Quran.com word response and skips ayah markers', () {
      final words = QuranInterlinearRepositoryImpl.parsePageWords(
        pageNumber: 1,
        json: _pageJson(),
      );

      expect(words, hasLength(2));
      expect(words.first.verseKey, '1:1');
      expect(words.first.ayahNumber, 1);
      expect(words.first.wordIndex, 1);
      expect(words.first.arabicText, 'بِسْمِ');
      expect(words.first.translation, 'In');
      expect(words.first.page, 1);
      expect(words.first.lineNumber, 1);
    });

    test('uses cached words before fetching network data', () async {
      final store = QuranInterlinearWordsStore.memory();
      await store.savePageWords(
        pageNumber: 1,
        language: 'en',
        words: const [
          QuranWord(
            verseKey: '1:1',
            ayahNumber: 1,
            wordIndex: 1,
            arabicText: 'بِسْمِ',
            translation: 'In',
            page: 1,
            lineNumber: 1,
          ),
        ],
      );
      var fetched = false;
      final repository = QuranInterlinearRepositoryImpl(
        store: store,
        fetchPageWords: ({required pageNumber, required language}) async {
          fetched = true;
          return _pageJson();
        },
      );

      final words = await repository.getPageWords(1);

      expect(words, hasLength(1));
      expect(fetched, isFalse);
    });

    test('cached page words never fetch network data', () async {
      final store = QuranInterlinearWordsStore.memory();
      var fetched = false;
      final repository = QuranInterlinearRepositoryImpl(
        store: store,
        fetchPageWords: ({required pageNumber, required language}) async {
          fetched = true;
          return _pageJson();
        },
      );

      final words = await repository.cachedPageWords(1);

      expect(words, isEmpty);
      expect(fetched, isFalse);
    });

    test('full cache requires all pages and complete metadata', () async {
      final store = QuranInterlinearWordsStore.memory();
      final repository = QuranInterlinearRepositoryImpl(store: store);

      expect(await repository.hasFullCache(), isFalse);

      for (var page = 1; page <= 604; page++) {
        await store.savePageWords(
          pageNumber: page,
          language: 'en',
          words: [
            QuranWord(
              verseKey: '1:1',
              ayahNumber: 1,
              wordIndex: 1,
              arabicText: 'بِسْمِ',
              translation: 'In',
              page: page,
              lineNumber: 1,
            ),
          ],
        );
      }

      expect(await repository.hasFullCache(), isFalse);

      await store.markFullCacheComplete(
        language: 'en',
        version: QuranInterlinearRepositoryImpl.currentCacheVersion,
        pageCount: 604,
      );

      expect(await repository.hasFullCache(), isTrue);
    });

    test('downloads full cache and reports progress', () async {
      final store = QuranInterlinearWordsStore.memory();
      final repository = QuranInterlinearRepositoryImpl(
        store: store,
        totalPagesForDownload: 3,
        fetchPageWords: ({required pageNumber, required language}) async {
          return _pageJson(pageNumber: pageNumber);
        },
      );

      final progress = await repository.downloadFullCache().toList();

      expect(progress.last.completedPages, 3);
      expect(progress.last.totalPages, 3);
      expect(progress.last.isComplete, isTrue);
      expect(
        store.hasFullCache(
          language: 'en',
          version: QuranInterlinearRepositoryImpl.currentCacheVersion,
          pageCount: 3,
        ),
        isTrue,
      );
      expect(store.pageWords(pageNumber: 3, language: 'en'), isNotEmpty);
    });

    test('keeps full cache completion separate per language', () async {
      final store = QuranInterlinearWordsStore.memory();
      final requestedLanguages = <String>[];
      final repository = QuranInterlinearRepositoryImpl(
        store: store,
        totalPagesForDownload: 1,
        fetchPageWords: ({required pageNumber, required language}) async {
          requestedLanguages.add(language);
          return _pageJson(pageNumber: pageNumber);
        },
      );

      final progress = await repository
          .downloadFullCache(language: 'ur')
          .toList();

      expect(progress.last.isComplete, isTrue);
      expect(requestedLanguages, ['ur']);
      expect(await repository.hasFullCache(language: 'ur'), isTrue);
      expect(await repository.hasFullCache(language: 'en'), isFalse);
      expect(store.pageWords(pageNumber: 1, language: 'ur'), isNotEmpty);
      expect(store.pageWords(pageNumber: 1, language: 'en'), isEmpty);
    });
  });
}

Map<String, Object?> _pageJson({int pageNumber = 1}) {
  return {
    'verses': [
      {
        'verse_key': '1:1',
        'verse_number': 1,
        'page_number': pageNumber,
        'words': [
          {
            'position': 1,
            'text_uthmani': 'بِسْمِ',
            'page_number': pageNumber,
            'line_number': 1,
            'char_type_name': 'word',
            'translation': {'text': 'In'},
          },
          {
            'position': 2,
            'text_uthmani': 'ٱللَّهِ',
            'page_number': pageNumber,
            'line_number': 1,
            'char_type_name': 'word',
            'translation': {'text': 'Allah'},
          },
          {
            'position': 3,
            'text_uthmani': '١',
            'page_number': pageNumber,
            'line_number': 1,
            'char_type_name': 'end',
            'translation': {'text': ''},
          },
        ],
      },
    ],
  };
}
