import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prayer_calculation_settings.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import 'prayer_times_state.dart';

class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  PrayerTimesCubit({required PrayerTimesRepository repository})
    : _repository = repository,
      super(const PrayerTimesState.initial());

  final PrayerTimesRepository _repository;

  Future<void> load({DateTime? date}) async {
    emit(state.copyWith(status: PrayerTimesStatus.loading));
    try {
      final dailyTimes = await _repository.getDailyPrayerTimes(
        date: date ?? DateTime.now(),
      );
      emit(
        PrayerTimesState(
          status: PrayerTimesStatus.success,
          dailyTimes: dailyTimes,
        ),
      );
    } catch (error) {
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
