import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_repository.dart';
import 'quran_list_event.dart';
import 'quran_list_state.dart';

class QuranListBloc extends Bloc<QuranListEvent, QuranListState> {
  QuranListBloc({required QuranRepository repository})
    : _repository = repository,
      super(const QuranListState.initial()) {
    on<QuranListStarted>(_onStarted);
    on<QuranListQueryChanged>(_onQueryChanged);
  }

  final QuranRepository _repository;

  Future<void> _onStarted(
    QuranListStarted event,
    Emitter<QuranListState> emit,
  ) async {
    emit(state.copyWith(status: QuranListStatus.loading));
    try {
      final surahs = await _repository.getSurahs();
      emit(
        state.copyWith(
          status: QuranListStatus.success,
          surahs: surahs,
          visibleSurahs: _filter(surahs, state.query),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onQueryChanged(
    QuranListQueryChanged event,
    Emitter<QuranListState> emit,
  ) {
    emit(
      state.copyWith(
        query: event.query,
        visibleSurahs: _filter(state.surahs, event.query),
      ),
    );
  }

  List<QuranSurah> _filter(List<QuranSurah> surahs, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return surahs;
    }

    return surahs.where((surah) {
      return surah.number.toString() == normalized ||
          surah.englishName.toLowerCase().contains(normalized) ||
          surah.arabicName.contains(normalized);
    }).toList();
  }
}
