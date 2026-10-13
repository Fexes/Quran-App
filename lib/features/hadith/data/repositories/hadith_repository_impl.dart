import 'dart:async';

import '../../../../core/content/content_source.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/entities/hadeeth_enc_item.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_chapter.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/services/hadith_authenticity_policy.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../datasources/fawaz_hadith_translation_data_source.dart';
import '../datasources/hadeeth_enc_data_source.dart';
import '../datasources/local_hadith_data_source.dart';
import '../stores/hadeeth_enc_store.dart';
import '../stores/hadith_translation_store.dart';

class HadithRepositoryImpl
    implements
        HadithRepository,
        HadithScopedSearchRepository,
        HadithTranslationPackRepository {
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
    if (!_translationStore.hasFullBook(
      bookId: bookId,
      languageCode: normalized,
    )) {
      return false;
    }
    if (!await _bookSupportsLanguage(bookId, normalized)) {
      return false;
    }
    return _translationStore.hasFullBook(
      bookId: bookId,
      languageCode: normalized,
      requiredNumbers: await _requiredNumbers(bookId),
    );
  }

  @override
  Future<HadithTranslationPackStatus> translationPackStatus(
    String bookId,
    String languageCode,
  ) async {
    final code = languageCode.trim().toLowerCase();
    if (code == 'en') {
      final items = await _localDataSource.getHadiths(
        bookId: bookId,
        limit: 100000,
      );
      return HadithTranslationPackStatus(
        isDownloaded: items.isNotEmpty,
        totalHadiths: items.length,
        translatedHadiths: items
            .where((item) => item.translation.trim().isNotEmpty)
            .length,
      );
    }
    final downloaded = _translationStore.hasDownloadedBook(
      bookId: bookId,
      languageCode: code,
    );
    if (!downloaded &&
        !_translationStore.hasFullBook(bookId: bookId, languageCode: code)) {
      return HadithTranslationPackStatus(
        isDownloaded: false,
        totalHadiths:
            (await _localDataSource.getBook(bookId))?.hadithCount ?? 0,
        translatedHadiths: 0,
      );
    }
    final numbers = await _requiredNumbers(bookId);
    final translations = _translationStore.translationsForBook(
      bookId: bookId,
      languageCode: code,
    );
    final translated = numbers
        .where((number) => translations[number]?.trim().isNotEmpty == true)
        .length;
    return HadithTranslationPackStatus(
      isDownloaded:
          downloaded || (numbers.isNotEmpty && translated == numbers.length),
      totalHadiths: numbers.length,
      translatedHadiths: translated,
    );
  }

  @override
  Stream<HadithTranslationDownloadProgress> downloadBookTranslation(
    String bookId,
    String languageCode,
  ) async* {
    final normalized = languageCode.toLowerCase();
    final status = await translationPackStatus(bookId, normalized);
    final available = status.isDownloaded;
    yield HadithTranslationDownloadProgress(
      bookId: bookId,
      languageCode: normalized,
      completedItems: available ? status.totalHadiths : 0,
      totalItems: status.totalHadiths,
      isComplete: available,
      hasFailed: false,
      unavailableTranslations: available ? status.unavailableTranslations : 0,
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

    final requiredNumbers = await _requiredNumbers(bookId);
    var cancelled = false;
    final updates = StreamController<HadithTranslationDownloadProgress>(
      onCancel: () => cancelled = true,
    );
    void report(double progress, String stage) {
      if (cancelled || updates.isClosed) return;
      updates.add(
        HadithTranslationDownloadProgress(
          bookId: bookId,
          languageCode: normalized,
          completedItems: 0,
          totalItems: requiredNumbers.length,
          downloadProgress: progress,
          stage: stage,
        ),
      );
    }

    Future<void> download() async {
      try {
        final result = await _translationDataSource.downloadBookTranslation(
          bookId: bookId,
          languageCode: normalized,
          isCancelled: () => cancelled,
          onProgress: (value) => report(value * 0.85, 'Downloading'),
        );
        if (cancelled) return;
        report(0.9, 'Saving');
        await _translationStore.saveBookTranslations(
          bookId: bookId,
          languageCode: normalized,
          editionName: result.editionName,
          translations: result.translations,
          requiredNumbers: requiredNumbers,
          sourceDownloadComplete: true,
        );
        await _translationDataSource.finishBookDownload(bookId, normalized);
        final translated = requiredNumbers
            .where(
              (number) =>
                  result.translations[number]?.trim().isNotEmpty == true,
            )
            .length;
        if (cancelled) return;
        updates.add(
          HadithTranslationDownloadProgress(
            bookId: bookId,
            languageCode: normalized,
            completedItems: requiredNumbers.length,
            totalItems: requiredNumbers.length,
            isComplete: _translationStore.hasDownloadedBook(
              bookId: bookId,
              languageCode: normalized,
            ),
            unavailableTranslations: requiredNumbers.length - translated,
          ),
        );
      } catch (error) {
        if (!cancelled) {
          updates.add(
            HadithTranslationDownloadProgress(
              bookId: bookId,
              languageCode: normalized,
              completedItems: 0,
              totalItems: 1,
              hasFailed: true,
              errorMessage: error.toString(),
            ),
          );
        }
      } finally {
        if (!updates.isClosed) await updates.close();
      }
    }

    unawaited(download());
    yield* updates.stream;
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
      final item = hadeethEncItem.toHadithItem();
      return HadithAuthenticityPolicy.shouldShow(item) ? item : null;
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
      ...await compute(_translatedIndexRecords, {
        'records': records,
        'packs': _translationStore.cachedPacks(),
      }),
      ...await compute(_hadeethEncIndexRecords, [
        for (final languageCode in _hadeethEncStore.downloadedLanguageCodes())
          ..._hadeethEncStore.itemsForLanguage(languageCode),
      ]),
    ];
  }

  @override
  Future<List<HadithItem>> search(String query, {int limit = 30}) async {
    final matches = await compute(_searchContentRecords, {
      'records': await getSearchIndexRecords(),
      'query': SearchTextNormalizer.normalize(query),
      'limit': limit,
    });
    final results = <HadithItem>[];
    for (final record in matches) {
      final item = await getHadithById(
        record.targetId,
        languageCode: record.languageCode,
      );
      if (item != null) results.add(item);
    }
    return results;
  }

  @override
  Future<List<HadithItem>> searchInBook({
    required String bookId,
    required String query,
    String? languageCode,
    int limit = 50,
  }) async {
    final items = await _localDataSource.getHadiths(
      bookId: bookId,
      limit: 100000,
    );
    return compute(searchHadithBook, {
      'hadiths': _applyCachedTranslation(items, languageCode),
      'query': SearchTextNormalizer.normalize(query),
      'limit': limit,
    });
  }

  Future<List<String>> _requiredNumbers(String bookId) async =>
      (await _localDataSource.getHadiths(
        bookId: bookId,
        limit: 100000,
      )).map((item) => item.hadithNumber).toList();

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
    return _hadeethEncStore.hasFullLanguage(languageCode) &&
        _hadeethEncStore
            .itemsForLanguage(languageCode)
            .any(
              (item) =>
                  item.hadithTextArabic.trim().isNotEmpty &&
                  item.hadithText.trim().isNotEmpty &&
                  HadithAuthenticityPolicy.shouldShow(item.toHadithItem()),
            );
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
    if (await hasHadeethEncLanguage(languageCode)) {
      final items = _hadeethEncStore.itemsForLanguage(languageCode);
      yield HadeethEncDownloadProgress(
        languageCode: languageCode,
        completedItems: items.length,
        totalItems: items.length,
        isComplete: true,
      );
      return;
    }
    var cancelled = false;
    final updates = StreamController<HadeethEncDownloadProgress>(
      onCancel: () => cancelled = true,
    );
    void report(double progress, String stage) {
      if (cancelled || updates.isClosed) return;
      updates.add(
        HadeethEncDownloadProgress(
          languageCode: languageCode,
          completedItems: 0,
          totalItems: 0,
          downloadProgress: progress,
          stage: stage,
        ),
      );
    }

    Future<void> download() async {
      try {
        final result = await _hadeethEncDataSource.downloadLanguage(
          languageCode,
          isCancelled: () => cancelled,
          onProgress: (value) => report(value * 0.85, 'Downloading'),
        );
        if (cancelled) return;
        if (!result.items.any(
          (item) =>
              item.hadithTextArabic.trim().isNotEmpty &&
              item.hadithText.trim().isNotEmpty &&
              HadithAuthenticityPolicy.shouldShow(item.toHadithItem()),
        )) {
          throw const FormatException(
            'No translated authentic hadiths were found',
          );
        }
        report(0.9, 'Saving');
        await _hadeethEncStore.saveLanguageItems(
          languageCode: languageCode,
          version: result.version,
          items: result.items,
        );
        await _hadeethEncDataSource.finishLanguageDownload(languageCode);
        if (cancelled) return;
        updates.add(
          HadeethEncDownloadProgress(
            languageCode: languageCode,
            completedItems: result.items.length,
            totalItems: result.items.length,
            isComplete: true,
          ),
        );
      } catch (_) {
        if (!cancelled) {
          updates.add(
            HadeethEncDownloadProgress(
              languageCode: languageCode,
              completedItems: 0,
              totalItems: 0,
              hasFailed: true,
            ),
          );
        }
      } finally {
        if (!updates.isClosed) await updates.close();
      }
    }

    unawaited(download());
    yield* updates.stream;
  }

  @override
  Future<List<HadeethEncItem>> getHadeethEncItems({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  }) async {
    return _hadeethEncStore
        .itemsForLanguage(languageCode)
        .where(
          (item) => HadithAuthenticityPolicy.shouldShow(item.toHadithItem()),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<HadeethEncItem>> searchHadeethEnc({
    required String languageCode,
    required String query,
    int limit = 30,
  }) async {
    final matches = _hadeethEncStore.search(
      languageCode: languageCode,
      query: query,
      limit: 100000,
    );
    return matches
        .where(
          (item) => HadithAuthenticityPolicy.shouldShow(item.toHadithItem()),
        )
        .take(limit)
        .toList();
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

  static List<DeepSearchIndexRecord> _hadeethEncIndexRecords(
    List<HadeethEncItem> items,
  ) => [
    for (final item in items)
      if (HadithAuthenticityPolicy.shouldShow(item.toHadithItem()))
        _hadeethEncIndexRecord(item),
  ];

  static DeepSearchIndexRecord _hadeethEncIndexRecord(HadeethEncItem item) {
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

List<DeepSearchIndexRecord> _searchContentRecords(Map<String, Object> args) {
  final query = args['query'] as String;
  if (query.isEmpty) return const [];
  final records = args['records'] as List<DeepSearchIndexRecord>;
  return records
      .where((record) => record.normalizedText.contains(query))
      .take(args['limit'] as int)
      .toList();
}

List<DeepSearchIndexRecord> _translatedIndexRecords(Map<String, Object> args) {
  final records = args['records'] as List<DeepSearchIndexRecord>;
  final byId = {for (final record in records) record.targetId: record};
  final packs =
      args['packs']
          as List<
            ({
              String bookId,
              String languageCode,
              Map<String, String> translations,
            })
          >;
  return [
    for (final pack in packs)
      for (final entry in pack.translations.entries)
        if (entry.value.trim().isNotEmpty)
          if (byId['hadith:${pack.bookId}:${entry.key}'] case final record?)
            DeepSearchIndexRecord(
              id: '${record.id}:translation:${pack.languageCode}',
              category: 'hadith',
              title: record.title,
              subtitle: pack.languageCode,
              primaryPreview: record.primaryPreview,
              secondaryPreview: SearchTextNormalizer.cleanVisibleText(
                entry.value,
              ),
              normalizedText: SearchTextNormalizer.normalize(
                '${record.title} ${entry.value}',
              ),
              targetType: 'hadith',
              targetId: record.targetId,
              bookId: record.bookId,
              languageCode: pack.languageCode,
            ),
  ];
}
