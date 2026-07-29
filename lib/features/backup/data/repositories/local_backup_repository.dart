import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../hifz/data/stores/hifz_store.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../quran/data/stores/quran_user_data_store.dart';
import '../../../prayer_tracking/data/stores/prayer_tracking_store.dart';
import '../../../reading_goals/data/stores/reading_progress_store.dart';
import '../../domain/entities/backup_models.dart';
import '../../domain/repositories/backup_repository.dart';

class LocalBackupRepository implements BackupRepository {
  const LocalBackupRepository({
    required SettingsStore settingsStore,
    required QuranUserDataStore quranUserDataStore,
    required ReadingProgressStore readingProgressStore,
    required HifzStore hifzStore,
    required PrayerTrackingStore prayerTrackingStore,
    required LibraryUserDataStore libraryUserDataStore,
  }) : _settingsStore = settingsStore,
       _quranUserDataStore = quranUserDataStore,
       _readingProgressStore = readingProgressStore,
       _hifzStore = hifzStore,
       _prayerTrackingStore = prayerTrackingStore,
       _libraryUserDataStore = libraryUserDataStore;

  static const schemaVersion = 1;
  static const _format = 'quran-local-backup';
  static const _iterations = 100000;

  final SettingsStore _settingsStore;
  final QuranUserDataStore _quranUserDataStore;
  final ReadingProgressStore _readingProgressStore;
  final HifzStore _hifzStore;
  final PrayerTrackingStore _prayerTrackingStore;
  final LibraryUserDataStore _libraryUserDataStore;

  @override
  Future<Uint8List> createEncryptedBackup(String password) async {
    _validatePassword(password);
    final payload = <String, Object?>{
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'categories': {
        'settings': _jsonSafe(_settingsStore.exportSnapshot()),
        'quranUserData': _jsonSafe(_quranUserDataStore.exportSnapshot()),
        'reading': _jsonSafe(_readingProgressStore.exportSnapshot()),
        'hifz': _jsonSafe(_hifzStore.exportSnapshot()),
        'worship': _jsonSafe(_prayerTrackingStore.exportSnapshot()),
        'library': _jsonSafe(_libraryUserDataStore.exportSnapshot()),
      },
    };
    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final salt = _randomBytes(16);
    final iv = _randomBytes(12);
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm),
    );
    final encrypted = encrypter.encryptBytes(plaintext, iv: encrypt.IV(iv));
    final envelope = {
      'format': _format,
      'schemaVersion': schemaVersion,
      'encryption': {
        'algorithm': 'AES-256-GCM',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
        'iv': base64Encode(iv),
      },
      'payload': base64Encode(encrypted.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  @override
  Future<BackupPreview> inspectEncryptedBackup(
    Uint8List bytes,
    String password,
  ) async {
    final payload = _decrypt(bytes, password);
    final categories = _categories(payload);
    return BackupPreview(
      schemaVersion: _int(payload['schemaVersion']),
      createdAt:
          DateTime.tryParse(payload['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      categoryCounts: {
        for (final category in BackupDataCategory.values)
          category: _entryCount(categories[category.name]),
      },
    );
  }

  @override
  Future<BackupRestoreResult> restoreEncryptedBackup({
    required Uint8List bytes,
    required String password,
    required BackupRestoreMode mode,
  }) async {
    final payload = _decrypt(bytes, password);
    final categories = _categories(payload);
    final replace = mode == BackupRestoreMode.replace;
    final restored = <BackupDataCategory>[];

    final settings = _stringMap(categories['settings']);
    if (settings != null) {
      await _settingsStore.restoreSnapshot(
        replace ? settings : {..._settingsStore.exportSnapshot(), ...settings},
        replace: replace,
      );
      restored.add(BackupDataCategory.settings);
    }

    final quran = _stringMap(categories['quranUserData']);
    if (quran != null) {
      await _quranUserDataStore.restoreSnapshot(
        replace
            ? quran
            : _mergeQuran(_quranUserDataStore.exportSnapshot(), quran),
        replace: replace,
      );
      restored.add(BackupDataCategory.quranUserData);
    }

    final reading = _stringMap(categories['reading']);
    if (reading != null) {
      await _readingProgressStore.restoreSnapshot(
        replace
            ? reading
            : _mergeReading(_readingProgressStore.exportSnapshot(), reading),
        replace: replace,
      );
      restored.add(BackupDataCategory.reading);
    }

    final hifz = _stringMap(categories['hifz']);
    if (hifz != null) {
      await _hifzStore.restoreSnapshot(
        replace ? hifz : _mergeHifz(_hifzStore.exportSnapshot(), hifz),
        replace: replace,
      );
      restored.add(BackupDataCategory.hifz);
    }

    final library = _stringMap(categories['library']);
    if (library != null) {
      await _libraryUserDataStore.restoreSnapshot(
        replace
            ? library
            : {..._libraryUserDataStore.exportSnapshot(), ...library},
        replace: replace,
      );
      restored.add(BackupDataCategory.library);
    }

    final worship = _stringMap(categories['worship']);
    if (worship != null) {
      await _prayerTrackingStore.restoreSnapshot(
        replace
            ? worship
            : _mergeWorship(_prayerTrackingStore.exportSnapshot(), worship),
        replace: replace,
      );
      restored.add(BackupDataCategory.worship);
    }
    return BackupRestoreResult(mode: mode, restoredCategories: restored);
  }

  @override
  Future<void> eraseCategory(BackupDataCategory category) {
    return switch (category) {
      BackupDataCategory.settings => _settingsStore.clearAll(),
      BackupDataCategory.quranUserData => _quranUserDataStore.clearAll(),
      BackupDataCategory.reading => _readingProgressStore.clearAll(),
      BackupDataCategory.hifz => _hifzStore.clearAll(),
      BackupDataCategory.worship => _prayerTrackingStore.clearAll(),
      BackupDataCategory.library => _libraryUserDataStore.clearAll(),
    };
  }

  @override
  Future<void> eraseAllUserData() async {
    await _quranUserDataStore.clearAll();
    await _readingProgressStore.clearAll();
    await _hifzStore.clearAll();
    await _prayerTrackingStore.clearAll();
    await _libraryUserDataStore.clearAll();
    await _settingsStore.clearAll();
    await _settingsStore.setOnboardingStep(0);
  }

  Map<String, Object?> _decrypt(Uint8List bytes, String password) {
    _validatePassword(password);
    final envelopeRaw = jsonDecode(utf8.decode(bytes));
    if (envelopeRaw is! Map || envelopeRaw['format'] != _format) {
      throw const FormatException('Not a Quran backup file.');
    }
    final encryption = envelopeRaw['encryption'];
    if (encryption is! Map ||
        encryption['algorithm'] != 'AES-256-GCM' ||
        encryption['kdf'] != 'PBKDF2-HMAC-SHA256') {
      throw const FormatException('Unsupported backup encryption.');
    }
    final iterations = _int(encryption['iterations']);
    if (iterations != _iterations) {
      throw const FormatException('Unsupported backup key settings.');
    }
    final version = _int(envelopeRaw['schemaVersion']);
    if (version <= 0 || version > schemaVersion) {
      throw const FormatException('Unsupported backup version.');
    }
    final salt = base64Decode(encryption['salt'] as String? ?? '');
    final iv = base64Decode(encryption['iv'] as String? ?? '');
    final cipherText = base64Decode(envelopeRaw['payload'] as String? ?? '');
    final key = _deriveKey(password, salt);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.gcm),
    );
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(cipherText),
      iv: encrypt.IV(iv),
    );
    final payloadRaw = jsonDecode(utf8.decode(decrypted));
    if (payloadRaw is! Map) {
      throw const FormatException('Invalid backup payload.');
    }
    final payload = _stringMap(payloadRaw);
    if (payload == null || _int(payload['schemaVersion']) > schemaVersion) {
      throw const FormatException('Unsupported backup payload.');
    }
    return payload;
  }

  Map<String, Object?> _categories(Map<String, Object?> payload) {
    return _stringMap(payload['categories']) ?? const {};
  }

  Map<String, Object?> _mergeQuran(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final result = {...current, ...incoming};
    result['bookmark_entries'] = _mergeListByKey(
      current['bookmark_entries'],
      incoming['bookmark_entries'],
      (item) => '${item['surahNumber']}:${item['ayahNumber']}',
      timestampKey: 'createdAt',
      preferNewest: false,
    );
    result['bookmark_collections'] = _mergeListByKey(
      current['bookmark_collections'],
      incoming['bookmark_collections'],
      (item) => item['id']?.toString() ?? '',
      timestampKey: 'createdAt',
      preferNewest: true,
    );
    result['notes'] = _mergeListByKey(
      current['notes'],
      incoming['notes'],
      (item) => item['id']?.toString() ?? '',
      timestampKey: 'updatedAt',
      preferNewest: true,
    );
    final currentLast = _date(current['last_read_updated_at']);
    final incomingLast = _date(incoming['last_read_updated_at']);
    if (currentLast != null &&
        (incomingLast == null || currentLast.isAfter(incomingLast))) {
      for (final key in const [
        'last_read_surah',
        'last_read_ayah',
        'last_read_updated_at',
        'last_read_page',
        'last_navigation_kind',
        'last_navigation_index',
        'last_navigation_page',
      ]) {
        result[key] = current[key];
      }
    }
    return result;
  }

  Map<String, Object?> _mergeReading(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final result = {...current, ...incoming};
    final currentDays = _stringMap(current['daily_progress']) ?? const {};
    final incomingDays = _stringMap(incoming['daily_progress']) ?? const {};
    final mergedDays = <String, Object?>{...currentDays};
    for (final entry in incomingDays.entries) {
      final oldDay = _stringMap(mergedDays[entry.key]);
      final newDay = _stringMap(entry.value);
      if (oldDay == null || newDay == null) {
        mergedDays[entry.key] = entry.value;
        continue;
      }
      mergedDays[entry.key] = {
        ...oldDay,
        ...newDay,
        'verseKeys': {
          ..._stringList(oldDay['verseKeys']),
          ..._stringList(newDay['verseKeys']),
        }.toList(),
        'pages': {
          ..._intList(oldDay['pages']),
          ..._intList(newDay['pages']),
        }.toList(),
        'minutes': max(_int(oldDay['minutes']), _int(newDay['minutes'])),
      };
    }
    result['daily_progress'] = mergedDays;
    result['reading_plans'] = _mergeListByKey(
      current['reading_plans'],
      incoming['reading_plans'],
      (item) => item['id']?.toString() ?? '',
      timestampKey: 'updatedAt',
      preferNewest: true,
    );
    result['active_khatma'] = _newerMap(
      current['active_khatma'],
      incoming['active_khatma'],
      'updatedAt',
    );
    return result;
  }

  Map<String, Object?> _mergeHifz(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final result = {...current, ...incoming};
    result['collections'] = _mergeListByKey(
      current['collections'],
      incoming['collections'],
      (item) => item['id']?.toString() ?? '',
      timestampKey: 'updatedAt',
      preferNewest: true,
    );
    final currentCards = _stringMap(current['cards']) ?? const {};
    final incomingCards = _stringMap(incoming['cards']) ?? const {};
    result['cards'] = {
      ...currentCards,
      for (final entry in incomingCards.entries)
        entry.key: _newerMap(
          currentCards[entry.key],
          entry.value,
          'lastReviewedAt',
        ),
    };
    return result;
  }

  Map<String, Object?> _mergeWorship(
    Map<String, Object?> current,
    Map<String, Object?> incoming,
  ) {
    final result = {...current, ...incoming};
    for (final key in const [
      'prayer_records',
      'pause_ranges',
      'fasting_records',
    ]) {
      result[key] = _mergeListByKey(
        current[key],
        incoming[key],
        (item) => item['id']?.toString() ?? '',
        timestampKey: 'updatedAt',
        preferNewest: true,
      );
    }
    result['qada_plan'] = _newerMap(
      current['qada_plan'],
      incoming['qada_plan'],
      'updatedAt',
    );
    return result;
  }

  List<Object?> _mergeListByKey(
    Object? current,
    Object? incoming,
    String Function(Map<String, Object?> item) keyFor, {
    required String timestampKey,
    required bool preferNewest,
  }) {
    final merged = <String, Map<String, Object?>>{};
    for (final raw in [..._mapList(current), ..._mapList(incoming)]) {
      final key = keyFor(raw);
      if (key.isEmpty) {
        continue;
      }
      final existing = merged[key];
      if (existing == null) {
        merged[key] = raw;
        continue;
      }
      final oldDate = _date(existing[timestampKey]);
      final newDate = _date(raw[timestampKey]);
      final useNew = preferNewest
          ? oldDate == null || (newDate?.isAfter(oldDate) ?? false)
          : oldDate == null || (newDate?.isBefore(oldDate) ?? false);
      if (useNew) {
        merged[key] = raw;
      }
    }
    return merged.values.toList(growable: false);
  }

  Object? _newerMap(Object? current, Object? incoming, String timestampKey) {
    final oldMap = _stringMap(current);
    final newMap = _stringMap(incoming);
    if (oldMap == null) {
      return incoming;
    }
    if (newMap == null) {
      return current;
    }
    final oldDate = _date(oldMap[timestampKey]);
    final newDate = _date(newMap[timestampKey]);
    return oldDate != null && (newDate == null || oldDate.isAfter(newDate))
        ? current
        : incoming;
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const FormatException('Backup password must have 8 characters.');
    }
  }

  Object? _jsonSafe(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value;
  }

  Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (_stringMap(item) != null) _stringMap(item)!,
    ];
  }

  List<String> _stringList(Object? value) {
    return value is List ? value.whereType<String>().toList() : const [];
  }

  List<int> _intList(Object? value) {
    return value is List
        ? value.map(_int).where((item) => item > 0).toList()
        : const [];
  }

  int _entryCount(Object? value) {
    if (value is Map) {
      return value.length;
    }
    if (value is List) {
      return value.length;
    }
    return value == null ? 0 : 1;
  }

  int _int(Object? value) {
    return value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
