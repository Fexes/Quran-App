import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import 'prayer_tracking_state.dart';

class PrayerTrackingCubit extends Cubit<PrayerTrackingState> {
  PrayerTrackingCubit({required PrayerTrackingRepository repository})
    : _repository = repository,
      super(const PrayerTrackingState());

  final PrayerTrackingRepository _repository;
  int _loadGeneration = 0;
  bool _saving = false;

  Future<void> load([DateTime? date]) async {
    if (isClosed || _saving) return;
    final requested = date ?? state.selectedDate ?? DateTime.now();
    final selected = DateTime(requested.year, requested.month, requested.day);
    final generation = ++_loadGeneration;
    emit(
      state.copyWith(
        status: PrayerTrackingStatus.loading,
        selectedDate: selected,
        clearError: true,
      ),
    );
    try {
      final dashboard = await _repository.dashboard(selected);
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: PrayerTrackingStatus.success,
          selectedDate: selected,
          dashboard: dashboard,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: PrayerTrackingStatus.failure,
          errorMessage: 'Your journal could not be loaded. Please try again.',
        ),
      );
    }
  }

  Future<void> changeDay(int offset) {
    final current = state.selectedDate ?? DateTime.now();
    return load(DateTime(current.year, current.month, current.day + offset));
  }

  Future<void> savePrayer({
    required TrackedPrayer prayer,
    required PrayerCompletion status,
    required bool congregation,
  }) => _mutate(
    (date) => _repository.savePrayer(
      date: date,
      prayer: prayer,
      status: status,
      congregation: congregation,
    ),
  );

  Future<void> setQadaPlan({
    required int currentBalance,
    required int dailyTarget,
    required bool enabled,
  }) => _mutate(
    (_) => _repository.setQadaPlan(
      currentBalance: currentBalance,
      dailyTarget: dailyTarget,
      enabled: enabled,
    ),
  );

  Future<void> addPauseRange({
    required DateTime start,
    required DateTime end,
    required bool suppressReminders,
    required bool exemptTracking,
  }) => _mutate(
    (_) => _repository.addPauseRange(
      start: start,
      end: end,
      suppressReminders: suppressReminders,
      exemptTracking: exemptTracking,
    ),
  );

  Future<void> removePauseRange(String id) =>
      _mutate((_) => _repository.removePauseRange(id));

  Future<void> saveFast(FastType type, FastStatus status) => _mutate(
    (date) => _repository.saveFast(date: date, type: type, status: status),
  );

  Future<void> removeFast() => _mutate(_repository.removeFast);

  Future<void> _mutate(Future<void> Function(DateTime date) action) async {
    if (isClosed || _saving) return;
    final date = state.selectedDate ?? DateTime.now();
    _saving = true;
    _loadGeneration++;
    emit(
      state.copyWith(status: PrayerTrackingStatus.loading, clearError: true),
    );
    try {
      await action(date);
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PrayerTrackingStatus.failure,
            errorMessage: 'Your changes could not be saved. Please try again.',
          ),
        );
      }
      rethrow;
    } finally {
      _saving = false;
    }
    if (!isClosed) await load(date);
  }
}
