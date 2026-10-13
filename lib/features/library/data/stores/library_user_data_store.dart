import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/search/local_search_revision.dart';

class LibraryUserDataStore {
  LibraryUserDataStore._box(this._box) : _memory = null;

  LibraryUserDataStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'library_user_data';
  static const _achievementsEnabledKey = 'achievements_enabled';
  static const _modifiedPrefix = 'modified:';

  Map<String, String> get notes => {
    for (final key in _keys())
      if (key.startsWith('note:') && !key.startsWith('note:mosque-cache:'))
        key.substring(5): _read(key)?.toString() ?? '',
  };

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
    final previousKeys = _keys().toList();
    for (final key in previousKeys) {
      if (!key.startsWith(_modifiedPrefix) &&
          values.containsKey('$_modifiedPrefix$key') &&
          !values.containsKey(key)) {
        await _delete(key, recordModification: false);
      }
    }
    for (final entry in values.entries) {
      if (entry.value != null) {
        await _write(entry.key, entry.value!, recordModification: false);
      }
    }
  }

  static Map<String, Object?> mergeSnapshots(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final result = Map<String, Object?>.from(current);
    final keys = {
      for (final key in {...current.keys, ...incoming.keys})
        key.startsWith(_modifiedPrefix)
            ? key.substring(_modifiedPrefix.length)
            : key,
    };
    for (final key in keys) {
      final modifiedKey = '$_modifiedPrefix$key';
      final localDate = DateTime.tryParse(
        current[modifiedKey]?.toString() ?? '',
      );
      final backupDate = DateTime.tryParse(
        incoming[modifiedKey]?.toString() ?? '',
      );
      final hasLocal =
          current.containsKey(key) || current.containsKey(modifiedKey);
      final useBackup =
          !hasLocal ||
          (localDate != null &&
              backupDate != null &&
              backupDate.isAfter(localDate));
      if (!useBackup) continue;
      if (incoming.containsKey(key)) {
        result[key] = incoming[key];
      } else {
        result.remove(key);
      }
      if (incoming.containsKey(modifiedKey)) {
        result[modifiedKey] = incoming[modifiedKey];
      } else {
        result.remove(modifiedKey);
      }
    }
    return result;
  }

  Future<void> clearAll() => _clear();

  Object? _read(String key) {
    final box = _box;
    if (box != null) {
      return box.get(key);
    }
    return _memory?[key];
  }

  Future<void> _write(
    String key,
    Object value, {
    bool recordModification = true,
  }) async {
    final values = <String, Object>{
      key: value,
      if (recordModification)
        '$_modifiedPrefix$key': DateTime.now().toUtc().toIso8601String(),
    };
    final box = _box;
    if (box != null) {
      await box.putAll(values);
    } else {
      _memory?.addAll(values);
    }
    if (key.startsWith('note:')) LocalSearchRevision.changed();
  }

  Future<void> _delete(String key, {bool recordModification = true}) async {
    final box = _box;
    if (box != null) {
      if (recordModification) {
        await box.put(
          '$_modifiedPrefix$key',
          DateTime.now().toUtc().toIso8601String(),
        );
      }
      await box.delete(key);
    } else {
      if (recordModification) {
        _memory?['$_modifiedPrefix$key'] = DateTime.now()
            .toUtc()
            .toIso8601String();
      }
      _memory?.remove(key);
    }
    if (key.startsWith('note:')) LocalSearchRevision.changed();
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
    LocalSearchRevision.changed();
  }

  static String _bookmarkKey(String itemKey) => 'bookmark:$itemKey';
  static String _noteKey(String itemKey) => 'note:$itemKey';
  static String _lastReadKey(String scopeKey) => 'last_read:$scopeKey';
}
