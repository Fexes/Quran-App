import 'package:flutter/foundation.dart';

import '../entities/quran_translation.dart';

abstract interface class QuranTranslationRepository {
  Future<List<QuranTranslationLanguage>> translationLanguages();

  Future<QuranTranslationResource?> selectedTranslation();

  Future<void> setSelectedTranslation(int? resourceId);

  Future<bool> hasFullTranslation(int resourceId);

  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  );

  Future<String?> cachedTranslationForVerse(int resourceId, String verseKey);

  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  );
}

abstract interface class QuranTranslationSelectionObservable {
  Listenable get selectionChanges;
}

abstract interface class QuranReadingLanguageDownloadRepository {
  Future<bool> hasFullReadingLanguage(int resourceId);
}

extension QuranReadingLanguageAvailability on QuranTranslationRepository {
  Future<bool> hasReadyReadingLanguage(int resourceId) =>
      this is QuranReadingLanguageDownloadRepository
      ? (this as QuranReadingLanguageDownloadRepository).hasFullReadingLanguage(
          resourceId,
        )
      : hasFullTranslation(resourceId);
}

abstract interface class QuranTranslationCacheMetadataRepository {
  Future<DateTime?> fullTranslationExpiresAt(int resourceId);
}

abstract interface class QuranMultiTranslationRepository {
  Future<List<QuranTranslationResource>> selectedTranslations();

  Future<void> setSelectedTranslations(List<int> resourceIds);

  Future<List<QuranTranslationResource>> downloadedTranslations();

  Future<QuranTranslationPackStatus> translationPackStatus(int resourceId);

  Stream<QuranTranslationDownloadProgress> downloadSurahTranslation(
    int resourceId,
    int surahNumber,
  );

  Future<void> deleteTranslation(int resourceId);
}
