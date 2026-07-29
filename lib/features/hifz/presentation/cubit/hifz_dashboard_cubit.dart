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

  Future<void> load() async {
    emit(
      HifzDashboardState(
        status: HifzDashboardStatus.loading,
        dashboard: state.dashboard,
      ),
    );
    try {
      final dashboard = await _repository.dashboard();
      if (!isClosed) {
        emit(
          HifzDashboardState(
            status: HifzDashboardStatus.success,
            dashboard: dashboard,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          HifzDashboardState(
            status: HifzDashboardStatus.failure,
            dashboard: state.dashboard,
            errorMessage: 'Hifz progress could not be loaded.',
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
    final ayahs = await _quranRepository.getAyahs(surahNumber);
    final keys = [
      for (final ayah in ayahs)
        if (ayah.number >= startAyah && ayah.number <= endAyah) ayah.verseKey,
    ];
    if (keys.isEmpty) {
      return;
    }
    await _repository.saveCollection(title: title, verseKeys: keys);
    await load();
  }

  Future<void> deleteCollection(String id) async {
    await _repository.deleteCollection(id);
    await load();
  }
}
