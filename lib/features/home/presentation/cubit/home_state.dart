import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../quran/domain/entities/quran_last_read.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../domain/entities/daily_ayah.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    this.lastRead,
    this.lastReadSurah,
    this.dailyPrayerTimes,
    this.dailyAyah,
    this.readingDashboard,
    this.prayerErrorMessage,
    this.readingErrorMessage,
    this.dailyAyahErrorMessage,
    this.errorMessage,
  });

  const HomeState.initial()
    : status = HomeStatus.initial,
      lastRead = null,
      lastReadSurah = null,
      dailyPrayerTimes = null,
      dailyAyah = null,
      readingDashboard = null,
      prayerErrorMessage = null,
      readingErrorMessage = null,
      dailyAyahErrorMessage = null,
      errorMessage = null;

  final HomeStatus status;
  final QuranLastRead? lastRead;
  final QuranSurah? lastReadSurah;
  final DailyPrayerTimes? dailyPrayerTimes;
  final DailyAyah? dailyAyah;
  final ReadingDashboard? readingDashboard;
  final String? prayerErrorMessage;
  final String? readingErrorMessage;
  final String? dailyAyahErrorMessage;
  final String? errorMessage;

  bool get hasLastRead => lastRead != null && lastReadSurah != null;

  HomeState copyWith({
    HomeStatus? status,
    QuranLastRead? lastRead,
    QuranSurah? lastReadSurah,
    DailyPrayerTimes? dailyPrayerTimes,
    DailyAyah? dailyAyah,
    ReadingDashboard? readingDashboard,
    String? prayerErrorMessage,
    String? readingErrorMessage,
    String? dailyAyahErrorMessage,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      lastRead: lastRead ?? this.lastRead,
      lastReadSurah: lastReadSurah ?? this.lastReadSurah,
      dailyPrayerTimes: dailyPrayerTimes ?? this.dailyPrayerTimes,
      dailyAyah: dailyAyah ?? this.dailyAyah,
      readingDashboard: readingDashboard ?? this.readingDashboard,
      prayerErrorMessage: prayerErrorMessage,
      readingErrorMessage: readingErrorMessage,
      dailyAyahErrorMessage: dailyAyahErrorMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    lastRead,
    lastReadSurah,
    dailyPrayerTimes,
    dailyAyah,
    readingDashboard,
    prayerErrorMessage,
    readingErrorMessage,
    dailyAyahErrorMessage,
    errorMessage,
  ];
}
