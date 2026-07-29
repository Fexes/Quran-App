import 'dart:ui' show TextAlign, TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/repositories/quran_translation_repository_impl.dart';
import 'package:quran/features/quran/data/stores/quran_translation_store.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';

void main() {
  group('QuranTranslationResource', () {
    test('detects RTL translation languages', () {
      for (final language in const [
        'urdu',
        'Persian',
        'farsi',
        'pashto',
        'dari',
        'Sindhi',
        'hebrew',
        'kurdish',
        'uighur, uyghur',
      ]) {
        final resource = QuranTranslationResource(
          id: 1,
          languageName: language,
          name: 'Test',
          authorName: 'Test',
          slug: 'test',
        );

        expect(resource.isRtl, isTrue, reason: language);
        expect(resource.textDirection, TextDirection.rtl, reason: language);
        expect(resource.textAlign, TextAlign.right, reason: language);
      }
    });

    test('detects LTR translation languages', () {
      for (final language in const [
        'english',
        'French',
        'turkish',
        'russian',
        'indonesian',
      ]) {
        final resource = QuranTranslationResource(
          id: 1,
          languageName: language,
          name: 'Test',
          authorName: 'Test',
          slug: 'test',
        );

        expect(resource.isRtl, isFalse, reason: language);
        expect(resource.textDirection, TextDirection.ltr, reason: language);
        expect(resource.textAlign, TextAlign.left, reason: language);
      }
    });

    test('maps supported languages to Quran.com word translation codes', () {
      const cases = {
        'english': 'en',
        'Urdu': 'ur',
        'Persian': 'fa',
        'farsi': 'fa',
        'turkish': 'tr',
      };

      for (final entry in cases.entries) {
        final resource = QuranTranslationResource(
          id: 1,
          languageName: entry.key,
          name: 'Test',
          authorName: 'Test',
          slug: 'test',
        );

        expect(resource.wordTranslationLanguageCode, entry.value);
      }
    });

    test('returns no word translation code for unsupported languages', () {
      final resource = QuranTranslationResource(
        id: 1,
        languageName: 'French',
        name: 'Test',
        authorName: 'Test',
        slug: 'test',
      );

      expect(resource.wordTranslationLanguageCode, isNull);
    });
  });

  group('QuranTranslationRepositoryImpl', () {
    test('groups Quran.com resources into one default per language', () async {
      final repository = QuranTranslationRepositoryImpl(
        store: QuranTranslationStore.memory(),
        resourcesFetcher: () async => {
          'translations': [
            {
              'id': 85,
              'language_name': 'english',
              'name': 'M.A.S. Abdel Haleem',
              'author_name': 'Abdul Haleem',
              'slug': 'en-haleem',
            },
            {
              'id': 19,
              'language_name': 'english',
              'name': 'M. Pickthall',
              'author_name': 'M. Pickthall',
              'slug': 'quran.en.pickthall',
            },
            {
              'id': 234,
              'language_name': 'urdu',
              'name': 'Fatah Muhammad Jalandhari',
              'author_name': 'Fatah Muhammad Jalandhari',
              'slug': 'ur-fatah-muhammad-jalandhari',
            },
          ],
        },
      );

      final languages = await repository.translationLanguages();

      expect(languages, hasLength(2));
      expect(languages.first.languageName, 'english');
      expect(languages.first.defaultResource.id, 85);
      expect(languages.first.resourceCount, 2);
      expect(languages.last.languageName, 'urdu');
    });

    test(
      'falls back to bundled 69-language catalog when network fails',
      () async {
        final repository = QuranTranslationRepositoryImpl(
          store: QuranTranslationStore.memory(),
          resourcesFetcher: () async => throw StateError('offline'),
        );

        final languages = await repository.translationLanguages();

        expect(languages, hasLength(69));
        expect(
          languages.map((language) => language.defaultResource.id),
          containsAll([85, 234]),
        );
      },
    );

    test(
      'downloads full translation and marks it complete after all verses',
      () async {
        final store = QuranTranslationStore.memory();
        final repository = QuranTranslationRepositoryImpl(
          store: store,
          totalChaptersForDownload: 2,
          totalVersesForDownload: 3,
          chapterTranslationFetcher:
              ({required chapterNumber, required resourceId}) async {
                return {
                  'verses': [
                    {
                      'verse_key': '$chapterNumber:1',
                      'translations': [
                        {
                          'resource_id': resourceId,
                          'text': 'Translation $chapterNumber:1',
                        },
                      ],
                    },
                    if (chapterNumber == 1)
                      {
                        'verse_key': '1:2',
                        'translations': [
                          {
                            'resource_id': resourceId,
                            'text': 'Translation 1:2',
                          },
                        ],
                      },
                  ],
                };
              },
        );

        final progress = await repository.downloadFullTranslation(85).toList();

        expect(progress.last.isComplete, isTrue);
        expect(progress.last.completedChapters, 2);
        expect(progress.last.completedVerses, 3);
        expect(await repository.hasFullTranslation(85), isTrue);
        expect(
          await repository.cachedTranslationForVerse(85, '1:2'),
          'Translation 1:2',
        );
        expect(await repository.cachedTranslationsForSurah(85, 1), {
          '1:1': 'Translation 1:1',
          '1:2': 'Translation 1:2',
        });
      },
    );

    test('keeps failed translation incomplete', () async {
      final repository = QuranTranslationRepositoryImpl(
        store: QuranTranslationStore.memory(),
        totalChaptersForDownload: 2,
        totalVersesForDownload: 2,
        chapterTranslationFetcher:
            ({required chapterNumber, required resourceId}) async {
              if (chapterNumber == 2) {
                throw StateError('failed');
              }
              return {
                'verses': [
                  {
                    'verse_key': '1:1',
                    'translations': [
                      {'resource_id': resourceId, 'text': 'Translation 1:1'},
                    ],
                  },
                ],
              };
            },
      );

      final progress = await repository.downloadFullTranslation(85).toList();

      expect(progress.last.isComplete, isFalse);
      expect(progress.last.failedChapters, 1);
      expect(await repository.hasFullTranslation(85), isFalse);
    });

    test(
      'keeps selected language available before full cache exists',
      () async {
        final repository = QuranTranslationRepositoryImpl(
          store: QuranTranslationStore.memory(),
        );

        await repository.setSelectedTranslation(234);

        expect(await repository.hasFullTranslation(234), isFalse);
        expect((await repository.selectedTranslation())?.id, 234);
        expect(
          (await repository.selectedTranslation())?.displayLanguage,
          'Urdu',
        );
      },
    );
  });
}
