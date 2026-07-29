import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import 'prayer_tracking_state.dart';

class PrayerTrackingCubit extends Cubit<PrayerTrackingState> {
  PrayerTrackingCubit({required PrayerTrackingRepository repository})
    : _repository = repository,
      super(const PrayerTrackingState());

  final PrayerTrackingRepository _repository;

  Future<void> load([DateTime? date]) async {
    final selected = date ?? state.selectedDate ?? DateTime.now();
    emit(
      state.copyWith(
        status: PrayerTrackingStatus.loading,
        selectedDate: selected,
        clearError: true,
      ),
    );
    try {
      final dashboard = await _repository.dashboard(selected);
      emit(
        state.copyWith(
          status: PrayerTrackingStatus.success,
          selectedDate: selected,
          dashboard: dashboard,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PrayerTrackingStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> changeDay(int offset) {
    final current = state.selectedDate ?? DateTime.now();
    return load(current.add(Duration(days: offset)));
  }

  Future<void> savePrayer({
    required TrackedPrayer prayer,
    required PrayerCompletion status,
    required bool congregation,
  }) async {
    await _repository.savePrayer(
      date: state.selectedDate ?? DateTime.now(),
      prayer: prayer,
      status: status,
      congregation: congregation,
    );
    await load();
  }

  Future<void> setQadaPlan({
    required int currentBalance,
    required int dailyTarget,
    required bool enabled,
  }) async {
    await _repository.setQadaPlan(
      currentBalance: currentBalance,
      dailyTarget: dailyTarget,
      enabled: enabled,
    );
    await load();
  }

  Future<void> addPauseRange({
    required DateTime start,
    required DateTime end,
    required bool suppressReminders,
    required bool exemptTracking,
  }) async {
    await _repository.addPauseRange(
      start: start,
      end: end,
      suppressReminders: suppressReminders,
      exemptTracking: exemptTracking,
    );
    await load();
  }

  Future<void> removePauseRange(String id) async {
    await _repository.removePauseRange(id);
    await load();
  }

  Future<void> saveFast(FastType type, FastStatus status) async {
    await _repository.saveFast(
      date: state.selectedDate ?? DateTime.now(),
      type: type,
      status: status,
    );
    await load();
  }

  Future<void> removeFast() async {
    await _repository.removeFast(state.selectedDate ?? DateTime.now());
    await load();
  }
}
