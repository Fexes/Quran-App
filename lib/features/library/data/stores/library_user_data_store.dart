import 'package:hive_flutter/hive_flutter.dart';

class LibraryUserDataStore {
  LibraryUserDataStore._box(this._box) : _memory = null;

  LibraryUserDataStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'library_user_data';
  static const _achievementsEnabledKey = 'achievements_enabled';

  static Future<LibraryUserDataStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return LibraryUserDataStore._box(box);
  }

  bool isBookmarked(String itemKey) {
    return _read(_bookmarkKey(itemKey)) == true;
  }

  Future<bool> toggleBookmark(String itemKey) async {
    final next = !isBookmarked(itemKey);
    await _write(_bookmarkKey(itemKey), next);
    return next;
  }

  String noteFor(String itemKey) {
    final value = _read(_noteKey(itemKey));
    return value is String ? value : '';
  }

  Future<void> saveNote(String itemKey, String note) async {
    final normalized = note.trim();
    if (normalized.isEmpty) {
      await _delete(_noteKey(itemKey));
      return;
    }
    await _write(_noteKey(itemKey), normalized);
  }

  String? lastReadFor(String scopeKey) {
    final value = _read(_lastReadKey(scopeKey));
    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> saveLastRead({
    required String scopeKey,
    required String itemKey,
  }) {
    return _write(_lastReadKey(scopeKey), itemKey);
  }

  bool get achievementsEnabled => _read(_achievementsEnabledKey) != false;

  Future<void> setAchievementsEnabled(bool value) {
    return _write(_achievementsEnabledKey, value);
  }

  Map<String, Object?> exportSnapshot() {
    return {
      for (final key in _keys())
        if (!key.startsWith('note:mosque-cache:')) key: _read(key),
    };
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

  Future<void> _clear() async {
    final box = _box;
    if (box != null) {
      await box.clear();
    } else {
      _memory?.clear();
    }
  }

  static String _bookmarkKey(String itemKey) => 'bookmark:$itemKey';
  static String _noteKey(String itemKey) => 'note:$itemKey';
  static String _lastReadKey(String scopeKey) => 'last_read:$scopeKey';
}
