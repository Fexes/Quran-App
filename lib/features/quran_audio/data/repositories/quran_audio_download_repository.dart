import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/quran_audio_download_item.dart';
import '../../domain/entities/quran_audio_queue_item.dart';
import '../stores/quran_audio_download_store.dart';

typedef QuranAudioDirectoryProvider = Future<Directory> Function();

class QuranAudioDownloadRepository {
  QuranAudioDownloadRepository({
    required QuranRepository quranRepository,
    required QuranAudioDownloadStore store,
    QuranAudioDirectoryProvider? supportDirectoryProvider,
  }) : _quranRepository = quranRepository,
       _store = store,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final QuranRepository _quranRepository;
  final QuranAudioDownloadStore _store;
  final QuranAudioDirectoryProvider _supportDirectoryProvider;

  QuranAudioDownloadStore get store => _store;

  Future<List<QuranAudioQueueItem>> resolveQueue(
    List<QuranAudioQueueItem> queue,
  ) async {
    final resolved = <QuranAudioQueueItem>[];
    for (final item in queue) {
      final localUri = await localUriForQueueItem(item);
      if (localUri == null) {
        resolved.add(
          item.copyWithPlayback(
            playbackUri: item.remoteAudioUrl,
            isDownloaded: false,
          ),
        );
      } else {
        resolved.add(
          item.copyWithPlayback(
            playbackUri: localUri,
            localUri: localUri,
            isDownloaded: true,
          ),
        );
      }
    }
    return resolved;
  }

  Future<String?> localUriForQueueItem(QuranAudioQueueItem item) async {
    final downloadItem = await itemForQueueItem(item);
    final existing = _store.itemById(downloadItem.id) ?? downloadItem;
    final file = await fileForItem(existing);
    if (await _isUsableFile(file)) {
      final localUri = file.uri.toString();
      if (!existing.isDownloaded || existing.localUri != localUri) {
        await _store.saveItem(
          existing.copyWith(
            status: QuranAudioDownloadStatus.downloaded,
            localUri: localUri,
            bytesDownloaded: await file.length(),
            bytesTotal: await file.length(),
            updatedAt: DateTime.now().toUtc(),
            clearError: true,
          ),
        );
      }
      return localUri;
    }

    if (existing.status == QuranAudioDownloadStatus.downloaded) {
      await _store.saveItem(
        existing.copyWith(
          status: QuranAudioDownloadStatus.notDownloaded,
          updatedAt: DateTime.now().toUtc(),
          clearLocalUri: true,
          clearBytes: true,
        ),
      );
    }
    return null;
  }

  Future<QuranAudioDownloadItem> itemForQueueItem(
    QuranAudioQueueItem item,
  ) async {
    final surahNumber = item.audioSurahNumber;
    final ayahNumber = item.audioAyahNumber;
    return QuranAudioDownloadItem(
      id: QuranAudioDownloadItem.idFor(
        reciterId: item.reciterId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
      reciterId: item.reciterId,
      reciterName: item.reciterName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      verseKey: '$surahNumber:$ayahNumber',
      page: item.isBismillah ? 1 : item.page,
      remoteUrl: item.remoteAudioUrl,
      relativeDirectory: _relativeDirectory(item.reciterId, surahNumber),
      filename: _filename(ayahNumber),
      status: QuranAudioDownloadStatus.notDownloaded,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  QuranAudioDownloadItem itemForAyah({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
  }) {
    final existing = _store.itemById(
      QuranAudioDownloadItem.idFor(
        reciterId: reciter.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
    );
    if (existing != null) {
      return existing;
    }
    return QuranAudioDownloadItem(
      id: QuranAudioDownloadItem.idFor(
        reciterId: reciter.id,
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
      reciterId: reciter.id,
      reciterName: reciter.name,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.number,
      verseKey: ayah.verseKey,
      page: ayah.page,
      remoteUrl: reciter.audioUrlFor(ayah),
      relativeDirectory: _relativeDirectory(reciter.id, ayah.surahNumber),
      filename: _filename(ayah.number),
      status: QuranAudioDownloadStatus.notDownloaded,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<List<QuranAudioDownloadItem>> itemsForSurah({
    required QuranAudioReciter reciter,
    required int surahNumber,
  }) async {
    final surah = await _quranRepository.getSurah(surahNumber);
    final ayahs = await _quranRepository.getAyahs(surahNumber);
    final bismillah = surahNumber != 1 && surahNumber != 9
        ? (await _quranRepository.getAyahs(
            1,
          )).firstWhere((ayah) => ayah.number == 1)
        : null;
    return [
      if (bismillah != null)
        itemForAyah(ayah: bismillah, surah: surah, reciter: reciter),
      for (final ayah in ayahs)
        itemForAyah(ayah: ayah, surah: surah, reciter: reciter),
    ];
  }

  Future<List<QuranAudioDownloadItem>> itemsForReciter(
    QuranAudioReciter reciter,
  ) async {
    final surahs = await _quranRepository.getSurahs();
    final items = <QuranAudioDownloadItem>[];
    for (final surah in surahs) {
      final ayahs = await _quranRepository.getAyahs(surah.number);
      for (final ayah in ayahs) {
        items.add(itemForAyah(ayah: ayah, surah: surah, reciter: reciter));
      }
    }
    return items;
  }

  Future<List<QuranAudioDownloadGroup>> surahGroups({
    required QuranAudioReciter reciter,
  }) async {
    final surahs = await _quranRepository.getSurahs();
    final existing = _store.itemsForReciter(reciter.id);
    final bySurah = <int, List<QuranAudioDownloadItem>>{};
    for (final item in existing) {
      bySurah.putIfAbsent(item.surahNumber, () => []).add(item);
    }
    final bismillah = _store.itemById(
      QuranAudioDownloadItem.idFor(
        reciterId: reciter.id,
        surahNumber: 1,
        ayahNumber: 1,
      ),
    );
    return [
      for (final surah in surahs)
        _groupForSurah(
          reciter: reciter,
          surah: surah,
          items: [
            ...?bySurah[surah.number],
            if (surah.number != 1 && surah.number != 9 && bismillah != null)
              bismillah,
          ],
        ),
    ];
  }

  List<QuranAudioDownloadGroup> activeGroups() {
    final active = _store.activeItems();
    final byKey = <String, List<QuranAudioDownloadItem>>{};
    for (final item in active) {
      final key = '${item.reciterId}_${item.surahNumber}';
      byKey.putIfAbsent(key, () => []).add(item);
    }
    return byKey.entries
        .map((entry) => _groupFromItems(entry.value))
        .toList(growable: false)
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  List<QuranAudioDownloadGroup> downloadedGroups() {
    final downloaded = _store.allItems
        .where((item) => item.status == QuranAudioDownloadStatus.downloaded)
        .toList(growable: false);
    final byKey = <String, List<QuranAudioDownloadItem>>{};
    for (final item in downloaded) {
      final key = '${item.reciterId}_${item.surahNumber}';
      byKey.putIfAbsent(key, () => []).add(item);
    }
    return byKey.entries
        .map((entry) => _groupFromItems(entry.value))
        .toList(growable: false)
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<int> storageUsedBytes() async {
    var total = 0;
    for (final item in _store.allItems) {
      if (item.status != QuranAudioDownloadStatus.downloaded) {
        continue;
      }
      final file = await fileForItem(item);
      if (await _isUsableFile(file)) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<File> fileForItem(QuranAudioDownloadItem item) async {
    final root = await _supportDirectoryProvider();
    final directory = item.relativeDirectory.replaceAll(
      '/',
      Platform.pathSeparator,
    );
    return File(
      '${root.path}${Platform.pathSeparator}$directory'
      '${Platform.pathSeparator}${item.filename}',
    );
  }

  Future<void> deleteItems(Iterable<QuranAudioDownloadItem> items) async {
    final ids = <String>[];
    for (final item in items) {
      ids.add(item.id);
      final file = await fileForItem(item);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _store.deleteItems(ids);
  }

  Future<void> deleteSurah({
    required String reciterId,
    required int surahNumber,
  }) async {
    await deleteItems(
      _store.itemsForSurah(reciterId: reciterId, surahNumber: surahNumber),
    );
  }

  Future<void> deleteReciter(String reciterId) async {
    await deleteItems(_store.itemsForReciter(reciterId));
  }

  Future<void> deleteAll() async {
    final root = await _supportDirectoryProvider();
    final audioDir = Directory(
      '${root.path}${Platform.pathSeparator}quran_audio',
    );
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
    await _store.clear();
  }

  Future<void> reconcileDownloadedFiles() async {
    for (final item in _store.allItems) {
      if (item.status != QuranAudioDownloadStatus.downloaded) {
        continue;
      }
      final file = await fileForItem(item);
      if (!await _isUsableFile(file)) {
        await _store.saveItem(
          item.copyWith(
            status: QuranAudioDownloadStatus.notDownloaded,
            updatedAt: DateTime.now().toUtc(),
            clearLocalUri: true,
            clearBytes: true,
          ),
        );
      }
    }
  }

  Future<bool> _isUsableFile(File file) async {
    return await file.exists() && await file.length() > 0;
  }

  QuranAudioDownloadGroup _groupForSurah({
    required QuranAudioReciter reciter,
    required QuranSurah surah,
    required List<QuranAudioDownloadItem> items,
  }) {
    return QuranAudioDownloadGroup(
      id: '${reciter.id}_${surah.number}',
      title: surah.englishName,
      subtitle: 'Surah ${surah.number} • ${surah.ayahCount} ayahs',
      reciterId: reciter.id,
      scope: QuranAudioDownloadScope.surah,
      surahNumber: surah.number,
      totalAyahs:
          surah.ayahCount + (surah.number != 1 && surah.number != 9 ? 1 : 0),
      downloadedAyahs: items
          .where((item) => item.status == QuranAudioDownloadStatus.downloaded)
          .length,
      failedAyahs: items
          .where((item) => item.status == QuranAudioDownloadStatus.failed)
          .length,
      queuedAyahs: items
          .where((item) => item.status == QuranAudioDownloadStatus.queued)
          .length,
      downloadingAyahs: items
          .where((item) => item.status == QuranAudioDownloadStatus.downloading)
          .length,
      bytesDownloaded: items.fold<int>(
        0,
        (sum, item) => sum + (item.bytesDownloaded ?? 0),
      ),
      bytesTotal: items.fold<int>(
        0,
        (sum, item) => sum + (item.bytesTotal ?? 0),
      ),
      items: List.unmodifiable(items),
    );
  }

  QuranAudioDownloadGroup _groupFromItems(List<QuranAudioDownloadItem> items) {
    final sorted = [...items]
      ..sort((a, b) {
        final surah = a.surahNumber.compareTo(b.surahNumber);
        return surah != 0 ? surah : a.ayahNumber.compareTo(b.ayahNumber);
      });
    final first = sorted.first;
    return QuranAudioDownloadGroup(
      id: '${first.reciterId}_${first.surahNumber}',
      title: 'Surah ${first.surahNumber}',
      subtitle: first.reciterName,
      reciterId: first.reciterId,
      scope: QuranAudioDownloadScope.surah,
      surahNumber: first.surahNumber,
      totalAyahs: sorted.length,
      downloadedAyahs: sorted
          .where((item) => item.status == QuranAudioDownloadStatus.downloaded)
          .length,
      failedAyahs: sorted
          .where((item) => item.status == QuranAudioDownloadStatus.failed)
          .length,
      queuedAyahs: sorted
          .where((item) => item.status == QuranAudioDownloadStatus.queued)
          .length,
      downloadingAyahs: sorted
          .where((item) => item.status == QuranAudioDownloadStatus.downloading)
          .length,
      bytesDownloaded: sorted.fold<int>(
        0,
        (sum, item) => sum + (item.bytesDownloaded ?? 0),
      ),
      bytesTotal: sorted.fold<int>(
        0,
        (sum, item) => sum + (item.bytesTotal ?? 0),
      ),
      items: List.unmodifiable(sorted),
    );
  }

  String _relativeDirectory(String reciterId, int surahNumber) {
    return 'quran_audio/${_safeReciterId(reciterId)}/'
        '${surahNumber.toString().padLeft(3, '0')}';
  }

  String _filename(int ayahNumber) {
    return '${ayahNumber.toString().padLeft(3, '0')}.mp3';
  }

  String _safeReciterId(String reciterId) {
    return reciterId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }
}
