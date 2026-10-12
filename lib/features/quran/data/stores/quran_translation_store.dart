import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_translation.dart';

class QuranTranslationStore {
  QuranTranslationStore._box(this._box) : _memory = null;

  QuranTranslationStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'quran_translations';
  static const _contentRevisionKey = 'translation_content_revision';

  static Future<QuranTranslationStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranTranslationStore._box(box);
  }

  List<QuranTranslationResource> catalog({ContentCachePolicy? cachePolicy}) {
    if (!_isFresh(
      fetchedAt: _date(_read('translation_catalog_fetched_at')),
      cachePolicy: cachePolicy,
    )) {
      return const [];
    }
    final raw = _read('translation_catalog');
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) QuranTranslationResource.fromJson(item),
    ];
  }

  Future<void> saveCatalog(List<QuranTranslationResource> resources) async {
    await _write('translation_catalog', [
      for (final resource in resources) resource.toJson(),
    ]);
    await _write(
      'translation_catalog_fetched_at',
      DateTime.now().toIso8601String(),
    );
  }

  QuranTranslationResource? selectedResource() {
    final raw = _read('selected_translation_resource');
    if (raw is! Map) {
      return null;
    }
    return QuranTranslationResource.fromJson(raw);
  }

  int? preferredResourceId(String languageName) {
    final value = _read(
      'preferred_translation:${languageName.trim().toLowerCase()}',
    );
    if (value is int) return value;
    final selected = selectedResource();
    return selected?.languageName.toLowerCase() == languageName.toLowerCase()
        ? selected?.id
        : null;
  }

  Future<void> saveSelectedResource(QuranTranslationResource? resource) async {
    if (resource == null) {
      await _delete('selected_translation_resource');
      return;
    }
    await _write('selected_translation_resource', resource.toJson());
    await _write(
      'preferred_translation:${resource.languageName.trim().toLowerCase()}',
      resource.id,
    );
  }

  List<QuranTranslationResource> selectedResources() {
    final raw = _read('selected_translation_resources');
    if (raw is List) {
      final parsed = [
        for (final item in raw)
          if (item is Map) QuranTranslationResource.fromJson(item),
      ].where((item) => item.id > 0).toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    final primary = selectedResource();
    return primary == null ? const [] : [primary];
  }

  Future<void> saveSelectedResources(
    List<QuranTranslationResource> resources,
  ) async {
    final unique = <int, QuranTranslationResource>{
      for (final resource in resources) resource.id: resource,
    }.values.toList(growable: false);
    if (unique.isEmpty) {
      await _delete('selected_translation_resources');
      return;
    }
    await _write('selected_translation_resources', [
      for (final resource in unique) resource.toJson(),
    ]);
  }

  String? translationForVerse({
    required int resourceId,
    required String verseKey,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_verseId(resourceId: resourceId, verseKey: verseKey));
    return _translationText(raw, cachePolicy: cachePolicy);
  }

  Future<void> saveVerseTranslations({
    required int resourceId,
    required Map<String, String> translations,
  }) async {
    for (final entry in translations.entries) {
      await _write(_verseId(resourceId: resourceId, verseKey: entry.key), {
        'text': entry.value,
        'fetchedAt': DateTime.now().toIso8601String(),
      });
    }
    await _incrementContentRevision();
  }

  Map<String, String> translationsForSurah({
    required int resourceId,
    required int surahNumber,
    ContentCachePolicy? cachePolicy,
  }) {
    final prefix = 'translation:$resourceId:verse:$surahNumber:';
    final result = <String, String>{};
    for (final key in _keys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final value = _translationText(_read(key), cachePolicy: cachePolicy);
      if (value != null) {
        final verseKey = key.substring('translation:$resourceId:verse:'.length);
        result[verseKey] = value;
      }
    }
    return result;
  }

  bool hasSurahTranslation({
    required int resourceId,
    required int surahNumber,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_chapterMetaId(resourceId, surahNumber));
    return raw is Map &&
        raw['complete'] == true &&
        _isFresh(
          fetchedAt: _date(raw['completedAt']),
          cachePolicy: cachePolicy,
        ) &&
        translationsForSurah(
          resourceId: resourceId,
          surahNumber: surahNumber,
          cachePolicy: cachePolicy,
        ).isNotEmpty;
  }

  Future<void> markSurahTranslationComplete({
    required QuranTranslationResource resource,
    required int surahNumber,
    required int verseCount,
  }) {
    return _write(_chapterMetaId(resource.id, surahNumber), {
      'resourceId': resource.id,
      'surahNumber': surahNumber,
      'languageName': resource.languageName,
      'resourceName': resource.name,
      'revision': resource.revision,
      'checksum': resource.checksum,
      'complete': true,
      'verseCount': verseCount,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  List<int> downloadedSurahs({
    required int resourceId,
    ContentCachePolicy? cachePolicy,
  }) {
    final result = <int>[];
    for (var surah = 1; surah <= 114; surah++) {
      if (hasSurahTranslation(
        resourceId: resourceId,
        surahNumber: surah,
        cachePolicy: cachePolicy,
      )) {
        result.add(surah);
      }
    }
    return result;
  }

  Set<int> downloadedResourceIds({ContentCachePolicy? cachePolicy}) {
    final result = <int>{};
    final chapterPattern = RegExp(r'^translation:(\d+):chapter:\d+:meta$');
    final fullPattern = RegExp(r'^translation:(\d+):meta$');
    for (final key in _keys()) {
      final match =
          chapterPattern.firstMatch(key) ?? fullPattern.firstMatch(key);
      if (match == null) {
        continue;
      }
      final raw = _read(key);
      if (raw is Map &&
          raw['complete'] == true &&
          _isFresh(
            fetchedAt: _date(raw['completedAt']),
            cachePolicy: cachePolicy,
          )) {
        result.add(int.parse(match.group(1)!));
      }
    }
    return result;
  }

  DateTime? surahTranslationExpiresAt({
    required int resourceId,
    required int surahNumber,
    required ContentCachePolicy cachePolicy,
  }) {
    final raw = _read(_chapterMetaId(resourceId, surahNumber));
    return raw is Map ? cachePolicy.expiresAt(_date(raw['completedAt'])) : null;
  }

  DateTime? surahTranslationDownloadedAt({
    required int resourceId,
    required int surahNumber,
  }) {
    final raw = _read(_chapterMetaId(resourceId, surahNumber));
    return raw is Map ? _date(raw['completedAt']) : null;
  }

  int cachedResourceBytes(int resourceId) {
    var bytes = 0;
    final prefix = 'translation:$resourceId:verse:';
    for (final key in _keys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final raw = _read(key);
      if (raw is Map && raw['text'] is String) {
        bytes += utf8.encode(raw['text'] as String).length;
      }
    }
    return bytes;
  }

  Future<void> deleteResource(int resourceId) async {
    final prefix = 'translation:$resourceId:';
    for (final key in _keys().toList()) {
      if (key.startsWith(prefix)) {
        await _delete(key);
      }
    }
    final selected = selectedResources()
        .where((item) => item.id != resourceId)
        .toList(growable: false);
    await saveSelectedResources(selected);
    if (selectedResource()?.id == resourceId) {
      await saveSelectedResource(selected.firstOrNull);
    }
    await _incrementContentRevision();
  }

  int get contentRevision {
    final raw = _read(_contentRevisionKey);
    return raw is int ? raw : 0;
  }

  Future<void> _incrementContentRevision() {
    return _write(_contentRevisionKey, contentRevision + 1);
  }

  List<QuranCachedTranslationVerse> allCachedVerseTranslations({
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) {
    final selected = selectedResource();
    final resources = {for (final resource in catalog()) resource.id: resource};
    if (selected != null) {
      resources[selected.id] = selected;
    }
    final entries = <QuranCachedTranslationVerse>[];
    final prefix = 'translation:';
    const middle = ':verse:';
    for (final key in _keys()) {
      if (!key.startsWith(prefix) || !key.contains(middle)) {
        continue;
      }
      final value = _translationText(_read(key), cachePolicy: cachePolicy);
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
        QuranCachedTranslationVerse(
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

  bool hasFullTranslation({
    required int resourceId,
    required String version,
    required int verseCount,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_metaId(resourceId));
    if (raw is! Map) {
      return false;
    }
    return _isFresh(
          fetchedAt: _date(raw['completedAt']),
          cachePolicy: cachePolicy,
        ) &&
        raw['version'] == version &&
        raw['complete'] == true &&
        raw['verseCount'] == verseCount;
  }

  DateTime? fullTranslationExpiresAt({
    required int resourceId,
    required ContentCachePolicy cachePolicy,
  }) {
    final raw = _read(_metaId(resourceId));
    if (raw is! Map) {
      return null;
    }
    return cachePolicy.expiresAt(_date(raw['completedAt']));
  }

  Future<void> purgeExpired({
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) async {
    if (!_isFresh(
      fetchedAt: _date(_read('translation_catalog_fetched_at')),
      cachePolicy: cachePolicy,
    )) {
      await _delete('translation_catalog');
      await _delete('translation_catalog_fetched_at');
    }

    for (final key in _keys().toList()) {
      if (!key.startsWith('translation:')) {
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

  Future<void> markFullTranslationComplete({
    required QuranTranslationResource resource,
    required String version,
    required int verseCount,
  }) {
    return _write(_metaId(resource.id), {
      'resourceId': resource.id,
      'languageName': resource.languageName,
      'resourceName': resource.name,
      'version': version,
      'complete': true,
      'verseCount': verseCount,
      'completedAt': DateTime.now().toIso8601String(),
    });
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

  static String? _translationText(
    Object? raw, {
    ContentCachePolicy? cachePolicy,
  }) {
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
    return 'translation:$resourceId:verse:$verseKey';
  }

  static String _metaId(int resourceId) {
    return 'translation:$resourceId:meta';
  }

  static String _chapterMetaId(int resourceId, int surahNumber) {
    return 'translation:$resourceId:chapter:$surahNumber:meta';
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
