import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/reading_progress.dart';

class ReadingProgressStore {
  ReadingProgressStore._box(this._box) : _memory = null;

  ReadingProgressStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {});

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;

  static const boxName = 'reading_progress';
  static const _goalKey = 'daily_goal';
  static const _daysKey = 'daily_progress';
  static const _khatmaKey = 'active_khatma';
  static const _plansKey = 'reading_plans';

  static Future<ReadingProgressStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    return ReadingProgressStore._box(box);
  }

  ReadingGoal get goal {
    final raw = _read(_goalKey);
    return raw is Map
        ? ReadingGoal.fromJson(raw)
        : const ReadingGoal(metric: ReadingGoalMetric.pages, dailyTarget: 2);
  }

  Map<String, DailyReadingProgress> get days {
    final raw = _read(_daysKey);
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is Map)
          entry.key as String: DailyReadingProgress.fromJson(
            entry.value as Map,
          ),
    };
  }

  KhatmaPlan? get khatma {
    final raw = _read(_khatmaKey);
    if (raw is! Map) {
      return null;
    }
    final plan = KhatmaPlan.fromJson(raw);
    return plan.id.isEmpty ? null : plan;
  }

  List<ReadingPlan> get plans {
    final raw = _read(_plansKey);
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map) ReadingPlan.fromJson(item),
    ].where((item) => item.id.isNotEmpty).toList(growable: false);
  }

  Future<void> saveGoal(ReadingGoal goal) => _write(_goalKey, goal.toJson());

  Future<void> saveDay(DailyReadingProgress progress) async {
    final next = {
      for (final entry in days.entries) entry.key: entry.value.toJson(),
      progress.dateKey: progress.toJson(),
    };
    await _write(_daysKey, next);
  }

  Future<void> saveKhatma(KhatmaPlan? plan) async {
    if (plan == null) {
      await _delete(_khatmaKey);
      return;
    }
    await _write(_khatmaKey, plan.toJson());
  }

  Future<void> savePlans(List<ReadingPlan> plans) {
    return _write(
      _plansKey,
      plans.map((item) => item.toJson()).toList(growable: false),
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

  Object? _read(String key) {
    return _box?.get(key) ?? _memory?[key];
  }

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) {
      await box.put(key, value);
    } else {
      _memory?[key] = value;
    }
  }

  Future<void> _delete(String key) async {
    final box = _box;
    if (box != null) {
      await box.delete(key);
    } else {
      _memory?.remove(key);
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
