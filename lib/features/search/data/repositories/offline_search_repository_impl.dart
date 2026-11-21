import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/search/offline_search_normalizer.dart';
import '../../../../core/search/search_query_terms.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/entities/search_document.dart';
import '../../domain/repositories/offline_search_repository.dart';
import '../services/offline_search_database.dart';
import '../services/offline_search_overlay.dart';

/// An app-scoped worker owns keyword/reference databases and local content updates.
class LocalOfflineSearchRepository implements MutableOfflineSearchRepository {
  LocalOfflineSearchRepository({
    this.config = const OfflineSearchConfig(),
    Map<String, String>? bundledFiles,
    this.overlayPath,
  }) : _bundledFiles = bundledFiles == null
           ? null
           : Map.unmodifiable(bundledFiles);

  final OfflineSearchConfig config;
  final String? overlayPath;
  final Map<String, String>? _bundledFiles;
  Future<SendPort>? _workerFuture;
  Isolate? _isolate;
  ReceivePort? _events;
  final _pending = <int, Completer<OfflineSearchResponse>>{};
  final _syncPending = <int, Completer<void>>{};
  final _revisionPending = <int, Completer<Map<String, String>>>{};
  Future<void> _syncTail = Future.value();
  int _nextId = 0;
  bool _disposed = false;
  Completer<SendPort>? _ready;
  Completer<void>? _stopped;

  @override
  Future<void> warmUp() async {
    if (_disposed) throw StateError('Offline search has been closed.');
    await _getWorker();
  }

  @override
  Future<void> setIndexingEnabled(bool enabled) async {
    // Keyword changes are committed by synchronizeSource; no model jobs run.
  }

  @override
  Future<Map<String, String>> completedSourceRevisions() async {
    final worker = await _getWorker();
    if (_disposed) throw StateError('Search is closed.');
    final id = ++_nextId;
    final pending = Completer<Map<String, String>>();
    _revisionPending[id] = pending;
    worker.send(_RevisionRequest(id));
    return pending.future;
  }

  @override
  Future<void> synchronizeSource(
    String sourceId,
    String revision,
    Stream<List<SearchDocument>> batches,
  ) {
    final operation = _syncTail.then((_) async {
      final worker = await _getWorker();
      if (_disposed) throw StateError('Search is closed.');
      final snapshot = '$revision:${DateTime.now().microsecondsSinceEpoch}';
      Future<void> send(List<SearchDocument> documents, bool finish) async {
        final id = ++_nextId;
        final pending = Completer<void>();
        _syncPending[id] = pending;
        worker.send(
          _SyncRequest(id, sourceId, snapshot, documents, finish, revision),
        );
        await pending.future;
      }

      await for (final batch in batches) {
        if (_disposed) throw StateError('Search is closed.');
        for (var start = 0; start < batch.length; start += 32) {
          await send(
            batch.sublist(start, (start + 32).clamp(0, batch.length)),
            false,
          );
        }
      }
      await send(const [], true);
    });
    _syncTail = operation.catchError((Object _) {});
    return operation;
  }

  Future<SendPort> _getWorker() => _workerFuture ??= _startWorker().catchError((
    Object error,
    StackTrace stack,
  ) {
    _workerFuture = null;
    Error.throwWithStackTrace(error, stack);
  });

  Future<SendPort> _startWorker() async {
    final files = _bundledFiles ?? await _prepareFiles();
    final privatePath =
        overlayPath ??
        (_bundledFiles != null
            ? '${(await Directory.systemTemp.createTemp('quran-search-')).path}/overlay.sqlite'
            : '${(await getApplicationSupportDirectory()).path}/search_overlay.sqlite');
    await File(privatePath).parent.create(recursive: true);
    if (_disposed) throw StateError('Offline search has been closed.');
    final ready = Completer<SendPort>();
    _ready = ready;
    final events = ReceivePort();
    _events = events;
    events.listen((message) {
      if (message is SendPort) {
        if (!ready.isCompleted) ready.complete(message);
      } else if (message is _RevisionReply) {
        _revisionPending.remove(message.id)?.complete(message.revisions);
      } else if (message is _SyncReply) {
        final pending = _syncPending.remove(message.id);
        if (message.error != null) {
          pending?.completeError(StateError(message.error!));
        } else {
          pending?.complete();
        }
      } else if (message is _SearchReply) {
        final pending = _pending.remove(message.id);
        if (pending == null) return;
        if (message.response case final response?) {
          pending.complete(response);
        } else {
          pending.completeError(StateError(message.error ?? 'Search failed.'));
        }
      } else if (message is _WorkerStopped) {
        if (!(_stopped?.isCompleted ?? true)) _stopped!.complete();
      } else if (message is _WorkerFailure) {
        _workerFailed(ready, message.message);
      } else if (message is List) {
        _workerFailed(ready, 'Offline search stopped unexpectedly.');
      } else if (message == null && !_disposed) {
        _workerFailed(ready, 'Offline search stopped unexpectedly.');
      }
    });
    try {
      _isolate = await Isolate.spawn(
        _searchWorker,
        _WorkerStart(events.sendPort, files, config, privatePath),
        onError: events.sendPort,
        onExit: events.sendPort,
        errorsAreFatal: true,
        debugName: 'offline-quran-hadith-search',
      );
      return await ready.future.timeout(const Duration(seconds: 60));
    } catch (error) {
      events.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _events = null;
      _workerFuture = null;
      rethrow;
    }
  }

  void _workerFailed(Completer<SendPort> ready, String message) {
    final error = StateError(message);
    if (!ready.isCompleted) ready.completeError(error);
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
    for (final pending in _syncPending.values) {
      pending.completeError(error);
    }
    _syncPending.clear();
    for (final pending in _revisionPending.values) {
      pending.completeError(error);
    }
    _revisionPending.clear();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _events?.close();
    _events = null;
    _workerFuture = null;
  }

  @override
  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  }) async {
    if (_disposed) throw StateError('Offline search has been closed.');
    if (limit < 1 || limit > 100) throw ArgumentError.value(limit, 'limit');
    final normalized = OfflineSearchNormalizer.semantic(query);
    if (normalized.runes.length > 4000) {
      throw ArgumentError(
        'Search queries must be shorter than 4,000 characters.',
      );
    }
    if (_pending.length >= 4) {
      throw StateError('Offline search is busy. Please try again.');
    }
    if (normalized.isEmpty) {
      return const OfflineSearchResponse(
        hits: [],
        timingsMs: {},
        semanticAvailable: false,
      );
    }
    final worker = await _getWorker();
    if (_disposed) throw StateError('Offline search has been closed.');
    if (_pending.length >= 4) {
      throw StateError('Offline search is busy. Please try again.');
    }
    final id = ++_nextId;
    final completer = Completer<OfflineSearchResponse>();
    _pending[id] = completer;
    worker.send(_SearchRequest(id, normalized, filter, limit));
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final completer in _pending.values) {
      completer.completeError(StateError('Offline search has been closed.'));
    }
    _pending.clear();
    for (final pending in _syncPending.values) {
      pending.completeError(StateError('Search is closed.'));
    }
    _syncPending.clear();
    for (final pending in _revisionPending.values) {
      pending.completeError(StateError('Search is closed.'));
    }
    _revisionPending.clear();
    final future = _workerFuture;
    if (future == null) return;
    _stopped = Completer<void>();
    Future<void> stop() async {
      final worker = await future;
      worker.send(const _StopWorker());
      await _stopped!.future;
    }

    try {
      await stop().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Bound shutdown even if startup or the database is unresponsive.
    } finally {
      _isolate?.kill(priority: Isolate.immediate);
      if (_ready case final ready? when !ready.isCompleted) {
        ready.completeError(StateError('Offline search has been closed.'));
      }
      _events?.close();
    }
    _workerFuture = null;
    _isolate = null;
    _events = null;
  }
}

class _WorkerStart {
  const _WorkerStart(this.reply, this.files, this.config, this.overlayPath);
  final SendPort reply;
  final Map<String, String> files;
  final OfflineSearchConfig config;
  final String overlayPath;
}

class _SyncRequest {
  const _SyncRequest(
    this.id,
    this.source,
    this.revision,
    this.documents,
    this.finish,
    this.sourceRevision,
  );
  final int id;
  final String source;
  final String revision;
  final List<SearchDocument> documents;
  final bool finish;
  final String sourceRevision;
}

class _RevisionRequest {
  const _RevisionRequest(this.id);
  final int id;
}

class _RevisionReply {
  const _RevisionReply(this.id, this.revisions);
  final int id;
  final Map<String, String> revisions;
}

class _SyncReply {
  const _SyncReply(this.id, [this.error]);
  final int id;
  final String? error;
}

class _SearchRequest {
  const _SearchRequest(this.id, this.query, this.filter, this.limit);
  final int id;
  final String query;
  final OfflineSearchFilter filter;
  final int limit;
}

class _SearchReply {
  const _SearchReply(this.id, {this.response, this.error});
  final int id;
  final OfflineSearchResponse? response;
  final String? error;
}

class _WorkerFailure {
  const _WorkerFailure(this.message);
  final String message;
}

class _StopWorker {
  const _StopWorker();
}

class _WorkerStopped {
  const _WorkerStopped();
}

Future<void> _searchWorker(_WorkerStart start) async {
  OfflineSearchDatabase? database;
  OfflineSearchOverlay? overlay;
  final receive = ReceivePort();
  String? startupError;
  try {
    final manifest =
        jsonDecode(await File(start.files['manifest.json']!).readAsString())
            as Map<String, dynamic>;
    if (manifest['retrieval_mode'] != 'keyword' ||
        manifest['schema_version'] != 3 ||
        manifest['normalization_version'] != 1) {
      throw const FormatException('Unsupported keyword search package.');
    }
    final artifacts = manifest['artifacts'] as Map<String, dynamic>;
    final path = start.files['search.sqlite']!;
    await _verifyArtifact(
      path,
      Map<String, dynamic>.from(artifacts['search.sqlite'] as Map),
    );
    database = OfflineSearchDatabase(path, config: start.config);
    if (database.metadata['schema_version'] != '3' ||
        database.metadata['retrieval_mode'] != 'keyword' ||
        database.metadata['normalization_version'] != '1') {
      throw const FormatException(
        'Search index and package versions do not match.',
      );
    }
    overlay = OfflineSearchOverlay(start.overlayPath, 'keyword-v1');
    start.reply.send(receive.sendPort);
    await for (final request in receive) {
      if (request is _StopWorker) break;
      if (request is _RevisionRequest) {
        start.reply.send(
          _RevisionReply(request.id, overlay.completedSourceRevisions),
        );
        continue;
      }
      if (request is _SyncRequest) {
        try {
          overlay.upsert(request.source, request.revision, request.documents);
          if (request.finish) {
            overlay.finish(
              request.source,
              request.revision,
              completedRevision: request.sourceRevision,
            );
          }
          start.reply.send(_SyncReply(request.id));
        } catch (_) {
          start.reply.send(
            _SyncReply(request.id, 'Local content could not be indexed.'),
          );
        }
        continue;
      }
      if (request is! _SearchRequest) continue;
      try {
        final total = Stopwatch()..start();
        final step = Stopwatch()..start();
        final exact = database.exactReferences(request.query, request.filter);
        final allExact = request.filter == OfflineSearchFilter.all
            ? exact
            : database.exactReferences(request.query, OfflineSearchFilter.all);
        final originals = database.retrieve([
          for (final id in allExact) RankedPassage(id, 1),
        ], limit: 100);
        final localExact = overlay.exactReferences(
          request.query,
          request.filter,
          canonicalIds: originals.map((hit) => hit.passage.canonicalId),
        );
        if (exact.isNotEmpty ||
            localExact.isNotEmpty ||
            database.looksLikeCanonicalReference(request.query)) {
          final exactPassages = <String, OfflineSearchPassage>{
            for (final hit in database.retrieve([
              for (final id in exact) RankedPassage(id, 1),
            ], limit: request.limit))
              hit.passage.canonicalId: hit.passage,
          };
          for (final passage in localExact) {
            final original = originals
                .where((hit) => hit.passage.canonicalId == passage.canonicalId)
                .firstOrNull;
            exactPassages[passage.canonicalId] = original == null
                ? passage
                : _withOriginal(passage, original.passage);
          }
          start.reply.send(
            _SearchReply(
              request.id,
              response: OfflineSearchResponse(
                hits: _enrichHits([
                  for (final passage in exactPassages.values.take(
                    request.limit,
                  ))
                    OfflineSearchHit(passage: passage, score: 1),
                ], overlay),
                timingsMs: {
                  'reference': step.elapsedMilliseconds,
                  'total': total.elapsedMilliseconds,
                },
                semanticAvailable: false,
                warning: exactPassages.isEmpty
                    ? 'This reference is not available in the selected sources.'
                    : null,
              ),
            ),
          );
          continue;
        }
        final analysis = SearchQueryTerms.analyze(request.query);
        final keyword = database.keywordScores(request.query, request.filter);
        final localKeyword = overlay.keywordScores(
          request.query,
          request.filter,
          start.config.candidateLimit,
        );
        final keywordMs = step.elapsedMilliseconds;
        step
          ..reset()
          ..start();
        final hits = _federatedResults(
          database,
          overlay,
          analysis,
          keyword,
          localKeyword,
          start.config,
          request.limit,
        );
        start.reply.send(
          _SearchReply(
            request.id,
            response: OfflineSearchResponse(
              hits: hits,
              semanticAvailable: false,
              timingsMs: {
                'keyword': keywordMs,
                'ranking': step.elapsedMilliseconds,
                'total': total.elapsedMilliseconds,
              },
            ),
          ),
        );
      } catch (_) {
        start.reply.send(
          _SearchReply(request.id, error: 'Offline search could not finish.'),
        );
      }
    }
  } catch (_) {
    startupError = 'The keyword search package could not be opened.';
  } finally {
    database?.dispose();
    overlay?.dispose();
    receive.close();
  }
  if (startupError case final error?) {
    start.reply.send(_WorkerFailure(error));
  } else {
    start.reply.send(const _WorkerStopped());
  }
  Isolate.exit();
}

List<OfflineSearchHit> _federatedResults(
  OfflineSearchDatabase database,
  OfflineSearchOverlay overlay,
  SearchQueryAnalysis analysis,
  Map<int, double> keyword,
  Map<int, double> localKeyword,
  OfflineSearchConfig config,
  int limit,
) {
  final baseIds = keyword.keys.toSet();
  // Preserve the database-ID association without relying on retrieval row order.
  final baseById = <int, OfflineSearchPassage>{};
  final retrieved = database.retrieve([
    for (final id in baseIds) RankedPassage(id, 0),
  ], limit: baseIds.length);
  final orderedIds = baseIds.toList();
  for (var i = 0; i < retrieved.length; i++) {
    baseById[orderedIds[i]] = retrieved[i].passage;
  }
  final local = overlay.passages(localKeyword.keys);
  final passages = {
    for (final hit in retrieved) hit.passage.canonicalId: hit.passage,
  };
  final baseEvidence = {
    for (final entry in baseById.entries)
      entry.key: keyword.containsKey(entry.key)
          ? _queryEvidence(analysis, entry.value)
          : const SearchQueryEvidence(0, 0, 0),
  };
  final localEvidence = {
    for (final entry in local.entries)
      entry.key: localKeyword.containsKey(entry.key)
          ? _queryEvidence(analysis, entry.value)
          : const SearchQueryEvidence(0, 0, 0),
  };
  final baseCoverage = {
    for (final entry in baseEvidence.entries) entry.key: entry.value.coverage,
  };
  final localCoverage = {
    for (final entry in localEvidence.entries) entry.key: entry.value.coverage,
  };
  final surfaceEvidence = {
    for (final entry in baseById.entries)
      entry.value.canonicalId: baseEvidence[entry.key]!,
  };
  final surfaceScores = {
    for (final entry in baseById.entries)
      entry.value.canonicalId: baseCoverage[entry.key]!,
  };
  for (final entry in local.entries) {
    final passage = entry.value;
    final existing = passages[passage.canonicalId];
    final coverage = localCoverage[entry.key]!;
    if (existing == null) {
      passages[passage.canonicalId] = passage;
      surfaceScores[passage.canonicalId] = coverage;
      surfaceEvidence[passage.canonicalId] = localEvidence[entry.key]!;
    } else if (coverage > surfaceScores[passage.canonicalId]!) {
      passages[passage.canonicalId] = _withOriginal(passage, existing);
      surfaceScores[passage.canonicalId] = coverage;
      surfaceEvidence[passage.canonicalId] = localEvidence[entry.key]!;
    } else {
      passages[passage.canonicalId] = _mergePassages(existing, [passage]);
    }
  }
  final keywordRanks = <String, double>{};
  void add(
    Map<int, double> scores,
    Map<int, OfflineSearchPassage> documents,
    Map<String, double> target, {
    Map<int, double>? lexical,
    Map<int, SearchQueryEvidence>? evidence,
  }) {
    for (final entry in scores.entries) {
      final passage = documents[entry.key];
      if (passage == null) continue;
      if (lexical != null && lexical[entry.key]! <= 0) continue;
      // FTS statistics differ between the shipped and personal databases.
      // Rank lexical coverage consistently across both, then use local BM25.
      final score = lexical != null
          ? lexical[entry.key]! +
                (evidence?[entry.key]?.compactness ?? 0) * 0.02 +
                entry.value / (entry.value + 1) * 0.01
          : entry.value;
      final old = target[passage.canonicalId];
      if (old == null || score > old) target[passage.canonicalId] = score;
    }
  }

  add(
    keyword,
    baseById,
    keywordRanks,
    lexical: baseCoverage,
    evidence: baseEvidence,
  );
  add(
    localKeyword,
    local,
    keywordRanks,
    lexical: localCoverage,
    evidence: localEvidence,
  );
  List<String> ranked(Map<String, double> scores) {
    final ids = scores.keys.toList()
      ..sort((a, b) {
        final order = scores[b]!.compareTo(scores[a]!);
        return order == 0 ? a.compareTo(b) : order;
      });
    return ids.take(config.candidateLimit).toList();
  }

  final fused = <String, double>{};
  void fuse(List<String> ids, double weight) {
    for (var i = 0; i < ids.length; i++) {
      fused.update(
        ids[i],
        (v) => v + weight / (config.rrfConstant + i + 1),
        ifAbsent: () => weight / (config.rrfConstant + i + 1),
      );
    }
  }

  fuse(ranked(keywordRanks), config.keywordWeight);
  // Downweight keyword candidates that miss the question's actual topic.
  // Coverage and compactness remain comparable across both keyword indexes.
  if (analysis.conceptIds.isNotEmpty) {
    for (final id in fused.keys.toList()) {
      final coverage = surfaceScores[id] ?? 0;
      var factor = 0.55 + 0.45 * coverage;
      final evidence = surfaceEvidence[id];
      if (analysis.isQuestion &&
          analysis.conceptIds.length >= 2 &&
          evidence != null) {
        factor *=
            0.3 + 0.7 * evidence.conceptCoverage * evidence.conceptCoverage;
        factor *= 0.65 + 0.35 * evidence.compactness;
      }
      fused[id] = fused[id]! * factor;
    }
  }
  final ids = fused.keys.toList()
    ..sort((a, b) {
      final score = fused[b]!.compareTo(fused[a]!);
      return score == 0 ? a.compareTo(b) : score;
    });
  final selected = ids.take(limit).toList();
  final originals = database.canonicalPassages(selected);
  return _enrichHits([
    for (final id in selected)
      OfflineSearchHit(
        passage: originals[id] == null
            ? passages[id]!
            : _withOriginal(passages[id]!, originals[id]!),
        score: fused[id]!,
      ),
  ], overlay);
}

SearchQueryEvidence _queryEvidence(
  SearchQueryAnalysis analysis,
  OfflineSearchPassage passage,
) {
  return analysis.evidence(
    '${passage.kind == 'azkar' ? 'supplication ' : ''}'
    '${passage.title} ${passage.arabic} ${passage.body} '
    '${passage.translations.map((t) => t.text).join(' ')}',
  );
}

List<OfflineSearchHit> _enrichHits(
  List<OfflineSearchHit> hits,
  OfflineSearchOverlay overlay,
) => [
  for (final hit in hits)
    OfflineSearchHit(
      passage: _mergePassages(
        hit.passage,
        overlay.variants(hit.passage.canonicalId),
      ),
      score: hit.score,
    ),
];

OfflineSearchPassage _withOriginal(
  OfflineSearchPassage match,
  OfflineSearchPassage original,
) {
  final combined = _mergePassages(original, [match]);
  return OfflineSearchPassage(
    canonicalId: original.canonicalId,
    kind: original.kind,
    reference: original.reference,
    title: original.title,
    arabic: original.arabic,
    translations: combined.translations,
    grades: original.grades,
    surahNumber: original.surahNumber,
    ayahNumber: original.ayahNumber,
    itemId: original.itemId,
    body: match.body.isEmpty ? original.body : match.body,
    route: match.route.isEmpty ? original.route : match.route,
    language: match.language,
    sourceLabel: match.sourceLabel.isEmpty
        ? original.sourceLabel
        : match.sourceLabel,
    isUserContent: original.isUserContent,
    metadata: {...original.metadata, ...match.metadata},
  );
}

OfflineSearchPassage _mergePassages(
  OfflineSearchPassage base,
  List<OfflineSearchPassage> variants,
) {
  if (variants.isEmpty) return base;
  final translations = <String, OfflineSearchTranslation>{
    for (final t in base.translations) '${t.language}:${t.source}': t,
    for (final p in variants)
      for (final t in p.translations) '${t.language}:${t.source}': t,
  };
  return OfflineSearchPassage(
    canonicalId: base.canonicalId,
    kind: base.kind,
    reference: base.reference,
    title: base.title,
    arabic: base.arabic,
    translations: translations.values.toList(),
    grades: base.grades,
    surahNumber: base.surahNumber,
    ayahNumber: base.ayahNumber,
    itemId: base.itemId,
    body: base.body,
    route: base.route,
    language: base.language,
    sourceLabel: base.sourceLabel,
    isUserContent: base.isUserContent,
    metadata: base.metadata,
  );
}

Future<void> _verifyArtifact(
  String path,
  Map<String, dynamic> specification,
) async {
  final hash = specification['sha256'] as String;
  final size = specification['bytes'] as int;
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash) ||
      size < 1 ||
      size > 1024 * 1024 * 1024) {
    throw const FormatException('Invalid offline package manifest.');
  }
  final file = File(path);
  if (await file.length() != size ||
      (await sha256.bind(file.openRead()).first).toString() != hash) {
    throw const FormatException('Corrupt offline package asset.');
  }
}

const _assetNames = ['manifest.json', 'search.sqlite'];

Future<Map<String, String>> _prepareFiles() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final files = await const MethodChannel('quran/offline_search_assets')
        .invokeMapMethod<String, String>('prepare')
        .timeout(const Duration(seconds: 60));
    if (files == null || _assetNames.any((name) => !files.containsKey(name))) {
      throw StateError('Missing native offline search assets.');
    }
    return files;
  }
  // Desktop preview fallback. Mobile uses native file paths, avoiding large
  // database transfers through Flutter's UI isolate and platform asset messages.
  final directory = await getApplicationSupportDirectory();
  final files = <String, String>{};
  final cache = Directory('${directory.path}/keyword_search_desktop');
  await cache.create(recursive: true);
  for (final name in _assetNames) {
    final bytes = await rootBundle.load('assets/keyword_search/$name');
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final path = '${cache.path}/$name';
    await Isolate.run(() async => File(path).writeAsBytes(data, flush: true));
    files[name] = path;
  }
  final oldCache = Directory('${directory.path}/offline_search_desktop');
  try {
    if (await oldCache.exists()) await oldCache.delete(recursive: true);
  } on FileSystemException {
    // Cache cleanup is optional and must not prevent keyword search.
  }
  return files;
}
