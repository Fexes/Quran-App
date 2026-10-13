import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prayer_calculation_settings.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({required PrayerTimesRepository repository})
    : _repository = repository,
      super(const PrayerTimesState.initial()) {
    if (_repository case final PrayerLocationObservable observable) {
      observable.locationChanges.addListener(load);
    }
  }

  final PrayerTimesRepository _repository;
  int _loadRevision = 0;

  @override
  Future<void> close() {
    _loadRevision++;
    if (_repository case final PrayerLocationObservable observable) {
      observable.locationChanges.removeListener(load);
    }
    return super.close();
  }

  Future<void> load({DateTime? date}) async {
    if (isClosed) return;
    final revision = ++_loadRevision;
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    try {
      final dailyTimes = await _repository.getDailyPrayerTimes(
        date: date ?? DateTime.now(),
      );
      if (isClosed || revision != _loadRevision) return;
      emit(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          dailyTimes: dailyTimes,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _loadRevision) return;
      emit(
        state.copyWith(
          status: PrayerTimesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> updateSettings(PrayerCalculationSettings settings) async {
    await _repository.saveSettings(settings);
    await load();
  }

  Future<void> updateLocation(PrayerLocation location) async {
    await _repository.saveLocation(location);
    await load();
  }
}
