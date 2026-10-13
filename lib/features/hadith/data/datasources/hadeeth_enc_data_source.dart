import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/network/resumable_file_downloader.dart';

import '../../domain/entities/hadeeth_enc_item.dart';
import '../services/hadeeth_enc_excel_parser.dart';

typedef HadeethEncLanguagesFetcher = Future<List<Object?>> Function();
typedef HadeethEncExcelFetcher =
    Future<Uint8List> Function(String languageCode);
typedef HadeethEncExcelParserFn =
    HadeethEncImportResult Function({
      required Uint8List bytes,
      required String languageCode,
    });

class HadeethEncDataSource {
  HadeethEncDataSource({
    HadeethEncLanguagesFetcher? languagesFetcher,
    HadeethEncExcelFetcher? excelFetcher,
    HadeethEncExcelParserFn? excelParser,
  }) : _languagesFetcher = languagesFetcher ?? _fetchLanguages,
       _excelFetcher = excelFetcher,
       _excelParser = excelParser;

  final HadeethEncLanguagesFetcher _languagesFetcher;
  final HadeethEncExcelFetcher? _excelFetcher;
  final HadeethEncExcelParserFn? _excelParser;

  Future<List<HadeethEncLanguage>> languages() async {
    final raw = await _languagesFetcher();
    return [
      for (final item in raw)
        if (item is Map) HadeethEncLanguage.fromJson(item),
    ].where((language) => language.code.isNotEmpty).toList(growable: false);
  }

  Future<HadeethEncImportResult> downloadLanguage(
    String languageCode, {
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final bytes = _excelFetcher == null
        ? await (await ResumableFileDownloader.instance.download(
            _downloadUri(languageCode),
            onProgress: onProgress,
            isCancelled: isCancelled,
          )).readBytes()
        : await _excelFetcher(languageCode);
    if (isCancelled?.call() == true) throw StateError('Download cancelled');
    onProgress?.call(1);
    final parser = _excelParser;
    try {
      return parser == null
          ? await compute(_parseExcel, {
              'bytes': bytes,
              'languageCode': languageCode,
            })
          : parser(bytes: bytes, languageCode: languageCode);
    } on FormatException {
      if (_excelFetcher == null && isCancelled?.call() != true) {
        await ResumableFileDownloader.instance.discard(
          _downloadUri(languageCode),
        );
      }
      rethrow;
    }
  }

  Future<void> finishLanguageDownload(String languageCode) async {
    if (_excelFetcher != null) return;
    try {
      await ResumableFileDownloader.instance.discard(
        _downloadUri(languageCode),
      );
    } catch (_) {
      // Keep the installed language even if temporary-file cleanup fails.
    }
  }

  static Uri _downloadUri(String languageCode) =>
      Uri.parse('https://hadeethenc.com/browse/download/$languageCode');

  static Future<List<Object?>> _fetchLanguages() async {
    final bytes = await _httpGet(
      Uri.parse('https://hadeethenc.com/api/v1/languages'),
    );
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is List ? decoded : const [];
  }

  static HadeethEncImportResult _parseExcel(Map<String, Object> input) =>
      HadeethEncExcelParser.parseXlsx(
        bytes: input['bytes'] as Uint8List,
        languageCode: input['languageCode'] as String,
      );

  static Future<Uint8List> _httpGet(
    Uri uri, {
    void Function(double)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final client = HttpClient();
    client.userAgent = 'QuranApp/1.0';
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 30));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HadeethEnc request failed with ${response.statusCode}',
          uri: uri,
        );
      }
      final chunks = <int>[];
      var lastProgress = -1.0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        if (isCancelled?.call() == true) throw StateError('Download cancelled');
        chunks.addAll(chunk);
        if (response.contentLength > 0) {
          final progress = (chunks.length / response.contentLength).clamp(
            0.0,
            1.0,
          );
          if (progress - lastProgress >= 0.01) {
            lastProgress = progress;
            onProgress?.call(progress);
          }
        }
      }
      return Uint8List.fromList(chunks);
    } finally {
      client.close(force: true);
    }
  }
}
