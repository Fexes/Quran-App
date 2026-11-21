import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/repositories/hifz_repository.dart';
import 'hifz_dashboard_state.dart';

class HifzDashboardCubit extends Cubit<HifzDashboardState> {
  HifzDashboardCubit({
    required HifzRepository repository,
    required QuranRepository quranRepository,
  }) : _repository = repository,
       _quranRepository = quranRepository,
       super(const HifzDashboardState.initial());

  final HifzRepository _repository;
  final QuranRepository _quranRepository;
  int _loadGeneration = 0;

  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    emit(
      HifzDashboardState(
        status: HifzDashboardStatus.loading,
        dashboard: state.dashboard,
      ),
    );
    try {
      final dashboard = await _repository.dashboard();
      if (!isClosed && generation == _loadGeneration) {
        emit(
          HifzDashboardState(
            status: HifzDashboardStatus.success,
            dashboard: dashboard,
          ),
        );
      }
    } catch (_) {
      if (!isClosed && generation == _loadGeneration) {
        emit(
          HifzDashboardState(
            status: HifzDashboardStatus.failure,
            dashboard: state.dashboard,
            errorMessage: 'Memorization progress could not be loaded.',
          ),
        );
      }
    }
  }

  Future<void> createCollection({
    required String title,
    required int surahNumber,
    required int startAyah,
    required int endAyah,
  }) async {
    if (title.trim().isEmpty || startAyah < 1 || endAyah < startAyah) {
      throw ArgumentError('Choose a title and a valid ayah range.');
    }
    final ayahs = await _quranRepository.getAyahs(surahNumber);
    final keys = [
      for (final ayah in ayahs)
        if (ayah.number >= startAyah && ayah.number <= endAyah) ayah.verseKey,
    ];
    if (keys.length != endAyah - startAyah + 1) {
      throw ArgumentError('The ayah range is outside this Surah.');
    }
    await _repository.saveCollection(title: title.trim(), verseKeys: keys);
    await load();
  }

  Future<void> deleteCollection(String id) async {
    await _repository.deleteCollection(id);
    await load();
  }
}
