import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../search/domain/repositories/deep_search_repository.dart';
import 'quran_search_event.dart';
import 'quran_search_state.dart';

class QuranSearchBloc extends Bloc<QuranSearchEvent, QuranSearchState> {
  QuranSearchBloc({required DeepSearchRepository repository})
    : _repository = repository,
      super(const QuranSearchState.initial()) {
    on<QuranSearchSubmitted>(_onSubmitted);
    on<QuranSearchQueryChanged>(_onQueryChanged);
    on<QuranSearchWarmUpRequested>(_onWarmUpRequested);
    on<QuranSearchCategorySelected>(_onCategorySelected);
    on<QuranSearchCleared>(_onCleared);
  }

  final DeepSearchRepository _repository;
  Timer? _debounce;
  int _requestRevision = 0;

  @override
  Future<void> close() async {
    _requestRevision++;
    _debounce?.cancel();
    if (_repository case final DisposableDeepSearchRepository disposable) {
      await disposable.dispose();
    }
    await super.close();
  }

  void _onQueryChanged(
    QuranSearchQueryChanged event,
    Emitter<QuranSearchState> emit,
  ) {
    _debounce?.cancel();
    _requestRevision++;
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const QuranSearchState.initial());
      return;
    }
    emit(
      state.copyWith(
        query: query,
        status: state.sections.isEmpty
            ? QuranSearchStatus.initial
            : state.status,
        clearSelectedCategory: true,
      ),
    );
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (!isClosed) {
        add(QuranSearchSubmitted(query));
      }
    });
  }

  void _onWarmUpRequested(
    QuranSearchWarmUpRequested event,
    Emitter<QuranSearchState> emit,
  ) {
    unawaited(_repository.warmUp().catchError((Object _) {}));
  }

  Future<void> _onSubmitted(
    QuranSearchSubmitted event,
    Emitter<QuranSearchState> emit,
  ) async {
    _debounce?.cancel();
    final revision = ++_requestRevision;
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const QuranSearchState.initial());
      return;
    }

    emit(
      state.copyWith(
        status: QuranSearchStatus.loading,
        query: query,
        sections: const [],
        clearSelectedCategory: true,
      ),
    );

    try {
      final sections = await _repository.search(query, limitPerCategory: 20);
      if (emit.isDone || revision != _requestRevision) return;
      emit(
        QuranSearchState(
          status: sections.isEmpty
              ? QuranSearchStatus.empty
              : QuranSearchStatus.success,
          query: query,
          sections: sections,
        ),
      );
    } catch (error) {
      if (emit.isDone || revision != _requestRevision) return;
      emit(
        state.copyWith(
          status: QuranSearchStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onCategorySelected(
    QuranSearchCategorySelected event,
    Emitter<QuranSearchState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        clearSelectedCategory: event.category == null,
      ),
    );
  }

  void _onCleared(QuranSearchCleared event, Emitter<QuranSearchState> emit) {
    _requestRevision++;
    _debounce?.cancel();
    emit(const QuranSearchState.initial());
  }
}
