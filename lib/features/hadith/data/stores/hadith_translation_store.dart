import 'package:hive_flutter/hive_flutter.dart';

class HadithTranslationStore {
  HadithTranslationStore._box(this._box) : _memory = null;

  HadithTranslationStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'hadith_translations';

  static Future<HadithTranslationStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return HadithTranslationStore._box(box);
  }

  bool hasFullBook({required String bookId, required String languageCode}) {
    final raw = _read(_metaKey(bookId, languageCode));
    if (raw is! Map || raw['complete'] != true) {
      return false;
    }
    final itemCount = raw['itemCount'];
    return itemCount is int && itemCount > 0;
  }

  String? translationFor({
    required String bookId,
    required String languageCode,
    required String hadithNumber,
  }) {
    final translations = _read(_itemsKey(bookId, languageCode));
    return translations is Map ? translations[hadithNumber]?.toString() : null;
  }

  Map<String, String> translationsForBook({
    required String bookId,
    required String languageCode,
  }) {
    final raw = _read(_itemsKey(bookId, languageCode));
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value?.toString() ?? '',
    };
  }

  Future<void> saveBookTranslations({
    required String bookId,
    required String languageCode,
    required String editionName,
    required Map<String, String> translations,
  }) async {
    await _write(_itemsKey(bookId, languageCode), translations);
    await _write(_metaKey(bookId, languageCode), {
      'bookId': bookId,
      'languageCode': languageCode,
      'editionName': editionName,
      'complete': translations.isNotEmpty,
      'itemCount': translations.length,
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

  static String _itemsKey(String bookId, String languageCode) =>
      'hadith_translation:$bookId:$languageCode:items';

  static String _metaKey(String bookId, String languageCode) =>
      'hadith_translation:$bookId:$languageCode:meta';
}
