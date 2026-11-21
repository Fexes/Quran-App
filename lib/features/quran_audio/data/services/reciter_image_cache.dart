import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/resumable_file_downloader.dart';

typedef ReciterImageDirectoryProvider = Future<Directory> Function();

class ReciterImageCache {
  ReciterImageCache({
    ReciterImageDirectoryProvider? directoryProvider,
    HttpClient? httpClient,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _httpClient = httpClient ?? HttpClient();

  static final ReciterImageCache instance = ReciterImageCache();
  static const _maximumRememberedFiles = 100;

  final ReciterImageDirectoryProvider _directoryProvider;
  final HttpClient _httpClient;
  final Map<String, Future<File?>> _inFlight = {};
  final LinkedHashMap<String, File> _cachedFiles = LinkedHashMap();
  late final _downloads = ResumableFileDownloader(
    directoryProvider: _directoryProvider,
    httpClient: _httpClient,
  );

  File? cachedFileFor(String url) {
    final key = url.trim();
    final file = _cachedFiles.remove(key);
    if (file == null) return null;
    try {
      if (file.existsSync() && file.lengthSync() > 0) {
        _cachedFiles[key] = file;
        return file;
      }
    } catch (_) {
      // A removed or inaccessible file can be fetched again.
    }
    return null;
  }

  Future<File?> fileFor(String url) {
    final key = url.trim();
    final cached = cachedFileFor(key);
    if (cached != null) return Future.value(cached);
    final uri = Uri.tryParse(key);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return Future.value(null);
    }
    return _inFlight.putIfAbsent(
      key,
      () => _fileFor(key, uri).whenComplete(() {
        _inFlight.remove(key);
      }),
    );
  }

  Future<File?> _fileFor(String key, Uri uri) async {
    try {
      final root = await _directoryProvider();
      final filename = sha256.convert(utf8.encode(key)).toString();
      final file = File(
        '${root.path}${Platform.pathSeparator}reciter_avatars'
        '${Platform.pathSeparator}$filename.img',
      );
      if (await _isUsable(file)) {
        return _remember(key, file);
      }
      await _deleteIfPresent(file);
      final downloaded = await _download(uri, file);
      return downloaded == null ? null : _remember(key, downloaded);
    } catch (_) {
      return null;
    }
  }

  Future<File?> _download(Uri uri, File destination) async {
    final temporary = File('${destination.path}.part');
    var downloaded = false;
    try {
      await destination.parent.create(recursive: true);
      final result = await _downloads.download(
        uri,
        expectedContentType: 'image/',
        timeout: const Duration(seconds: 5),
        attempts: 1,
      );
      downloaded = true;
      final bytes = await result.readBytes();
      if (!await _isImage(bytes)) return null;
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(destination.path);
      return destination;
    } catch (_) {
      return null;
    } finally {
      await _deleteIfPresent(temporary);
      if (downloaded) {
        try {
          // Invalid image responses must not become permanent checkpoints.
          await _downloads.discard(uri);
        } catch (_) {
          // The validated avatar remains usable if checkpoint cleanup fails.
        }
      }
    }
  }

  File _remember(String key, File file) {
    _cachedFiles.remove(key);
    _cachedFiles[key] = file;
    while (_cachedFiles.length > _maximumRememberedFiles) {
      _cachedFiles.remove(_cachedFiles.keys.first);
    }
    return file;
  }

  static Future<bool> _isImage(Uint8List bytes) async {
    if (bytes.isEmpty) return false;
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
      final frame = await codec.getNextFrame();
      image = frame.image;
      return image.width > 0 && image.height > 0;
    } catch (_) {
      return false;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static Future<bool> _isUsable(File file) async {
    try {
      return await file.exists() && await _isImage(await file.readAsBytes());
    } catch (_) {
      return false;
    }
  }

  static Future<void> _deleteIfPresent(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cache failures should not interrupt playback or the reciter picker.
    }
  }
}
