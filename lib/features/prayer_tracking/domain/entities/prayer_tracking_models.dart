import 'package:equatable/equatable.dart';

enum TrackedPrayer { fajr, dhuhr, asr, maghrib, isha }

enum PrayerCompletion { unrecorded, onTime, late, missed, qada, exempt }

enum FastType { ramadan, voluntary, makeup }

enum FastStatus { completed, missed, exempt }

class PrayerTrackingRecord extends Equatable {
  const PrayerTrackingRecord({
    required this.dateKey,
    required this.prayer,
    required this.status,
    required this.congregation,
    required this.updatedAt,
    DateTime? statusChangedAt,
    DateTime? debtCreatedAt,
  }) : statusChangedAt = statusChangedAt ?? updatedAt,
       debtCreatedAt =
           debtCreatedAt ??
           (status == PrayerCompletion.missed ? updatedAt : null);

  factory PrayerTrackingRecord.fromJson(Map<dynamic, dynamic> json) {
    return PrayerTrackingRecord(
      dateKey: json['dateKey'] as String? ?? '',
      prayer: TrackedPrayer.values.firstWhere(
        (item) => item.name == json['prayer'],
        orElse: () => TrackedPrayer.fajr,
      ),
      status: PrayerCompletion.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => PrayerCompletion.unrecorded,
      ),
      congregation: json['congregation'] as bool? ?? false,
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      statusChangedAt:
          _date(json['statusChangedAt']) ?? _date(json['updatedAt']),
      debtCreatedAt: _date(json['debtCreatedAt']),
    );
  }

  final String dateKey;
  final TrackedPrayer prayer;
  final PrayerCompletion status;
  final bool congregation;
  final DateTime updatedAt;
  final DateTime statusChangedAt;
  final DateTime? debtCreatedAt;

  String get id => '$dateKey:${prayer.name}';

  Map<String, Object> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'prayer': prayer.name,
      'status': status.name,
      'congregation': congregation,
      'updatedAt': updatedAt.toIso8601String(),
      'statusChangedAt': statusChangedAt.toIso8601String(),
      if (debtCreatedAt != null)
        'debtCreatedAt': debtCreatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    dateKey,
    prayer,
    status,
    congregation,
    updatedAt,
    statusChangedAt,
    debtCreatedAt,
  ];
}

class QadaPlan extends Equatable {
  const QadaPlan({
    required this.baselineDue,
    required this.baselineAt,
    required this.dailyTarget,
    required this.enabled,
    required this.updatedAt,
  });

  factory QadaPlan.initial() {
    final now = DateTime.now();
    return QadaPlan(
      baselineDue: 0,
      baselineAt: DateTime.fromMillisecondsSinceEpoch(0),
      dailyTarget: 1,
      enabled: false,
      updatedAt: now,
    );
  }

  factory QadaPlan.fromJson(Map<dynamic, dynamic> json) {
    final now = DateTime.now();
    return QadaPlan(
      baselineDue: _int(json['baselineDue']).clamp(0, 1000000),
      baselineAt: _date(json['baselineAt']) ?? now,
      dailyTarget: _int(json['dailyTarget']).clamp(1, 100),
      enabled: json['enabled'] as bool? ?? false,
      updatedAt: _date(json['updatedAt']) ?? now,
    );
  }

  final int baselineDue;
  final DateTime baselineAt;
  final int dailyTarget;
  final bool enabled;
  final DateTime updatedAt;

  Map<String, Object> toJson() {
    return {
      'baselineDue': baselineDue,
      'baselineAt': baselineAt.toIso8601String(),
      'dailyTarget': dailyTarget,
      'enabled': enabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    baselineDue,
    baselineAt,
    dailyTarget,
    enabled,
    updatedAt,
  ];
}

class CyclePauseRange extends Equatable {
  const CyclePauseRange({
    required this.id,
    required this.startDateKey,
    required this.endDateKey,
    required this.suppressReminders,
    required this.exemptTracking,
    required this.updatedAt,
  });

  factory CyclePauseRange.fromJson(Map<dynamic, dynamic> json) {
    return CyclePauseRange(
      id: json['id'] as String? ?? '',
      startDateKey: json['startDateKey'] as String? ?? '',
      endDateKey: json['endDateKey'] as String? ?? '',
      suppressReminders: json['suppressReminders'] as bool? ?? true,
      exemptTracking: json['exemptTracking'] as bool? ?? true,
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final String startDateKey;
  final String endDateKey;
  final bool suppressReminders;
  final bool exemptTracking;
  final DateTime updatedAt;

  bool contains(String dateKey) {
    return dateKey.compareTo(startDateKey) >= 0 &&
        dateKey.compareTo(endDateKey) <= 0;
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'startDateKey': startDateKey,
      'endDateKey': endDateKey,
      'suppressReminders': suppressReminders,
      'exemptTracking': exemptTracking,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    startDateKey,
    endDateKey,
    suppressReminders,
    exemptTracking,
    updatedAt,
  ];
}

class FastingRecord extends Equatable {
  const FastingRecord({
    required this.dateKey,
    required this.type,
    required this.status,
    required this.updatedAt,
  });

  factory FastingRecord.fromJson(Map<dynamic, dynamic> json) {
    return FastingRecord(
      dateKey: json['dateKey'] as String? ?? '',
      type: FastType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => FastType.ramadan,
      ),
      status: FastStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => FastStatus.completed,
      ),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }

  final String dateKey;
  final FastType type;
  final FastStatus status;
  final DateTime updatedAt;

  String get id => dateKey;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'type': type.name,
      'status': status.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [dateKey, type, status, updatedAt];
}

class WorshipPeriodSummary extends Equatable {
  const WorshipPeriodSummary({
    required this.prayersCompleted,
    required this.prayersMissed,
    required this.prayersExempt,
    required this.congregational,
    required this.fastsCompleted,
    required this.fastsMissed,
  });

  final int prayersCompleted;
  final int prayersMissed;
  final int prayersExempt;
  final int congregational;
  final int fastsCompleted;
  final int fastsMissed;

  @override
  List<Object> get props => [
    prayersCompleted,
    prayersMissed,
    prayersExempt,
    congregational,
    fastsCompleted,
    fastsMissed,
  ];
}

class PrayerTrackingDashboard extends Equatable {
  const PrayerTrackingDashboard({
    required this.dateKey,
    required this.dayRecords,
    required this.qadaPlan,
    required this.qadaDue,
    required this.pauseRanges,
    required this.activePause,
    required this.fast,
    required this.missedRamadanFasts,
    required this.makeupFasts,
    required this.week,
    required this.month,
    this.prayerStreak = 0,
  });

  final String dateKey;
  final Map<TrackedPrayer, PrayerTrackingRecord> dayRecords;
  final QadaPlan qadaPlan;
  final int qadaDue;
  final List<CyclePauseRange> pauseRanges;
  final CyclePauseRange? activePause;
  final FastingRecord? fast;
  final int missedRamadanFasts;
  final int makeupFasts;
  final WorshipPeriodSummary week;
  final WorshipPeriodSummary month;
  final int prayerStreak;

  @override
  List<Object?> get props => [
    dateKey,
    dayRecords,
    qadaPlan,
    qadaDue,
    pauseRanges,
    activePause,
    fast,
    missedRamadanFasts,
    makeupFasts,
    week,
    month,
    prayerStreak,
  ];
}

String worshipDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime worshipDateFromKey(String value) {
  return DateTime.tryParse(value) ?? DateTime.now();
}

int _int(Object? value) {
  return value is num
      ? value.round()
      : int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
