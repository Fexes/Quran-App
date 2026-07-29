import 'dart:convert';
import 'dart:io';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_word.dart';
import '../../domain/repositories/quran_interlinear_repository.dart';
import '../stores/quran_interlinear_words_store.dart';

typedef QuranPageWordsFetcher =
    Future<Map<String, Object?>> Function({
      required int pageNumber,
      required String language,
    });

class QuranInterlinearRepositoryImpl
    implements
        QuranInterlinearRepository,
        QuranInterlinearCacheMetadataRepository {
  QuranInterlinearRepositoryImpl({
    required QuranInterlinearWordsStore store,
    QuranPageWordsFetcher? fetchPageWords,
    int totalPagesForDownload = 604,
    int concurrentDownloads = 4,
  }) : _store = store,
       _fetchPageWords = fetchPageWords ?? _fetchPageWordsJson,
       _totalPagesForDownload = totalPagesForDownload,
       _concurrentDownloads = concurrentDownloads;

  static const currentCacheVersion = 'quran-com-v4-en-words-v1';
  static const contentCachePolicy = ContentCachePolicy.quranFoundation;

  final QuranInterlinearWordsStore _store;
  final QuranPageWordsFetcher _fetchPageWords;
  final int _totalPagesForDownload;
  final int _concurrentDownloads;

  @override
  String get cacheVersion => currentCacheVersion;

  @override
  Future<List<QuranWord>> getPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    final normalizedPage = pageNumber.clamp(1, 604).toInt();
    await _store.purgeExpired(
      language: language,
      cachePolicy: contentCachePolicy,
    );
    final cached = _store.pageWords(
      pageNumber: normalizedPage,
      language: language,
      cachePolicy: contentCachePolicy,
    );
    if (cached.isNotEmpty) {
      return cached;
    }

    try {
      final json = await _fetchPageWords(
        pageNumber: normalizedPage,
        language: language,
      );
      final words = parsePageWords(pageNumber: normalizedPage, json: json);
      if (words.isNotEmpty) {
        await _store.savePageWords(
          pageNumber: normalizedPage,
          language: language,
          words: words,
        );
      }
      return words;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<QuranWord>> cachedPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return _store.pageWords(
      pageNumber: pageNumber.clamp(1, 604).toInt(),
      language: language,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Future<bool> hasFullCache({String language = 'en'}) async {
    return _store.hasFullCache(
      language: language,
      version: cacheVersion,
      pageCount: _totalPagesForDownload,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Future<DateTime?> fullCacheExpiresAt({String language = 'en'}) async {
    return _store.fullCacheExpiresAt(
      language: language,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Stream<QuranInterlinearDownloadProgress> downloadFullCache({
    String language = 'en',
  }) async* {
    await _store.purgeExpired(
      language: language,
      cachePolicy: contentCachePolicy,
    );
    final totalPages = _totalPagesForDownload.clamp(1, 604).toInt();
    var completed = 0;
    var failed = 0;

    for (var page = 1; page <= totalPages; page++) {
      if (_store.hasPageWords(
        pageNumber: page,
        language: language,
        cachePolicy: contentCachePolicy,
      )) {
        completed++;
      }
    }
    yield QuranInterlinearDownloadProgress(
      completedPages: completed,
      totalPages: totalPages,
      failedPages: failed,
    );

    for (var start = 1; start <= totalPages; start += _concurrentDownloads) {
      final pages = [
        for (
          var page = start;
          page < start + _concurrentDownloads && page <= totalPages;
          page++
        )
          if (!_store.hasPageWords(
            pageNumber: page,
            language: language,
            cachePolicy: contentCachePolicy,
          ))
            page,
      ];
      if (pages.isEmpty) {
        continue;
      }
      final results = await Future.wait([
        for (final page in pages) _downloadPage(page, language),
      ]);
      for (final result in results) {
        if (result) {
          completed++;
        } else {
          failed++;
        }
      }
      yield QuranInterlinearDownloadProgress(
        completedPages: completed,
        totalPages: totalPages,
        failedPages: failed,
      );
    }

    final complete = failed == 0 && completed >= totalPages;
    if (complete) {
      await _store.markFullCacheComplete(
        language: language,
        version: cacheVersion,
        pageCount: totalPages,
      );
    }
    yield QuranInterlinearDownloadProgress(
      completedPages: completed,
      totalPages: totalPages,
      failedPages: failed,
      isComplete: complete,
    );
  }

  Future<bool> _downloadPage(int pageNumber, String language) async {
    try {
      final json = await _fetchPageWords(
        pageNumber: pageNumber,
        language: language,
      );
      final words = parsePageWords(pageNumber: pageNumber, json: json);
      if (words.isEmpty) {
        return false;
      }
      await _store.savePageWords(
        pageNumber: pageNumber,
        language: language,
        words: words,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<QuranWord> parsePageWords({
    required int pageNumber,
    required Map<dynamic, dynamic> json,
  }) {
    final verses = json['verses'];
    if (verses is! List) {
      return const [];
    }
    final words = <QuranWord>[];
    for (final verse in verses) {
      if (verse is! Map) {
        continue;
      }
      final verseKey = _string(verse['verse_key'] ?? verse['verseKey']);
      if (verseKey.isEmpty) {
        continue;
      }
      final ayahNumber = _int(verse['verse_number'] ?? verse['verseNumber']);
      final versePage = _int(verse['page_number'] ?? verse['pageNumber']);
      final rawWords = verse['words'];
      if (rawWords is! List) {
        continue;
      }
      for (final rawWord in rawWords) {
        if (rawWord is! Map) {
          continue;
        }
        final charType = _string(
          rawWord['char_type_name'] ?? rawWord['charTypeName'],
        );
        if (charType == 'end') {
          continue;
        }
        final arabicText = _string(
          rawWord['text_uthmani'] ??
              rawWord['textUthmani'] ??
              rawWord['text_imlaei'] ??
              rawWord['textImlaei'],
        ).trim();
        if (arabicText.isEmpty) {
          continue;
        }
        final wordPage = _int(rawWord['page_number'] ?? rawWord['pageNumber']);
        words.add(
          QuranWord(
            verseKey: verseKey,
            ayahNumber: ayahNumber,
            wordIndex: _int(rawWord['position']),
            arabicText: arabicText,
            translation: _wordTranslation(rawWord),
            page: wordPage > 0 ? wordPage.clamp(1, 604).toInt() : versePage,
            lineNumber: _int(rawWord['line_number'] ?? rawWord['lineNumber']),
          ),
        );
      }
    }
    return words.where((word) => word.page == pageNumber).toList();
  }

  static Future<Map<String, Object?>> _fetchPageWordsJson({
    required int pageNumber,
    required String language,
  }) async {
    final uri =
        Uri.https('api.quran.com', '/api/v4/verses/by_page/$pageNumber', {
          'language': language,
          'words': 'true',
          'word_fields':
              'text_uthmani,text_imlaei,page_number,line_number,position',
          'per_page': '50',
        });
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Failed to fetch Quran word data');
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

  static String _wordTranslation(Map<dynamic, dynamic> rawWord) {
    final translation = rawWord['translation'];
    if (translation is Map) {
      return _cleanTranslation(_string(translation['text']));
    }
    return _cleanTranslation(_string(rawWord['translation']));
  }

  static String _cleanTranslation(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _string(Object? value) {
    return value is String ? value : '';
  }

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
