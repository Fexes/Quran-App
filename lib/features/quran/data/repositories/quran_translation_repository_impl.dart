import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/content/content_cache_policy.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../library/domain/services/library_language_download_service.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import '../../domain/services/quran_translation_audio_pairings.dart';
import '../stores/quran_translation_store.dart';

typedef QuranTranslationResourcesFetcher =
    Future<Map<String, Object?>> Function();

// Text-only language defaults. Verified audio-linked editions take priority below.
const _recommendedTranslationIds = {
  'ur': 234,
  'en': 85,
  'bn': 161,
  'es': 83,
  'fa': 29,
  'fr': 31,
  'id': 33,
  'it': 153,
  'ms': 39,
  'nl': 144,
  'pt': 43,
  'ru': 45,
  'sq': 47,
  'sw': 49,
  'th': 230,
  'tr': 77,
  'vi': 220,
  'zh': 56,
};

typedef QuranChapterTranslationFetcher =
    Future<Map<String, Object?>> Function({
      required int chapterNumber,
      required int resourceId,
    });

class QuranTranslationRepositoryImpl
    implements
        QuranTranslationRepository,
        QuranTranslationCacheMetadataRepository,
        QuranMultiTranslationRepository,
        QuranTranslationSelectionObservable,
        QuranReadingLanguageDownloadRepository {
  QuranTranslationRepositoryImpl({
    required QuranTranslationStore store,
    SettingsStore? settingsStore,
    LibraryLanguageDownloadService? libraryDownloads,
    QuranTranslationResourcesFetcher? resourcesFetcher,
    QuranChapterTranslationFetcher? chapterTranslationFetcher,
    int totalChaptersForDownload = 114,
    int totalVersesForDownload = 6236,
  }) : _store = store,
       _settingsStore = settingsStore,
       _libraryDownloads = libraryDownloads,
       _resourcesFetcher = resourcesFetcher ?? _fetchResourcesJson,
       _chapterTranslationFetcher =
           chapterTranslationFetcher ?? _fetchChapterTranslationJson,
       _totalChaptersForDownload = totalChaptersForDownload,
       _totalVersesForDownload = totalVersesForDownload;

  static const currentCacheVersion = 'quran-com-v4-translations-v1';
  static const contentCachePolicy = ContentCachePolicy.quranFoundation;

  final QuranTranslationStore _store;
  final SettingsStore? _settingsStore;
  final LibraryLanguageDownloadService? _libraryDownloads;

  @override
  Future<bool> hasFullReadingLanguage(int resourceId) async {
    if (!await hasFullTranslation(resourceId)) return false;
    final downloads = _libraryDownloads;
    if (downloads == null) return true;
    final resource = await _resourceForId(resourceId);
    return resource != null && await downloads.isReady(resource);
  }

  final QuranTranslationResourcesFetcher _resourcesFetcher;
  final QuranChapterTranslationFetcher _chapterTranslationFetcher;
  final int _totalChaptersForDownload;
  final int _totalVersesForDownload;

  @override
  Listenable get selectionChanges => _store.selectionChanges;

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async {
    final resources = await _resources();
    return _languagesFromResources(resources);
  }

  @override
  Future<QuranTranslationResource?> selectedTranslation() async {
    return _store.selectedResource();
  }

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {
    if (resourceId == null) {
      await _saveAudioEditionPreference(null);
      await _store.saveSelectedResources(const []);
      await _store.saveSelectedResource(null);
      return;
    }
    final selected = await _resourceForId(resourceId);
    if (selected != null) {
      final resource = selected;
      await _saveAudioEditionPreference(resource);
      await _store.saveSelectedResources([resource]);
      await _store.saveSelectedResource(resource);
    }
  }

  @override
  Future<List<QuranTranslationResource>> selectedTranslations() async {
    final primary = await selectedTranslation();
    return _readerSelection([?primary, ..._store.selectedResources()]);
  }

  @override
  Future<void> setSelectedTranslations(List<int> resourceIds) async {
    final resources = await _resources();
    final byId = {for (final resource in resources) resource.id: resource};
    final selected = <QuranTranslationResource>[];
    for (final id in resourceIds.take(3)) {
      final resource = byId[id];
      if (resource != null && !selected.any((item) => item.id == id)) {
        selected.add(resource);
      }
    }
    final normalized = _readerSelection(selected);
    await _saveAudioEditionPreference(normalized.firstOrNull);
    await _store.saveSelectedResources(normalized);
    await _store.saveSelectedResource(normalized.firstOrNull);
  }

  Future<void> _saveAudioEditionPreference(
    QuranTranslationResource? resource,
  ) async {
    final settings = _settingsStore;
    if (settings == null) return;
    await settings.setAudioMeaningLanguageCode(
      resource?.resolvedLanguageCode ?? '',
    );
    final pair = resource == null
        ? null
        : quranTranslationPairForResource(resource.id);
    if (pair == null) {
      await settings.setAudioTranslationReciterId('');
      await settings.setAudioPlayTranslationEnabled(false);
    } else if (!pair.voiceIds.contains(settings.audioTranslationReciterId)) {
      await settings.setAudioTranslationReciterId(
        pair.voiceIds.first,
        languageCode: resource!.resolvedLanguageCode,
      );
    }
  }

  static List<QuranTranslationResource> _readerSelection(
    Iterable<QuranTranslationResource> resources,
  ) {
    final unique = <int, QuranTranslationResource>{};
    for (final resource in resources) {
      unique.putIfAbsent(resource.id, () => resource);
    }
    final primary = unique.values.firstOrNull;
    if (primary?.isUrdu == true) return [primary!];
    return unique.values.take(3).toList(growable: false);
  }

  @override
  Future<List<QuranTranslationResource>> downloadedTranslations() async {
    final resources = await _resources();
    final selected = _store.selectedResources();
    final byId = {for (final resource in resources) resource.id: resource};
    for (final resource in selected) {
      byId[resource.id] = resource;
    }
    final ids = _store.downloadedResourceIds(cachePolicy: contentCachePolicy);
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ]..sort((a, b) => a.displayLanguage.compareTo(b.displayLanguage));
  }

  @override
  Future<QuranTranslationPackStatus> translationPackStatus(
    int resourceId,
  ) async {
    var surahs = _store.downloadedSurahs(
      resourceId: resourceId,
      cachePolicy: contentCachePolicy,
    );
    if (surahs.isEmpty && await hasFullTranslation(resourceId)) {
      surahs = [for (var surah = 1; surah <= 114; surah++) surah];
    }
    DateTime? earliestExpiry;
    DateTime? latestDownload;
    for (final surah in surahs) {
      final downloadedAt = _store.surahTranslationDownloadedAt(
        resourceId: resourceId,
        surahNumber: surah,
      );
      if (downloadedAt != null &&
          (latestDownload == null || downloadedAt.isAfter(latestDownload))) {
        latestDownload = downloadedAt;
      }
      final expiry = _store.surahTranslationExpiresAt(
        resourceId: resourceId,
        surahNumber: surah,
        cachePolicy: contentCachePolicy,
      );
      if (expiry != null &&
          (earliestExpiry == null || expiry.isBefore(earliestExpiry))) {
        earliestExpiry = expiry;
      }
    }
    return QuranTranslationPackStatus(
      downloadedSurahs: surahs,
      cachedBytes: _store.cachedResourceBytes(resourceId),
      downloadedAt: latestDownload,
      expiresAt: earliestExpiry,
    );
  }

  @override
  Stream<QuranTranslationDownloadProgress> downloadSurahTranslation(
    int resourceId,
    int surahNumber,
  ) async* {
    final resource = await _resourceForId(resourceId);
    final chapter = surahNumber.clamp(1, 114);
    if (resource == null) {
      yield const QuranTranslationDownloadProgress(
        completedChapters: 0,
        totalChapters: 1,
        completedVerses: 0,
        totalVerses: 1,
        failedChapters: 1,
      );
      return;
    }
    if (_store.hasSurahTranslation(
      resourceId: resourceId,
      surahNumber: chapter,
      cachePolicy: contentCachePolicy,
    )) {
      final count = _store
          .translationsForSurah(
            resourceId: resourceId,
            surahNumber: chapter,
            cachePolicy: contentCachePolicy,
          )
          .length;
      yield QuranTranslationDownloadProgress(
        completedChapters: 1,
        totalChapters: 1,
        completedVerses: count,
        totalVerses: count,
        failedChapters: 0,
        isComplete: true,
      );
      return;
    }
    yield const QuranTranslationDownloadProgress(
      completedChapters: 0,
      totalChapters: 1,
      completedVerses: 0,
      totalVerses: 1,
      failedChapters: 0,
    );
    try {
      final json = await _chapterTranslationFetcher(
        chapterNumber: chapter,
        resourceId: resourceId,
      );
      final translations = parseChapterTranslations(
        json: json,
        resourceId: resourceId,
      );
      if (translations.isEmpty) {
        throw const FormatException('Translation pack was empty.');
      }
      await _store.saveVerseTranslations(
        resourceId: resourceId,
        translations: translations,
      );
      await _store.markSurahTranslationComplete(
        resource: resource,
        surahNumber: chapter,
        verseCount: translations.length,
      );
      yield QuranTranslationDownloadProgress(
        completedChapters: 1,
        totalChapters: 1,
        completedVerses: translations.length,
        totalVerses: translations.length,
        failedChapters: 0,
        isComplete: true,
      );
    } catch (_) {
      yield const QuranTranslationDownloadProgress(
        completedChapters: 0,
        totalChapters: 1,
        completedVerses: 0,
        totalVerses: 1,
        failedChapters: 1,
      );
    }
  }

  @override
  Future<void> deleteTranslation(int resourceId) {
    return _store.deleteResource(resourceId);
  }

  @override
  Future<bool> hasFullTranslation(int resourceId) async {
    return _store.hasFullTranslation(
      resourceId: resourceId,
      version: currentCacheVersion,
      verseCount: _totalVersesForDownload,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Future<DateTime?> fullTranslationExpiresAt(int resourceId) async {
    return _store.fullTranslationExpiresAt(
      resourceId: resourceId,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {
    final resource = await _resourceForId(resourceId);
    if (resource == null) {
      yield QuranTranslationDownloadProgress(
        completedChapters: 0,
        totalChapters: _totalChaptersForDownload,
        completedVerses: 0,
        totalVerses: _totalVersesForDownload,
        failedChapters: _totalChaptersForDownload,
      );
      return;
    }

    final existingChapters = _store.downloadedSurahs(
      resourceId: resourceId,
      cachePolicy: contentCachePolicy,
    );
    var completedChapters = existingChapters.length;
    var completedVerses = existingChapters.fold<int>(
      0,
      (total, chapter) =>
          total +
          _store
              .translationsForSurah(
                resourceId: resourceId,
                surahNumber: chapter,
                cachePolicy: contentCachePolicy,
              )
              .length,
    );
    var failedChapters = 0;
    final downloads = _libraryDownloads;
    double? quranProgress() => downloads == null
        ? null
        : (completedVerses / _totalVersesForDownload).clamp(0, 1) * 0.5;
    yield QuranTranslationDownloadProgress(
      completedChapters: completedChapters,
      totalChapters: _totalChaptersForDownload,
      completedVerses: completedVerses,
      totalVerses: _totalVersesForDownload,
      failedChapters: failedChapters,
      overallProgress: quranProgress(),
    );

    for (var chapter = 1; chapter <= _totalChaptersForDownload; chapter++) {
      if (existingChapters.contains(chapter)) {
        continue;
      }
      try {
        final json = await _chapterTranslationFetcher(
          chapterNumber: chapter,
          resourceId: resourceId,
        );
        final translations = parseChapterTranslations(
          json: json,
          resourceId: resourceId,
        );
        if (translations.isEmpty) {
          failedChapters++;
        } else {
          await _store.saveVerseTranslations(
            resourceId: resourceId,
            translations: translations,
          );
          await _store.markSurahTranslationComplete(
            resource: resource,
            surahNumber: chapter,
            verseCount: translations.length,
          );
          completedChapters++;
          completedVerses += translations.length;
        }
      } catch (_) {
        failedChapters++;
      }
      yield QuranTranslationDownloadProgress(
        completedChapters: completedChapters,
        totalChapters: _totalChaptersForDownload,
        completedVerses: completedVerses,
        totalVerses: _totalVersesForDownload,
        failedChapters: failedChapters,
        overallProgress: quranProgress(),
      );
    }

    final complete =
        failedChapters == 0 && completedVerses >= _totalVersesForDownload;
    String? notice;
    if (complete) {
      await _store.markFullTranslationComplete(
        resource: resource,
        version: currentCacheVersion,
        verseCount: _totalVersesForDownload,
      );
      if (downloads != null) {
        yield QuranTranslationDownloadProgress(
          completedChapters: completedChapters,
          totalChapters: _totalChaptersForDownload,
          completedVerses: completedVerses,
          totalVerses: _totalVersesForDownload,
          failedChapters: failedChapters,
          quranTextReady: true,
          contentLabel: 'Starting Hadith downloads',
          contentProgress: 0,
          overallProgress: 0.5,
        );
        await for (final progress in downloads.download(resource)) {
          if (progress.isComplete) {
            notice = progress.detail;
            break;
          }
          yield QuranTranslationDownloadProgress(
            completedChapters: completedChapters,
            totalChapters: _totalChaptersForDownload,
            completedVerses: completedVerses,
            totalVerses: _totalVersesForDownload,
            failedChapters: failedChapters,
            contentLabel: progress.label,
            contentDetail: progress.detail,
            contentProgress: progress.percent,
            failedContent: progress.hasFailed,
            quranTextReady: true,
            overallProgress: 0.5 + (progress.percent ?? 0) * 0.5,
          );
          if (progress.hasFailed) return;
        }
      }
    }
    yield QuranTranslationDownloadProgress(
      completedChapters: completedChapters,
      totalChapters: _totalChaptersForDownload,
      completedVerses: completedVerses,
      totalVerses: _totalVersesForDownload,
      failedChapters: failedChapters,
      isComplete: complete,
      quranTextReady: complete,
      overallProgress: downloads == null
          ? null
          : complete
          ? 1
          : quranProgress(),
      contentDetail: notice,
    );
  }

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async {
    return _store.translationForVerse(
      resourceId: resourceId,
      verseKey: verseKey,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async {
    return _store.translationsForSurah(
      resourceId: resourceId,
      surahNumber: surahNumber,
      cachePolicy: contentCachePolicy,
    );
  }

  Future<QuranTranslationResource?> _resourceForId(int resourceId) async {
    final paired = quranTranslationPairForResource(resourceId)?.resource;
    if (paired != null) return paired;
    final resources = await _resources();
    return resources.cast<QuranTranslationResource?>().firstWhere(
      (resource) => resource?.id == resourceId,
      orElse: () => null,
    );
  }

  Future<List<QuranTranslationResource>> _resources() async {
    await _store.purgeExpired(cachePolicy: contentCachePolicy);
    final cached = _store.catalog(cachePolicy: contentCachePolicy);
    if (cached.isNotEmpty) {
      return _withPairedEditions(cached);
    }
    try {
      final json = await _resourcesFetcher();
      final resources = parseResources(json);
      if (resources.isNotEmpty) {
        await _store.saveCatalog(resources);
        return _withPairedEditions(resources);
      }
    } catch (_) {
      // Use bundled fallback below.
    }
    return _withPairedEditions(fallbackTranslationResources);
  }

  static List<QuranTranslationResource> _withPairedEditions(
    List<QuranTranslationResource> resources,
  ) {
    return {
      for (final resource in resources) resource.id: resource,
      for (final pair in quranTranslationAudioPairs)
        if (resources.any(
          (resource) =>
              resource.resolvedLanguageCode ==
              pair.resource.resolvedLanguageCode,
        ))
          pair.resource.id: pair.resource,
    }.values.toList(growable: false);
  }

  static List<QuranTranslationResource> parseResources(
    Map<dynamic, dynamic> json,
  ) {
    final raw = json['translations'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) QuranTranslationResource.fromJson(item),
    ].where((resource) {
      return resource.id > 0 && resource.languageName.trim().isNotEmpty;
    }).toList();
  }

  static Map<String, String> parseChapterTranslations({
    required Map<dynamic, dynamic> json,
    required int resourceId,
  }) {
    if (json['result'] is List) {
      return {
        for (final verse in json['result'] as List)
          if (verse is Map &&
              _int(verse['sura']) > 0 &&
              _int(verse['aya']) > 0 &&
              _cleanTranslation(_string(verse['translation'])).isNotEmpty)
            '${_int(verse['sura'])}:${_int(verse['aya'])}': _cleanTranslation(
              _string(verse['translation']),
            ),
      };
    }
    final data = json['data'];
    if (data is Map && data['ayahs'] is List && _int(data['number']) > 0) {
      return {
        for (final verse in data['ayahs'] as List)
          if (verse is Map &&
              _int(verse['numberInSurah']) > 0 &&
              _cleanTranslation(_string(verse['text'])).isNotEmpty)
            '${_int(data['number'])}:${_int(verse['numberInSurah'])}':
                _cleanTranslation(_string(verse['text'])),
      };
    }
    final verses = json['verses'];
    if (verses is! List) {
      return const {};
    }
    final result = <String, String>{};
    for (final verse in verses) {
      if (verse is! Map) {
        continue;
      }
      final verseKey = _string(verse['verse_key'] ?? verse['verseKey']);
      if (verseKey.isEmpty) {
        continue;
      }
      final translations = verse['translations'];
      if (translations is! List) {
        continue;
      }
      for (final translation in translations) {
        if (translation is! Map) {
          continue;
        }
        if (_int(translation['resource_id'] ?? translation['resourceId']) !=
            resourceId) {
          continue;
        }
        final text = _cleanTranslation(_string(translation['text']));
        if (text.isNotEmpty) {
          result[verseKey] = text;
        }
      }
    }
    return result;
  }

  List<QuranTranslationLanguage> _languagesFromResources(
    List<QuranTranslationResource> resources,
  ) {
    final grouped = <String, List<QuranTranslationResource>>{};
    for (final resource in resources) {
      final editions = grouped.putIfAbsent(resource.languageName, () => []);
      if (!editions.any((item) => item.id == resource.id)) {
        editions.add(resource);
      }
    }
    for (final editions in grouped.values) {
      final code = editions.first.resolvedLanguageCode;
      for (final pair in quranTranslationAudioPairs) {
        if (pair.resource.resolvedLanguageCode == code &&
            !editions.any((resource) => resource.id == pair.resource.id)) {
          editions.add(pair.resource);
        }
      }
    }
    final languages = [
      for (final entry in grouped.entries)
        QuranTranslationLanguage(
          languageName: entry.key,
          displayName: entry.value.first.displayLanguage,
          resourceCount: entry.value.length,
          defaultResource: _defaultResource(entry.key, entry.value),
          resources: List.unmodifiable(entry.value),
        ),
    ];
    languages.sort((a, b) => a.languageName.compareTo(b.languageName));
    return languages;
  }

  QuranTranslationResource _defaultResource(
    String language,
    List<QuranTranslationResource> resources,
  ) {
    final preferredId = _store.preferredResourceId(language);
    final bundled = fallbackTranslationResources
        .where(
          (resource) =>
              resource.languageName.toLowerCase() == language.toLowerCase(),
        )
        .firstOrNull;
    for (final id in [
      preferredId,
      quranDefaultPairedTranslation(resources.first.resolvedLanguageCode)?.id,
      _recommendedTranslationIds[resources.first.resolvedLanguageCode],
      bundled?.id,
    ]) {
      for (final resource in resources) {
        if (resource.id == id) return resource;
      }
    }
    // shortcut: providers publish no popularity ranking; use their first text edition for new languages.
    return resources.firstWhere(
      (resource) => !resource.name.toLowerCase().contains('transliteration'),
      orElse: () => resources.first,
    );
  }

  static Future<Map<String, Object?>> _fetchResourcesJson() async {
    final uri = Uri.https('api.quran.com', '/api/v4/resources/translations');
    return _getJson(uri);
  }

  static Future<Map<String, Object?>> _fetchChapterTranslationJson({
    required int chapterNumber,
    required int resourceId,
  }) async {
    final resource = quranTranslationPairForResource(resourceId)?.resource;
    if (resource?.provider == QuranTranslationProvider.quranEnc) {
      return _getJson(
        Uri.https(
          'quranenc.com',
          '/api/v1/translation/sura/${resource!.providerKey}/$chapterNumber',
        ),
      );
    }
    if (resource?.provider == QuranTranslationProvider.alQuranCloud) {
      final json = await _getJson(
        Uri.https(
          'api.alquran.cloud',
          '/v1/surah/$chapterNumber/${resource!.providerKey}',
        ),
      );
      final data = json['data'];
      if (data is! Map ||
          data['edition'] is! Map ||
          (data['edition'] as Map)['identifier'] != resource.providerKey) {
        throw const FormatException('Translation edition did not match.');
      }
      return json;
    }
    final uri = Uri.https(
      'api.quran.com',
      '/api/v4/verses/by_chapter/$chapterNumber',
      {'translations': '$resourceId', 'fields': 'verse_key', 'per_page': '286'},
    );
    return _getJson(uri);
  }

  static Future<Map<String, Object?>> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 20);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 25));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 25),
      );
      final body = await utf8
          .decodeStream(response)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Failed to fetch Quran translation data');
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      return const {};
    } finally {
      client.close(force: true);
    }
  }

  static String _cleanTranslation(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _string(Object? value) => value is String ? value : '';

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

const fallbackTranslationResources = <QuranTranslationResource>[
  QuranTranslationResource(
    id: 236,
    languageName: "Amazigh",
    name: "Ramdane At Mansour",
    authorName: "Ramdane At Mansour",
    slug: "",
  ),
  QuranTranslationResource(
    id: 237,
    languageName: "Bulgarian",
    name: "Tzvetan Theophanov",
    authorName: "Tzvetan Theophanov",
    slug: "",
  ),
  QuranTranslationResource(
    id: 144,
    languageName: "Dutch",
    name: "Sofian S. Siregar",
    authorName: "Sofian S. Siregar",
    slug: "nl_sofian_s._siregar",
  ),
  QuranTranslationResource(
    id: 44,
    languageName: "Romanian",
    name: "Grigore",
    authorName: "George Grigore",
    slug: "ro-grigore",
  ),
  QuranTranslationResource(
    id: 238,
    languageName: "Sindhi",
    name: "Taj Mehmood Amroti",
    authorName: "Taj Mehmood Amroti",
    slug: "",
  ),
  QuranTranslationResource(
    id: 88,
    languageName: "albanian",
    name: "Hasan Efendi Nahi",
    authorName: "Hasan Efendi Nahi",
    slug: "al-hasan-efendi",
  ),
  QuranTranslationResource(
    id: 87,
    languageName: "amharic",
    name: "Sadiq and Sani",
    authorName: "Sadiq and Sani",
    slug: "am-sadiq",
  ),
  QuranTranslationResource(
    id: 120,
    languageName: "assamese",
    name: "Shaykh Rafeequl Islam Habibur-Rahman",
    authorName: "Shaykh Rafeequl Islam Habibur-Rahman",
    slug: "",
  ),
  QuranTranslationResource(
    id: 75,
    languageName: "azeri",
    name: "Alikhan Musayev",
    authorName: "Alikhan Musayev",
    slug: "az-alikhan",
  ),
  QuranTranslationResource(
    id: 795,
    languageName: "bambara",
    name: "Suliman Kanti",
    authorName: "Suliman Kanti",
    slug: "",
  ),
  QuranTranslationResource(
    id: 161,
    languageName: "bengali",
    name: "Taisirul Quran",
    authorName: "Tawheed Publication",
    slug: "bn-taisirul-quran",
  ),
  QuranTranslationResource(
    id: 214,
    languageName: "bosnian",
    name: "Dar Al-Salam Center",
    authorName: "Dar Al-Salam Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 128,
    languageName: "central khmer",
    name: "Cambodian Muslim Community Development",
    authorName: "Cambodian Muslim Community Development",
    slug: "",
  ),
  QuranTranslationResource(
    id: 106,
    languageName: "chechen",
    name: "Magomed Magomedov",
    authorName: "Magomed Magomedov",
    slug: "chechen-translation",
  ),
  QuranTranslationResource(
    id: 56,
    languageName: "chinese",
    name: "Chinese Translation (Simplified) - Ma Jain",
    authorName: "Ma Jian",
    slug: "quran.zh.ma.jain",
  ),
  QuranTranslationResource(
    id: 26,
    languageName: "czech",
    name: "Czech",
    authorName: "Czech",
    slug: "cs-unknown",
  ),
  QuranTranslationResource(
    id: 785,
    languageName: "dari",
    name: "Mawlawi Muhammad Anwar Badkhashani",
    authorName: "Mawlawi Muhammad Anwar Badkhashani",
    slug: "",
  ),
  QuranTranslationResource(
    id: 840,
    languageName: "divehi",
    name: "Abu Bakr Ibrahim Ali (Bakurube)",
    authorName: "Abu Bakr Ibrahim Ali",
    slug: "ml-shaikh-aboobakr-ibrahim-ali",
  ),
  QuranTranslationResource(
    id: 86,
    languageName: "divehi, dhivehi, maldivian",
    name: "Office of the president of Maldives",
    authorName: "Office of the president of Maldives",
    slug: "dv-unknow",
  ),
  QuranTranslationResource(
    id: 235,
    languageName: "dutch",
    name: "Malak Faris Abdalsalaam",
    authorName: "Malak Faris Abdalsalaam",
    slug: "nl-abdalsalaam",
  ),
  QuranTranslationResource(
    id: 85,
    languageName: "english",
    name: "M.A.S. Abdel Haleem",
    authorName: "Abdul Haleem",
    slug: "en-haleem",
  ),
  QuranTranslationResource(
    id: 30,
    languageName: "finnish",
    name: "Finnish",
    authorName: "Finnish",
    slug: "fi-unknown",
  ),
  QuranTranslationResource(
    id: 136,
    languageName: "french",
    name: "Montada Islamic Foundation",
    authorName: "Montada Islamic Foundation",
    slug: "",
  ),
  QuranTranslationResource(
    id: 232,
    languageName: "ganda",
    name: "African Development Foundation",
    authorName: "African Development Foundation",
    slug: "",
  ),
  QuranTranslationResource(
    id: 208,
    languageName: "german",
    name: "Abu Reda Muhammad ibn Ahmad",
    authorName: "Abu Reda Muhammad ibn Ahmad",
    slug: "",
  ),
  QuranTranslationResource(
    id: 225,
    languageName: "gujarati",
    name: "Rabila Al-Umry",
    authorName: "Rabila Al-Umry",
    slug: "",
  ),
  QuranTranslationResource(
    id: 32,
    languageName: "hausa",
    name: "Hausa Translation(Abubakar Gumi)",
    authorName: "Abubakar Mahmoud Gumi",
    slug: "quran.ha.abubakar",
  ),
  QuranTranslationResource(
    id: 233,
    languageName: "hebrew",
    name: "Dar Al-Salam Center",
    authorName: "Dar Al-Salam Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 122,
    languageName: "hindi",
    name: "Maulana Azizul Haque al-Umari",
    authorName: "Maulana Azizul Haque al-Umari",
    slug: "",
  ),
  QuranTranslationResource(
    id: 134,
    languageName: "indonesian",
    name: "King Fahad Quran Complex",
    authorName: "King Fahad Quran Complex",
    slug: "",
  ),
  QuranTranslationResource(
    id: 153,
    languageName: "italian",
    name: "Hamza Roberto Piccardo",
    authorName: "Hamza Roberto Piccardo",
    slug: "hamza-roberto-piccardo",
  ),
  QuranTranslationResource(
    id: 35,
    languageName: "japanese",
    name: "Ryoichi Mita",
    authorName: "Ryoichi Mita",
    slug: "ja-ryoichi-mita",
  ),
  QuranTranslationResource(
    id: 771,
    languageName: "kannada",
    name: "Kannada Translation",
    authorName: "Kannada Translation",
    slug: "kannada-quran",
  ),
  QuranTranslationResource(
    id: 222,
    languageName: "kazakh",
    name: "Khalifa Altay",
    authorName: "Khalifa Altay",
    slug: "",
  ),
  QuranTranslationResource(
    id: 774,
    languageName: "kinyarwanda",
    name: "The Rwanda Muslims Association team",
    authorName: "The Rwanda Muslims Association team",
    slug: "",
  ),
  QuranTranslationResource(
    id: 36,
    languageName: "korean",
    name: "Korean",
    authorName: "Korean",
    slug: "ko-unknown",
  ),
  QuranTranslationResource(
    id: 81,
    languageName: "kurdish",
    name: "Burhan Muhammad-Amin",
    authorName: "Burhan Muhammad-Amin",
    slug: "ku-burhan-muhammad",
  ),
  QuranTranslationResource(
    id: 39,
    languageName: "malay",
    name: "Abdullah Muhammad Basmeih",
    authorName: "Abdullah Muhammad Basmeih",
    slug: "ms-abdullah",
  ),
  QuranTranslationResource(
    id: 80,
    languageName: "malayalam",
    name: "Muhammad Karakunnu and Vanidas Elayavoor",
    authorName: "Muhammad Karakunnu and Vanidas Elayavoor",
    slug: "ml-karakunnu",
  ),
  QuranTranslationResource(
    id: 38,
    languageName: "maranao",
    name: "Maranao",
    authorName: "Maranao",
    slug: "mrn-unknown",
  ),
  QuranTranslationResource(
    id: 226,
    languageName: "marathi",
    name: "Muhammad Shafi’i Ansari",
    authorName: "Muhammad Shafi’i Ansari",
    slug: "",
  ),
  QuranTranslationResource(
    id: 108,
    languageName: "nepali",
    name: "Ahl Al-Hadith Central Society of Nepal",
    authorName: "Ahl Al-Hadith Central Society of Nepal",
    slug: "",
  ),
  QuranTranslationResource(
    id: 41,
    languageName: "norwegian",
    name: "Norwegian",
    authorName: "Norwegian",
    slug: "no-unknown",
  ),
  QuranTranslationResource(
    id: 111,
    languageName: "oromo",
    name: "Ghali Apapur Apaghuna",
    authorName: "Ghali Apapur Apaghuna",
    slug: "",
  ),
  QuranTranslationResource(
    id: 118,
    languageName: "pashto",
    name: "Zakaria Abulsalam",
    authorName: "Zakaria Abulsalam",
    slug: "",
  ),
  QuranTranslationResource(
    id: 135,
    languageName: "persian",
    name: "IslamHouse.com",
    authorName: "IslamHouse.com",
    slug: "",
  ),
  QuranTranslationResource(
    id: 42,
    languageName: "polish",
    name: "Józef Bielawski",
    authorName: "Józef Bielawski",
    slug: "pl-jozef-bielawski",
  ),
  QuranTranslationResource(
    id: 103,
    languageName: "portuguese",
    name: "Helmi Nasr",
    authorName: "Helmi Nasr",
    slug: "",
  ),
  QuranTranslationResource(
    id: 782,
    languageName: "romanian",
    name: "Islamic and Cultural League",
    authorName: "Islamic and Cultural League",
    slug: "",
  ),
  QuranTranslationResource(
    id: 78,
    languageName: "russian",
    name: "Ministry of Awqaf, Egypt",
    authorName: "Ministry of Awqaf, Egypt",
    slug: "ru-ministry-of-awqaf",
  ),
  QuranTranslationResource(
    id: 228,
    languageName: "sinhala, sinhalese",
    name: "Ruwwad Center",
    authorName: "Translation Pioneers Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 46,
    languageName: "somali",
    name: "Mahmud Muhammad Abduh",
    authorName: "Mahmud Muhammad Abduh",
    slug: "so-mahmud-abduh",
  ),
  QuranTranslationResource(
    id: 83,
    languageName: "spanish",
    name: "Sheikh Isa Garcia",
    authorName: "Sheikh Isa Garcia",
    slug: "es-isa-garcia",
  ),
  QuranTranslationResource(
    id: 231,
    languageName: "swahili",
    name: "Dr. Abdullah Muhammad Abu Bakr and Sheikh Nasir Khamis",
    authorName: "Dr. Abdullah Muhammad Abu Bakr and Sheikh Nasir Khamis",
    slug: "",
  ),
  QuranTranslationResource(
    id: 48,
    languageName: "swedish",
    name: "Knut Bernström",
    authorName: "Knut Bernström",
    slug: "sv-knut",
  ),
  QuranTranslationResource(
    id: 211,
    languageName: "tagalog",
    name: "Dar Al-Salam Center",
    authorName: "Dar Al-Salam Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 139,
    languageName: "tajik",
    name: "Khawaja Mirof & Khawaja Mir",
    authorName: "Khawaja Mirof & Khawaja Mir",
    slug: "",
  ),
  QuranTranslationResource(
    id: 229,
    languageName: "tamil",
    name: "Sheikh Omar Sharif bin Abdul Salam",
    authorName: "Sheikh Omar Sharif bin Abdul Salam",
    slug: "",
  ),
  QuranTranslationResource(
    id: 53,
    languageName: "tatar",
    name: "Tatar",
    authorName: "Tatar",
    slug: "tt-unknow",
  ),
  QuranTranslationResource(
    id: 227,
    languageName: "telugu",
    name: "Maulana Abder-Rahim ibn Muhammad",
    authorName: "Maulana Abder-Rahim ibn Muhammad",
    slug: "",
  ),
  QuranTranslationResource(
    id: 230,
    languageName: "thai",
    name: "Society of Institutes and Universities",
    authorName: "Society of Institutes and Universities",
    slug: "",
  ),
  QuranTranslationResource(
    id: 210,
    languageName: "turkish",
    name: "Dar Al-Salam Center",
    authorName: "Dar Al-Salam Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 76,
    languageName: "uighur, uyghur",
    name: "Muhammad Saleh",
    authorName: "Muhammad Saleh",
    slug: "ug-saleh",
  ),
  QuranTranslationResource(
    id: 217,
    languageName: "ukrainian",
    name: "Dr. Mikhailo Yaqubovic",
    authorName: "Dr. Mikhailo Yaqubovic",
    slug: "",
  ),
  QuranTranslationResource.urduJalandhari,
  QuranTranslationResource(
    id: 55,
    languageName: "uzbek",
    name: "Muhammad Sodiq Muhammad Yusuf (Latin) ",
    authorName: "Muhammad Sodiq Muhammad Yusuf",
    slug: "quran.uz.sodik",
  ),
  QuranTranslationResource(
    id: 220,
    languageName: "vietnamese",
    name: "Ruwwad Center",
    authorName: "Translation Pioneers Center",
    slug: "",
  ),
  QuranTranslationResource(
    id: 798,
    languageName: "yau,yuw",
    name: "Abdul Hamid Silika",
    authorName: "Abdul Hamid Silika",
    slug: "",
  ),
  QuranTranslationResource(
    id: 125,
    languageName: "yoruba",
    name: "Shaykh Abu Rahimah Mikael Aykyuni",
    authorName: "Shaykh Abu Rahimah Mikael Aykyuni",
    slug: "",
  ),
];

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
