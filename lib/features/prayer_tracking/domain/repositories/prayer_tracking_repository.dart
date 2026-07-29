import '../entities/prayer_tracking_models.dart';

abstract interface class PrayerTrackingRepository {
  Future<PrayerTrackingDashboard> dashboard(DateTime date);

  Future<void> savePrayer({
    required DateTime date,
    required TrackedPrayer prayer,
    required PrayerCompletion status,
    required bool congregation,
  });

  Future<void> setQadaPlan({
    required int currentBalance,
    required int dailyTarget,
    required bool enabled,
  });

  Future<void> addPauseRange({
    required DateTime start,
    required DateTime end,
    required bool suppressReminders,
    required bool exemptTracking,
  });

  Future<void> removePauseRange(String id);

  Future<void> saveFast({
    required DateTime date,
    required FastType type,
    required FastStatus status,
  });

  Future<void> removeFast(DateTime date);
}
