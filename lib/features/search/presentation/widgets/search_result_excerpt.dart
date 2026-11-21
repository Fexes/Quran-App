import '../../../../core/search/search_query_terms.dart';
import '../../../../core/search/search_text_normalizer.dart';

/// Selects a contiguous extract from the original source, without paraphrasing.
/// The display window is independent of retrieval rank and religious authority.
String searchResultExcerpt(
  String text,
  String query, {
  int maxCharacters = 420,
}) {
  if (text.length <= maxCharacters) return text;
  final words = RegExp(r'\S+').allMatches(text).toList(growable: false);
  if (words.isEmpty) return text;
  final terms = SearchQueryTerms.keywords(query)
      .map(SearchTextNormalizer.normalize)
      .where((term) => term.isNotEmpty)
      .toSet();
  final normalized = words
      .map((word) => SearchTextNormalizer.normalize(word.group(0)!))
      .toList(growable: false);
  var bestStart = 0;
  var bestEnd = 0;
  var bestScore = -1.0;
  // Linear scan with overlapping windows. A late match in a long commentary
  // remains eligible; only the visible extract is shortened.
  for (var start = 0; start < words.length; start += 18) {
    var end = start;
    while (end + 1 < words.length &&
        words[end + 1].end - words[start].start <= maxCharacters) {
      end++;
    }
    final window = ' ${normalized.sublist(start, end + 1).join(' ')} ';
    final matches = terms.where((term) => window.contains(' $term ')).length;
    // Prefer a full contextual window over a short trailing fragment.
    final fullness = (words[end].end - words[start].start) / maxCharacters;
    // When semantic retrieval has no literal overlap, retain the opening text
    // rather than choosing an arbitrary fuller window from the middle.
    final score = matches == 0 ? 0.0 : matches + fullness.clamp(0, 1) * 0.01;
    if (score > bestScore) {
      bestScore = score;
      bestStart = start;
      bestEnd = end;
    }
    if (end == words.length - 1) break;
  }
  var start = words[bestStart].start;
  var end = words[bestEnd].end;
  // Exceptionally long unbroken text still has a bounded preview. Avoid
  // splitting a UTF-16 surrogate pair in source text.
  if (end - start > maxCharacters && bestStart == bestEnd) {
    end = start + maxCharacters;
    final codeUnit = text.codeUnitAt(end - 1);
    if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) end--;
  }
  // Include the start of a nearby sentence rather than beginning mid-thought.
  if (bestStart > 0) {
    for (
      var index = bestStart - 1;
      index >= 0 && index >= bestStart - 10;
      index--
    ) {
      if (RegExp(r'[.!?؟۔][”"\x27)]?$').hasMatch(words[index].group(0)!)) {
        start = words[index + 1].start;
        break;
      }
    }
  }
  return '${start == 0 ? '' : '… '}${text.substring(start, end).trim()}${end == text.length ? '' : ' …'}';
}
