import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/hifz_models.dart';

class HifzStore {
  HifzStore._box(this._box) : _memory = null;

  HifzStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'hifz_progress';
  static const _collectionsKey = 'collections';
  static const _cardsKey = 'cards';

  static Future<HifzStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return HifzStore._box(box);
  }

  List<HifzCollection> get collections {
    final raw = _read(_collectionsKey);
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) HifzCollection.fromJson(item),
    ].where((item) => item.id.isNotEmpty).toList(growable: false);
  }

  Map<String, HifzCard> get cards {
    final raw = _read(_cardsKey);
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is Map)
          entry.key as String: HifzCard.fromJson(entry.value as Map),
    };
  }

  Future<void> saveCollections(List<HifzCollection> collections) {
    return _write(
      _collectionsKey,
      collections.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> saveCards(Map<String, HifzCard> cards) {
    return _write(_cardsKey, {
      for (final entry in cards.entries) entry.key: entry.value.toJson(),
    });
  }

  Map<String, Object?> exportSnapshot() {
    return {for (final key in _keys()) key: _read(key)};
  }

  Future<void> restoreSnapshot(
    Map<String, Object?> values, {
    required bool replace,
  }) async {
    if (replace) {
      await _clear();
    }
    for (final entry in values.entries) {
      if (entry.value != null) {
        await _write(entry.key, entry.value!);
      }
    }
  }

  Future<void> clearAll() => _clear();

  Object? _read(String key) => _box?.get(key) ?? _memory?[key];

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) {
      await box.put(key, value);
    } else {
      _memory?[key] = value;
    }
  }

  Iterable<String> _keys() {
    final box = _box;
    if (box != null) {
      return box.keys.whereType<String>();
    }
    return _memory?.keys ?? const [];
  }

  Future<void> _clear() async {
    final box = _box;
    if (box != null) {
      await box.clear();
    } else {
      _memory?.clear();
    }
  }
}
