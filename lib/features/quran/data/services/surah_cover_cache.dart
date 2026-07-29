import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

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
    if (await _isUsable(file)) {
      return file;
    }
    return _downloadCover(surahNumber, file);
  }

  Future<File?> _downloadCover(int surahNumber, File destination) async {
    final uri = Uri.tryParse(_imageUrlBuilder(surahNumber));
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    final tempFile = File('${destination.path}.part');
    try {
      await destination.parent.create(recursive: true);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return null;
      }

      final sink = tempFile.openWrite();
      await response.pipe(sink);
      if (!await _isUsable(tempFile)) {
        await tempFile.delete();
        return null;
      }
      if (await destination.exists()) {
        await destination.delete();
      }
      await tempFile.rename(destination.path);
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
