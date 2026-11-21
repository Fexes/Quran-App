import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/search/local_search_revision.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/repositories/offline_search_repository.dart';

enum OfflineSearchStatus { initial, loading, success, empty, failure }

class OfflineSearchState {
  const OfflineSearchState({
    this.status = OfflineSearchStatus.initial,
    this.query = '',
    this.filter = OfflineSearchFilter.all,
    this.response,
    this.errorMessage,
  });

  final OfflineSearchStatus status;
  final String query;
  final OfflineSearchFilter filter;
  final OfflineSearchResponse? response;
  final String? errorMessage;
}

class OfflineSearchCubit extends Cubit<OfflineSearchState> {
  OfflineSearchCubit({
    required OfflineSearchRepository repository,
    OfflineSearchFilter initialFilter = OfflineSearchFilter.all,
  }) : _repository = repository,
       super(OfflineSearchState(filter: initialFilter)) {
    LocalSearchRevision.changes.addListener(_contentChanged);
  }

  final OfflineSearchRepository _repository;
  int _revision = 0;
  Timer? _refreshTimer;
  Timer? _liveRefreshTimer;
  bool _refreshPending = false;

  Future<void> submit(String query, {OfflineSearchFilter? filter}) =>
      _search(query, filter ?? state.filter);

  void _contentChanged() {
    if (isClosed || state.query.isEmpty) return;
    _refreshPending = true;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(refreshSubmittedQuery());
    });
  }

  Future<void> refreshSubmittedQuery() async {
    if (isClosed || state.query.isEmpty) return;
    if (state.status == OfflineSearchStatus.loading) {
      _refreshPending = true;
      return;
    }
    await _search(state.query, state.filter);
  }

  Future<void> _search(String query, OfflineSearchFilter filter) async {
    if (isClosed) return;
    _refreshTimer?.cancel();
    _liveRefreshTimer?.cancel();
    _refreshPending = false;
    final normalized = query.trim();
    final revision = ++_revision;
    if (normalized.isEmpty) {
      emit(OfflineSearchState(filter: filter));
      return;
    }

    emit(
      OfflineSearchState(
        status: OfflineSearchStatus.loading,
        query: normalized,
        filter: filter,
      ),
    );
    try {
      final response = await _repository.search(normalized, filter: filter);
      if (isClosed || revision != _revision) return;
      emit(
        OfflineSearchState(
          status: response.hits.isEmpty
              ? OfflineSearchStatus.empty
              : OfflineSearchStatus.success,
          query: normalized,
          filter: filter,
          response: response,
        ),
      );
      _scheduleLiveRefresh(response);
    } catch (_) {
      if (isClosed || revision != _revision) return;
      emit(
        OfflineSearchState(
          status: OfflineSearchStatus.failure,
          query: normalized,
          filter: filter,
          errorMessage: 'Offline search could not finish. Please try again.',
        ),
      );
    } finally {
      if (!isClosed && revision == _revision && _refreshPending) {
        _contentChanged();
      }
    }
  }

  void _scheduleLiveRefresh(OfflineSearchResponse response) {
    final now = DateTime.now();
    DateTime? earliest;
    for (final hit in response.hits) {
      if (!hit.passage.canonicalId.startsWith('live:')) continue;
      final raw = hit.passage.metadata['refreshAt'];
      final deadline = raw == null ? null : DateTime.tryParse(raw);
      if (deadline != null &&
          (earliest == null || deadline.isBefore(earliest))) {
        earliest = deadline;
      }
    }
    if (earliest == null) return;
    final remaining = earliest.difference(now) + const Duration(seconds: 1);
    _liveRefreshTimer = Timer(
      remaining < const Duration(seconds: 5)
          ? const Duration(seconds: 5)
          : remaining,
      () => unawaited(refreshSubmittedQuery()),
    );
  }

  Future<void> selectFilter(OfflineSearchFilter filter) async {
    if (state.filter == filter) return;
    await _search(state.query, filter);
  }

  void clear() {
    _revision++;
    _refreshTimer?.cancel();
    _liveRefreshTimer?.cancel();
    _refreshPending = false;
    emit(OfflineSearchState(filter: state.filter));
  }

  @override
  Future<void> close() {
    _revision++;
    LocalSearchRevision.changes.removeListener(_contentChanged);
    _refreshTimer?.cancel();
    _liveRefreshTimer?.cancel();
    return super.close();
  }
}
