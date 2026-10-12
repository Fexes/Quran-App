enum QuranArabicScript {
  uthmani,
  indoPak;

  static QuranArabicScript forCountry(String countryCode) =>
      const {'PK', 'IN', 'BD'}.contains(countryCode.trim().toUpperCase())
      ? indoPak
      : uthmani;

  String get label => this == indoPak ? 'IndoPak' : 'Uthmani';
  String? get fontFamily => this == indoPak ? 'IndoPakQuran' : 'UthmanicHafs';

  double get readerLineHeight => this == indoPak ? 2.2 : 2.05;

  static String cleanUthmaniText(String text) =>
      text.replaceFirst(RegExp(r'\s*[\uFC00-\uFD1D]\s*$'), '').trim();

  static List<String> wordSpans(String text) {
    final result = <String>[];
    var prefix = '';
    for (final match in RegExp(r'\S+\s*').allMatches(text)) {
      final token = match.group(0)!;
      if (RegExp(r'^[\u06D6-\u06ED]+$').hasMatch(token.trim())) {
        // Quranic annotation marks do not consume a recitation word index.
        if (result.isEmpty) {
          prefix += token;
        } else {
          result[result.length - 1] += token;
        }
      } else {
        result.add(prefix + token);
        prefix = '';
      }
    }
    if (prefix.isNotEmpty) result.add(prefix);
    return result;
  }

  String get bismillah => this == indoPak
      ? 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ'
      : 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';
}
