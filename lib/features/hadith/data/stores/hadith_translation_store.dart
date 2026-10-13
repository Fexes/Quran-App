import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/search/local_search_revision.dart';

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

  bool hasFullBook({
    required String bookId,
    required String languageCode,
    Iterable<String>? requiredNumbers,
  }) {
    final raw = _read(_metaKey(bookId, languageCode));
    if (raw is! Map || raw['complete'] != true) {
      return false;
    }
    final numbers =
        requiredNumbers ??
        (raw['requiredNumbers'] as List?)?.cast<String>() ??
        const <String>[];
    if (numbers.isEmpty) return false;
    final items = translationsForBook(
      bookId: bookId,
      languageCode: languageCode,
    );
    return numbers.every((number) => items[number]?.trim().isNotEmpty == true);
  }

  bool hasDownloadedBook({
    required String bookId,
    required String languageCode,
  }) {
    final raw = _read(_metaKey(bookId, languageCode));
    final items = _read(_itemsKey(bookId, languageCode));
    if (raw is! Map ||
        items is! Map ||
        raw['sourceDownloadComplete'] != true ||
        items.isEmpty ||
        raw['sourceItemCount'] != items.length) {
      return false;
    }
    final numbers = raw['sourceNumbers'];
    return numbers is List &&
        numbers.length == items.length &&
        numbers.toSet().length == numbers.length &&
        numbers.every((number) => items[number] is String);
  }

  List<({String bookId, String languageCode, Map<String, String> translations})>
  cachedPacks() => [
    for (final key
        in (_box?.keys ?? _memory?.keys ?? const []).whereType<String>())
      if (key.startsWith('hadith_translation:') &&
          key.endsWith(':items') &&
          key.split(':').length == 4)
        (
          bookId: key.split(':')[1],
          languageCode: key.split(':')[2],
          translations: translationsForBook(
            bookId: key.split(':')[1],
            languageCode: key.split(':')[2],
          ),
        ),
  ];

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
    Iterable<String> requiredNumbers = const [],
    bool sourceDownloadComplete = false,
  }) async {
    await _write(_itemsKey(bookId, languageCode), translations);
    await _write(_metaKey(bookId, languageCode), {
      'bookId': bookId,
      'languageCode': languageCode,
      'editionName': editionName,
      'complete':
          requiredNumbers.isNotEmpty &&
          requiredNumbers.every(
            (number) => translations[number]?.trim().isNotEmpty == true,
          ),
      'requiredNumbers': requiredNumbers.toList(),
      'itemCount': translations.length,
      'sourceDownloadComplete':
          sourceDownloadComplete && translations.isNotEmpty,
      'sourceItemCount': translations.length,
      'sourceNumbers': sourceDownloadComplete
          ? translations.keys.toList()
          : const <String>[],
      'completedAt': DateTime.now().toIso8601String(),
    });
    LocalSearchRevision.changed();
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
