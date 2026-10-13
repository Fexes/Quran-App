import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/services/quran_translation_audio_pairings.dart';
import 'package:quran/features/quran_audio/domain/services/quran_translation_audio_selector.dart';

void main() {
  group('quranCompatibleTranslationAudioReciters', () {
    test(
      'uses only the exact verified edition, not all voices in its language',
      () {
        final fooladvand = quranTranslationPairForVoice(
          'alqurancloud:fa.hedayatfarfooladvand',
        )!;
        final voices = quranCompatibleTranslationAudioReciters(
          reciters: _translationReciters,
          selectedTranslation: fooladvand.resource,
        );
        expect(voices.map((voice) => voice.id), [
          'alqurancloud:fa.hedayatfarfooladvand',
        ]);
        expect(
          preferredQuranTranslationVoice(
            voices,
            preferredId: 'everyayah:translations/Makarem_Kabiri_16Kbps',
          )?.id,
          'alqurancloud:fa.hedayatfarfooladvand',
        );
      },
    );

    test('does not pair another Urdu edition or an unverified voice', () {
      const unpairedUrdu = QuranTranslationResource(
        id: 97,
        languageName: 'urdu',
        name: 'Maududi',
        authorName: 'Maududi',
        slug: 'ur-maududi',
      );
      expect(
        quranCompatibleTranslationAudioReciters(
          reciters: _translationReciters,
          selectedTranslation: unpairedUrdu,
        ),
        isEmpty,
      );
      expect(
        quranCompatibleTranslationAudioReciters(
          reciters: const [
            QuranAudioReciter(
              id: 'unverified:urdu',
              name: 'Unverified Urdu voice',
              provider: QuranAudioProvider.alQuranCloud,
              identifier: 'ur.unknown',
              languageCode: 'ur',
              isTranslation: true,
            ),
          ],
          selectedTranslation: QuranTranslationResource.urduJalandhari,
        ),
        isEmpty,
      );
    });

    test('never falls back to English without a selected text edition', () {
      expect(
        quranCompatibleTranslationAudioReciters(
          reciters: _translationReciters,
          selectedTranslation: null,
        ),
        isEmpty,
      );
    });

    test('every catalog pair resolves back to the same text edition', () {
      final ids = <String>{};
      final resources = <int>{};
      for (final pair in quranTranslationAudioPairs) {
        expect(resources.add(pair.resource.id), isTrue);
        expect(pair.evidenceUrl, startsWith('https://'));
        expect(pair.voiceIds, isNotEmpty);
        for (final voiceId in pair.voiceIds) {
          expect(ids.add(voiceId), isTrue);
          expect(
            quranTranslationPairForVoice(voiceId)?.resource.id,
            pair.resource.id,
          );
          expect(
            quranTranslationPairForResource(pair.resource.id)?.voiceIds,
            contains(voiceId),
          );
        }
      }
    });
  });

  group('quranTranslationAudioRecitersFor', () {
    test('returns only voices matching the selected translation language', () {
      final reciters = quranTranslationAudioRecitersFor(
        reciters: _translationReciters,
        selectedTranslation: const QuranTranslationResource(
          id: 1,
          languageName: 'Urdu',
          name: 'Urdu translation',
          authorName: 'Author',
          slug: 'urdu',
        ),
      );

      expect(reciters.map((reciter) => reciter.id), ['alqurancloud:ur.khan']);
      expect(
        preferredQuranTranslationVoice(reciters)?.id,
        'alqurancloud:ur.khan',
      );
      expect(
        preferredQuranTranslationVoice(
          reciters,
          preferredId: 'alqurancloud:en.walk',
        )?.id,
        'alqurancloud:ur.khan',
      );
    });

    test('returns no voices when no translation language is selected', () {
      final reciters = quranTranslationAudioRecitersFor(
        reciters: _translationReciters,
        selectedTranslation: null,
      );

      expect(reciters, isEmpty);
      expect(preferredQuranTranslationVoice(reciters), isNull);
      expect(
        quranTranslationAudioLanguageLabel(null),
        'Select translation language',
      );
    });

    test('returns empty list for unsupported translation languages', () {
      final reciters = quranTranslationAudioRecitersFor(
        reciters: _translationReciters,
        selectedTranslation: const QuranTranslationResource(
          id: 2,
          languageName: 'Indonesian',
          name: 'Indonesian translation',
          authorName: 'Author',
          slug: 'indonesian',
        ),
      );

      expect(reciters, isEmpty);
    });

    test(
      'maps Persian and Russian language names to verified audio voices',
      () {
        final persian = quranTranslationAudioRecitersFor(
          reciters: _translationReciters,
          selectedTranslation: const QuranTranslationResource(
            id: 3,
            languageName: 'Persian',
            name: 'Persian translation',
            authorName: 'Author',
            slug: 'persian',
          ),
        );
        final russian = quranTranslationAudioRecitersFor(
          reciters: _translationReciters,
          selectedTranslation: const QuranTranslationResource(
            id: 4,
            languageName: 'Russian',
            name: 'Russian translation',
            authorName: 'Author',
            slug: 'russian',
          ),
        );

        expect(persian.map((reciter) => reciter.id), [
          'alqurancloud:fa.hedayatfarfooladvand',
          'everyayah:translations/Makarem_Kabiri_16Kbps',
        ]);
        expect(russian.map((reciter) => reciter.id), [
          'alqurancloud:ru.kuliev-audio',
          'alqurancloud:ru.kuliev-audio-2',
        ]);
        expect(
          preferredQuranTranslationVoice(
            russian,
            preferredId: russian.last.id,
          )?.id,
          russian.last.id,
        );
        final reordered = quranTranslationAudioRecitersFor(
          reciters: russian.reversed.toList(),
          selectedTranslation: null,
          preferredLanguageCode: 'ru',
        );
        expect(reordered.first.id, 'alqurancloud:ru.kuliev-audio');
      },
    );

    test('maps Bosnian language names to verified audio voices', () {
      final reciters = quranTranslationAudioRecitersFor(
        reciters: _translationReciters,
        selectedTranslation: const QuranTranslationResource(
          id: 5,
          languageName: 'Bosnian',
          name: 'Bosnian translation',
          authorName: 'Author',
          slug: 'bosnian',
        ),
      );

      expect(reciters.map((reciter) => reciter.id), [
        'everyayah:translations/besim_korkut_ajet_po_ajet',
      ]);
    });

    test('maps QuranEnc translation audio language names', () {
      const expectedIds = {
        'Portuguese': ['quranenc:portuguese_nasr'],
        'Dutch': ['quranenc:dutch_center'],
        'Tagalog': ['quranenc:tagalog_rwwad'],
        'Vietnamese': ['quranenc:vietnamese_rwwad'],
        'Assamese': ['quranenc:assamese_rafeeq'],
        'Sinhalese': ['quranenc:sinhalese_mahir'],
        'Somali': ['quranenc:somali_yacob'],
      };

      for (final entry in expectedIds.entries) {
        final reciters = quranTranslationAudioRecitersFor(
          reciters: _translationReciters,
          selectedTranslation: QuranTranslationResource(
            id: entry.key.hashCode,
            languageName: entry.key,
            name: '${entry.key} translation',
            authorName: 'Author',
            slug: entry.key.toLowerCase(),
          ),
        );

        expect(
          reciters.map((reciter) => reciter.id),
          entry.value,
          reason: entry.key,
        );
      }
    });
  });
}

const _translationReciters = [
  QuranAudioReciter(
    id: 'alqurancloud:en.walk',
    name: 'Ibrahim Walk',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'en.walk',
    languageCode: 'en',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'alqurancloud:fa.hedayatfarfooladvand',
    name: 'Fooladvand - Hedayatfar',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'fa.hedayatfarfooladvand',
    languageCode: 'fa',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'everyayah:translations/Makarem_Kabiri_16Kbps',
    name: 'Makarem - Kabiri',
    provider: QuranAudioProvider.everyAyah,
    identifier: 'translations/Makarem_Kabiri_16Kbps',
    languageCode: 'fa',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'alqurancloud:ur.khan',
    name: 'Shamshad Ali Khan',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'ur.khan',
    languageCode: 'ur',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'alqurancloud:ru.kuliev-audio',
    name: 'Elmir Kuliev by 1MuslimApp',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'ru.kuliev-audio',
    languageCode: 'ru',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'alqurancloud:ru.kuliev-audio-2',
    name: 'Elmir Kuliev 2 by 1MuslimApp',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'ru.kuliev-audio-2',
    languageCode: 'ru',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'everyayah:translations/besim_korkut_ajet_po_ajet',
    name: 'Besim Korkut',
    provider: QuranAudioProvider.everyAyah,
    identifier: 'translations/besim_korkut_ajet_po_ajet',
    languageCode: 'bs',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:portuguese_nasr',
    name: 'Portuguese Translation - Helmi Nasr',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'portuguese_nasr',
    languageCode: 'pt',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:dutch_center',
    name: 'Dutch Translation - Rowwad Translation Center',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'dutch_center',
    languageCode: 'nl',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:tagalog_rwwad',
    name: 'Filipino Translation (Tagalog) - Rowwad Translation Center',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'tagalog_rwwad',
    languageCode: 'tl',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:vietnamese_rwwad',
    name: 'Vietnamese Translation - Rowwad Translation Center',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'vietnamese_rwwad',
    languageCode: 'vi',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:assamese_rafeeq',
    name: 'Assamese Translation - Rafiqul Islam Habibur-Rahman',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'assamese_rafeeq',
    languageCode: 'as',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:sinhalese_mahir',
    name: 'Sinhalese Translation - Rowwad Translation Center',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'sinhalese_mahir',
    languageCode: 'si',
    isTranslation: true,
  ),
  QuranAudioReciter(
    id: 'quranenc:somali_yacob',
    name: 'Somali Translation - Abdullah Hasan Yaqoub',
    provider: QuranAudioProvider.quranEnc,
    identifier: 'somali_yacob',
    languageCode: 'so',
    isTranslation: true,
  ),
];
