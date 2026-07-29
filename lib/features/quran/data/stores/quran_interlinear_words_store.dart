import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_word.dart';

class QuranInterlinearWordsStore {
  QuranInterlinearWordsStore._box(this._box) : _memory = null;

  QuranInterlinearWordsStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'quran_interlinear_words';

  static Future<QuranInterlinearWordsStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranInterlinearWordsStore._box(box);
  }

  List<QuranWord> pageWords({
    required int pageNumber,
    required String language,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_idFor(pageNumber: pageNumber, language: language));
    final rawWords = raw is Map ? raw['words'] : raw;
    final fetchedAt = raw is Map ? _date(raw['fetchedAt']) : null;
    if (!_isFresh(fetchedAt: fetchedAt, cachePolicy: cachePolicy) ||
        rawWords is! List) {
      return const [];
    }
    return [
      for (final item in rawWords)
        if (item is Map) QuranWord.fromJson(item),
    ];
  }

  Future<void> savePageWords({
    required int pageNumber,
    required String language,
    required List<QuranWord> words,
  }) {
    return _write(_idFor(pageNumber: pageNumber, language: language), {
      'fetchedAt': DateTime.now().toIso8601String(),
      'words': [for (final word in words) word.toJson()],
    });
  }

  bool hasPageWords({
    required int pageNumber,
    required String language,
    ContentCachePolicy? cachePolicy,
  }) {
    return pageWords(
      pageNumber: pageNumber,
      language: language,
      cachePolicy: cachePolicy,
    ).isNotEmpty;
  }

  bool hasFullCache({
    required String language,
    required String version,
    required int pageCount,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_fullCacheIdFor(language: language));
    if (raw is! Map) {
      return false;
    }
    if (raw['version'] != version || raw['pageCount'] != pageCount) {
      return false;
    }
    if (raw['complete'] != true) {
      return false;
    }
    if (!_isFresh(
      fetchedAt: _date(raw['completedAt']),
      cachePolicy: cachePolicy,
    )) {
      return false;
    }
    for (var page = 1; page <= pageCount; page++) {
      if (!hasPageWords(
        pageNumber: page,
        language: language,
        cachePolicy: cachePolicy,
      )) {
        return false;
      }
    }
    return true;
  }

  Future<void> markFullCacheComplete({
    required String language,
    required String version,
    required int pageCount,
  }) {
    return _write(_fullCacheIdFor(language: language), {
      'language': language,
      'version': version,
      'pageCount': pageCount,
      'complete': true,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  DateTime? fullCacheExpiresAt({
    required String language,
    required ContentCachePolicy cachePolicy,
  }) {
    final raw = _read(_fullCacheIdFor(language: language));
    if (raw is! Map) {
      return null;
    }
    return cachePolicy.expiresAt(_date(raw['completedAt']));
  }

  Future<void> purgeExpired({
    required String language,
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) async {
    final pagePrefix = 'interlinear_words:$language:page:';
    for (final key in _keys().toList()) {
      if (!key.startsWith(pagePrefix)) {
        continue;
      }
      final raw = _read(key);
      final fetchedAt = raw is Map ? _date(raw['fetchedAt']) : null;
      if (!_isFresh(fetchedAt: fetchedAt, cachePolicy: cachePolicy)) {
        await _delete(key);
      }
    }
    final metadataKey = _fullCacheIdFor(language: language);
    final metadata = _read(metadataKey);
    final completedAt = metadata is Map ? _date(metadata['completedAt']) : null;
    if (!_isFresh(fetchedAt: completedAt, cachePolicy: cachePolicy)) {
      await _delete(metadataKey);
    }
  }

  Object? _read(String key) {
    final box = _box;
    if (box != null) {
      return box.get(key);
    }
    return _memory?[key];
  }

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) {
      await box.put(key, value);
      return;
    }
    _memory?[key] = value;
  }

  Future<void> _delete(String key) async {
    final box = _box;
    if (box != null) {
      await box.delete(key);
      return;
    }
    _memory?.remove(key);
  }

  Iterable<String> _keys() {
    final box = _box;
    if (box != null) {
      return box.keys.whereType<String>();
    }
    return _memory?.keys ?? const [];
  }

  static bool _isFresh({
    required DateTime? fetchedAt,
    required ContentCachePolicy? cachePolicy,
  }) {
    return cachePolicy?.isValid(fetchedAt: fetchedAt) ?? true;
  }

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  static String _idFor({required int pageNumber, required String language}) {
    return 'interlinear_words:$language:page:$pageNumber';
  }

  static String _fullCacheIdFor({required String language}) {
    return 'interlinear_words:$language:full_cache';
  }
}
