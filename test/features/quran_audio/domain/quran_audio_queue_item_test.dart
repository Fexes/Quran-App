import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_queue_item.dart';

void main() {
  test('builds QuranEnc static translation audio urls', () {
    const ayah = QuranAyah(
      surahNumber: 18,
      number: 110,
      text: 'قل إنما أنا بشر مثلكم',
      translation: 'Say, I am only a man like you.',
      page: 304,
      juz: 16,
      isSajda: false,
    );
    const reciter = QuranAudioReciter(
      id: 'quranenc:chinese_suliman',
      name: 'Chinese Translation - Muhammad Suleiman',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'chinese_suliman',
      languageCode: 'zh',
      isTranslation: true,
    );

    expect(
      reciter.audioUrlFor(ayah),
      'https://d.quranenc.com/data/audio/chinese_suliman/018110.mp3',
    );
  });

  test('preserves translation segment type through media item extras', () {
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
    const reciter = QuranAudioReciter(
      id: 'alqurancloud:en.walk',
      name: 'Ibrahim Walk',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'en.walk',
      languageCode: 'en',
      isTranslation: true,
    );

    final item = QuranAudioQueueItem.fromAyah(
      ayah: ayah,
      surah: surah,
      reciter: reciter,
      segmentType: QuranAudioSegmentType.translation,
    );

    final restored = QuranAudioQueueItem.fromMediaItem(item.toMediaItem());

    expect(restored, isNotNull);
    expect(restored!.segmentType, QuranAudioSegmentType.translation);
    expect(restored.isTranslationSegment, true);
    expect(restored.timingProvider, QuranAudioTimingProvider.none);
    expect(restored.reciterId, 'alqurancloud:en.walk');
  });
}
