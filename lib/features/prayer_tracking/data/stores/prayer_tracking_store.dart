import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/prayer_tracking_models.dart';

class PrayerTrackingStore {
  PrayerTrackingStore._box(this._box) : _memory = null;

  PrayerTrackingStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'prayer_tracking';
  static const _prayersKey = 'prayer_records';
  static const _qadaPlanKey = 'qada_plan';
  static const _pauseRangesKey = 'pause_ranges';
  static const _fastsKey = 'fasting_records';

  static Future<PrayerTrackingStore> open() async {
    await Hive.initFlutter();
    return PrayerTrackingStore._box(await Hive.openBox<dynamic>(boxName));
  }

  List<PrayerTrackingRecord> get prayerRecords {
    final raw = _read(_prayersKey);
    return raw is List
        ? [
            for (final item in raw)
              if (item is Map) PrayerTrackingRecord.fromJson(item),
          ].where((item) => item.dateKey.isNotEmpty).toList(growable: false)
        : const [];
  }

  QadaPlan get qadaPlan {
    final raw = _read(_qadaPlanKey);
    return raw is Map ? QadaPlan.fromJson(raw) : QadaPlan.initial();
  }

  List<CyclePauseRange> get pauseRanges {
    final raw = _read(_pauseRangesKey);
    return raw is List
        ? [
            for (final item in raw)
              if (item is Map) CyclePauseRange.fromJson(item),
          ].where((item) => item.id.isNotEmpty).toList(growable: false)
        : const [];
  }

  List<FastingRecord> get fastingRecords {
    final raw = _read(_fastsKey);
    return raw is List
        ? [
            for (final item in raw)
              if (item is Map) FastingRecord.fromJson(item),
          ].where((item) => item.dateKey.isNotEmpty).toList(growable: false)
        : const [];
  }

  bool suppressesRemindersFor(String dateKey) {
    return pauseRanges.any(
      (range) => range.suppressReminders && range.contains(dateKey),
    );
  }

  Future<void> savePrayerRecords(List<PrayerTrackingRecord> records) {
    return _write(
      _prayersKey,
      records.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> saveQadaPlan(QadaPlan plan) =>
      _write(_qadaPlanKey, plan.toJson());

  Future<void> savePauseRanges(List<CyclePauseRange> ranges) {
    return _write(
      _pauseRangesKey,
      ranges.map((item) => item.toJson()).toList(growable: false),
    );
  }

  Future<void> saveFastingRecords(List<FastingRecord> records) {
    return _write(
      _fastsKey,
      records.map((item) => item.toJson()).toList(growable: false),
    );
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
    return _box?.keys.whereType<String>() ?? _memory?.keys ?? const [];
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
