import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran_audio/data/repositories/quran_word_timing_repository_impl.dart';
import 'package:quran/features/quran_audio/data/stores/quran_word_timing_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_queue_item.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_word_timing.dart';

void main() {
  group('QuranWordTimingRepositoryImpl', () {
    test('parses Quran Foundation verse segments as 1-based word timings', () {
      final result = QuranWordTimingRepositoryImpl.parseQuranFoundationVerse(
        reciterId: 'everyayah:Alafasy_128kbps',
        verseKey: '1:1',
        json: const {
          'audio_files': [
            {
              'verse_key': '1:1',
              'segments': [
                [0, 1, 60, 610],
                [1, 2, 620, 1310],
              ],
            },
          ],
        },
      );

      expect(result.source, QuranWordTimingSource.quranFoundation);
      expect(result.isExact, true);
      expect(result.segments, [
        const QuranWordTimingSegment(
          verseKey: '1:1',
          wordIndex: 1,
          startMs: 60,
          endMs: 610,
        ),
        const QuranWordTimingSegment(
          verseKey: '1:1',
          wordIndex: 2,
          startMs: 620,
          endMs: 1310,
        ),
      ]);
    });

    test(
      'expands quran-align ranged segments into individual word timings',
      () {
        final result = QuranWordTimingRepositoryImpl.parseQuranAlignEntry(
          reciterId: 'everyayah:test',
          json: const {
            'surah': 1,
            'ayah': 2,
            'segments': [
              [0, 2, 120, 900],
            ],
          },
        );

        expect(result.source, QuranWordTimingSource.quranAlign);
        expect(result.segments.map((segment) => segment.wordIndex), [1, 2]);
        expect(
          result.segments.every((segment) => segment.startMs == 120),
          true,
        );
        expect(result.segments.every((segment) => segment.endMs == 900), true);
      },
    );

    test('uses cached timing before fetching again', () async {
      final store = QuranWordTimingStore.memory();
      var calls = 0;
      final repository = QuranWordTimingRepositoryImpl(
        store: store,
        fetchQuranFoundationVerse:
            ({required recitationId, required verseKey}) async {
              calls += 1;
              return const {
                'audio_files': [
                  {
                    'verse_key': '1:1',
                    'segments': [
                      [0, 1, 60, 610],
                    ],
                  },
                ],
              };
            },
      );

      final item = _queueItem();
      final first = await repository.timingsFor(
        reciter: _reciter(timingRecitationId: 7),
        item: item,
      );
      final second = await repository.timingsFor(
        reciter: _reciter(timingRecitationId: 7),
        item: item,
      );

      expect(first.segments, isNotEmpty);
      expect(second.segments, first.segments);
      expect(calls, 1);
    });

    test('returns empty timing for unsupported reciters', () async {
      final repository = QuranWordTimingRepositoryImpl(
        store: QuranWordTimingStore.memory(),
      );

      final result = await repository.timingsFor(
        reciter: _reciter(),
        item: _queueItem(),
      );

      expect(result.segments, isEmpty);
      expect(result.source, QuranWordTimingSource.unavailable);
      expect(result.isExact, false);
    });
  });
}

QuranAudioReciter _reciter({int? timingRecitationId}) {
  return QuranAudioReciter(
    id: 'everyayah:Alafasy_128kbps',
    name: 'Mishary Alafasy',
    provider: QuranAudioProvider.everyAyah,
    identifier: 'Alafasy_128kbps',
    timingProvider: timingRecitationId == null
        ? QuranAudioTimingProvider.none
        : QuranAudioTimingProvider.quranFoundation,
    timingRecitationId: timingRecitationId,
  );
}

QuranAudioQueueItem _queueItem() {
  const ayah = QuranAyah(
    surahNumber: 1,
    number: 1,
    text: 'بسم الله الرحمن الرحيم',
    translation: 'In the name of Allah.',
    page: 1,
    juz: 1,
    isSajda: false,
  );
  const surah = QuranSurah(
    number: 1,
    englishName: 'Al-Fatihah',
    arabicName: 'الفاتحة',
    ayahCount: 7,
    revelationType: 'Meccan',
  );
  return QuranAudioQueueItem.fromAyah(
    ayah: ayah,
    surah: surah,
    reciter: _reciter(timingRecitationId: 7),
  );
}
