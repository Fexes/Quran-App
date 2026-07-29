import 'package:equatable/equatable.dart';

enum ReadingGoalMetric { verses, pages, minutes }

class ReadingGoal extends Equatable {
  const ReadingGoal({
    required this.metric,
    required this.dailyTarget,
    this.allowOneGraceDay = true,
    this.enabled = true,
  });

  factory ReadingGoal.fromJson(Map<dynamic, dynamic> json) {
    return ReadingGoal(
      metric: ReadingGoalMetric.values.firstWhere(
        (item) => item.name == json['metric'],
        orElse: () => ReadingGoalMetric.pages,
      ),
      dailyTarget: _int(json['dailyTarget']).clamp(1, 1000),
      allowOneGraceDay: json['allowOneGraceDay'] as bool? ?? true,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final ReadingGoalMetric metric;
  final int dailyTarget;
  final bool allowOneGraceDay;
  final bool enabled;

  Map<String, Object> toJson() {
    return {
      'metric': metric.name,
      'dailyTarget': dailyTarget,
      'allowOneGraceDay': allowOneGraceDay,
      'enabled': enabled,
    };
  }

  @override
  List<Object> get props => [metric, dailyTarget, allowOneGraceDay, enabled];
}

class DailyReadingProgress extends Equatable {
  const DailyReadingProgress({
    required this.dateKey,
    required this.verseKeys,
    required this.pages,
    required this.minutes,
  });

  factory DailyReadingProgress.empty(String dateKey) {
    return DailyReadingProgress(
      dateKey: dateKey,
      verseKeys: const {},
      pages: const {},
      minutes: 0,
    );
  }

  factory DailyReadingProgress.fromJson(Map<dynamic, dynamic> json) {
    return DailyReadingProgress(
      dateKey: json['dateKey'] as String? ?? '',
      verseKeys: {
        for (final item
            in json['verseKeys'] is List ? json['verseKeys'] as List : const [])
          if (item is String && item.trim().isNotEmpty) item,
      },
      pages: {
        for (final item
            in json['pages'] is List ? json['pages'] as List : const [])
          if (_int(item) > 0) _int(item),
      },
      minutes: _int(json['minutes']).clamp(0, 1440),
    );
  }

  final String dateKey;
  final Set<String> verseKeys;
  final Set<int> pages;
  final int minutes;

  int valueFor(ReadingGoalMetric metric) {
    return switch (metric) {
      ReadingGoalMetric.verses => verseKeys.length,
      ReadingGoalMetric.pages => pages.length,
      ReadingGoalMetric.minutes => minutes,
    };
  }

  DailyReadingProgress copyWith({
    Set<String>? verseKeys,
    Set<int>? pages,
    int? minutes,
  }) {
    return DailyReadingProgress(
      dateKey: dateKey,
      verseKeys: verseKeys ?? this.verseKeys,
      pages: pages ?? this.pages,
      minutes: minutes ?? this.minutes,
    );
  }

  Map<String, Object> toJson() {
    return {
      'dateKey': dateKey,
      'verseKeys': verseKeys.toList()..sort(),
      'pages': pages.toList()..sort(),
      'minutes': minutes,
    };
  }

  @override
  List<Object> get props => [dateKey, verseKeys, pages, minutes];
}

class KhatmaPlan extends Equatable {
  const KhatmaPlan({
    required this.id,
    required this.startedAt,
    required this.targetDate,
    required this.startPage,
    required this.currentPage,
    required this.updatedAt,
    this.paused = false,
    this.completed = false,
  });

  factory KhatmaPlan.fromJson(Map<dynamic, dynamic> json) {
    final startedAt = _date(json['startedAt']) ?? DateTime.now();
    return KhatmaPlan(
      id: json['id'] as String? ?? '',
      startedAt: startedAt,
      targetDate:
          _date(json['targetDate']) ?? startedAt.add(const Duration(days: 30)),
      startPage: _int(json['startPage']).clamp(1, 604),
      currentPage: _int(json['currentPage']).clamp(1, 604),
      updatedAt: _date(json['updatedAt']) ?? startedAt,
      paused: json['paused'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String id;
  final DateTime startedAt;
  final DateTime targetDate;
  final int startPage;
  final int currentPage;
  final DateTime updatedAt;
  final bool paused;
  final bool completed;

  int get remainingPages => (604 - currentPage).clamp(0, 603);

  int dailyPagesRequired(DateTime now) {
    if (remainingPages == 0) {
      return 0;
    }
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final days = target.difference(today).inDays + 1;
    if (days <= 1) {
      return remainingPages;
    }
    return (remainingPages / days).ceil();
  }

  double get progress {
    final total = (604 - startPage + 1).clamp(1, 604);
    final done = (currentPage - startPage + 1).clamp(0, total);
    return done / total;
  }

  KhatmaPlan copyWith({
    DateTime? targetDate,
    int? currentPage,
    DateTime? updatedAt,
    bool? paused,
    bool? completed,
  }) {
    return KhatmaPlan(
      id: id,
      startedAt: startedAt,
      targetDate: targetDate ?? this.targetDate,
      startPage: startPage,
      currentPage: currentPage ?? this.currentPage,
      updatedAt: updatedAt ?? this.updatedAt,
      paused: paused ?? this.paused,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'startPage': startPage,
      'currentPage': currentPage,
      'updatedAt': updatedAt.toIso8601String(),
      'paused': paused,
      'completed': completed,
    };
  }

  @override
  List<Object> get props => [
    id,
    startedAt,
    targetDate,
    startPage,
    currentPage,
    updatedAt,
    paused,
    completed,
  ];
}

class ReadingPlan extends Equatable {
  const ReadingPlan({
    required this.id,
    required this.title,
    required this.startPage,
    required this.endPage,
    required this.currentPage,
    required this.startedAt,
    required this.targetDate,
    required this.updatedAt,
    this.paused = false,
    this.completed = false,
  });

  factory ReadingPlan.fromJson(Map<dynamic, dynamic> json) {
    final startedAt = _date(json['startedAt']) ?? DateTime.now();
    return ReadingPlan(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Reading plan',
      startPage: _int(json['startPage']).clamp(1, 604),
      endPage: _int(json['endPage']).clamp(1, 604),
      currentPage: _int(json['currentPage']).clamp(1, 604),
      startedAt: startedAt,
      targetDate:
          _date(json['targetDate']) ?? startedAt.add(const Duration(days: 30)),
      updatedAt: _date(json['updatedAt']) ?? startedAt,
      paused: json['paused'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final int startPage;
  final int endPage;
  final int currentPage;
  final DateTime startedAt;
  final DateTime targetDate;
  final DateTime updatedAt;
  final bool paused;
  final bool completed;

  double get progress {
    final total = (endPage - startPage + 1).clamp(1, 604);
    final done = (currentPage - startPage + 1).clamp(0, total);
    return done / total;
  }

  int dailyPagesRequired(DateTime now) {
    final remaining = (endPage - currentPage).clamp(0, 603);
    if (remaining == 0) {
      return 0;
    }
    final days =
        DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        ).difference(DateTime(now.year, now.month, now.day)).inDays +
        1;
    return days <= 1 ? remaining : (remaining / days).ceil();
  }

  ReadingPlan copyWith({
    int? currentPage,
    DateTime? updatedAt,
    bool? paused,
    bool? completed,
  }) {
    return ReadingPlan(
      id: id,
      title: title,
      startPage: startPage,
      endPage: endPage,
      currentPage: currentPage ?? this.currentPage,
      startedAt: startedAt,
      targetDate: targetDate,
      updatedAt: updatedAt ?? this.updatedAt,
      paused: paused ?? this.paused,
      completed: completed ?? this.completed,
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'startPage': startPage,
      'endPage': endPage,
      'currentPage': currentPage,
      'startedAt': startedAt.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paused': paused,
      'completed': completed,
    };
  }

  @override
  List<Object> get props => [
    id,
    title,
    startPage,
    endPage,
    currentPage,
    startedAt,
    targetDate,
    updatedAt,
    paused,
    completed,
  ];
}

class ReadingDashboard extends Equatable {
  const ReadingDashboard({
    required this.goal,
    required this.today,
    required this.currentStreak,
    required this.bestStreak,
    required this.khatma,
    required this.plans,
  });

  final ReadingGoal goal;
  final DailyReadingProgress today;
  final int currentStreak;
  final int bestStreak;
  final KhatmaPlan? khatma;
  final List<ReadingPlan> plans;

  int get todayValue => today.valueFor(goal.metric);
  double get goalProgress =>
      (todayValue / goal.dailyTarget).clamp(0.0, 1.0).toDouble();
  bool get goalComplete => todayValue >= goal.dailyTarget;

  @override
  List<Object?> get props => [
    goal,
    today,
    currentStreak,
    bestStreak,
    khatma,
    plans,
  ];
}

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
