import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/repositories/quran_tafsir_repository_impl.dart';
import 'package:quran/features/quran/data/stores/quran_tafsir_store.dart';

void main() {
  test('groups matching tafsir resource by selected language', () async {
    final repository = QuranTafsirRepositoryImpl(
      store: QuranTafsirStore.memory(),
      resourcesFetcher: () async => {
        'tafsirs': [
          {
            'id': 169,
            'name': 'Ibn Kathir',
            'author_name': 'Ibn Kathir',
            'slug': 'en-tafsir',
            'language_name': 'english',
          },
          {
            'id': 160,
            'name': 'Tafsir Ibn Kathir Urdu',
            'author_name': 'Ibn Kathir',
            'slug': 'ur-tafsir',
            'language_name': 'urdu',
          },
        ],
      },
    );

    final resource = await repository.defaultResourceForLanguage('Urdu');

    expect(resource?.id, 160);
    expect(resource?.isRtl, isTrue);
  });

  test('fetches, cleans, and caches tafsir for a verse', () async {
    var fetchCount = 0;
    final store = QuranTafsirStore.memory();
    final repository = QuranTafsirRepositoryImpl(
      store: store,
      resourcesFetcher: () async => {
        'tafsirs': [
          {
            'id': 169,
            'name': 'Ibn Kathir',
            'author_name': 'Ibn Kathir',
            'slug': 'en-tafsir',
            'language_name': 'english',
          },
        ],
      },
      verseTafsirFetcher: ({required resourceId, required verseKey}) async {
        fetchCount += 1;
        return {
          'tafsir': {
            'verses': {
              verseKey: {'id': 1},
            },
            'resource_id': resourceId,
            'resource_name': 'Ibn Kathir',
            'language_name': 'english',
            'slug': 'en-tafsir',
            'text': '<p>In the name &amp; mercy.</p><p>Second line.</p>',
          },
        };
      },
    );

    final first = await repository.tafsirForVerse(
      verseKey: '1:1',
      languageName: 'english',
    );
    final second = await repository.tafsirForVerse(
      verseKey: '1:1',
      languageName: 'english',
    );

    expect(first?.text, 'In the name & mercy.\nSecond line.');
    expect(second?.text, first?.text);
    expect(fetchCount, 1);
  });

  test('returns null when selected language has no tafsir resource', () async {
    final repository = QuranTafsirRepositoryImpl(
      store: QuranTafsirStore.memory(),
      resourcesFetcher: () async => {
        'tafsirs': [
          {
            'id': 169,
            'name': 'Ibn Kathir',
            'author_name': 'Ibn Kathir',
            'slug': 'en-tafsir',
            'language_name': 'english',
          },
        ],
      },
    );

    final resource = await repository.defaultResourceForLanguage('French');

    expect(resource, isNull);
  });

  test('downloads and marks a surah tafsir available offline', () async {
    var fetchedPages = <int>[];
    final store = QuranTafsirStore.memory();
    final repository = QuranTafsirRepositoryImpl(
      store: store,
      resourcesFetcher: () async => {
        'tafsirs': [
          {
            'id': 169,
            'name': 'Ibn Kathir',
            'author_name': 'Ibn Kathir',
            'slug': 'en-tafsir',
            'language_name': 'english',
          },
        ],
      },
      surahTafsirFetcher:
          ({required resourceId, required surahNumber, required page}) async {
            fetchedPages.add(page);
            return {
              'tafsirs': [
                for (var ayah = 1; ayah <= 7; ayah++)
                  {
                    'resource_id': resourceId,
                    'verse_key': '$surahNumber:$ayah',
                    'language_name': 'english',
                    'resource_name': 'Ibn Kathir',
                    'text': '<p>Tafsir $ayah</p>',
                  },
              ],
              'pagination': {'next_page': null, 'total_records': 7},
            };
          },
    );

    final progress = await repository
        .downloadSurahTafsir(surahNumber: 1, languageName: 'english')
        .toList();

    expect(fetchedPages, [1]);
    expect(progress.last.isComplete, isTrue);
    expect(
      await repository.hasDownloadedSurahTafsir(
        surahNumber: 1,
        languageName: 'english',
      ),
      isTrue,
    );
    expect(
      (await repository.tafsirForVerse(
        verseKey: '1:4',
        languageName: 'english',
      ))?.text,
      'Tafsir 4',
    );
  });
}
