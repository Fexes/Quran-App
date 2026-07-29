import '../entities/quran_tafsir.dart';

abstract interface class QuranTafsirRepository {
  Future<List<QuranTafsirResource>> tafsirResources();

  Future<QuranTafsirResource?> defaultResourceForLanguage(String? languageName);

  Future<QuranTafsirResult?> tafsirForVerse({
    required String verseKey,
    required String? languageName,
  });

  Future<bool> hasDownloadedSurahTafsir({
    required int surahNumber,
    required String? languageName,
  });

  Stream<QuranTafsirDownloadProgress> downloadSurahTafsir({
    required int surahNumber,
    required String? languageName,
  });
}

abstract interface class QuranTafsirEditionRepository {
  Future<QuranTafsirResource?> resourceForId(int resourceId);

  Future<QuranTafsirResult?> tafsirForVerseByResource({
    required String verseKey,
    required int resourceId,
  });
}
