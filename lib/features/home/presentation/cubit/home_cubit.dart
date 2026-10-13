import 'package:flutter/foundation.dart';
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
    Listenable? lastReadChanges,
    Listenable? translationChanges,
    DailyAyahService dailyAyahService = const DailyAyahService(),
    DateTime Function()? now,
  }) : _quranRepository = quranRepository,
       _prayerTimesRepository = prayerTimesRepository,
       _translationRepository = translationRepository,
       _readingProgressRepository = readingProgressRepository,
       _lastReadChanges = lastReadChanges,
       _translationChanges = translationChanges,
       _dailyAyahService = dailyAyahService,
       _now = now ?? DateTime.now,
       super(const HomeState.initial()) {
    _lastReadChanges?.addListener(refreshLastRead);
    _translationChanges?.addListener(load);
    if (_prayerTimesRepository case final PrayerLocationObservable observable) {
      observable.locationChanges.addListener(load);
    }
  }

  final QuranRepository _quranRepository;
  final PrayerTimesRepository _prayerTimesRepository;
  final QuranTranslationRepository? _translationRepository;
  final ReadingProgressRepository? _readingProgressRepository;
  final Listenable? _lastReadChanges;
  final Listenable? _translationChanges;
  final DailyAyahService _dailyAyahService;
  final DateTime Function() _now;
  int _lastReadRevision = 0;
  int _loadRevision = 0;

  Future<void> refreshLastRead() async {
    if (isClosed) return;
    final revision = ++_lastReadRevision;
    try {
      final lastRead = await _quranRepository.getLastRead();
      final surah = lastRead == null
          ? null
          : state.lastReadSurah?.number == lastRead.surahNumber
          ? state.lastReadSurah
          : await _quranRepository.getSurah(lastRead.surahNumber);
      if (isClosed || revision != _lastReadRevision) return;
      emit(
        state.copyWith(
          lastRead: lastRead,
          lastReadSurah: surah,
          clearLastRead: lastRead == null,
          prayerErrorMessage: state.prayerErrorMessage,
          dailyAyahErrorMessage: state.dailyAyahErrorMessage,
          errorMessage: state.errorMessage,
        ),
      );
    } catch (_) {
      if (isClosed || revision != _lastReadRevision) return;
      emit(
        state.copyWith(
          readingErrorMessage: 'Your reading position could not be refreshed.',
          prayerErrorMessage: state.prayerErrorMessage,
          dailyAyahErrorMessage: state.dailyAyahErrorMessage,
          errorMessage: state.errorMessage,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    if (_prayerTimesRepository case final PrayerLocationObservable observable) {
      observable.locationChanges.removeListener(load);
    }
    _lastReadChanges?.removeListener(refreshLastRead);
    _translationChanges?.removeListener(load);
    return super.close();
  }

  Future<void> load() async {
    if (isClosed) return;
    final loadRevision = ++_loadRevision;
    final lastReadRevision = ++_lastReadRevision;
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
          final position = await _quranRepository.getLastRead();
          final surah = position == null
              ? null
              : await _quranRepository.getSurah(position.surahNumber);
          lastRead = position;
          lastReadSurah = surah;
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

    if (isClosed || loadRevision != _loadRevision) {
      return;
    }
    // A live save wins over a dashboard refresh that started earlier.
    if (lastReadRevision != _lastReadRevision) {
      lastRead = state.lastRead;
      lastReadSurah = state.lastReadSurah;
      readingError = state.readingErrorMessage;
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
