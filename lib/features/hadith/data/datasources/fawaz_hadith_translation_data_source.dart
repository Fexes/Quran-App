import 'dart:convert';
import 'dart:io';

class FawazHadithTranslationDataSource {
  const FawazHadithTranslationDataSource({
    Future<List<int>> Function(Uri uri)? fetcher,
  }) : _fetcher = fetcher ?? _httpGet;

  final Future<List<int>> Function(Uri uri) _fetcher;

  static const _baseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  Future<FawazHadithBookTranslation> downloadBookTranslation({
    required String bookId,
    required String languageCode,
  }) async {
    final editionPrefix = editionPrefixFor(languageCode);
    if (editionPrefix == null) {
      throw UnsupportedError('Hadith language not supported: $languageCode');
    }
    final editionName = '$editionPrefix-$bookId';
    final uri = Uri.parse('$_baseUrl/$editionName.min.json');
    final bytes = await _fetcher(uri);
    final decoded = jsonDecode(utf8.decode(bytes));
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
        continue;
      }
      final number = item['hadithnumber']?.toString() ?? '';
      final text = _cleanText(item['text']);
      if (number.isNotEmpty && text.isNotEmpty) {
        translations[number] = text;
      }
    }
    return FawazHadithBookTranslation(
      editionName: editionName,
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

  static Future<List<int>> _httpGet(Uri uri) async {
    final client = HttpClient();
    client.userAgent = 'QuranApp/1.0';
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Hadith translation request failed with ${response.statusCode}',
          uri: uri,
        );
      }
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      return chunks;
    } finally {
      client.close(force: true);
    }
  }

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
