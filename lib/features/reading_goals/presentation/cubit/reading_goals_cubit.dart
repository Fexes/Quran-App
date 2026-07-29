import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import 'reading_goals_state.dart';

class ReadingGoalsCubit extends Cubit<ReadingGoalsState> {
  ReadingGoalsCubit({
    required ReadingProgressRepository repository,
    required QuranRepository quranRepository,
    DateTime Function()? now,
  }) : _repository = repository,
       _quranRepository = quranRepository,
       _now = now ?? DateTime.now,
       super(const ReadingGoalsState.initial());

  final ReadingProgressRepository _repository;
  final QuranRepository _quranRepository;
  final DateTime Function() _now;

  Future<void> load() async {
    emit(
      ReadingGoalsState(
        status: ReadingGoalsStatus.loading,
        dashboard: state.dashboard,
      ),
    );
    try {
      final dashboard = await _repository.dashboard(now: _now());
      if (!isClosed) {
        emit(
          ReadingGoalsState(
            status: ReadingGoalsStatus.success,
            dashboard: dashboard,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          ReadingGoalsState(
            status: ReadingGoalsStatus.failure,
            dashboard: state.dashboard,
            errorMessage: 'Reading progress could not be loaded.',
          ),
        );
      }
    }
  }

  Future<void> saveGoal(ReadingGoal goal) async {
    await _repository.saveGoal(goal);
    await load();
  }

  Future<void> startKhatma(int days) async {
    final now = _now();
    await _repository.startKhatma(
      targetDate: now.add(Duration(days: days.clamp(1, 3650))),
      startPage: await _currentPage(),
      now: now,
    );
    await load();
  }

  Future<void> setKhatmaPaused(bool paused) async {
    await _repository.setKhatmaPaused(paused, now: _now());
    await load();
  }

  Future<void> clearKhatma() async {
    await _repository.clearKhatma();
    await load();
  }

  Future<void> startFullQuranPlan({int days = 30}) async {
    final now = _now();
    await _repository.startPlan(
      title: '$days-day Quran plan',
      startPage: 1,
      endPage: 604,
      targetDate: now.add(Duration(days: days)),
      now: now,
    );
    await load();
  }

  Future<void> startCustomPlan({
    required String title,
    required int startPage,
    required int endPage,
    required int days,
  }) async {
    final now = _now();
    await _repository.startPlan(
      title: title,
      startPage: startPage,
      endPage: endPage,
      targetDate: now.add(Duration(days: days.clamp(1, 3650))),
      now: now,
    );
    await load();
  }

  Future<void> setPlanPaused(String id, bool paused) async {
    await _repository.setPlanPaused(id, paused, now: _now());
    await load();
  }

  Future<void> removePlan(String id) async {
    await _repository.removePlan(id);
    await load();
  }

  Future<int> _currentPage() async {
    final lastRead = await _quranRepository.getLastRead();
    if (lastRead == null) {
      return 1;
    }
    final ayahs = await _quranRepository.getAyahs(lastRead.surahNumber);
    for (final ayah in ayahs) {
      if (ayah.number == lastRead.ayahNumber) {
        return ayah.page.clamp(1, 604);
      }
    }
    return 1;
  }
}
