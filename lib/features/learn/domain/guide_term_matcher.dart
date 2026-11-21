import 'guide_term.dart';

class GuideTermMatch {
  const GuideTermMatch({
    required this.start,
    required this.end,
    required this.term,
  });

  final int start;
  final int end;
  final GuideTerm term;
}

/// Finds complete glossary aliases without changing their displayed spelling.
class GuideTermMatcher {
  GuideTermMatcher(List<GuideTerm> terms) {
    final aliases = <({String text, String pattern, GuideTerm term})>[];
    final seen = <String>{};
    void add(String text, GuideTerm term) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      final pattern = _aliasPattern(trimmed);
      if (!seen.add(pattern.toLowerCase())) return;
      aliases.add((text: trimmed, pattern: pattern, term: term));
    }

    for (final term in terms) {
      for (final alias in {term.title, ...term.aliases}) {
        add(alias, term);
        final normalized = alias.trim().toLowerCase();
        if (normalized.length < 3 || normalized.endsWith('s')) continue;
        if (RegExp(r'[^aeiou]y$').hasMatch(normalized)) {
          add('${alias.trim().substring(0, alias.trim().length - 1)}ies', term);
        } else if (RegExp(r'(ch|sh|x|z)$').hasMatch(normalized)) {
          add('${alias.trim()}es', term);
        } else {
          add('${alias.trim()}s', term);
        }
      }
    }
    aliases.sort((a, b) => b.text.length.compareTo(a.text.length));
    _terms = [for (final alias in aliases) alias.term];
    _pattern = aliases.isEmpty
        ? null
        : RegExp(
            r'(?<![\p{L}\p{N}_])(?:' +
                aliases.map((alias) => '(${alias.pattern})').join('|') +
                r')(?![\p{L}\p{N}_])',
            caseSensitive: false,
            unicode: true,
          );
  }

  late final RegExp? _pattern;
  late final List<GuideTerm> _terms;

  Iterable<GuideTermMatch> findIn(String text) sync* {
    final pattern = _pattern;
    if (pattern == null) return;
    for (final match in pattern.allMatches(text)) {
      for (var index = 0; index < _terms.length; index++) {
        if (match.group(index + 1) == null) continue;
        yield GuideTermMatch(
          start: match.start,
          end: match.end,
          term: _terms[index],
        );
        break;
      }
    }
  }

  static String _aliasPattern(String alias) {
    const apostrophes = {"'", '’', '‘', 'ʼ', 'ʻ', 'ʾ', 'ʿ', '`', '´'};
    final words = alias.split(RegExp(r'\s+'));
    return words
        .map((word) {
          return word.runes.map((rune) {
            final character = String.fromCharCode(rune);
            if (apostrophes.contains(character)) return r"['’‘ʼʻʾʿ`´]";
            if ('-‐‑‒–'.contains(character)) return r'[-‐‑‒–]';
            return RegExp.escape(character);
          }).join();
        })
        .join(r'\s+');
  }
}
