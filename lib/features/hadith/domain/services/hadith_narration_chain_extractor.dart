import '../entities/hadith_item.dart';

class HadithNarrationChain {
  const HadithNarrationChain({required this.english, required this.arabic});

  final String english;
  final String arabic;

  bool get hasAny => english.isNotEmpty || arabic.isNotEmpty;
}

class HadithNarrationChainExtractor {
  const HadithNarrationChainExtractor._();

  static HadithNarrationChain extract(HadithItem hadith) {
    return HadithNarrationChain(
      english: _extractEnglish(hadith.translation),
      arabic: _extractArabic(hadith.arabic),
    );
  }

  static String _extractEnglish(String source) {
    final text = _clean(source);
    if (text.isEmpty) {
      return '';
    }

    final lower = text.toLowerCase();
    final whoSaid = lower.indexOf(' who said');
    if (whoSaid > 0 && _looksLikeEnglishChain(lower.substring(0, whoSaid))) {
      return _trimTerminalPunctuation(text.substring(0, whoSaid));
    }

    final colon = text.indexOf(':');
    if (colon > 0 && colon <= 260) {
      final prefix = text.substring(0, colon);
      if (_looksLikeEnglishChain(prefix.toLowerCase())) {
        return _trimTerminalPunctuation(prefix);
      }
    }

    return '';
  }

  static String _extractArabic(String source) {
    final text = _clean(source);
    if (text.isEmpty) {
      return '';
    }

    final marker = _firstPositive([
      text.indexOf(' قَالَ سَمِعْتُ رَسُولَ'),
      text.indexOf(' قال سمعت رسول'),
      text.indexOf(' قَالَ سَمِعْتُ النَّبِيَّ'),
      text.indexOf(' قال سمعت النبي'),
      text.indexOf(' يَقُولُ سَمِعْتُ رَسُولَ'),
      text.indexOf(' يقول سمعت رسول'),
      text.indexOf(' قَالَ رَسُولُ'),
      text.indexOf(' قال رسول'),
      text.indexOf(' قَالَ النَّبِيُّ'),
      text.indexOf(' قال النبي'),
      text.indexOf(' أَنَّ رَسُولَ'),
      text.indexOf(' أن رسول'),
      text.indexOf(' أَنَّ النَّبِيَّ'),
      text.indexOf(' أن النبي'),
      text.indexOf(' عَنِ النَّبِيِّ'),
      text.indexOf(' عن النبي'),
    ]);
    if (marker > 0) {
      return _compact(text.substring(0, marker), maxLength: 260);
    }

    final quote = _firstPositive([
      text.indexOf('"'),
      text.indexOf('“'),
      text.indexOf('”'),
      text.indexOf('«'),
      text.indexOf('»'),
    ]);
    if (quote > 0) {
      return _compact(text.substring(0, quote), maxLength: 260);
    }

    if (_looksLikeArabicChain(text)) {
      return _compact(text, maxLength: 260);
    }
    return '';
  }

  static bool _looksLikeEnglishChain(String text) {
    return const [
      'narrated',
      'reported',
      'authority of',
      'on the authority',
      'transmitted',
    ].any(text.contains);
  }

  static bool _looksLikeArabicChain(String text) {
    return const [
      'حَدَّثَنَا',
      'حَدَّثَنَا',
      'حدثنا',
      'حَدَّثَنِي',
      'حَدَّثَنِي',
      'حدثني',
      'أَخْبَرَنَا',
      'اخبرنا',
      'عَنْ',
      'عَنِ',
      'عن ',
    ].any(text.contains);
  }

  static int _firstPositive(List<int> indexes) {
    final positives = indexes.where((index) => index > 0).toList();
    if (positives.isEmpty) {
      return -1;
    }
    positives.sort();
    return positives.first;
  }

  static String _clean(String source) {
    return source.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _trimTerminalPunctuation(String source) {
    return source.trim().replaceFirst(RegExp(r'[\s:;,.]+$'), '');
  }

  static String _compact(String source, {required int maxLength}) {
    final text = _trimTerminalPunctuation(_clean(source));
    if (text.length <= maxLength) {
      return text;
    }
    final cut = text.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > 120) {
      return '${cut.substring(0, lastSpace).trim()}...';
    }
    return '${cut.trim()}...';
  }
}
