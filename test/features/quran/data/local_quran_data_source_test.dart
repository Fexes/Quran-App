import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/data/datasources/local_quran_data_source.dart';

void main() {
  group('LocalQuranDataSource', () {
    test('loads all surah metadata', () {
      final dataSource = LocalQuranDataSource();

      final surahs = dataSource.getSurahs();

      expect(surahs, hasLength(114));
      expect(surahs.first.number, 1);
      expect(surahs.first.englishName, startsWith('Al-F'));
      expect(surahs.first.arabicName, isNotEmpty);
      expect(surahs.first.ayahCount, 7);
    });

    test('loads Arabic ayahs with English translation', () {
      final dataSource = LocalQuranDataSource();

      final ayahs = dataSource.getAyahs(1);

      expect(ayahs, hasLength(7));
      expect(ayahs.first.verseKey, '1:1');
      expect(ayahs.first.text, isNotEmpty);
      expect(ayahs.first.translation, isNotEmpty);
      expect(ayahs.first.page, 1);
      expect(ayahs.first.juz, 1);
      expect(ayahs.first.globalNumber, 1);
    });

    test('loads ayahs by Mushaf page and clamps invalid page numbers', () {
      final dataSource = LocalQuranDataSource();

      final firstPage = dataSource.getPageAyahs(1);
      final secondPage = dataSource.getPageAyahs(2);
      final lastPage = dataSource.getPageAyahs(604);
      final clampedFirstPage = dataSource.getPageAyahs(0);
      final clampedLastPage = dataSource.getPageAyahs(700);

      expect(firstPage.first.verseKey, '1:1');
      expect(firstPage.last.verseKey, '1:7');
      expect(secondPage.first.verseKey, '2:1');
      expect(lastPage.last.verseKey, '114:6');
      expect(clampedFirstPage.first.verseKey, firstPage.first.verseKey);
      expect(clampedLastPage.last.verseKey, lastPage.last.verseKey);
    });

    test('looks up page number for an ayah', () {
      final dataSource = LocalQuranDataSource();

      expect(dataSource.getPageNumberForAyah(surahNumber: 1, ayahNumber: 1), 1);
      expect(dataSource.getPageNumberForAyah(surahNumber: 2, ayahNumber: 1), 2);
    });

    test('loads broad audio reciter catalog and builds ayah urls', () {
      final dataSource = LocalQuranDataSource();
      final ayah = dataSource.getAyahs(2).first;

      final reciters = dataSource.getAudioReciters();

      expect(reciters.length, greaterThanOrEqualTo(50));
      expect(
        reciters.map((reciter) => reciter.id).toSet(),
        hasLength(reciters.length),
      );
      expect(
        reciters.first.audioUrlFor(ayah),
        'https://everyayah.com/data/Alafasy_128kbps/002001.mp3',
      );
      expect(
        reciters
            .firstWhere((reciter) => reciter.id == 'alqurancloud:ar.alafasy')
            .audioUrlFor(ayah),
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/8.mp3',
      );
      expect(
        reciters
            .firstWhere((reciter) => reciter.id == 'alqurancloud:en.walk')
            .audioUrlFor(ayah),
        'https://cdn.islamic.network/quran/audio/192/en.walk/8.mp3',
      );
      expect(
        reciters
            .firstWhere((reciter) => reciter.id == 'alqurancloud:ur.khan')
            .audioUrlFor(ayah),
        'https://cdn.islamic.network/quran/audio/64/ur.khan/8.mp3',
      );
      expect(
        reciters
            .firstWhere(
              (reciter) => reciter.id == 'alqurancloud:fa.hedayatfarfooladvand',
            )
            .audioUrlFor(ayah),
        'https://cdn.islamic.network/quran/audio/40/fa.hedayatfarfooladvand/8.mp3',
      );
      expect(
        reciters
            .firstWhere(
              (reciter) =>
                  reciter.id == 'everyayah:translations/Makarem_Kabiri_16Kbps',
            )
            .audioUrlFor(ayah),
        'https://everyayah.com/data/translations/Makarem_Kabiri_16Kbps/002001.mp3',
      );
      expect(
        reciters
            .firstWhere(
              (reciter) =>
                  reciter.id ==
                  'everyayah:translations/besim_korkut_ajet_po_ajet',
            )
            .audioUrlFor(ayah),
        'https://everyayah.com/data/translations/besim_korkut_ajet_po_ajet/002001.mp3',
      );
      expect(
        reciters
            .firstWhere(
              (reciter) => reciter.id == 'alqurancloud:ru.kuliev-audio-2',
            )
            .audioUrlFor(ayah),
        'https://cdn.islamic.network/quran/audio/320/ru.kuliev-audio-2/8.mp3',
      );
    });
  });
}
