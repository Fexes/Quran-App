import '../../../../core/content/content_source.dart';
import '../entities/quran_audio_reciter.dart';
import '../entities/quran_ayah.dart';
import '../entities/quran_bookmark.dart';
import '../entities/quran_last_read.dart';
import '../entities/quran_navigation.dart';
import '../entities/quran_reading_mode.dart';
import '../entities/quran_surah.dart';

abstract interface class QuranRepository {
  Future<List<ContentSource>> getContentSources();

  Future<List<QuranAudioReciter>> getAudioReciters();

  Future<String?> getSelectedAudioReciterId();

  Future<void> saveSelectedAudioReciterId(String reciterId);

  Future<QuranAyahTextLayout> getAyahTextLayout();

  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout);

  Future<List<QuranSurah>> getSurahs();

  Future<QuranSurah> getSurah(int surahNumber);

  Future<List<QuranAyah>> getAyahs(int surahNumber);

  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  });

  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  });

  Future<List<QuranAyah>> search(String query, {int limit = 30});

  Future<QuranLastRead?> getLastRead();

  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  });

  Future<List<QuranBookmark>> getBookmarks();

  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  });

  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  });
}

abstract interface class QuranStructureRepository {
  Future<List<QuranNavigationPoint>> getNavigationPoints(
    QuranStructureKind kind,
  );

  Future<void> saveNavigationContext({
    required QuranStructureKind kind,
    required int index,
    required int page,
  });
}

abstract interface class QuranBookmarkCollectionsRepository {
  Future<List<QuranBookmarkCollection>> getBookmarkCollections();

  Future<QuranBookmarkCollection> createBookmarkCollection({
    required String name,
    String description = '',
    required int colorValue,
    required int iconCodePoint,
  });

  Future<void> moveBookmarkToCollection({
    required String verseKey,
    required String collectionId,
  });

  Future<void> deleteBookmarkCollection(String collectionId);
}
