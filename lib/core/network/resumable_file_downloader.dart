import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ResumableDownloadFile {
  const ResumableDownloadFile(this.file, this.contentEncoding);

  final File file;
  final String? contentEncoding;

  Future<Uint8List> readBytes() async {
    final bytes = await file.readAsBytes();
    final encoding = contentEncoding?.toLowerCase();
    if (encoding == null || encoding.isEmpty || encoding == 'identity') {
      return bytes;
    }
    return Isolate.run(
      () => Uint8List.fromList(switch (encoding) {
        'gzip' => gzip.decode(bytes),
        'deflate' => zlib.decode(bytes),
        _ => throw FormatException('Unsupported download encoding: $encoding'),
      }),
    );
  }
}

/// Persists partial files and validates HTTP ranges before joining their bytes.
class ResumableFileDownloader {
  ResumableFileDownloader({
    Future<Directory> Function()? directoryProvider,
    HttpClient? httpClient,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _httpClient = httpClient;

  static final instance = ResumableFileDownloader();
  static final Map<String, Future<void>> _locks = {};

  final Future<Directory> Function() _directoryProvider;
  final HttpClient? _httpClient;

  Future<ResumableDownloadFile> download(
    Uri uri, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
    String? expectedContentType,
    Duration timeout = const Duration(seconds: 30),
    Duration? maxAge,
    int attempts = 3,
  }) async {
    final root = await _directoryProvider();
    final prefix = '${root.path}/download_checkpoints/${_fileKey(uri)}';
    return _serialized(prefix, () async {
      await Directory(
        '${root.path}/download_checkpoints',
      ).create(recursive: true);
      final partial = File('$prefix.part');
      final complete = File('$prefix.bin');
      final metadataFile = File('$prefix.json');
      var metadata = await _readMetadata(metadataFile);
      final fetchedAt = DateTime.tryParse('${metadata['fetchedAt'] ?? ''}');
      final expired =
          maxAge != null &&
          (fetchedAt == null || DateTime.now().difference(fetchedAt) > maxAge);
      if (metadata['uri'] != uri.toString() || expired) {
        await _deleteFiles([partial, complete, metadataFile]);
        metadata = {};
      }
      _checkCancelled(isCancelled);
      if (metadata['complete'] == true && metadata['total'] is int) {
        final saved = await complete.exists() ? complete : partial;
        if (await saved.exists() &&
            await saved.length() == metadata['total'] &&
            await saved.length() > 0 &&
            (expectedContentType == null ||
                '${metadata['contentType']}'.startsWith(expectedContentType))) {
          if (saved.path == partial.path) await partial.rename(complete.path);
          onProgress?.call(1);
          return ResumableDownloadFile(
            complete,
            metadata['encoding'] as String?,
          );
        }
      }
      for (var attempt = 0; attempt < attempts; attempt++) {
        _checkCancelled(isCancelled);
        try {
          return await _transfer(
            uri,
            partial,
            complete,
            metadataFile,
            onProgress: onProgress,
            isCancelled: isCancelled,
            expectedContentType: expectedContentType,
            timeout: timeout,
          );
        } catch (error) {
          _checkCancelled(isCancelled);
          if (attempt == attempts - 1 ||
              (error is _DownloadHttpException &&
                  error.statusCode < 500 &&
                  error.statusCode != 429)) {
            rethrow;
          }
          await Future<void>.delayed(
            Duration(milliseconds: 250 * (attempt + 1)),
          );
        }
      }
      throw StateError('Download did not finish');
    });
  }

  Future<ResumableDownloadFile> _transfer(
    Uri uri,
    File partial,
    File complete,
    File metadataFile, {
    required void Function(double)? onProgress,
    required bool Function()? isCancelled,
    required String? expectedContentType,
    required Duration timeout,
  }) async {
    final metadata = await _readMetadata(metadataFile);
    var offset = await partial.exists() ? await partial.length() : 0;
    final etag = metadata['etag'] as String?;
    final validator = etag != null && !etag.startsWith('W/')
        ? etag
        : metadata['lastModified'] as String?;
    if (validator == null || metadata['uri'] != uri.toString()) offset = 0;
    final client = _httpClient ?? HttpClient();
    client.autoUncompress = false;
    client.connectionTimeout = timeout;
    HttpClientRequest? request;
    IOSink? sink;
    Timer? cancellation;
    try {
      cancellation = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (isCancelled?.call() == true) {
          request?.abort(StateError('Download cancelled'));
          if (_httpClient == null) client.close(force: true);
        }
      });
      request = await client.getUrl(uri).timeout(timeout);
      _checkCancelled(isCancelled);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      request.headers.set(HttpHeaders.userAgentHeader, 'QuranApp/1.0');
      if (offset > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
        request.headers.set(HttpHeaders.ifRangeHeader, validator!);
      }
      final response = await request.close().timeout(timeout);
      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        final total = int.tryParse(
          response.headers
                  .value(HttpHeaders.contentRangeHeader)
                  ?.split('/')
                  .last ??
              '',
        );
        await response.drain<void>().timeout(timeout);
        if (offset > 0 && total == offset && metadata['total'] == total) {
          await _writeMetadata(metadataFile, {...metadata, 'complete': true});
          await partial.rename(complete.path);
          onProgress?.call(1);
          return ResumableDownloadFile(
            complete,
            metadata['encoding'] as String?,
          );
        }
        await _deleteFiles([partial, metadataFile]);
        throw const FormatException('Download source changed');
      }
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.partialContent) {
        await response.drain<void>().timeout(timeout);
        throw _DownloadHttpException(response.statusCode, uri);
      }
      final contentType = response.headers.contentType?.mimeType ?? '';
      if (expectedContentType != null &&
          !contentType.startsWith(expectedContentType)) {
        await response.drain<void>().timeout(timeout);
        throw const FormatException('Unexpected download content type');
      }
      int? total;
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      if (response.statusCode == HttpStatus.partialContent) {
        final range = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(
          response.headers.value(HttpHeaders.contentRangeHeader) ?? '',
        );
        final responseEtag = response.headers.value(HttpHeaders.etagHeader);
        final responseModified = response.headers.value(
          HttpHeaders.lastModifiedHeader,
        );
        if (range == null ||
            int.parse(range[1]!) != offset ||
            int.parse(range[2]!) < offset ||
            int.parse(range[2]!) >= int.parse(range[3]!) ||
            (metadata['encoding'] != encoding && offset > 0) ||
            (offset > 0 &&
                etag != null &&
                responseEtag != null &&
                etag != responseEtag) ||
            (offset > 0 &&
                etag == null &&
                responseModified != null &&
                responseModified != validator) ||
            (offset > 0 &&
                metadata['total'] != null &&
                metadata['total'] != int.parse(range[3]!))) {
          await response.drain<void>().timeout(timeout);
          await _deleteFiles([partial, metadataFile]);
          throw const FormatException('Invalid resumed download response');
        }
        total = int.parse(range[3]!);
      } else {
        // Servers without Range support return 200: replace, never append.
        offset = 0;
        total = response.contentLength > 0 ? response.contentLength : null;
      }
      final updated = <String, Object?>{
        'uri': uri.toString(),
        'etag':
            response.headers.value(HttpHeaders.etagHeader) ??
            (offset > 0 ? etag : null),
        'lastModified':
            response.headers.value(HttpHeaders.lastModifiedHeader) ??
            (offset > 0 ? metadata['lastModified'] : null),
        'encoding': encoding,
        'contentType': contentType,
        'total': total,
        'complete': false,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
      await _writeMetadata(metadataFile, updated);
      sink = partial.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var received = offset;
      var flushedAt = offset;
      var lastProgress = -1.0;
      if (total != null) onProgress?.call((received / total).clamp(0, 1));
      await for (final chunk in response.timeout(timeout)) {
        _checkCancelled(isCancelled);
        sink.add(chunk);
        received += chunk.length;
        if (received - flushedAt >= 256 * 1024) {
          await sink.flush();
          flushedAt = received;
        }
        if (total != null) {
          if (received > total) {
            throw const FormatException('Download length mismatch');
          }
          final progress = (received / total).clamp(0.0, 1.0);
          if (progress - lastProgress >= 0.01) {
            lastProgress = progress;
            onProgress?.call(progress);
          }
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (received <= 0 || (total != null && received != total)) {
        throw const FormatException('Download interrupted before completion');
      }
      _checkCancelled(isCancelled);
      await _writeMetadata(metadataFile, {
        ...updated,
        'total': received,
        'complete': true,
      });
      if (await complete.exists()) await complete.delete();
      await partial.rename(complete.path);
      onProgress?.call(1);
      return ResumableDownloadFile(complete, encoding);
    } finally {
      cancellation?.cancel();
      if (sink != null) {
        try {
          await sink.flush();
          await sink.close();
        } catch (_) {
          // Keep whatever bytes reached disk for the next attempt.
        }
      }
      request?.abort();
      if (_httpClient == null) client.close(force: true);
    }
  }

  Future<void> discard(Uri uri) async {
    final root = await _directoryProvider();
    final prefix = '${root.path}/download_checkpoints/${_fileKey(uri)}';
    await _serialized(
      prefix,
      () => _deleteFiles([
        File('$prefix.part'),
        File('$prefix.bin'),
        File('$prefix.json'),
      ]),
    );
  }

  static Future<T> _serialized<T>(
    String key,
    Future<T> Function() action,
  ) async {
    final previous = _locks[key];
    final gate = Completer<void>();
    _locks[key] = gate.future;
    if (previous != null) await previous;
    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_locks[key], gate.future)) _locks.remove(key);
    }
  }

  static void _checkCancelled(bool Function()? cancelled) {
    if (cancelled?.call() == true) throw StateError('Download cancelled');
  }

  static Future<Map<String, dynamic>> _readMetadata(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeMetadata(
    File file,
    Map<String, Object?> metadata,
  ) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(metadata), flush: true);
    await temporary.rename(file.path);
  }

  static Future<void> _deleteFiles(List<File> files) async {
    for (final file in files) {
      if (await file.exists()) await file.delete();
    }
  }

  static String _fileKey(Uri uri) {
    var hash = 1469598103934665603;
    for (final byte in utf8.encode(uri.toString())) {
      hash = ((hash ^ byte) * 1099511628211) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}

class _DownloadHttpException extends HttpException {
  _DownloadHttpException(this.statusCode, Uri uri)
    : super('Download request failed ($statusCode)', uri: uri);

  final int statusCode;
}
