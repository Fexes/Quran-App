import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/quran_note.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/entities/quran_reading_mode.dart';

class QuranUserDataStore {
  QuranUserDataStore._box(this._box) : _memory = null;

  QuranUserDataStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;
  final _lastReadChanges = ValueNotifier(0);

  Listenable get lastReadChanges => _lastReadChanges;

  static const boxName = 'quran_user_data';
  static const _lastReadSurahKey = 'last_read_surah';
  static const _lastReadAyahKey = 'last_read_ayah';
  static const _lastReadUpdatedAtKey = 'last_read_updated_at';
  static const _lastReadPageKey = 'last_read_page';
  static const _lastNavigationKindKey = 'last_navigation_kind';
  static const _lastNavigationIndexKey = 'last_navigation_index';
  static const _lastNavigationPageKey = 'last_navigation_page';
  static const _bookmarksKey = 'bookmarks';
  static const _bookmarkEntriesKey = 'bookmark_entries';
  static const _bookmarkCollectionsKey = 'bookmark_collections';
  static const _audioReciterIdKey = 'audio_reciter_id';
  static const _ayahTextLayoutKey = 'ayah_text_layout';
  static const _notesKey = 'notes';

  static Future<QuranUserDataStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranUserDataStore._box(box);
  }

  int? get lastReadSurah => _readInt(_lastReadSurahKey);
  int? get lastReadAyah => _readInt(_lastReadAyahKey);
  int? get lastReadPage => _readInt(_lastReadPageKey);
  String? get lastNavigationKind => _read(_lastNavigationKindKey) as String?;
  int? get lastNavigationIndex => _readInt(_lastNavigationIndexKey);
  int? get lastNavigationPage => _readInt(_lastNavigationPageKey);

  DateTime? get lastReadUpdatedAt {
    final raw = _read(_lastReadUpdatedAtKey);
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  List<String> get bookmarks {
    return bookmarkEntries.map((item) => item.verseKey).toList(growable: false);
  }

  List<QuranBookmark> get bookmarkEntries {
    final detailed = _read(_bookmarkEntriesKey);
    if (detailed is List) {
      return [
        for (final item in detailed)
          if (item is Map && _parseBookmark(item) != null)
            _parseBookmark(item)!,
      ];
    }
    final legacy = _read(_bookmarksKey);
    if (legacy is! List) {
      return const [];
    }
    return [
      for (final key in legacy.whereType<String>())
        if (_bookmarkFromLegacyKey(key) != null) _bookmarkFromLegacyKey(key)!,
    ];
  }

  List<QuranBookmarkCollection> get bookmarkCollections {
    final raw = _read(_bookmarkCollectionsKey);
    final parsed = raw is List
        ? [
            for (final item in raw)
              if (item is Map) QuranBookmarkCollection.fromJson(item),
          ]
        : <QuranBookmarkCollection>[];
    if (!parsed.any((item) => item.id == QuranBookmarkCollection.defaultId)) {
      parsed.insert(0, _defaultBookmarkCollection());
    }
    return parsed;
  }

  List<QuranNote> get notes {
    final raw = _read(_notesKey);
    if (raw is! List) {
      return const [];
    }
    final parsed = <QuranNote>[];
    for (final item in raw) {
      final note = _parseNote(item);
      if (note != null) {
        parsed.add(note);
      }
    }
    parsed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return parsed;
  }

  String? get audioReciterId {
    final raw = _read(_audioReciterIdKey);
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    return null;
  }

  QuranAyahTextLayout get ayahTextLayout {
    final raw = _read(_ayahTextLayoutKey);
    if (raw == 'book') {
      return QuranAyahTextLayout.combined;
    }
    return _readEnum(
      _ayahTextLayoutKey,
      QuranAyahTextLayout.values,
      QuranAyahTextLayout.separated,
    );
  }

  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
    required DateTime updatedAt,
    int? page,
  }) async {
    final values = <String, Object>{
      _lastReadSurahKey: surahNumber,
      _lastReadAyahKey: ayahNumber,
      _lastReadUpdatedAtKey: updatedAt.toIso8601String(),
      if (page != null) _lastReadPageKey: page.clamp(1, 604),
    };
    if (_box != null) {
      await _box.putAll(values);
    } else {
      _memory?.addAll(values);
    }
    _lastReadChanges.value++;
  }

  Future<void> saveNavigationContext({
    required String kind,
    required int index,
    required int page,
  }) async {
    await _write(_lastNavigationKindKey, kind);
    await _write(_lastNavigationIndexKey, index);
    await _write(_lastNavigationPageKey, page.clamp(1, 604));
  }

  Future<void> setBookmarks(List<String> verseKeys) async {
    final normalized = <String>[];
    final seen = <String>{};
    for (final key in verseKeys) {
      final trimmed = key.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      normalized.add(trimmed);
    }
    final existing = {for (final item in bookmarkEntries) item.verseKey: item};
    await setBookmarkEntries([
      for (final key in normalized)
        existing[key] ?? _bookmarkFromLegacyKey(key)!,
    ]);
  }

  Future<void> setBookmarkEntries(List<QuranBookmark> bookmarks) async {
    await _write(
      _bookmarkEntriesKey,
      bookmarks.map(_bookmarkToMap).toList(growable: false),
    );
    await _write(
      _bookmarksKey,
      bookmarks.map((item) => item.verseKey).toList(growable: false),
    );
  }

  Future<void> setBookmarkCollections(
    List<QuranBookmarkCollection> collections,
  ) {
    return _write(
      _bookmarkCollectionsKey,
      collections.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> setAudioReciterId(String reciterId) async {
    final normalized = reciterId.trim();
    if (normalized.isEmpty) {
      return;
    }
    await _write(_audioReciterIdKey, normalized);
  }

  Future<void> setAyahTextLayout(QuranAyahTextLayout layout) {
    return _write(_ayahTextLayoutKey, layout.name);
  }

  Future<QuranNote> saveNote({
    String? id,
    required String text,
    String? verseKey,
    int? translationResourceId,
    DateTime? now,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Note text cannot be empty.');
    }
    final timestamp = now ?? DateTime.now();
    final current = notes;
    QuranNote? existing;
    if (id != null) {
      for (final note in current) {
        if (note.id == id) {
          existing = note;
          break;
        }
      }
    }
    final note = QuranNote(
      id: existing?.id ?? timestamp.microsecondsSinceEpoch.toString(),
      text: trimmed,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      verseKey: verseKey ?? existing?.verseKey,
      translationResourceId:
          translationResourceId ?? existing?.translationResourceId,
    );
    final next = [
      note,
      for (final item in current)
        if (item.id != note.id) item,
    ];
    await _write(_notesKey, next.map(_noteToMap).toList(growable: false));
    return note;
  }

  Future<void> deleteNote(String id) async {
    final next = notes.where((note) => note.id != id).toList(growable: false);
    await _write(_notesKey, next.map(_noteToMap).toList(growable: false));
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
    _lastReadChanges.value++;
  }

  Future<void> clearAll() async {
    await _clear();
    _lastReadChanges.value++;
  }

  T _readEnum<T extends Enum>(String key, List<T> values, T fallback) {
    final raw = _read(key);
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) {
          return value;
        }
      }
    }
    return fallback;
  }

  int? _readInt(String key) {
    final raw = _read(key);
    if (raw is int) {
      return raw;
    }
    return null;
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

  QuranNote? _parseNote(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final id = raw['id'];
    final text = raw['text'];
    final createdAt = raw['createdAt'];
    final updatedAt = raw['updatedAt'];
    if (id is! String || text is! String) {
      return null;
    }
    final created = createdAt is String ? DateTime.tryParse(createdAt) : null;
    final updated = updatedAt is String ? DateTime.tryParse(updatedAt) : null;
    if (created == null || updated == null || text.trim().isEmpty) {
      return null;
    }
    return QuranNote(
      id: id,
      text: text.trim(),
      createdAt: created,
      updatedAt: updated,
      verseKey: raw['verseKey'] as String?,
      translationResourceId: raw['translationResourceId'] as int?,
    );
  }

  Map<String, Object> _noteToMap(QuranNote note) {
    return {
      'id': note.id,
      'text': note.text,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      if (note.verseKey != null) 'verseKey': note.verseKey!,
      if (note.translationResourceId != null)
        'translationResourceId': note.translationResourceId!,
    };
  }

  QuranBookmark? _parseBookmark(Map<dynamic, dynamic> raw) {
    final surah = raw['surahNumber'];
    final ayah = raw['ayahNumber'];
    if (surah is! int || ayah is! int) {
      return null;
    }
    return QuranBookmark(
      surahNumber: surah,
      ayahNumber: ayah,
      createdAt:
          DateTime.tryParse(raw['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      collectionId:
          raw['collectionId'] as String? ?? QuranBookmarkCollection.defaultId,
    );
  }

  QuranBookmark? _bookmarkFromLegacyKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) {
      return null;
    }
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) {
      return null;
    }
    return QuranBookmark(
      surahNumber: surah,
      ayahNumber: ayah,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object> _bookmarkToMap(QuranBookmark bookmark) {
    return {
      'surahNumber': bookmark.surahNumber,
      'ayahNumber': bookmark.ayahNumber,
      'createdAt': bookmark.createdAt.toIso8601String(),
      'collectionId': bookmark.collectionId,
    };
  }

  QuranBookmarkCollection _defaultBookmarkCollection() {
    return QuranBookmarkCollection(
      id: QuranBookmarkCollection.defaultId,
      name: 'Saved ayahs',
      description: 'Bookmarks migrated from the reader',
      colorValue: 0xFF2E7D5B,
      iconCodePoint: 0xe0bb,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
