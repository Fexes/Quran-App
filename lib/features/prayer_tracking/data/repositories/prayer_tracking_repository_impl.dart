import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../stores/prayer_tracking_store.dart';

class PrayerTrackingRepositoryImpl implements PrayerTrackingRepository {
  const PrayerTrackingRepositoryImpl({required PrayerTrackingStore store})
    : _store = store;

  final PrayerTrackingStore _store;

  @override
  Future<PrayerTrackingDashboard> dashboard(DateTime date) async {
    final dateKey = worshipDateKey(date);
    final records = _store.prayerRecords;
    final ranges = [..._store.pauseRanges]
      ..sort((a, b) => b.startDateKey.compareTo(a.startDateKey));
    CyclePauseRange? activePause;
    for (final range in ranges) {
      if (range.contains(dateKey)) {
        activePause = range;
        break;
      }
    }
    final dayRecords = <TrackedPrayer, PrayerTrackingRecord>{
      for (final record in records)
        if (record.dateKey == dateKey) record.prayer: record,
    };
    if (activePause?.exemptTracking == true) {
      for (final prayer in TrackedPrayer.values) {
        dayRecords[prayer] = PrayerTrackingRecord(
          dateKey: dateKey,
          prayer: prayer,
          status: PrayerCompletion.exempt,
          congregation: false,
          updatedAt: activePause!.updatedAt,
        );
      }
    }
    final plan = _store.qadaPlan;
    final laterRecords = records.where(
      (record) =>
          record.updatedAt.isAfter(plan.baselineAt) &&
          !_isExemptDate(record.dateKey, ranges),
    );
    final missed = laterRecords
        .where((record) => record.status == PrayerCompletion.missed)
        .length;
    final qada = laterRecords
        .where((record) => record.status == PrayerCompletion.qada)
        .length;
    final fasts = _store.fastingRecords;
    FastingRecord? selectedFast;
    for (final item in fasts) {
      if (item.dateKey == dateKey) {
        selectedFast = item;
        break;
      }
    }
    return PrayerTrackingDashboard(
      dateKey: dateKey,
      dayRecords: dayRecords,
      qadaPlan: plan,
      qadaDue: (plan.baselineDue + missed - qada).clamp(0, 1000000),
      pauseRanges: ranges,
      activePause: activePause,
      fast: selectedFast,
      missedRamadanFasts: fasts
          .where(
            (item) =>
                item.type == FastType.ramadan &&
                item.status == FastStatus.missed,
          )
          .length,
      makeupFasts: fasts
          .where(
            (item) =>
                item.type == FastType.makeup &&
                item.status == FastStatus.completed,
          )
          .length,
      week: _summary(
        date: date,
        days: 7,
        prayerRecords: records,
        fasts: fasts,
        pauseRanges: ranges,
      ),
      month: _summary(
        date: date,
        days: 30,
        prayerRecords: records,
        fasts: fasts,
        pauseRanges: ranges,
      ),
      prayerStreak: _prayerStreak(
        date: date,
        records: records,
        pauseRanges: ranges,
      ),
    );
  }

  @override
  Future<void> savePrayer({
    required DateTime date,
    required TrackedPrayer prayer,
    required PrayerCompletion status,
    required bool congregation,
  }) async {
    final dateKey = worshipDateKey(date);
    final id = '$dateKey:${prayer.name}';
    final next = [
      for (final item in _store.prayerRecords)
        if (item.id != id) item,
      if (status != PrayerCompletion.unrecorded)
        PrayerTrackingRecord(
          dateKey: dateKey,
          prayer: prayer,
          status: status,
          congregation:
              congregation &&
              status != PrayerCompletion.missed &&
              status != PrayerCompletion.exempt,
          updatedAt: DateTime.now(),
        ),
    ];
    await _store.savePrayerRecords(next);
  }

  @override
  Future<void> setQadaPlan({
    required int currentBalance,
    required int dailyTarget,
    required bool enabled,
  }) {
    final now = DateTime.now();
    return _store.saveQadaPlan(
      QadaPlan(
        baselineDue: currentBalance.clamp(0, 1000000),
        baselineAt: now,
        dailyTarget: dailyTarget.clamp(1, 100),
        enabled: enabled,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> addPauseRange({
    required DateTime start,
    required DateTime end,
    required bool suppressReminders,
    required bool exemptTracking,
  }) async {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (endDay.isBefore(startDay)) {
      throw ArgumentError('Pause end must not be before its start.');
    }
    final now = DateTime.now();
    final range = CyclePauseRange(
      id: now.microsecondsSinceEpoch.toString(),
      startDateKey: worshipDateKey(startDay),
      endDateKey: worshipDateKey(endDay),
      suppressReminders: suppressReminders,
      exemptTracking: exemptTracking,
      updatedAt: now,
    );
    await _store.savePauseRanges([..._store.pauseRanges, range]);
  }

  @override
  Future<void> removePauseRange(String id) {
    return _store.savePauseRanges(
      _store.pauseRanges.where((item) => item.id != id).toList(),
    );
  }

  @override
  Future<void> saveFast({
    required DateTime date,
    required FastType type,
    required FastStatus status,
  }) {
    final dateKey = worshipDateKey(date);
    return _store.saveFastingRecords([
      for (final item in _store.fastingRecords)
        if (item.id != dateKey) item,
      FastingRecord(
        dateKey: dateKey,
        type: type,
        status: status,
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<void> removeFast(DateTime date) {
    final dateKey = worshipDateKey(date);
    return _store.saveFastingRecords(
      _store.fastingRecords.where((item) => item.id != dateKey).toList(),
    );
  }

  WorshipPeriodSummary _summary({
    required DateTime date,
    required int days,
    required List<PrayerTrackingRecord> prayerRecords,
    required List<FastingRecord> fasts,
    required List<CyclePauseRange> pauseRanges,
  }) {
    final end = DateTime(date.year, date.month, date.day);
    final start = end.subtract(Duration(days: days - 1));
    bool inRange(String key) {
      final item = worshipDateFromKey(key);
      return !item.isBefore(start) && !item.isAfter(end);
    }

    final periodPrayers = prayerRecords.where(
      (record) =>
          inRange(record.dateKey) &&
          !_isExemptDate(record.dateKey, pauseRanges),
    );
    final periodFasts = fasts.where((record) => inRange(record.dateKey));
    return WorshipPeriodSummary(
      prayersCompleted: periodPrayers
          .where(
            (item) =>
                item.status == PrayerCompletion.onTime ||
                item.status == PrayerCompletion.late ||
                item.status == PrayerCompletion.qada,
          )
          .length,
      prayersMissed: periodPrayers
          .where((item) => item.status == PrayerCompletion.missed)
          .length,
      prayersExempt: periodPrayers
          .where((item) => item.status == PrayerCompletion.exempt)
          .length,
      congregational: periodPrayers.where((item) => item.congregation).length,
      fastsCompleted: periodFasts
          .where((item) => item.status == FastStatus.completed)
          .length,
      fastsMissed: periodFasts
          .where((item) => item.status == FastStatus.missed)
          .length,
    );
  }

  bool _isExemptDate(String dateKey, List<CyclePauseRange> ranges) {
    return ranges.any(
      (range) => range.exemptTracking && range.contains(dateKey),
    );
  }

  int _prayerStreak({
    required DateTime date,
    required List<PrayerTrackingRecord> records,
    required List<CyclePauseRange> pauseRanges,
  }) {
    final byDate = <String, Map<TrackedPrayer, PrayerTrackingRecord>>{};
    for (final record in records) {
      byDate.putIfAbsent(record.dateKey, () => {})[record.prayer] = record;
    }
    var cursor = DateTime(date.year, date.month, date.day);
    final todayKey = worshipDateKey(cursor);
    if (!_isExemptDate(todayKey, pauseRanges) &&
        !_dayComplete(byDate[todayKey])) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    for (var checked = 0; checked < 3650; checked++) {
      final key = worshipDateKey(cursor);
      if (_isExemptDate(key, pauseRanges)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (!_dayComplete(byDate[key])) {
        break;
      }
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _dayComplete(Map<TrackedPrayer, PrayerTrackingRecord>? day) {
    if (day == null || day.length < TrackedPrayer.values.length) {
      return false;
    }
    return TrackedPrayer.values.every((prayer) {
      final status = day[prayer]?.status;
      return status == PrayerCompletion.onTime ||
          status == PrayerCompletion.late ||
          status == PrayerCompletion.qada;
    });
  }
}
