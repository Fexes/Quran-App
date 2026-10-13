import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/resumable_file_downloader.dart';

import '../../domain/entities/surah_image_catalog.dart';

typedef SurahCoverDirectoryProvider = Future<Directory> Function();
typedef SurahCoverImageUrlBuilder = String Function(int surahNumber);

class SurahCoverCache {
  SurahCoverCache({
    SurahCoverDirectoryProvider? directoryProvider,
    SurahCoverImageUrlBuilder? imageUrlBuilder,
    HttpClient? httpClient,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _imageUrlBuilder = imageUrlBuilder ?? SurahImageCatalog.imageUrlFor,
       _httpClient = httpClient ?? HttpClient();

  static final SurahCoverCache instance = SurahCoverCache();

  final SurahCoverDirectoryProvider _directoryProvider;
  final SurahCoverImageUrlBuilder _imageUrlBuilder;
  final HttpClient _httpClient;
  final Map<int, Future<File?>> _inFlight = {};
  final Map<int, DateTime> _fallbackAttempts = {};
  late final _downloads = ResumableFileDownloader(
    directoryProvider: _directoryProvider,
    httpClient: _httpClient,
  );

  Future<File?> fileFor(int surahNumber) {
    final normalized = SurahImageCatalog.normalize(surahNumber);
    return _inFlight.putIfAbsent(
      normalized,
      () => _fileFor(normalized).whenComplete(() {
        _inFlight.remove(normalized);
      }),
    );
  }

  Future<String?> uriFor(int surahNumber) async {
    final file = await fileFor(surahNumber);
    return file?.uri.toString();
  }

  Future<File?> _fileFor(int surahNumber) async {
    final file = await _coverFile(surahNumber);
    final fallbackMarker = File('${file.path}.fallback');
    final usable = await _isUsable(file);
    final lastAttempt = _fallbackAttempts[surahNumber];
    if (usable &&
        (!await fallbackMarker.exists() ||
            (lastAttempt != null &&
                DateTime.now().difference(lastAttempt) <
                    const Duration(minutes: 5)))) {
      return file;
    }
    _fallbackAttempts[surahNumber] = DateTime.now();
    final downloaded = await _downloadCover(surahNumber, file);
    if (downloaded != null) {
      if (await fallbackMarker.exists()) await fallbackMarker.delete();
      return downloaded;
    }
    if (usable) return file;

    // Device media players need a file URI, not a Flutter asset path.
    final tempFile = File('${file.path}.part');
    try {
      final data = await rootBundle.load(
        SurahImageCatalog.fallbackAssetPathFor(surahNumber),
      );
      await file.parent.create(recursive: true);
      await tempFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      final saved = await tempFile.rename(file.path);
      await fallbackMarker.writeAsString('fallback', flush: true);
      return saved;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return null;
    }
  }

  Future<File?> _downloadCover(int surahNumber, File destination) async {
    final uri = Uri.tryParse(_imageUrlBuilder(surahNumber));
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final tempFile = File('${destination.path}.part');
    try {
      await destination.parent.create(recursive: true);
      final download = await _downloads.download(
        uri,
        expectedContentType: 'image/',
        timeout: const Duration(seconds: 5),
        attempts: 1,
      );
      await tempFile.writeAsBytes(await download.readBytes(), flush: true);
      if (!await _isUsable(tempFile)) {
        await tempFile.delete();
        return null;
      }
      if (await destination.exists()) {
        await destination.delete();
      }
      await tempFile.rename(destination.path);
      await _downloads.discard(uri);
      return destination;
    } catch (_) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      return null;
    }
  }

  Future<File> _coverFile(int surahNumber) async {
    final root = await _directoryProvider();
    return File(
      '${root.path}${Platform.pathSeparator}surah_covers'
      '${Platform.pathSeparator}cover_$surahNumber.jpeg',
    );
  }

  Future<bool> _isUsable(File file) async {
    try {
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }
}
