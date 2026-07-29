import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/entities/hadeeth_enc_item.dart';

class HadeethEncStore {
  HadeethEncStore._box(this._box) : _memory = null;

  HadeethEncStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'hadeeth_enc';

  static Future<HadeethEncStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return HadeethEncStore._box(box);
  }

  List<HadeethEncLanguage> languages() {
    final raw = _read('languages');
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) HadeethEncLanguage.fromJson(item),
    ];
  }

  Future<void> saveLanguages(List<HadeethEncLanguage> languages) {
    return _write('languages', [
      for (final language in languages) language.toJson(),
    ]);
  }

  bool hasFullLanguage(String languageCode) {
    final raw = _read(_metaKey(languageCode));
    return raw is Map && raw['complete'] == true;
  }

  List<String> downloadedLanguageCodes() {
    return [
      for (final key in _keys())
        if (key.startsWith(_metaPrefix) && key.endsWith(_metaSuffix))
          key.substring(_metaPrefix.length, key.length - _metaSuffix.length),
    ];
  }

  String? versionForLanguage(String languageCode) {
    final raw = _read(_metaKey(languageCode));
    return raw is Map ? raw['version']?.toString() : null;
  }

  Future<void> saveLanguageItems({
    required String languageCode,
    required String version,
    required List<HadeethEncItem> items,
  }) async {
    await _write(_itemsKey(languageCode), [
      for (final item in items) item.toJson(),
    ]);
    await _write(_metaKey(languageCode), {
      'languageCode': languageCode,
      'version': version,
      'complete': true,
      'itemCount': items.length,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  List<HadeethEncItem> itemsForLanguage(String languageCode) {
    final raw = _read(_itemsKey(languageCode));
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) HadeethEncItem.fromJson(item),
    ];
  }

  List<HadeethEncItem> pageForLanguage({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  }) {
    return _page(itemsForLanguage(languageCode), offset, limit);
  }

  HadeethEncItem? itemById({required String languageCode, required String id}) {
    for (final item in itemsForLanguage(languageCode)) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<HadeethEncItem> search({
    required String languageCode,
    required String query,
    int limit = 30,
  }) {
    final normalized = SearchTextNormalizer.normalize(query);
    if (normalized.isEmpty) {
      return const [];
    }
    return itemsForLanguage(languageCode)
        .where((item) {
          final text = SearchTextNormalizer.normalize(
            '${item.id} ${item.title} ${item.hadithText} ${item.explanation} '
            '${item.grade} ${item.attribution} ${item.hadithTextArabic}',
          );
          return text.contains(normalized);
        })
        .take(limit)
        .toList(growable: false);
  }

  Object? _read(String key) {
    final box = _box;
    if (box != null) {
      return box.get(key);
    }
    return _memory?[key];
  }

  Iterable<String> _keys() {
    final box = _box;
    if (box != null) {
      return box.keys.map((key) => key.toString());
    }
    return _memory?.keys ?? const <String>[];
  }

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) {
      await box.put(key, value);
      return;
    }
    _memory?[key] = value;
  }

  static String _itemsKey(String languageCode) =>
      'hadeethenc:$languageCode:items';

  static const _metaPrefix = 'hadeethenc:';
  static const _metaSuffix = ':meta';

  static String _metaKey(String languageCode) =>
      '$_metaPrefix$languageCode$_metaSuffix';
}

List<T> _page<T>(List<T> items, int offset, int limit) {
  final start = offset.clamp(0, items.length).toInt();
  final end = (start + limit).clamp(start, items.length).toInt();
  return items.sublist(start, end);
}
