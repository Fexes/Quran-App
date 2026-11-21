import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/search/local_search_revision.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/entities/search_query_intent.dart';
import '../../domain/repositories/offline_search_repository.dart';
import '../sources/app_search_sources.dart';
import '../sources/live_search_source.dart';

/// Coordinates persistent retrieval with the app's current local content.
/// Mutation and resume hooks keep it current; queries wait for removals/edits.
class AppSearchRepository
    with WidgetsBindingObserver
    implements OfflineSearchRepository {
  AppSearchRepository({
    required MutableOfflineSearchRepository engine,
    required AppSearchSourceRegistry sources,
    required LiveSearchSource live,
  }) : _engine = engine,
       _sources = sources,
       _live = live {
    LocalSearchRevision.changes.addListener(_onContentChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  final MutableOfflineSearchRepository _engine;
  final AppSearchSourceRegistry _sources;
  final LiveSearchSource _live;
  final _indexed = <String, String>{};
  Future<void>? _synchronizing;
  Future<void>? _restoringRevisions;
  bool _revisionsLoaded = false;
  Timer? _debounce;
  bool _started = false;
  bool _disposed = false;
  bool _foreground = true;

  @override
  Future<void> warmUp() async {
    if (_disposed) throw StateError('Search is closed');
    _started = true;
    await _engine.warmUp();
    await (_restoringRevisions ??= _restoreRevisions().catchError((
      Object error,
    ) {
      _restoringRevisions = null;
      throw error;
    }));
    await _synchronize();
    await _engine.setIndexingEnabled(_foreground);
  }

  Future<void> _restoreRevisions() async {
    _indexed.addAll(await _engine.completedSourceRevisions());
    _revisionsLoaded = true;
  }

  Future<void> _synchronize() async {
    // Recheck the shared future after each await: multiple search callers may
    // all be waiting for the same snapshot. Only one may start its successor.
    for (var attempt = 0; attempt < 2; attempt++) {
      if (_disposed) throw StateError('Search is closed');
      final active = _synchronizing;
      if (active != null) {
        await active;
      } else {
        final pending = _syncChangedSources();
        _synchronizing = pending;
        try {
          await pending;
        } finally {
          if (identical(pending, _synchronizing)) _synchronizing = null;
        }
      }
      if (!_hasChanges()) return;
    }
  }

  bool _hasChanges() =>
      _sources.sources.any((source) => _indexed[source.id] != source.revision);

  Future<void> _syncChangedSources() async {
    if (!_hasChanges()) return;
    await _engine.setIndexingEnabled(false);
    try {
      for (final source in _sources.sources) {
        if (_disposed) return;
        final revision = source.revision;
        if (_indexed[source.id] == revision) continue;
        await _engine.synchronizeSource(
          source.id,
          revision,
          source.documents(),
        );
        _indexed[source.id] = revision;
      }
    } finally {
      await _engine.setIndexingEnabled(_foreground && !_disposed);
    }
  }

  void _onContentChanged() {
    if (!_started || !_revisionsLoaded || _disposed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      // Failure is retried and surfaced by the next explicit search.
      unawaited(_synchronize().catchError((Object _) {}));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started || _disposed) return;
    final foreground = state == AppLifecycleState.resumed;
    _foreground = foreground;
    unawaited(
      _engine
          .setIndexingEnabled(foreground && _synchronizing == null)
          .catchError((Object _) {}),
    );
    if (foreground) _onContentChanged();
  }

  @override
  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  }) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    if (query.trim().isEmpty) {
      return const OfflineSearchResponse(
        hits: [],
        timingsMs: {},
        semanticAvailable: false,
      );
    }
    await warmUp();
    final intent = SearchQueryIntent.analyze(query);
    final liveIntent =
        filter == OfflineSearchFilter.all &&
        intent.filter == OfflineSearchFilter.all &&
        LiveSearchSource.supportsQuery(query);
    final effective = filter != OfflineSearchFilter.all
        ? filter
        : liveIntent
        ? OfflineSearchFilter.timings
        : intent.filter;
    final sourceKinds = filter == OfflineSearchFilter.all && !liveIntent
        ? intent.sourceKinds
        : const <String>{};
    // Leave room for source-only questions after excluding app/personal hits.
    final candidateLimit = sourceKinds.isEmpty
        ? limit
        : (limit * 3).clamp(40, 100);
    OfflineSearchResponse? response;
    var revision = LocalSearchRevision.value;
    for (var attempt = 0; attempt < 3; attempt++) {
      await _synchronize();
      revision = LocalSearchRevision.value;
      response = await _engine.search(
        query,
        filter: effective,
        limit: candidateLimit,
      );
      if (revision == LocalSearchRevision.value && !_hasChanges()) break;
      response = null;
    }
    if (response == null) {
      throw StateError('Your content is still updating. Please search again.');
    }
    String? liveWarning;
    var live = <OfflineSearchHit>[];
    try {
      live = await _live.search(query, effective);
    } catch (_) {
      liveWarning =
          'Live times are unavailable. Check your saved location and prayer settings.';
    }
    if (revision != LocalSearchRevision.value || _hasChanges()) {
      throw StateError(
        'Your content changed during search. Please search again.',
      );
    }
    final seen = <String>{};
    final hits = [
      for (final hit in [...live, ...response.hits])
        if ((sourceKinds.isEmpty || sourceKinds.contains(hit.passage.kind)) &&
            seen.add(hit.passage.canonicalId))
          hit,
    ].take(limit).toList(growable: false);
    return OfflineSearchResponse(
      hits: hits,
      timingsMs: response.timingsMs,
      semanticAvailable: response.semanticAvailable,
      pendingDocuments: response.pendingDocuments,
      warning: [response.warning, liveWarning]
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .join('\n')
          .nullIfEmpty,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _debounce?.cancel();
    LocalSearchRevision.changes.removeListener(_onContentChanged);
    WidgetsBinding.instance.removeObserver(this);
    try {
      await _synchronizing;
    } catch (_) {}
    await _engine.dispose();
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
