import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
       _excelFetcher = excelFetcher ?? _fetchExcel,
       _excelParser = excelParser ?? HadeethEncExcelParser.parseXlsx;

  final HadeethEncLanguagesFetcher _languagesFetcher;
  final HadeethEncExcelFetcher _excelFetcher;
  final HadeethEncExcelParserFn _excelParser;

  Future<List<HadeethEncLanguage>> languages() async {
    final raw = await _languagesFetcher();
    return [
      for (final item in raw)
        if (item is Map) HadeethEncLanguage.fromJson(item),
    ].where((language) => language.code.isNotEmpty).toList(growable: false);
  }

  Future<HadeethEncImportResult> downloadLanguage(String languageCode) async {
    final bytes = await _excelFetcher(languageCode);
    return _excelParser(bytes: bytes, languageCode: languageCode);
  }

  static Future<List<Object?>> _fetchLanguages() async {
    final bytes = await _httpGet(
      Uri.parse('https://hadeethenc.com/api/v1/languages'),
    );
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is List ? decoded : const [];
  }

  static Future<Uint8List> _fetchExcel(String languageCode) {
    return _httpGet(
      Uri.parse('https://hadeethenc.com/browse/download/$languageCode'),
    );
  }

  static Future<Uint8List> _httpGet(Uri uri) async {
    final client = HttpClient();
    client.userAgent = 'QuranApp/1.0';
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HadeethEnc request failed with ${response.statusCode}',
          uri: uri,
        );
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    } finally {
      client.close(force: true);
    }
  }
}
