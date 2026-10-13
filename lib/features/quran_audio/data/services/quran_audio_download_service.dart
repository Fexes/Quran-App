import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import '../../domain/entities/quran_audio_download_item.dart';
import '../stores/quran_audio_download_store.dart';
import 'quran_audio_storage_policy.dart';

abstract interface class QuranAudioDownloadServicePort {
  Stream<void> get updates;

  Future<void> enqueueItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  });

  Future<void> pauseItems(Iterable<QuranAudioDownloadItem> items);

  Future<void> resumeItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  });

  Future<void> cancelItems(Iterable<QuranAudioDownloadItem> items);

  Future<void> retryItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  });
}

class QuranAudioDownloadService implements QuranAudioDownloadServicePort {
  QuranAudioDownloadService({
    required QuranAudioDownloadStore store,
    FileDownloader? downloader,
  }) : _store = store,
       _downloader = downloader ?? FileDownloader();

  static const group = 'quran_audio';

  final QuranAudioDownloadStore _store;
  final FileDownloader _downloader;
  final StreamController<void> _updatesController =
      StreamController<void>.broadcast();
  bool _initialized = false;
  Future<void>? _initialization;
  final Map<String, Future<void>> _itemUpdates = {};

  @override
  Stream<void> get updates => _updatesController.stream;

  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initialization ??= _initialize().whenComplete(
      () => _initialization = null,
    );
  }

  Future<void> _initialize() async {
    _downloader.registerCallbacks(
      group: group,
      taskStatusCallback: (update) => unawaited(_handleStatus(update)),
      taskProgressCallback: _handleProgress,
    );
    await _downloader.start();
    _initialized = true;
  }

  @override
  Future<void> enqueueItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {
    await initialize();
    final now = DateTime.now().toUtc();
    final queuedItems = <QuranAudioDownloadItem>[];
    final tasks = <DownloadTask>[];
    for (final item in items) {
      final existing = _store.itemById(item.id) ?? item;
      if (existing.status == QuranAudioDownloadStatus.downloaded ||
          existing.status == QuranAudioDownloadStatus.queued ||
          existing.status == QuranAudioDownloadStatus.downloading) {
        continue;
      }
      if (existing.status == QuranAudioDownloadStatus.paused) {
        final task = _taskForItem(existing, requiresWiFi: requiresWiFi);
        final resumed = await _downloader.resume(task);
        if (resumed) continue;
      }
      final queued = existing.copyWith(
        isBulkDownload: existing.isBulkDownload || item.isBulkDownload,
        requestedSurahNumber: item.downloadSurahNumber,
        status: QuranAudioDownloadStatus.queued,
        updatedAt: now,
        clearError: true,
      );
      queuedItems.add(queued);
      tasks.add(_taskForItem(queued, requiresWiFi: requiresWiFi));
    }
    if (tasks.isEmpty) {
      _notify();
      return;
    }
    await _store.saveItems(queuedItems);
    final results = await _downloader.enqueueAll(tasks);
    for (var index = 0; index < results.length; index += 1) {
      if (results[index]) {
        continue;
      }
      final item = queuedItems[index];
      await _store.saveItem(
        item.copyWith(
          status: QuranAudioDownloadStatus.failed,
          errorMessage: 'Could not queue download',
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    _notify();
  }

  @override
  Future<void> pauseItems(Iterable<QuranAudioDownloadItem> items) async {
    await initialize();
    final tasks = [
      for (final item in items)
        if (item.status == QuranAudioDownloadStatus.downloading ||
            item.status == QuranAudioDownloadStatus.queued)
          _taskForItem(item),
    ];
    if (tasks.isEmpty) {
      return;
    }
    final paused = await _downloader.pauseAll(tasks: tasks);
    final pausedIds = paused.map((task) => task.taskId).toSet();
    final now = DateTime.now().toUtc();
    for (final item in items) {
      if (pausedIds.contains(item.id)) {
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.paused,
            updatedAt: now,
          ),
        );
      }
    }
    _notify();
  }

  @override
  Future<void> resumeItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {
    await initialize();
    final paused = items
        .where((item) => item.status == QuranAudioDownloadStatus.paused)
        .toList(growable: false);
    if (paused.isEmpty) {
      await enqueueItems(items, requiresWiFi: requiresWiFi);
      return;
    }
    final tasks = [
      for (final item in paused) _taskForItem(item, requiresWiFi: requiresWiFi),
    ];
    // Status callbacks are authoritative; do not overwrite a completed task
    // with queued after resumeAll returns.
    final resumed = await _downloader.resumeAll(tasks: tasks);
    final resumedIds = resumed.map((task) => task.taskId).toSet();
    for (final item in paused) {
      if (!resumedIds.contains(item.id)) {
        await enqueueItems([item], requiresWiFi: requiresWiFi);
      }
    }
    await enqueueItems(
      items.where((item) => item.status != QuranAudioDownloadStatus.paused),
      requiresWiFi: requiresWiFi,
    );
    _notify();
  }

  @override
  Future<void> cancelItems(Iterable<QuranAudioDownloadItem> items) async {
    await initialize();
    final ids = items.map((item) => item.id).toList(growable: false);
    if (ids.isEmpty) {
      return;
    }
    await _downloader.cancelTasksWithIds(ids);
  }

  @override
  Future<void> retryItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) {
    final retry = items
        .where((item) => item.status == QuranAudioDownloadStatus.failed)
        .map(
          (item) => item.copyWith(
            status: QuranAudioDownloadStatus.notDownloaded,
            clearError: true,
          ),
        );
    return enqueueItems(retry, requiresWiFi: requiresWiFi);
  }

  DownloadTask _taskForItem(
    QuranAudioDownloadItem item, {
    bool requiresWiFi = false,
  }) {
    return DownloadTask(
      taskId: item.id,
      url: item.remoteUrl,
      filename: item.filename,
      directory: item.relativeDirectory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: group,
      updates: Updates.statusAndProgress,
      requiresWiFi: requiresWiFi,
      retries: 3,
      allowPause: true,
      metaData: item.id,
      displayName: '${item.reciterName} ${item.verseKey}',
    );
  }

  Future<void> _handleStatus(TaskStatusUpdate update) =>
      _updateItem(update.task.taskId, () => _applyStatus(update));

  Future<void> _applyStatus(TaskStatusUpdate update) async {
    final item = _store.itemById(update.task.taskId);
    if (item == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    switch (update.status) {
      case TaskStatus.enqueued:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.queued,
            updatedAt: now,
          ),
        );
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.downloading,
            updatedAt: now,
            clearError: true,
          ),
        );
      case TaskStatus.paused:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.paused,
            updatedAt: now,
          ),
        );
      case TaskStatus.complete:
        final path = await update.task.filePath();
        final file = File(path);
        final size = await file.exists() ? await file.length() : null;
        if (size != null && size > 0) {
          await QuranAudioStoragePolicy.excludeFromBackup(path);
          await _store.saveItem(
            item.copyWith(
              status: QuranAudioDownloadStatus.downloaded,
              localUri: file.uri.toString(),
              bytesDownloaded: size,
              bytesTotal: size,
              updatedAt: now,
              clearError: true,
            ),
          );
        } else {
          await _store.saveItem(
            item.copyWith(
              status: QuranAudioDownloadStatus.failed,
              errorMessage: 'Downloaded file was empty',
              updatedAt: now,
            ),
          );
        }
      case TaskStatus.notFound:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.failed,
            errorMessage: 'Audio file was not found',
            updatedAt: now,
          ),
        );
      case TaskStatus.failed:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.failed,
            errorMessage: update.exception?.description ?? 'Download failed',
            updatedAt: now,
          ),
        );
      case TaskStatus.canceled:
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.notDownloaded,
            updatedAt: now,
            clearLocalUri: true,
            clearBytes: true,
          ),
        );
    }
    _notify();
  }

  void _handleProgress(TaskProgressUpdate update) {
    if (update.progress < 0) return;
    unawaited(
      _updateItem(update.task.taskId, () async {
        final item = _store.itemById(update.task.taskId);
        if (item == null || !item.isActive) return;
        final total = update.hasExpectedFileSize
            ? update.expectedFileSize
            : null;
        final downloaded = total == null
            ? item.bytesDownloaded
            : (total * update.progress).round();
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.downloading,
            bytesDownloaded: downloaded,
            bytesTotal: total,
            updatedAt: DateTime.now().toUtc(),
            clearError: true,
          ),
        );
        _notify();
      }),
    );
  }

  // Preserve callback order so late progress cannot overwrite paused/completed.
  Future<void> _updateItem(String id, Future<void> Function() action) {
    final previous = _itemUpdates[id] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) => action());
    _itemUpdates[id] = next;
    return next.whenComplete(() {
      if (identical(_itemUpdates[id], next)) _itemUpdates.remove(id);
    });
  }

  void _notify() {
    if (!_updatesController.isClosed) {
      _updatesController.add(null);
    }
  }

  Future<void> dispose() async {
    await _updatesController.close();
  }
}
