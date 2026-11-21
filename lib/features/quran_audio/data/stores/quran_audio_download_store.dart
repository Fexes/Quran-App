import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/search/local_search_revision.dart';

import '../../domain/entities/quran_audio_download_item.dart';

class QuranAudioDownloadStore {
  QuranAudioDownloadStore._box(this._box) : _memory = null;

  QuranAudioDownloadStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'quran_audio_downloads';

  Map<String, Object?> searchSnapshot() => {
    for (final raw in _values())
      if (raw is Map && raw['id'] is String)
        raw['id'] as String: {
          for (final key in const [
            'id',
            'reciterId',
            'reciterName',
            'verseKey',
            'surahNumber',
            'ayahNumber',
            'remoteUrl',
            'status',
          ])
            key: raw[key],
        },
  };

  static Future<QuranAudioDownloadStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return QuranAudioDownloadStore._box(box);
  }

  QuranAudioDownloadItem? itemById(String id) {
    final raw = _read(id);
    return _parse(raw);
  }

  List<QuranAudioDownloadItem> get allItems {
    final items = <QuranAudioDownloadItem>[];
    for (final value in _values()) {
      final item = _parse(value);
      if (item != null) {
        items.add(item);
      }
    }
    return items..sort((a, b) {
      final surah = a.surahNumber.compareTo(b.surahNumber);
      if (surah != 0) {
        return surah;
      }
      final ayah = a.ayahNumber.compareTo(b.ayahNumber);
      if (ayah != 0) {
        return ayah;
      }
      return a.reciterName.compareTo(b.reciterName);
    });
  }

  List<QuranAudioDownloadItem> itemsForReciter(String reciterId) {
    return allItems
        .where((item) => item.reciterId == reciterId)
        .toList(growable: false);
  }

  List<QuranAudioDownloadItem> itemsForSurah({
    required String reciterId,
    required int surahNumber,
  }) {
    return allItems
        .where(
          (item) =>
              item.reciterId == reciterId && item.surahNumber == surahNumber,
        )
        .toList(growable: false);
  }

  List<QuranAudioDownloadItem> activeItems() {
    return allItems.where((item) => item.isActive).toList(growable: false);
  }

  Future<void> saveItem(QuranAudioDownloadItem item) async {
    final previous = itemById(item.id);
    await _write(item.id, item.toJson());
    if (previous?.status != item.status ||
        previous?.reciterName != item.reciterName) {
      LocalSearchRevision.changed(source: 'audio');
    }
  }

  Future<void> saveItems(Iterable<QuranAudioDownloadItem> items) async {
    for (final item in items) {
      await saveItem(item);
    }
  }

  Future<void> deleteItems(Iterable<String> ids) async {
    for (final id in ids) {
      await _delete(id);
    }
    LocalSearchRevision.changed(source: 'audio');
  }

  Future<void> clear() async {
    final box = _box;
    if (box != null) {
      await box.clear();
    } else {
      _memory?.clear();
    }
    LocalSearchRevision.changed(source: 'audio');
  }

  Object? _read(String key) {
    final box = _box;
    if (box != null) {
      return box.get(key);
    }
    return _memory?[key];
  }

  Iterable<Object?> _values() {
    final box = _box;
    if (box != null) {
      return box.values;
    }
    return _memory?.values ?? const [];
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

  QuranAudioDownloadItem? _parse(Object? raw) {
    if (raw is Map) {
      final item = QuranAudioDownloadItem.fromJson(raw);
      if (item.id.isNotEmpty &&
          item.reciterId.isNotEmpty &&
          item.remoteUrl.isNotEmpty) {
        return item;
      }
    }
    return null;
  }
}
