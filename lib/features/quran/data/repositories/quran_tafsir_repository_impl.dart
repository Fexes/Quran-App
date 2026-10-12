import 'dart:convert';
import 'dart:io';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_tafsir.dart';
import '../../domain/repositories/quran_tafsir_repository.dart';
import '../stores/quran_tafsir_store.dart';

typedef QuranTafsirResourcesFetcher = Future<Map<String, Object?>> Function();

typedef QuranVerseTafsirFetcher =
    Future<Map<String, Object?>> Function({
      required int resourceId,
      required String verseKey,
    });

typedef QuranSurahTafsirFetcher =
    Future<Map<String, Object?>> Function({
      required int resourceId,
      required int surahNumber,
      required int page,
    });

class QuranTafsirRepositoryImpl
    implements QuranTafsirRepository, QuranTafsirEditionRepository {
  QuranTafsirRepositoryImpl({
    required QuranTafsirStore store,
    QuranTafsirResourcesFetcher? resourcesFetcher,
    QuranVerseTafsirFetcher? verseTafsirFetcher,
    QuranSurahTafsirFetcher? surahTafsirFetcher,
  }) : _store = store,
       _resourcesFetcher = resourcesFetcher ?? _fetchResourcesJson,
       _verseTafsirFetcher = verseTafsirFetcher ?? _fetchVerseTafsirJson,
       _surahTafsirFetcher = surahTafsirFetcher ?? _fetchSurahTafsirJson;

  final QuranTafsirStore _store;
  final QuranTafsirResourcesFetcher _resourcesFetcher;
  final QuranVerseTafsirFetcher _verseTafsirFetcher;
  final QuranSurahTafsirFetcher _surahTafsirFetcher;

  static const contentCachePolicy = ContentCachePolicy.quranFoundation;

  @override
  Future<List<QuranTafsirResource>> tafsirResources() => _resources();

  @override
  Future<QuranTafsirResource?> defaultResourceForLanguage(
    String? languageName,
  ) async {
    final preferredTokens = quranTafsirLanguageTokens(
      languageName?.trim().isNotEmpty == true ? languageName! : 'english',
    );
    if (preferredTokens.isEmpty) {
      return null;
    }
    final resources = await _resources();
    for (final resource in resources) {
      final resourceTokens = quranTafsirLanguageTokens(resource.languageName);
      if (resourceTokens.intersection(preferredTokens).isNotEmpty) {
        return resource;
      }
    }
    return null;
  }

  @override
  Future<QuranTafsirResource?> resourceForId(int resourceId) async {
    final resources = await _resources();
    for (final resource in resources) {
      if (resource.id == resourceId) {
        return resource;
      }
    }
    return null;
  }

  @override
  Future<QuranTafsirResult?> tafsirForVerse({
    required String verseKey,
    required String? languageName,
  }) async {
    final resource = await defaultResourceForLanguage(languageName);
    if (resource == null) {
      return null;
    }
    return _tafsirForVerse(resource: resource, verseKey: verseKey);
  }

  @override
  Future<QuranTafsirResult?> tafsirForVerseByResource({
    required String verseKey,
    required int resourceId,
  }) async {
    final resource = await resourceForId(resourceId);
    if (resource == null) {
      return null;
    }
    return _tafsirForVerse(resource: resource, verseKey: verseKey);
  }

  Future<QuranTafsirResult?> _tafsirForVerse({
    required QuranTafsirResource resource,
    required String verseKey,
  }) async {
    final cached = _store.tafsirForVerse(
      resourceId: resource.id,
      verseKey: verseKey,
      cachePolicy: contentCachePolicy,
    );
    if (cached != null) {
      return QuranTafsirResult(
        resource: resource,
        verseKey: verseKey,
        text: cached,
      );
    }

    final json = await _verseTafsirFetcher(
      resourceId: resource.id,
      verseKey: verseKey,
    );
    final tafsir = parseVerseTafsir(json);
    if (tafsir == null || tafsir.text.isEmpty) {
      return null;
    }
    await _store.saveVerseTafsir(
      resourceId: resource.id,
      verseKey: verseKey,
      tafsir: tafsir.text,
    );
    return QuranTafsirResult(
      // Verse responses omit language_name; retain the complete catalog metadata.
      resource: resource,
      verseKey: verseKey,
      text: tafsir.text,
    );
  }

  @override
  Future<bool> hasDownloadedSurahTafsir({
    required int surahNumber,
    required String? languageName,
  }) async {
    final resource = await defaultResourceForLanguage(languageName);
    if (resource == null) {
      return false;
    }
    final verseCount = _surahAyahCounts[surahNumber];
    if (verseCount == null) {
      return false;
    }
    return _store.hasSurahTafsir(
      resourceId: resource.id,
      surahNumber: surahNumber,
      verseCount: verseCount,
      cachePolicy: contentCachePolicy,
    );
  }

  @override
  Stream<QuranTafsirDownloadProgress> downloadSurahTafsir({
    required int surahNumber,
    required String? languageName,
  }) async* {
    final resource = await defaultResourceForLanguage(languageName);
    final expectedVerseCount = _surahAyahCounts[surahNumber] ?? 0;
    if (resource == null || expectedVerseCount <= 0) {
      yield const QuranTafsirDownloadProgress(
        completedVerses: 0,
        totalVerses: 0,
        failed: true,
      );
      return;
    }

    if (await hasDownloadedSurahTafsir(
      surahNumber: surahNumber,
      languageName: languageName,
    )) {
      yield QuranTafsirDownloadProgress(
        completedVerses: expectedVerseCount,
        totalVerses: expectedVerseCount,
        isComplete: true,
      );
      return;
    }

    var page = 1;
    var completedVerses = 0;
    var totalVerses = expectedVerseCount;
    var failed = false;
    yield QuranTafsirDownloadProgress(
      completedVerses: completedVerses,
      totalVerses: totalVerses,
    );

    while (page > 0) {
      try {
        final json = await _surahTafsirFetcher(
          resourceId: resource.id,
          surahNumber: surahNumber,
          page: page,
        );
        final parsed = parseSurahTafsirs(json);
        totalVerses = _paginationTotalRecords(json) ?? totalVerses;
        if (parsed.isNotEmpty) {
          await _store.saveVerseTafsirs(
            resourceId: resource.id,
            tafsirs: parsed,
          );
          completedVerses += parsed.length;
        }
        yield QuranTafsirDownloadProgress(
          completedVerses: completedVerses.clamp(0, totalVerses).toInt(),
          totalVerses: totalVerses,
        );

        final nextPage = _paginationNextPage(json);
        if (nextPage == null || nextPage <= page) {
          page = 0;
        } else {
          page = nextPage;
        }
      } catch (_) {
        failed = true;
        page = 0;
      }
    }

    final complete =
        !failed && completedVerses >= totalVerses && completedVerses > 0;
    if (complete) {
      await _store.markSurahTafsirComplete(
        resource: resource,
        surahNumber: surahNumber,
        verseCount: expectedVerseCount,
      );
    }
    yield QuranTafsirDownloadProgress(
      completedVerses: completedVerses.clamp(0, totalVerses).toInt(),
      totalVerses: totalVerses,
      isComplete: complete,
      failed: !complete,
    );
  }

  Future<List<QuranTafsirResource>> _resources() async {
    await _store.purgeExpired(cachePolicy: contentCachePolicy);
    final cached = _store.catalog(cachePolicy: contentCachePolicy);
    if (cached.isNotEmpty) {
      return cached;
    }
    try {
      final json = await _resourcesFetcher();
      final resources = parseResources(json);
      if (resources.isNotEmpty) {
        await _store.saveCatalog(resources);
        return resources;
      }
    } catch (_) {
      // Use bundled fallback below.
    }
    return fallbackTafsirResources;
  }

  static List<QuranTafsirResource> parseResources(Map<dynamic, dynamic> json) {
    final raw = json['tafsirs'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) QuranTafsirResource.fromJson(item),
    ].where((resource) {
      return resource.id > 0 && resource.languageName.trim().isNotEmpty;
    }).toList();
  }

  static QuranTafsirResult? parseVerseTafsir(Map<dynamic, dynamic> json) {
    final tafsir = json['tafsir'];
    if (tafsir is! Map) {
      return null;
    }
    final text = _cleanHtml(_string(tafsir['text']));
    if (text.isEmpty) {
      return null;
    }
    final resource = QuranTafsirResource(
      id: _int(tafsir['resource_id'] ?? tafsir['resourceId']),
      languageName: _string(tafsir['language_name'] ?? tafsir['languageName']),
      name: _string(tafsir['resource_name'] ?? tafsir['resourceName']),
      authorName: '',
      slug: _string(tafsir['slug']),
    );
    return QuranTafsirResult(
      resource: resource,
      verseKey: _firstVerseKey(tafsir),
      text: text,
    );
  }

  static Map<String, String> parseSurahTafsirs(Map<dynamic, dynamic> json) {
    final raw = json['tafsirs'];
    if (raw is! List) {
      return const {};
    }
    final result = <String, String>{};
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final verseKey = _string(item['verse_key'] ?? item['verseKey']);
      if (verseKey.isEmpty) {
        continue;
      }
      final text = _cleanHtml(_string(item['text']));
      if (text.isNotEmpty) {
        result[verseKey] = text;
      }
    }
    return result;
  }

  static Future<Map<String, Object?>> _fetchResourcesJson() async {
    final uri = Uri.https('api.quran.com', '/api/v4/resources/tafsirs');
    return _getJson(uri);
  }

  static Future<Map<String, Object?>> _fetchVerseTafsirJson({
    required int resourceId,
    required String verseKey,
  }) async {
    final uri = Uri.https(
      'api.quran.com',
      '/api/v4/tafsirs/$resourceId/by_ayah/$verseKey',
    );
    return _getJson(uri);
  }

  static Future<Map<String, Object?>> _fetchSurahTafsirJson({
    required int resourceId,
    required int surahNumber,
    required int page,
  }) async {
    final uri = Uri.https(
      'api.quran.com',
      '/api/v4/tafsirs/$resourceId/by_chapter/$surahNumber',
      {
        'page': '$page',
        'per_page': '50',
        'fields': 'verse_key,resource_name,language_name',
      },
    );
    return _getJson(uri);
  }

  static Future<Map<String, Object?>> _getJson(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Failed to fetch Quran tafsir data');
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

  static String _firstVerseKey(Map<dynamic, dynamic> tafsir) {
    final verses = tafsir['verses'];
    if (verses is Map && verses.keys.isNotEmpty) {
      return verses.keys.first.toString();
    }
    return '';
  }

  static int? _paginationNextPage(Map<dynamic, dynamic> json) {
    final pagination = json['pagination'];
    if (pagination is! Map) {
      return null;
    }
    return _nullableInt(pagination['next_page'] ?? pagination['nextPage']);
  }

  static int? _paginationTotalRecords(Map<dynamic, dynamic> json) {
    final pagination = json['pagination'];
    if (pagination is! Map) {
      return null;
    }
    return _nullableInt(
      pagination['total_records'] ?? pagination['totalRecords'],
    );
  }

  static String _cleanHtml(String value) {
    final withBreaks = value
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</\s*(p|div|li|h[1-6])\s*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '');
    return _decodeEntities(withBreaks)
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _decodeEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final codePoint = int.tryParse(match.group(1) ?? '');
          return codePoint == null
              ? match.group(0)!
              : String.fromCharCode(codePoint);
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
          final codePoint = int.tryParse(match.group(1) ?? '', radix: 16);
          return codePoint == null
              ? match.group(0)!
              : String.fromCharCode(codePoint);
        });
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

  static int? _nullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

const _surahAyahCounts = <int, int>{
  1: 7,
  2: 286,
  3: 200,
  4: 176,
  5: 120,
  6: 165,
  7: 206,
  8: 75,
  9: 129,
  10: 109,
  11: 123,
  12: 111,
  13: 43,
  14: 52,
  15: 99,
  16: 128,
  17: 111,
  18: 110,
  19: 98,
  20: 135,
  21: 112,
  22: 78,
  23: 118,
  24: 64,
  25: 77,
  26: 227,
  27: 93,
  28: 88,
  29: 69,
  30: 60,
  31: 34,
  32: 30,
  33: 73,
  34: 54,
  35: 45,
  36: 83,
  37: 182,
  38: 88,
  39: 75,
  40: 85,
  41: 54,
  42: 53,
  43: 89,
  44: 59,
  45: 37,
  46: 35,
  47: 38,
  48: 29,
  49: 18,
  50: 45,
  51: 60,
  52: 49,
  53: 62,
  54: 55,
  55: 78,
  56: 96,
  57: 29,
  58: 22,
  59: 24,
  60: 13,
  61: 14,
  62: 11,
  63: 11,
  64: 18,
  65: 12,
  66: 12,
  67: 30,
  68: 52,
  69: 52,
  70: 44,
  71: 28,
  72: 28,
  73: 20,
  74: 56,
  75: 40,
  76: 31,
  77: 50,
  78: 40,
  79: 46,
  80: 42,
  81: 29,
  82: 19,
  83: 36,
  84: 25,
  85: 22,
  86: 17,
  87: 19,
  88: 26,
  89: 30,
  90: 20,
  91: 15,
  92: 21,
  93: 11,
  94: 8,
  95: 8,
  96: 19,
  97: 5,
  98: 8,
  99: 8,
  100: 11,
  101: 11,
  102: 8,
  103: 3,
  104: 9,
  105: 5,
  106: 4,
  107: 7,
  108: 3,
  109: 6,
  110: 3,
  111: 5,
  112: 4,
  113: 5,
  114: 6,
};

const fallbackTafsirResources = <QuranTafsirResource>[
  QuranTafsirResource(
    id: 169,
    languageName: 'english',
    name: 'Ibn Kathir (Abridged)',
    authorName: 'Hafiz Ibn Kathir',
    slug: 'en-tafisr-ibn-kathir',
  ),
  QuranTafsirResource(
    id: 16,
    languageName: 'arabic',
    name: 'Tafsir Muyassar',
    authorName: 'المیسر',
    slug: 'ar-tafsir-muyassar',
  ),
  QuranTafsirResource(
    id: 381,
    languageName: 'bengali',
    name: 'Tafsir Fathul Majid',
    authorName: 'AbdulRahman Bin Hasan Al-Alshaikh',
    slug: 'tafisr-fathul-majid-bn',
  ),
  QuranTafsirResource(
    id: 170,
    languageName: 'russian',
    name: "Al-Sa'di",
    authorName: 'Saddi',
    slug: 'ru-tafseer-al-saddi',
  ),
  QuranTafsirResource(
    id: 157,
    languageName: 'urdu',
    name: 'Fi Zilal al-Quran',
    authorName: 'Sayyid Ibrahim Qutb',
    slug: 'tafsir-fe-zalul-quran-syed-qatab',
  ),
  QuranTafsirResource(
    id: 804,
    languageName: 'kurdish',
    name: 'Rebar Kurdish Tafsir',
    authorName: 'Rebar Kurdish Tafsir',
    slug: 'kurd-tafsir-rebar',
  ),
];
