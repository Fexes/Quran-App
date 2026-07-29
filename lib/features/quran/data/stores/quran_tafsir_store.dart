import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_tafsir.dart';

class QuranTafsirStore {
  QuranTafsirStore._box(this._box) : _memory = null;

  QuranTafsirStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'quran_tafsirs';

  static Future<QuranTafsirStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranTafsirStore._box(box);
  }

  List<QuranTafsirResource> catalog({ContentCachePolicy? cachePolicy}) {
    if (!_isFresh(
      fetchedAt: _date(_read('tafsir_catalog_fetched_at')),
      cachePolicy: cachePolicy,
    )) {
      return const [];
    }
    final raw = _read('tafsir_catalog');
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) QuranTafsirResource.fromJson(item),
    ];
  }

  Future<void> saveCatalog(List<QuranTafsirResource> resources) async {
    await _write('tafsir_catalog', [
      for (final resource in resources) resource.toJson(),
    ]);
    await _write('tafsir_catalog_fetched_at', DateTime.now().toIso8601String());
  }

  String? tafsirForVerse({
    required int resourceId,
    required String verseKey,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_verseId(resourceId: resourceId, verseKey: verseKey));
    return _tafsirText(raw, cachePolicy: cachePolicy);
  }

  Future<void> saveVerseTafsir({
    required int resourceId,
    required String verseKey,
    required String tafsir,
  }) {
    return _write(_verseId(resourceId: resourceId, verseKey: verseKey), {
      'text': tafsir,
      'fetchedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveVerseTafsirs({
    required int resourceId,
    required Map<String, String> tafsirs,
  }) async {
    for (final entry in tafsirs.entries) {
      await saveVerseTafsir(
        resourceId: resourceId,
        verseKey: entry.key,
        tafsir: entry.value,
      );
    }
  }

  List<QuranCachedTafsirVerse> allCachedVerseTafsirs({
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) {
    final resources = {for (final resource in catalog()) resource.id: resource};
    final entries = <QuranCachedTafsirVerse>[];
    final prefix = 'tafsir:';
    const middle = ':verse:';
    for (final key in _keys()) {
      if (!key.startsWith(prefix) || !key.contains(middle)) {
        continue;
      }
      final value = _tafsirText(_read(key), cachePolicy: cachePolicy);
      if (value == null) {
        continue;
      }
      final withoutPrefix = key.substring(prefix.length);
      final divider = withoutPrefix.indexOf(middle);
      if (divider <= 0) {
        continue;
      }
      final resourceId = int.tryParse(withoutPrefix.substring(0, divider));
      final verseKey = withoutPrefix.substring(divider + middle.length);
      if (resourceId == null || verseKey.isEmpty) {
        continue;
      }
      final resource = resources[resourceId];
      entries.add(
        QuranCachedTafsirVerse(
          resourceId: resourceId,
          verseKey: verseKey,
          text: value,
          resourceName: resource?.name,
          languageName: resource?.languageName,
        ),
      );
    }
    return entries;
  }

  bool hasSurahTafsir({
    required int resourceId,
    required int surahNumber,
    required int verseCount,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(
      _surahMetaId(resourceId: resourceId, surahNumber: surahNumber),
    );
    if (raw is! Map) {
      return false;
    }
    return _isFresh(
          fetchedAt: _date(raw['completedAt']),
          cachePolicy: cachePolicy,
        ) &&
        raw['complete'] == true &&
        raw['verseCount'] == verseCount;
  }

  Future<void> markSurahTafsirComplete({
    required QuranTafsirResource resource,
    required int surahNumber,
    required int verseCount,
  }) {
    return _write(
      _surahMetaId(resourceId: resource.id, surahNumber: surahNumber),
      {
        'resourceId': resource.id,
        'languageName': resource.languageName,
        'resourceName': resource.name,
        'surahNumber': surahNumber,
        'complete': true,
        'verseCount': verseCount,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> purgeExpired({
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) async {
    if (!_isFresh(
      fetchedAt: _date(_read('tafsir_catalog_fetched_at')),
      cachePolicy: cachePolicy,
    )) {
      await _delete('tafsir_catalog');
      await _delete('tafsir_catalog_fetched_at');
    }
    for (final key in _keys().toList()) {
      if (!key.startsWith('tafsir:')) {
        continue;
      }
      final raw = _read(key);
      final fetchedAt = key.endsWith(':meta') && raw is Map
          ? _date(raw['completedAt'])
          : raw is Map
          ? _date(raw['fetchedAt'])
          : null;
      if (!_isFresh(fetchedAt: fetchedAt, cachePolicy: cachePolicy)) {
        await _delete(key);
      }
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

  static String? _tafsirText(Object? raw, {ContentCachePolicy? cachePolicy}) {
    if (raw is String) {
      if (cachePolicy != null || raw.trim().isEmpty) {
        return null;
      }
      return raw;
    }
    if (raw is! Map ||
        !_isFresh(
          fetchedAt: _date(raw['fetchedAt']),
          cachePolicy: cachePolicy,
        )) {
      return null;
    }
    final text = raw['text'];
    return text is String && text.trim().isNotEmpty ? text : null;
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

  static String _verseId({required int resourceId, required String verseKey}) {
    return 'tafsir:$resourceId:verse:$verseKey';
  }

  static String _surahMetaId({
    required int resourceId,
    required int surahNumber,
  }) {
    return 'tafsir:$resourceId:surah:$surahNumber:meta';
  }
}
