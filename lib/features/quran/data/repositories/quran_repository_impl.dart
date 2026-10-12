import '../../../../core/content/content_source.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/entities/quran_last_read.dart';
import '../../domain/entities/quran_navigation.dart';
import '../../domain/entities/quran_reading_mode.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/local_quran_data_source.dart';
import '../stores/quran_user_data_store.dart';

class QuranRepositoryImpl
    implements
        QuranRepository,
        QuranBookmarkCollectionsRepository,
        QuranStructureRepository {
  const QuranRepositoryImpl({
    required LocalQuranDataSource localDataSource,
    required QuranUserDataStore userDataStore,
  }) : _localDataSource = localDataSource,
       _userDataStore = userDataStore;

  final LocalQuranDataSource _localDataSource;
  final QuranUserDataStore _userDataStore;

  @override
  Future<List<ContentSource>> getContentSources() async {
    return _localDataSource.getContentSources();
  }

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async {
    return _localDataSource.getAudioReciters();
  }

  @override
  Future<String?> getSelectedAudioReciterId() async {
    return _userDataStore.audioReciterId;
  }

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) {
    return _userDataStore.setAudioReciterId(reciterId);
  }

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async {
    return _userDataStore.ayahTextLayout;
  }

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) {
    return _userDataStore.setAyahTextLayout(layout);
  }

  @override
  Future<List<QuranSurah>> getSurahs() async {
    return _localDataSource.getSurahs();
  }

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    return _localDataSource.getSurah(surahNumber);
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async {
    await _localDataSource.ensureQpcHafsLoaded();
    await _localDataSource.ensureIndoPakLoaded();
    return _localDataSource.getAyahs(surahNumber);
  }

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async {
    await _localDataSource.ensureIndoPakLoaded();
    await _localDataSource.ensureQpcHafsLoaded();
    return _localDataSource.getPageAyahs(
      pageNumber,
      includeTranslation: includeTranslation,
      includeTafsir: includeTafsir,
    );
  }

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _localDataSource.getPageNumberForAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async {
    await _localDataSource.ensureQpcHafsLoaded();
    return _localDataSource.search(query, limit: limit);
  }

  @override
  Future<QuranLastRead?> getLastRead() async {
    final surahNumber = _userDataStore.lastReadSurah;
    final ayahNumber = _userDataStore.lastReadAyah;
    final updatedAt = _userDataStore.lastReadUpdatedAt;

    if (surahNumber == null || ayahNumber == null || updatedAt == null) {
      return null;
    }

    return QuranLastRead(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      updatedAt: updatedAt,
      page:
          _userDataStore.lastReadPage ??
          _localDataSource.getPageNumberForAyah(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          ),
      structureKind: _userDataStore.lastNavigationKind,
      structureIndex: _userDataStore.lastNavigationIndex,
      ayahTextLayout: _userDataStore.ayahTextLayout.name,
    );
  }

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) {
    return _userDataStore.saveLastRead(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      updatedAt: DateTime.now(),
      page: _localDataSource.getPageNumberForAyah(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );
  }

  @override
  Future<List<QuranNavigationPoint>> getNavigationPoints(
    QuranStructureKind kind,
  ) async {
    await _localDataSource.ensureQpcHafsLoaded();
    return _localDataSource.getNavigationPoints(kind);
  }

  @override
  Future<void> saveNavigationContext({
    required QuranStructureKind kind,
    required int index,
    required int page,
  }) {
    return _userDataStore.saveNavigationContext(
      kind: kind.name,
      index: index,
      page: page,
    );
  }

  @override
  Future<List<QuranBookmark>> getBookmarks() async {
    return _userDataStore.bookmarkEntries;
  }

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _userDataStore.bookmarks.contains('$surahNumber:$ayahNumber');
  }

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final verseKey = '$surahNumber:$ayahNumber';
    final bookmarks = _userDataStore.bookmarkEntries.toList();
    final index = bookmarks.indexWhere((item) => item.verseKey == verseKey);
    final wasBookmarked = index >= 0;
    if (wasBookmarked) {
      bookmarks.removeAt(index);
    }
    if (!wasBookmarked) {
      bookmarks.add(
        QuranBookmark(
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _userDataStore.setBookmarkEntries(bookmarks);
    return !wasBookmarked;
  }

  @override
  Future<List<QuranBookmarkCollection>> getBookmarkCollections() async {
    return _userDataStore.bookmarkCollections;
  }

  @override
  Future<QuranBookmarkCollection> createBookmarkCollection({
    required String name,
    String description = '',
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final now = DateTime.now();
    final collection = QuranBookmarkCollection(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Collection' : name.trim(),
      description: description.trim(),
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      createdAt: now,
    );
    await _userDataStore.setBookmarkCollections([
      ..._userDataStore.bookmarkCollections,
      collection,
    ]);
    return collection;
  }

  @override
  Future<void> moveBookmarkToCollection({
    required String verseKey,
    required String collectionId,
  }) async {
    final validCollection = _userDataStore.bookmarkCollections.any(
      (item) => item.id == collectionId,
    );
    if (!validCollection) {
      return;
    }
    await _userDataStore.setBookmarkEntries([
      for (final bookmark in _userDataStore.bookmarkEntries)
        if (bookmark.verseKey == verseKey)
          QuranBookmark(
            surahNumber: bookmark.surahNumber,
            ayahNumber: bookmark.ayahNumber,
            createdAt: bookmark.createdAt,
            collectionId: collectionId,
          )
        else
          bookmark,
    ]);
  }

  @override
  Future<void> deleteBookmarkCollection(String collectionId) async {
    if (collectionId == QuranBookmarkCollection.defaultId) {
      return;
    }
    await _userDataStore.setBookmarkEntries([
      for (final bookmark in _userDataStore.bookmarkEntries)
        if (bookmark.collectionId == collectionId)
          QuranBookmark(
            surahNumber: bookmark.surahNumber,
            ayahNumber: bookmark.ayahNumber,
            createdAt: bookmark.createdAt,
          )
        else
          bookmark,
    ]);
    await _userDataStore.setBookmarkCollections(
      _userDataStore.bookmarkCollections
          .where((item) => item.id != collectionId)
          .toList(growable: false),
    );
  }
}
