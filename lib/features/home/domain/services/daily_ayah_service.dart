import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../entities/daily_ayah.dart';

class DailyAyahReference {
  const DailyAyahReference({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;
}

class DailyAyahService {
  const DailyAyahService();

  Future<DailyAyah> load({
    required DateTime date,
    required QuranRepository quranRepository,
    QuranTranslationRepository? translationRepository,
  }) async {
    final surahs = await quranRepository.getSurahs();
    final reference = dailyAyahReferenceForDate(date, surahs);
    final surah = surahs.firstWhere(
      (item) => item.number == reference.surahNumber,
    );
    final ayahs = await quranRepository.getAyahs(reference.surahNumber);
    final ayah = ayahs.firstWhere(
      (item) => item.number == reference.ayahNumber,
    );

    var translation = ayah.translation.trim();
    final translations = translationRepository;
    final selectedResource = await translations?.selectedTranslation();
    var visibleResource = selectedResource;
    if (selectedResource != null &&
        translations != null &&
        await translations.hasFullTranslation(selectedResource.id)) {
      final cached = await translations.cachedTranslationForVerse(
        selectedResource.id,
        ayah.verseKey,
      );
      if (cached != null && cached.trim().isNotEmpty) {
        translation = cached.trim();
      } else {
        visibleResource = null;
      }
    } else {
      visibleResource = null;
    }

    return DailyAyah(
      date: DateTime(date.year, date.month, date.day),
      ayah: ayah,
      surah: surah,
      translation: translation,
      translationResource: visibleResource,
    );
  }
}

DailyAyahReference dailyAyahReferenceForDate(
  DateTime date,
  List<QuranSurah> surahs,
) {
  if (surahs.isEmpty) {
    throw StateError('No Quran metadata is available.');
  }
  final totalAyahs = surahs.fold<int>(0, (sum, item) => sum + item.ayahCount);
  if (totalAyahs <= 0) {
    throw StateError('Quran metadata does not contain any ayahs.');
  }

  final localCalendarDay = DateTime.utc(date.year, date.month, date.day);
  final daysSinceEpoch =
      localCalendarDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  const dayStep = 7919;
  const seed = 104729;
  var remaining = (((daysSinceEpoch * dayStep) + seed) % totalAyahs) + 1;

  for (final surah in surahs) {
    if (remaining <= surah.ayahCount) {
      return DailyAyahReference(
        surahNumber: surah.number,
        ayahNumber: remaining,
      );
    }
    remaining -= surah.ayahCount;
  }

  final last = surahs.last;
  return DailyAyahReference(
    surahNumber: last.number,
    ayahNumber: last.ayahCount,
  );
}
