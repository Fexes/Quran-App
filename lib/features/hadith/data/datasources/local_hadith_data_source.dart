import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_chapter.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/services/hadith_authenticity_policy.dart';

class LocalHadithDataSource {
  LocalHadithDataSource({
    AssetBundle? assetBundle,
    List<ContentSource>? sources,
    List<HadithBook>? books,
    List<HadithChapter>? chapters,
    List<HadithItem>? hadiths,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _manualSources = sources,
       _manualBooks = books,
       _manualChapters = chapters,
       _manualHadiths = hadiths
           ?.where(HadithAuthenticityPolicy.shouldShow)
           .toList();

  static const _manifestPath = 'assets/data/hadith/manifest.json';
  static const _sourcesPath =
      'assets/data/content_sources/hadith_azkar_sources.json';
  static const _searchIndexPath = 'assets/data/hadith/search_index.jsonl';

  final AssetBundle _assetBundle;
  final List<ContentSource>? _manualSources;
  final List<HadithBook>? _manualBooks;
  final List<HadithChapter>? _manualChapters;
  final List<HadithItem>? _manualHadiths;
  final _bookCache = <String, _HadithBookAsset>{};
  final _bookLoadFutures = <String, Future<_HadithBookAsset>>{};

  Future<List<HadithBook>>? _booksFuture;
  Future<List<ContentSource>>? _sourcesFuture;
  Future<List<DeepSearchIndexRecord>>? _searchIndexFuture;
  Future<String>? _searchIndexSourceFuture;
  Future<Map<String, dynamic>>? _visibilityFuture;

  Future<Map<String, dynamic>> _visibility() => _visibilityFuture ??= () async {
    final raw = await _assetBundle.loadString(
      'assets/data/hadith/visibility.json',
    );
    return compute(_decodeJsonObject, raw);
  }();

  Future<List<ContentSource>> getContentSources() {
    final manual = _manualSources;
    if (manual != null) {
      return Future.value(List.unmodifiable(manual));
    }
    return _sourcesFuture ??= _loadContentSources();
  }

  Future<List<HadithBook>> getBooks() {
    final manual = _manualBooks;
    if (manual != null) {
      return Future.value(List.unmodifiable(manual));
    }
    return _booksFuture ??= _loadBooks();
  }

  Future<HadithBook?> getBook(String bookId) async {
    final books = await getBooks();
    for (final book in books) {
      if (book.id == bookId || book.slug == bookId) {
        return book;
      }
    }
    return null;
  }

  Future<List<HadithChapter>> getChapters(String bookId) async {
    final manual = _manualChapters;
    if (manual != null) {
      return manual
          .where((chapter) => chapter.bookId == bookId)
          .toList(growable: false);
    }
    final asset = await _loadBookAsset(bookId);
    return asset.chapters;
  }

  Future<List<String>> availableTranslationLanguagesForBook(
    String bookId,
  ) async {
    final book = await getBook(bookId);
    if (book == null) {
      return const [];
    }
    return book.availableLanguages
        .map(_languageCodeFor)
        .whereType<String>()
        .where((code) => code != 'ar')
        .toSet()
        .toList(growable: false);
  }

  Future<bool> hasFullTranslation(String bookId, String languageCode) async {
    if (languageCode.toLowerCase() != 'en') {
      return false;
    }
    final items = await getHadiths(bookId: bookId, limit: 100000);
    return items.isNotEmpty &&
        items.every((item) => item.translation.trim().isNotEmpty);
  }

  Future<List<HadithItem>> getHadiths({
    String? bookId,
    String? chapterId,
    String? languageCode,
    int offset = 0,
    int limit = 50,
  }) async {
    final manual = _manualHadiths;
    if (manual != null) {
      return _page(
        manual
            .where((hadith) {
              final matchesBook = bookId == null || hadith.bookId == bookId;
              final matchesChapter =
                  chapterId == null || hadith.chapterId == chapterId;
              return matchesBook && matchesChapter;
            })
            .toList(growable: false),
        offset,
        limit,
      );
    }
    final books = await getBooks();
    final effectiveBookId = bookId ?? (books.isEmpty ? null : books.first.id);
    if (effectiveBookId == null) {
      return const [];
    }
    final asset = await _loadBookAsset(effectiveBookId);
    final filtered = chapterId == null
        ? asset.hadiths
        : asset.hadiths
              .where((hadith) => hadith.chapterId == chapterId)
              .toList(growable: false);
    return _page(filtered, offset, limit);
  }

  Future<HadithItem?> getHadithById(String id, {String? languageCode}) async {
    final manual = _manualHadiths;
    if (manual != null) {
      for (final hadith in manual) {
        if (hadith.id == id) {
          return hadith;
        }
      }
      return null;
    }
    final parts = id.split(':');
    if (parts.length < 3) {
      return null;
    }
    final asset = await _loadBookAsset(parts[1]);
    for (final hadith in asset.hadiths) {
      if (hadith.id == id) {
        return hadith;
      }
    }
    return null;
  }

  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() {
    if (_manualHadiths != null) {
      return Future.value(_manualHadiths.map(_recordFromHadith).toList());
    }
    return _searchIndexFuture ??= _loadSearchIndex();
  }

  Future<List<HadithItem>> search(String query, {int limit = 30}) async {
    final normalized = SearchTextNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return const [];
    }
    final manual = _manualHadiths;
    late final List<String> targetIds;
    if (manual != null) {
      final matches = <({HadithItem item, int score})>[];
      for (final item in manual) {
        final record = _recordFromHadith(item);
        final score = _matchScore(
          query: normalized,
          text: record.normalizedText,
          number: item.hadithNumber,
        );
        if (score > 0) {
          matches.add((item: item, score: score));
        }
      }
      matches.sort((a, b) => b.score.compareTo(a.score));
      return [for (final match in matches.take(limit)) match.item];
    }
    final records = await getSearchIndexRecords();
    targetIds = await compute(_searchIndexMatches, {
      'records': records,
      'query': normalized,
      'limit': limit,
    });
    final results = <HadithItem>[];
    for (final targetId in targetIds) {
      final item = await getHadithById(targetId);
      if (item != null) {
        results.add(item);
      }
    }
    return results;
  }

  Future<List<HadithItem>> searchInBook(
    String bookId,
    String query, {
    int limit = 50,
  }) async {
    final normalized = SearchTextNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return const [];
    }
    final asset = await _loadBookAsset(bookId);
    return compute(searchHadithBook, {
      'hadiths': asset.hadiths,
      'query': normalized,
      'limit': limit,
    });
  }

  Future<List<ContentSource>> _loadContentSources() async {
    final raw = await _assetBundle.loadString(_sourcesPath);
    final map = _decodeJsonObject(raw);
    final sources = map['sources'] as List? ?? const [];
    return [
      for (final source in sources.cast<Map>())
        if (source['id'] == 'fawaz_hadith_api' ||
            source['id'] == 'ummah_library_hadith')
          ContentSource(
            id: source['id'] as String? ?? '',
            name: source['name'] as String? ?? '',
            attribution: source['attribution'] as String? ?? '',
            description: source['description'] as String?,
            url: source['sourceUrl'] as String?,
            license: source['license'] as String?,
          ),
    ];
  }

  Future<List<HadithBook>> _loadBooks() async {
    final raw = await _assetBundle.loadString(_manifestPath);
    final map = _decodeJsonObject(raw);
    final books = map['books'] as List? ?? const [];
    final visibleBooks = (await _visibility())['books'] as Map;
    return [
        for (final book in books.cast<Map<String, dynamic>>())
          HadithBook.fromMap({
            ...book,
            if (visibleBooks[book['slug']] case final Map counts) ...{
              'hadithCount': counts['hadithCount'],
              'chapterCount': counts['chapterCount'],
            },
          }),
      ].where((book) => book.hadithCount > 0).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<_HadithBookAsset> _loadBookAsset(String bookId) async {
    final cached = _bookCache.remove(bookId);
    if (cached != null) {
      _bookCache[bookId] = cached;
      return cached;
    }
    final book = await getBook(bookId);
    final slug = book?.slug ?? bookId;
    final cachedBySlug = _bookCache.remove(slug);
    if (cachedBySlug != null) {
      _bookCache[slug] = cachedBySlug;
      _bookCache[bookId] = cachedBySlug;
      return cachedBySlug;
    }
    final future = _bookLoadFutures.putIfAbsent(slug, () async {
      final raw = await _assetBundle.loadString(
        'assets/data/hadith/books/$slug.json',
      );
      return compute(_decodeHadithBookAsset, raw);
    });
    late final _HadithBookAsset asset;
    try {
      asset = await future;
    } finally {
      if (identical(_bookLoadFutures[slug], future)) {
        _bookLoadFutures.remove(slug);
      }
    }
    _bookCache[slug] = asset;
    _bookCache[bookId] = asset;
    while (_bookCache.length > 6) {
      _bookCache.remove(_bookCache.keys.first);
    }
    return asset;
  }

  Future<List<DeepSearchIndexRecord>> _loadSearchIndex() async {
    final raw = await _loadSearchIndexSource();
    final visibility = await _visibility();
    return compute(_decodeVisibleSearchIndex, {
      'source': raw,
      'visibility': visibility,
    });
  }

  Future<String> _loadSearchIndexSource() {
    return _searchIndexSourceFuture ??= _assetBundle.loadString(
      _searchIndexPath,
    );
  }

  DeepSearchIndexRecord _recordFromHadith(HadithItem hadith) {
    return DeepSearchIndexRecord(
      id: 'hadith:${hadith.id}',
      category: 'hadith',
      title: hadith.reference,
      subtitle: hadith.grade,
      primaryPreview: hadith.arabic,
      secondaryPreview: hadith.translation,
      normalizedText: SearchTextNormalizer.normalize(
        '${hadith.reference} ${hadith.grade} ${hadith.arabic} ${hadith.translation}',
      ),
      targetType: 'hadith',
      targetId: hadith.id,
      bookId: hadith.bookId,
    );
  }
}

String? _languageCodeFor(String language) {
  final normalized = language.toLowerCase().trim();
  return switch (normalized) {
    'arabic' => 'ar',
    'bengali' || 'bangla' => 'bn',
    'english' => 'en',
    'french' => 'fr',
    'indonesian' => 'id',
    'russian' => 'ru',
    'tamil' => 'ta',
    'turkish' => 'tr',
    'urdu' => 'ur',
    _ => null,
  };
}

class _HadithBookAsset {
  const _HadithBookAsset({required this.chapters, required this.hadiths});

  factory _HadithBookAsset.fromMap(Map<String, dynamic> map) {
    final hadiths = [
      for (final hadith in map['hadiths'] as List? ?? const [])
        HadithItem.fromMap(hadith as Map<String, dynamic>),
    ].where(HadithAuthenticityPolicy.shouldShow).toList();
    final populatedChapterIds = {
      for (final hadith in hadiths) hadith.chapterId,
    };
    return _HadithBookAsset(
      chapters: [
        for (final chapter in map['chapters'] as List? ?? const [])
          if (populatedChapterIds.contains(chapter['id']))
            HadithChapter.fromMap({
              ...chapter as Map<String, dynamic>,
              'hadithCount': hadiths
                  .where((item) => item.chapterId == chapter['id'])
                  .length,
            }),
      ],
      hadiths: hadiths,
    );
  }

  final List<HadithChapter> chapters;
  final List<HadithItem> hadiths;
}

int _matchScore({
  required String query,
  required String text,
  required String number,
}) {
  if (number == query || SearchTextNormalizer.normalize(number) == query) {
    return 100000;
  }
  final phraseIndex = text.indexOf(query);
  if (phraseIndex >= 0) {
    return 10000 - phraseIndex.clamp(0, 9000).toInt();
  }
  final terms = query.split(' ').where((term) => term.isNotEmpty);
  var score = 0;
  for (final term in terms) {
    final index = text.indexOf(term);
    if (index < 0) {
      return 0;
    }
    score += 500 - index.clamp(0, 450).toInt();
  }
  return score;
}

String _hadithNumberFromId(String id) {
  final parts = id.split(':');
  return parts.isEmpty ? '' : parts.last;
}

int _compareHadithNumbers(String a, String b) {
  final aParts = a.split('.');
  final bParts = b.split('.');
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var index = 0; index < length; index++) {
    final aPart = index < aParts.length ? int.tryParse(aParts[index]) ?? 0 : 0;
    final bPart = index < bParts.length ? int.tryParse(bParts[index]) ?? 0 : 0;
    final comparison = aPart.compareTo(bPart);
    if (comparison != 0) {
      return comparison;
    }
  }
  return a.compareTo(b);
}

List<T> _page<T>(List<T> items, int offset, int limit) {
  final start = offset.clamp(0, items.length).toInt();
  final end = (start + limit).clamp(start, items.length).toInt();
  return items.sublist(start, end);
}

Map<String, dynamic> _decodeJsonObject(String source) {
  return jsonDecode(source) as Map<String, dynamic>;
}

_HadithBookAsset _decodeHadithBookAsset(String source) {
  return _HadithBookAsset.fromMap(_decodeJsonObject(source));
}

List<DeepSearchIndexRecord> _decodeSearchIndex(String source) {
  return [
    for (final line in source.split('\n'))
      if (line.trim().isNotEmpty)
        DeepSearchIndexRecord.fromMap(jsonDecode(line) as Map<String, dynamic>),
  ];
}

List<DeepSearchIndexRecord> _decodeVisibleSearchIndex(
  Map<String, Object> args,
) {
  final books = (args['visibility'] as Map)['books'] as Map;
  final ids = <String>{
    for (final book in books.values) ...(book['ids'] as List).cast<String>(),
  };
  return _decodeSearchIndex(
    args['source'] as String,
  ).where((record) => ids.contains(record.targetId)).toList();
}

List<String> _searchIndexMatches(Map<String, Object> arguments) {
  final records = arguments['records']! as List<DeepSearchIndexRecord>;
  final query = arguments['query']! as String;
  final limit = arguments['limit']! as int;
  final matches = <({String targetId, int score})>[];
  for (final record in records) {
    final targetId = record.targetId;
    final score = _matchScore(
      query: query,
      text: record.normalizedText,
      number: _hadithNumberFromId(targetId),
    );
    if (score > 0) {
      matches.add((targetId: targetId, score: score));
    }
  }
  matches.sort((a, b) => b.score.compareTo(a.score));
  return [for (final match in matches.take(limit)) match.targetId];
}

List<HadithItem> searchHadithBook(Map<String, Object> arguments) {
  final hadiths = arguments['hadiths']! as List<HadithItem>;
  final query = arguments['query']! as String;
  final limit = arguments['limit']! as int;
  final matches = <({HadithItem item, int score})>[];
  for (final hadith in hadiths) {
    final text = SearchTextNormalizer.normalize(
      '${hadith.reference} ${hadith.cleanReference} ${hadith.grade} '
      '${hadith.arabic} ${hadith.translation}',
    );
    final score = _matchScore(
      query: query,
      text: text,
      number: hadith.hadithNumber,
    );
    if (score > 0) {
      matches.add((item: hadith, score: score));
    }
  }
  matches.sort((a, b) {
    final score = b.score.compareTo(a.score);
    return score != 0
        ? score
        : _compareHadithNumbers(a.item.hadithNumber, b.item.hadithNumber);
  });
  return [for (final match in matches.take(limit)) match.item];
}
