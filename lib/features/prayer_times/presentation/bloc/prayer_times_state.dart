import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_prayer_times.dart';

enum PrayerTimesStatus { initial, loading, success, failure }

class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    required this.status,
    this.dailyTimes,
    this.errorMessage,
  });

  const PrayerTimesState.initial()
    : status = PrayerTimesStatus.initial,
      dailyTimes = null,
      errorMessage = null;

  final PrayerTimesStatus status;
  final DailyPrayerTimes? dailyTimes;
  final String? errorMessage;

  PrayerTimesState copyWith({
    PrayerTimesStatus? status,
    DailyPrayerTimes? dailyTimes,
    String? errorMessage,
  }) {
    return PrayerTimesState(
      status: status ?? this.status,
      dailyTimes: dailyTimes ?? this.dailyTimes,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dailyTimes, errorMessage];
}
