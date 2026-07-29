import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/content/content_cache_policy.dart';
import '../../domain/entities/quran_word_timing.dart';

class QuranWordTimingStore {
  QuranWordTimingStore._box(this._box) : _memory = null;

  QuranWordTimingStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'quran_word_timings';

  static Future<QuranWordTimingStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranWordTimingStore._box(box);
  }

  QuranWordTimingResult? resultFor({
    required String reciterId,
    required String verseKey,
    ContentCachePolicy? cachePolicy,
  }) {
    final raw = _read(_idFor(reciterId: reciterId, verseKey: verseKey));
    if (raw is Map) {
      if (cachePolicy != null &&
          !cachePolicy.isValid(fetchedAt: _date(raw['fetchedAt']))) {
        return null;
      }
      final result = QuranWordTimingResult.fromJson(raw);
      if (result.reciterId == reciterId && result.verseKey == verseKey) {
        return result;
      }
    }
    return null;
  }

  Future<void> saveResult(QuranWordTimingResult result) {
    return _write(
      _idFor(reciterId: result.reciterId, verseKey: result.verseKey),
      {...result.toJson(), 'fetchedAt': DateTime.now().toIso8601String()},
    );
  }

  Future<void> purgeExpired({
    ContentCachePolicy cachePolicy = ContentCachePolicy.quranFoundation,
  }) async {
    for (final key in _keys().toList()) {
      final raw = _read(key);
      final fetchedAt = raw is Map ? _date(raw['fetchedAt']) : null;
      if (!cachePolicy.isValid(fetchedAt: fetchedAt)) {
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

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  static String _idFor({required String reciterId, required String verseKey}) {
    return '$reciterId::$verseKey';
  }
}
