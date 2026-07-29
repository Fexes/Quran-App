import '../entities/quran_word.dart';

abstract interface class QuranInterlinearRepository {
  String get cacheVersion;

  Future<List<QuranWord>> getPageWords(
    int pageNumber, {
    String language = 'en',
  });

  Future<List<QuranWord>> cachedPageWords(
    int pageNumber, {
    String language = 'en',
  });

  Future<bool> hasFullCache({String language = 'en'});

  Stream<QuranInterlinearDownloadProgress> downloadFullCache({
    String language = 'en',
  });
}

abstract interface class QuranInterlinearCacheMetadataRepository {
  Future<DateTime?> fullCacheExpiresAt({String language = 'en'});
}
