import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/entities/hadeeth_enc_item.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_chapter.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/fawaz_hadith_translation_data_source.dart';
import '../datasources/hadeeth_enc_data_source.dart';
import '../datasources/local_hadith_data_source.dart';
import '../stores/hadeeth_enc_store.dart';
import '../stores/hadith_translation_store.dart';

class HadithRepositoryImpl
    implements HadithRepository, HadithScopedSearchRepository {
  const HadithRepositoryImpl({
    required LocalHadithDataSource localDataSource,
    required HadeethEncDataSource hadeethEncDataSource,
    required HadeethEncStore hadeethEncStore,
    required FawazHadithTranslationDataSource translationDataSource,
    required HadithTranslationStore translationStore,
  }) : _localDataSource = localDataSource,
       _hadeethEncDataSource = hadeethEncDataSource,
       _hadeethEncStore = hadeethEncStore,
       _translationDataSource = translationDataSource,
       _translationStore = translationStore;

  final LocalHadithDataSource _localDataSource;
  final HadeethEncDataSource _hadeethEncDataSource;
  final HadeethEncStore _hadeethEncStore;
  final FawazHadithTranslationDataSource _translationDataSource;
  final HadithTranslationStore _translationStore;

  @override
  Future<List<ContentSource>> getContentSources() async {
    final sources = await _localDataSource.getContentSources();
    return [
      ...sources,
      const ContentSource(
        id: 'hadeethenc',
        name: 'HadeethEnc',
        attribution:
            'Multilingual hadith translations from HadeethEnc.com. Content is shown with source attribution and version metadata when downloaded.',
        description: 'Encyclopedia of translated authentic Prophetic hadiths.',
        url: 'https://hadeethenc.com',
        license: 'HadeethEnc terms and policies',
      ),
    ];
  }

  @override
  Future<List<HadithBook>> getBooks() async {
    return _localDataSource.getBooks();
  }

  @override
  Future<HadithBook?> getBook(String bookId) async {
    return _localDataSource.getBook(bookId);
  }

  @override
  Future<List<HadithChapter>> getChapters(String bookId) async {
    return _localDataSource.getChapters(bookId);
  }

  @override
  Future<List<String>> availableTranslationLanguagesForBook(
    String bookId,
  ) async {
    return _localDataSource.availableTranslationLanguagesForBook(bookId);
  }

  @override
  Future<bool> hasFullTranslation(String bookId, String languageCode) async {
    final normalized = languageCode.toLowerCase();
    if (normalized == 'en') {
      return _localDataSource.hasFullTranslation(bookId, normalized);
    }
    if (!await _bookSupportsLanguage(bookId, normalized)) {
      return false;
    }
    return _translationStore.hasFullBook(
      bookId: bookId,
      languageCode: normalized,
    );
  }

  @override
  Stream<HadithTranslationDownloadProgress> downloadBookTranslation(
    String bookId,
    String languageCode,
  ) async* {
    final normalized = languageCode.toLowerCase();
    final available = await hasFullTranslation(bookId, normalized);
    yield HadithTranslationDownloadProgress(
      bookId: bookId,
      languageCode: normalized,
      completedItems: available ? 1 : 0,
      totalItems: 1,
      isComplete: available,
      hasFailed: false,
    );
    if (available) {
      return;
    }
    if (!await _bookSupportsLanguage(bookId, normalized)) {
      yield HadithTranslationDownloadProgress(
        bookId: bookId,
        languageCode: normalized,
        completedItems: 0,
        totalItems: 1,
        hasFailed: true,
      );
      return;
    }

    try {
      final result = await _translationDataSource.downloadBookTranslation(
        bookId: bookId,
        languageCode: normalized,
      );
      await _translationStore.saveBookTranslations(
        bookId: bookId,
        languageCode: normalized,
        editionName: result.editionName,
        translations: result.translations,
      );
      yield HadithTranslationDownloadProgress(
        bookId: bookId,
        languageCode: normalized,
        completedItems: result.translations.length,
        totalItems: result.translations.length,
        isComplete: result.translations.isNotEmpty,
        hasFailed: result.translations.isEmpty,
      );
    } catch (_) {
      yield HadithTranslationDownloadProgress(
        bookId: bookId,
        languageCode: normalized,
        completedItems: 0,
        totalItems: 1,
        hasFailed: true,
      );
    }
  }

  @override
  Future<List<HadithItem>> getHadiths({
    String? bookId,
    String? chapterId,
    String? languageCode,
    int offset = 0,
    int limit = 50,
  }) async {
    final items = await _localDataSource.getHadiths(
      bookId: bookId,
      chapterId: chapterId,
      languageCode: languageCode,
      offset: offset,
      limit: limit,
    );
    return _applyCachedTranslation(items, languageCode);
  }

  @override
  Future<HadithItem?> getHadithById(String id, {String? languageCode}) async {
    final hadeethEncItem = _hadeethEncItemFromId(id);
    if (hadeethEncItem != null) {
      return hadeethEncItem.toHadithItem();
    }
    final item = await _localDataSource.getHadithById(
      id,
      languageCode: languageCode,
    );
    if (item == null) {
      return null;
    }
    return _applyCachedTranslation([item], languageCode).firstOrNull;
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() async {
    final records = await _localDataSource.getSearchIndexRecords();
    return [
      ...records,
      for (final languageCode in _hadeethEncStore.downloadedLanguageCodes())
        for (final item in _hadeethEncStore.itemsForLanguage(languageCode))
          _hadeethEncIndexRecord(item),
    ];
  }

  @override
  Future<List<HadithItem>> search(String query, {int limit = 30}) async {
    final local = await _localDataSource.search(query, limit: limit);
    final translated = <HadithItem>[];
    for (final languageCode in _hadeethEncStore.downloadedLanguageCodes()) {
      final remaining = limit - local.length - translated.length;
      if (remaining <= 0) {
        break;
      }
      translated.addAll(
        _hadeethEncStore
            .search(languageCode: languageCode, query: query, limit: remaining)
            .map((item) => item.toHadithItem()),
      );
    }
    return [...local, ...translated].take(limit).toList(growable: false);
  }

  @override
  Future<List<HadithItem>> searchInBook({
    required String bookId,
    required String query,
    String? languageCode,
    int limit = 50,
  }) async {
    final items = await _localDataSource.searchInBook(
      bookId,
      query,
      limit: limit,
    );
    return _applyCachedTranslation(items, languageCode);
  }

  @override
  Future<List<HadeethEncLanguage>> getHadeethEncLanguages() async {
    final cached = _hadeethEncStore.languages();
    if (cached.isNotEmpty) {
      return cached;
    }
    final languages = await _hadeethEncDataSource.languages();
    await _hadeethEncStore.saveLanguages(languages);
    return languages;
  }

  @override
  Future<bool> hasHadeethEncLanguage(String languageCode) async {
    return _hadeethEncStore.hasFullLanguage(languageCode);
  }

  @override
  Stream<HadeethEncDownloadProgress> downloadHadeethEncLanguage(
    String languageCode,
  ) async* {
    yield HadeethEncDownloadProgress(
      languageCode: languageCode,
      completedItems: 0,
      totalItems: 0,
    );
    try {
      final result = await _hadeethEncDataSource.downloadLanguage(languageCode);
      await _hadeethEncStore.saveLanguageItems(
        languageCode: languageCode,
        version: result.version,
        items: result.items,
      );
      yield HadeethEncDownloadProgress(
        languageCode: languageCode,
        completedItems: result.items.length,
        totalItems: result.items.length,
        isComplete: true,
      );
    } catch (_) {
      yield HadeethEncDownloadProgress(
        languageCode: languageCode,
        completedItems: 0,
        totalItems: 0,
        hasFailed: true,
      );
    }
  }

  @override
  Future<List<HadeethEncItem>> getHadeethEncItems({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  }) async {
    return _hadeethEncStore.pageForLanguage(
      languageCode: languageCode,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<List<HadeethEncItem>> searchHadeethEnc({
    required String languageCode,
    required String query,
    int limit = 30,
  }) async {
    return _hadeethEncStore.search(
      languageCode: languageCode,
      query: query,
      limit: limit,
    );
  }

  HadeethEncItem? _hadeethEncItemFromId(String id) {
    if (!id.startsWith('hadeethenc:')) {
      return null;
    }
    final parts = id.split(':');
    if (parts.length < 3) {
      return null;
    }
    final languageCode = parts[1];
    final itemId = parts.sublist(2).join(':');
    return _hadeethEncStore.itemById(languageCode: languageCode, id: itemId);
  }

  DeepSearchIndexRecord _hadeethEncIndexRecord(HadeethEncItem item) {
    final hadith = item.toHadithItem();
    final title = item.title.trim().isEmpty
        ? 'HadeethEnc ${item.id}'
        : item.title.trim();
    return DeepSearchIndexRecord(
      id: hadith.id,
      category: 'hadith',
      title: title,
      subtitle: 'HadeethEnc • ${item.languageCode}',
      primaryPreview: item.hadithTextArabic,
      secondaryPreview: item.hadithText,
      normalizedText: SearchTextNormalizer.normalize(
        '${item.id} ${item.title} ${item.hadithText} ${item.explanation} '
        '${item.grade} ${item.attribution} ${item.hadithTextArabic}',
      ),
      targetType: 'hadith',
      targetId: hadith.id,
      bookId: 'hadeethenc',
    );
  }

  Future<bool> _bookSupportsLanguage(String bookId, String languageCode) async {
    if (FawazHadithTranslationDataSource.editionPrefixFor(languageCode) ==
        null) {
      return false;
    }
    final available = await _localDataSource
        .availableTranslationLanguagesForBook(bookId);
    return available.contains(languageCode);
  }

  List<HadithItem> _applyCachedTranslation(
    List<HadithItem> items,
    String? languageCode,
  ) {
    final normalized = languageCode?.toLowerCase();
    if (normalized == null || normalized == 'en') {
      return items;
    }
    return [
      for (final item in items)
        _copyWithTranslation(
          item,
          _translationStore.translationFor(
                bookId: item.bookId,
                languageCode: normalized,
                hadithNumber: item.hadithNumber,
              ) ??
              '',
        ),
    ];
  }

  HadithItem _copyWithTranslation(HadithItem item, String translation) {
    return HadithItem(
      id: item.id,
      bookId: item.bookId,
      chapterId: item.chapterId,
      hadithNumber: item.hadithNumber,
      arabic: item.arabic,
      translation: translation,
      grade: item.grade,
      reference: item.reference,
      sourceId: item.sourceId,
      bookSlug: item.bookSlug,
      chapterNumber: item.chapterNumber,
      bookNumber: item.bookNumber,
      arabicNumber: item.arabicNumber,
      englishEdition: item.englishEdition,
      arabicEdition: item.arabicEdition,
      grades: item.grades,
      collectionName: item.collectionName,
      cleanReference: item.cleanReference,
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
