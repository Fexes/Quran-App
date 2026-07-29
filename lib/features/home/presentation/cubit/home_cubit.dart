import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/services/daily_ayah_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required QuranRepository quranRepository,
    required PrayerTimesRepository prayerTimesRepository,
    QuranTranslationRepository? translationRepository,
    ReadingProgressRepository? readingProgressRepository,
    DailyAyahService dailyAyahService = const DailyAyahService(),
    DateTime Function()? now,
  }) : _quranRepository = quranRepository,
       _prayerTimesRepository = prayerTimesRepository,
       _translationRepository = translationRepository,
       _readingProgressRepository = readingProgressRepository,
       _dailyAyahService = dailyAyahService,
       _now = now ?? DateTime.now,
       super(const HomeState.initial());

  final QuranRepository _quranRepository;
  final PrayerTimesRepository _prayerTimesRepository;
  final QuranTranslationRepository? _translationRepository;
  final ReadingProgressRepository? _readingProgressRepository;
  final DailyAyahService _dailyAyahService;
  final DateTime Function() _now;

  Future<void> load() async {
    final previous = state;
    emit(
      HomeState(
        status: HomeStatus.loading,
        lastRead: previous.lastRead,
        lastReadSurah: previous.lastReadSurah,
        dailyPrayerTimes: previous.dailyPrayerTimes,
        dailyAyah: previous.dailyAyah,
        readingDashboard: previous.readingDashboard,
      ),
    );

    final now = _now();
    var dailyPrayerTimes = previous.dailyPrayerTimes;
    var lastRead = previous.lastRead;
    var lastReadSurah = previous.lastReadSurah;
    DailyAyah? dailyAyah = previous.dailyAyah?.isForDate(now) == true
        ? previous.dailyAyah
        : null;
    ReadingDashboard? readingDashboard = previous.readingDashboard;
    String? prayerError;
    String? readingError;
    String? dailyAyahError;
    final details = <String>[];

    await Future.wait<void>([
      () async {
        try {
          dailyPrayerTimes = await _prayerTimesRepository.getDailyPrayerTimes(
            date: now,
          );
        } catch (error) {
          prayerError = 'Prayer times could not be refreshed.';
          details.add('Prayer times: $error');
        }
      }(),
      () async {
        final repository = _readingProgressRepository;
        if (repository == null) {
          return;
        }
        try {
          readingDashboard = await repository.dashboard(now: now);
        } catch (error) {
          details.add('Reading goal: $error');
        }
      }(),
      () async {
        try {
          lastRead = await _quranRepository.getLastRead();
          lastReadSurah = lastRead == null
              ? null
              : await _quranRepository.getSurah(lastRead!.surahNumber);
        } catch (error) {
          readingError = 'Your reading position could not be refreshed.';
          details.add('Last read: $error');
        }
      }(),
      () async {
        try {
          dailyAyah = await _dailyAyahService.load(
            date: now,
            quranRepository: _quranRepository,
            translationRepository: _translationRepository,
          );
        } catch (error) {
          dailyAyahError = 'Today\'s ayah could not be loaded.';
          details.add('Daily ayah: $error');
        }
      }(),
    ]);

    if (isClosed) {
      return;
    }
    final allFailed =
        prayerError != null && readingError != null && dailyAyahError != null;
    emit(
      HomeState(
        status: allFailed ? HomeStatus.failure : HomeStatus.success,
        lastRead: lastRead,
        lastReadSurah: lastReadSurah,
        dailyPrayerTimes: dailyPrayerTimes,
        dailyAyah: dailyAyah,
        readingDashboard: readingDashboard,
        prayerErrorMessage: prayerError,
        readingErrorMessage: readingError,
        dailyAyahErrorMessage: dailyAyahError,
        errorMessage: details.isEmpty ? null : details.join('\n'),
      ),
    );
  }
}
