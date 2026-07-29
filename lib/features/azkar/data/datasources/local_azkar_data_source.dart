import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/dhikr_item.dart';

class LocalAzkarDataSource {
  LocalAzkarDataSource({
    AssetBundle? assetBundle,
    List<ContentSource>? sources,
    List<AzkarCategory>? categories,
    List<DhikrItem>? dhikr,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _manualSources = sources,
       _manualCategories = categories,
       _manualDhikr = dhikr;

  static const _manifestPath = 'assets/data/azkar/manifest.json';
  static const _sourcesPath =
      'assets/data/content_sources/hadith_azkar_sources.json';
  static const _searchIndexPath = 'assets/data/azkar/search_index.jsonl';

  final AssetBundle _assetBundle;
  final List<ContentSource>? _manualSources;
  final List<AzkarCategory>? _manualCategories;
  final List<DhikrItem>? _manualDhikr;
  final _categoryCache = <String, List<DhikrItem>>{};

  Future<List<AzkarCategory>>? _categoriesFuture;
  Future<List<ContentSource>>? _sourcesFuture;
  Future<List<DeepSearchIndexRecord>>? _searchIndexFuture;

  Future<List<ContentSource>> getContentSources() {
    final manual = _manualSources;
    if (manual != null) {
      return Future.value(List.unmodifiable(manual));
    }
    return _sourcesFuture ??= _loadContentSources();
  }

  Future<List<AzkarCategory>> getCategories() {
    final manual = _manualCategories;
    if (manual != null) {
      return Future.value(List.unmodifiable(manual));
    }
    return _categoriesFuture ??= _loadCategories();
  }

  Future<List<String>> availableTranslationLanguages() async {
    return const ['en'];
  }

  Future<bool> hasFullTranslation(String languageCode) async {
    return languageCode.toLowerCase() == 'en';
  }

  Future<List<DhikrItem>> getDhikr({
    String? categoryId,
    String? languageCode,
    int offset = 0,
    int limit = 100,
  }) async {
    final manual = _manualDhikr;
    if (manual != null) {
      return _page(
        manual
            .where(
              (item) => categoryId == null || item.categoryId == categoryId,
            )
            .toList(growable: false),
        offset,
        limit,
      );
    }
    if (categoryId != null) {
      final items = await _loadCategoryItems(categoryId);
      return _page(items, offset, limit);
    }
    final categories = await getCategories();
    final all = <DhikrItem>[];
    for (final category in categories) {
      all.addAll(await _loadCategoryItems(category.id));
    }
    return _page(all, offset, limit);
  }

  Future<DhikrItem?> getDhikrById(String id) async {
    final manual = _manualDhikr;
    if (manual != null) {
      for (final item in manual) {
        if (item.id == id) {
          return item;
        }
      }
      return null;
    }
    final records = await getSearchIndexRecords();
    final record = records.where((record) => record.targetId == id).firstOrNull;
    final categoryId = record?.categoryId;
    if (categoryId == null) {
      return null;
    }
    final items = await _loadCategoryItems(categoryId);
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() {
    if (_manualDhikr != null) {
      return Future.value(_manualDhikr.map(_recordFromDhikr).toList());
    }
    return _searchIndexFuture ??= _loadSearchIndex();
  }

  Future<List<DhikrItem>> search(String query, {int limit = 30}) async {
    final normalized = SearchTextNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return const [];
    }
    final records = await getSearchIndexRecords();
    final matches = records
        .where((record) => record.normalizedText.contains(normalized))
        .take(limit)
        .toList(growable: false);
    final results = <DhikrItem>[];
    for (final record in matches) {
      final item = await getDhikrById(record.targetId);
      if (item != null) {
        results.add(item);
      }
    }
    return results;
  }

  Future<List<ContentSource>> _loadContentSources() async {
    final raw = await _assetBundle.loadString(_sourcesPath);
    final map = _decodeJsonObject(raw);
    final sources = map['sources'] as List? ?? const [];
    return [
      for (final source in sources.cast<Map>())
        if (source['id'] == 'muslim_data_android')
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

  Future<List<AzkarCategory>> _loadCategories() async {
    final raw = await _assetBundle.loadString(_manifestPath);
    final map = _decodeJsonObject(raw);
    final categories = map['categories'] as List? ?? const [];
    return [
      for (final category in categories.cast<Map<String, dynamic>>())
        AzkarCategory.fromMap(category),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<DhikrItem>> _loadCategoryItems(String categoryId) async {
    final cached = _categoryCache.remove(categoryId);
    if (cached != null) {
      _categoryCache[categoryId] = cached;
      return cached;
    }
    final raw = await _assetBundle.loadString(
      'assets/data/azkar/categories/$categoryId.json',
    );
    final map = _decodeJsonObject(raw);
    final items = [
      for (final item in map['items'] as List? ?? const [])
        DhikrItem.fromMap(item as Map<String, dynamic>),
    ];
    _categoryCache[categoryId] = items;
    while (_categoryCache.length > 6) {
      _categoryCache.remove(_categoryCache.keys.first);
    }
    return items;
  }

  Future<List<DeepSearchIndexRecord>> _loadSearchIndex() async {
    final raw = await _assetBundle.loadString(_searchIndexPath);
    return compute(_decodeSearchIndex, raw);
  }

  DeepSearchIndexRecord _recordFromDhikr(DhikrItem item) {
    return DeepSearchIndexRecord(
      id: 'azkar:${item.id}',
      category: 'azkar',
      title: item.title.isEmpty ? item.reference : item.title,
      subtitle: 'Repeat ${item.repeatCount}x',
      primaryPreview: item.arabic,
      secondaryPreview: item.translation,
      normalizedText: SearchTextNormalizer.normalize(
        '${item.title} ${item.arabic} ${item.translation} ${item.reference}',
      ),
      targetType: 'azkar',
      targetId: item.id,
      categoryId: item.categoryId,
    );
  }
}

List<T> _page<T>(List<T> items, int offset, int limit) {
  final start = offset.clamp(0, items.length).toInt();
  final end = (start + limit).clamp(start, items.length).toInt();
  return items.sublist(start, end);
}

Map<String, dynamic> _decodeJsonObject(String source) {
  return jsonDecode(source) as Map<String, dynamic>;
}

List<DeepSearchIndexRecord> _decodeSearchIndex(String source) {
  return [
    for (final line in source.split('\n'))
      if (line.trim().isNotEmpty)
        DeepSearchIndexRecord.fromMap(jsonDecode(line) as Map<String, dynamic>),
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
