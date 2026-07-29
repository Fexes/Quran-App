import '../entities/reading_progress.dart';

abstract interface class ReadingProgressRepository {
  Future<ReadingDashboard> dashboard({DateTime? now});

  Future<void> recordVerse({required String verseKey, int? page, DateTime? at});

  Future<void> recordMinutes(int minutes, {DateTime? at});

  Future<void> saveGoal(ReadingGoal goal);

  Future<void> startKhatma({
    required DateTime targetDate,
    required int startPage,
    DateTime? now,
  });

  Future<void> setKhatmaPaused(bool paused, {DateTime? now});

  Future<void> clearKhatma();

  Future<void> startPlan({
    required String title,
    required int startPage,
    required int endPage,
    required DateTime targetDate,
    DateTime? now,
  });

  Future<void> setPlanPaused(String planId, bool paused, {DateTime? now});

  Future<void> removePlan(String planId);
}
