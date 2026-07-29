import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../stores/reading_progress_store.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  const ReadingProgressRepositoryImpl({required ReadingProgressStore store})
    : _store = store;

  final ReadingProgressStore _store;

  @override
  Future<ReadingDashboard> dashboard({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final days = _store.days;
    final key = _dateKey(current);
    final goal = _store.goal;
    final streaks = _streaks(days: days, goal: goal, now: current);
    return ReadingDashboard(
      goal: goal,
      today: days[key] ?? DailyReadingProgress.empty(key),
      currentStreak: streaks.current,
      bestStreak: streaks.best,
      khatma: _store.khatma,
      plans: _store.plans,
    );
  }

  @override
  Future<void> recordVerse({
    required String verseKey,
    int? page,
    DateTime? at,
  }) async {
    final current = at ?? DateTime.now();
    final key = _dateKey(current);
    final existing = _store.days[key] ?? DailyReadingProgress.empty(key);
    final next = existing.copyWith(
      verseKeys: {...existing.verseKeys, verseKey},
      pages: {
        ...existing.pages,
        if (page != null && page >= 1 && page <= 604) page,
      },
    );
    await _store.saveDay(next);
    if (page != null) {
      await _advancePlans(page, current);
    }
  }

  @override
  Future<void> recordMinutes(int minutes, {DateTime? at}) async {
    if (minutes <= 0) {
      return;
    }
    final current = at ?? DateTime.now();
    final key = _dateKey(current);
    final existing = _store.days[key] ?? DailyReadingProgress.empty(key);
    await _store.saveDay(
      existing.copyWith(minutes: (existing.minutes + minutes).clamp(0, 1440)),
    );
  }

  @override
  Future<void> saveGoal(ReadingGoal goal) => _store.saveGoal(goal);

  @override
  Future<void> startKhatma({
    required DateTime targetDate,
    required int startPage,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return _store.saveKhatma(
      KhatmaPlan(
        id: current.microsecondsSinceEpoch.toString(),
        startedAt: current,
        targetDate: targetDate,
        startPage: startPage.clamp(1, 604),
        currentPage: startPage.clamp(1, 604),
        updatedAt: current,
      ),
    );
  }

  @override
  Future<void> setKhatmaPaused(bool paused, {DateTime? now}) async {
    final plan = _store.khatma;
    if (plan == null) {
      return;
    }
    await _store.saveKhatma(
      plan.copyWith(paused: paused, updatedAt: now ?? DateTime.now()),
    );
  }

  @override
  Future<void> clearKhatma() => _store.saveKhatma(null);

  @override
  Future<void> startPlan({
    required String title,
    required int startPage,
    required int endPage,
    required DateTime targetDate,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final normalizedStart = startPage.clamp(1, 604);
    final normalizedEnd = endPage.clamp(normalizedStart, 604);
    final plan = ReadingPlan(
      id: current.microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Reading plan' : title.trim(),
      startPage: normalizedStart,
      endPage: normalizedEnd,
      currentPage: normalizedStart,
      startedAt: current,
      targetDate: targetDate,
      updatedAt: current,
    );
    await _store.savePlans([..._store.plans, plan]);
  }

  @override
  Future<void> setPlanPaused(
    String planId,
    bool paused, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    await _store.savePlans([
      for (final plan in _store.plans)
        if (plan.id == planId)
          plan.copyWith(paused: paused, updatedAt: current)
        else
          plan,
    ]);
  }

  @override
  Future<void> removePlan(String planId) {
    return _store.savePlans(
      _store.plans.where((plan) => plan.id != planId).toList(growable: false),
    );
  }

  Future<void> _advancePlans(int page, DateTime now) async {
    final khatma = _store.khatma;
    if (khatma != null &&
        !khatma.paused &&
        !khatma.completed &&
        page > khatma.currentPage) {
      await _store.saveKhatma(
        khatma.copyWith(
          currentPage: page,
          updatedAt: now,
          completed: page >= 604,
        ),
      );
    }
    final plans = _store.plans;
    var changed = false;
    final next = <ReadingPlan>[];
    for (final plan in plans) {
      if (!plan.paused &&
          !plan.completed &&
          page >= plan.startPage &&
          page <= plan.endPage &&
          page > plan.currentPage) {
        changed = true;
        next.add(
          plan.copyWith(
            currentPage: page,
            updatedAt: now,
            completed: page >= plan.endPage,
          ),
        );
      } else {
        next.add(plan);
      }
    }
    if (changed) {
      await _store.savePlans(next);
    }
  }

  ({int current, int best}) _streaks({
    required Map<String, DailyReadingProgress> days,
    required ReadingGoal goal,
    required DateTime now,
  }) {
    bool qualifies(DateTime date) {
      final progress = days[_dateKey(date)];
      return progress != null && progress.valueFor(goal.metric) > 0;
    }

    var current = 0;
    var graceUsed = false;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!qualifies(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    for (var i = 0; i < 3660; i++) {
      if (qualifies(cursor)) {
        current++;
      } else if (goal.allowOneGraceDay && !graceUsed && current > 0) {
        graceUsed = true;
      } else {
        break;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final activeDates =
        days.values
            .where((item) => item.valueFor(goal.metric) > 0)
            .map((item) => DateTime.tryParse(item.dateKey))
            .whereType<DateTime>()
            .toList()
          ..sort();
    var best = activeDates.isEmpty ? 0 : 1;
    var run = best;
    var runGraceUsed = false;
    for (var i = 1; i < activeDates.length; i++) {
      final gap = activeDates[i].difference(activeDates[i - 1]).inDays;
      if (gap == 1 || (gap == 2 && goal.allowOneGraceDay && !runGraceUsed)) {
        run++;
        if (gap == 2) {
          runGraceUsed = true;
        }
      } else {
        run = 1;
        runGraceUsed = false;
      }
      if (run > best) {
        best = run;
      }
    }
    return (current: current, best: best);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
