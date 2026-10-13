import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/resumable_file_downloader.dart';

class FawazHadithTranslationDataSource {
  const FawazHadithTranslationDataSource({
    Future<List<int>> Function(Uri uri)? fetcher,
  }) : _fetcher = fetcher;

  final Future<List<int>> Function(Uri uri)? _fetcher;

  static const _baseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  Future<FawazHadithBookTranslation> downloadBookTranslation({
    required String bookId,
    required String languageCode,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final editionPrefix = editionPrefixFor(languageCode);
    if (editionPrefix == null) {
      throw UnsupportedError('Hadith language not supported: $languageCode');
    }
    final editionName = '$editionPrefix-$bookId';
    Object? lastError;
    for (final suffix in ['min.json', 'json']) {
      final uri = Uri.parse('$_baseUrl/$editionName.$suffix');
      ResumableDownloadFile? completedFile;
      try {
        if (_fetcher == null) {
          completedFile = await ResumableFileDownloader.instance.download(
            uri,
            onProgress: onProgress,
            isCancelled: isCancelled,
          );
        }
        final bytes = completedFile != null
            ? await completedFile.readBytes()
            : await _fetcher!(uri);
        if (isCancelled?.call() == true) throw StateError('Download cancelled');
        onProgress?.call(1);
        return await compute(_parseBookTranslation, {
          'bytes': bytes,
          'editionName': editionName,
        });
      } catch (error) {
        if (isCancelled?.call() == true) rethrow;
        if (completedFile != null && error is FormatException) {
          await ResumableFileDownloader.instance.discard(uri);
        }
        lastError = error;
      }
    }
    throw lastError ??
        const FormatException('Hadith translation download failed');
  }

  Future<void> finishBookDownload(String bookId, String languageCode) async {
    if (_fetcher != null) return;
    final prefix = editionPrefixFor(languageCode);
    if (prefix == null) return;
    try {
      for (final suffix in ['min.json', 'json']) {
        await ResumableFileDownloader.instance.discard(
          Uri.parse('$_baseUrl/$prefix-$bookId.$suffix'),
        );
      }
    } catch (_) {
      // Installed data is authoritative; cleanup must not fail the download.
    }
  }

  static FawazHadithBookTranslation _parseBookTranslation(
    Map<String, Object> input,
  ) {
    final decoded = jsonDecode(utf8.decode(input['bytes'] as List<int>));
    if (decoded is! Map) {
      throw const FormatException('Invalid Hadith translation response');
    }
    final rawHadiths = decoded['hadiths'];
    if (rawHadiths is! List) {
      throw const FormatException('Hadith translation response has no items');
    }
    final translations = <String, String>{};
    for (final item in rawHadiths) {
      if (item is! Map) {
        throw const FormatException('Invalid Hadith translation record');
      }
      final number = item['hadithnumber']?.toString() ?? '';
      final text = _cleanText(item['text']);
      if (number.isEmpty || translations.containsKey(number)) {
        throw const FormatException('Invalid or duplicate Hadith number');
      }
      // Empty source records are unavailable translations, not failed transfers.
      translations[number] = text;
    }
    if (translations.isEmpty) {
      throw const FormatException('Empty Hadith edition');
    }
    return FawazHadithBookTranslation(
      editionName: input['editionName'] as String,
      translations: translations,
    );
  }

  static String? editionPrefixFor(String languageCode) {
    return _editionPrefixes[languageCode.toLowerCase()];
  }

  static const _editionPrefixes = {
    'bn': 'ben',
    'en': 'eng',
    'fr': 'fra',
    'id': 'ind',
    'ru': 'rus',
    'ta': 'tam',
    'tr': 'tur',
    'ur': 'urd',
  };

  static String _cleanText(Object? value) {
    if (value == null) {
      return '';
    }
    return value
        .toString()
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class FawazHadithBookTranslation {
  const FawazHadithBookTranslation({
    required this.editionName,
    required this.translations,
  });

  final String editionName;
  final Map<String, String> translations;
}
