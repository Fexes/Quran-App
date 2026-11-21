import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Text transformations shared with the offline indexing pipeline.
abstract final class OfflineSearchNormalizer {
  static final _whitespace = RegExp(
    r'[\u0009-\u000d\u0020\u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+',
    unicode: true,
  );
  static final _arabicMarks = RegExp(
    r'[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed\u0640]',
    unicode: true,
  );
  static final _keywordSeparators = RegExp(
    r'[^\p{L}\p{N}\p{M}]+',
    unicode: true,
  );
  static final _cased = RegExp(r'^\p{Cased}$', unicode: true);
  static final _caseIgnorable = RegExp(r'^\p{Case_Ignorable}$', unicode: true);
  static final _outerSpaces = RegExp(r'^ +| +$');

  /// Preserve the source script and diacritics used by the embedding model.
  static String semantic(String text) =>
      text.replaceAll(_whitespace, ' ').replaceAll(_outerSpaces, '');

  static String keyword(String text) => semantic(
    _foldArabic(_lower(unorm.nfkc(text))).replaceAll(_keywordSeparators, ' '),
  );

  /// Keep citation separators while accepting both Arabic digit alphabets.
  static String reference(String text) {
    final normalized = _lower(unorm.nfkc(text));
    final digits = String.fromCharCodes(
      normalized.runes.map((rune) {
        if (rune >= 0x0660 && rune <= 0x0669) return rune - 0x0660 + 0x30;
        if (rune >= 0x06f0 && rune <= 0x06f9) return rune - 0x06f0 + 0x30;
        return rune;
      }),
    );
    return semantic(digits).replaceAll(RegExp(r' *: *'), ':');
  }

  /// Dart's simple case mapping omits Unicode's two default full-lowercase
  /// special rules. Match the Python indexing pipeline's str.lower behavior.
  static String _lower(String input) {
    if (!input.contains('\u03a3')) {
      return input.replaceAll('\u0130', 'i\u0307').toLowerCase();
    }
    final characters = [
      for (final rune in input.runes) String.fromCharCode(rune),
    ];
    final followedByCased = List<bool>.filled(characters.length, false);
    var nextIsCased = false;
    for (var i = characters.length - 1; i >= 0; i--) {
      followedByCased[i] = nextIsCased;
      if (!_caseIgnorable.hasMatch(characters[i])) {
        nextIsCased = _cased.hasMatch(characters[i]);
      }
    }
    final output = StringBuffer();
    var previousIsCased = false;
    for (var i = 0; i < characters.length; i++) {
      final character = characters[i];
      if (character == '\u03a3' && previousIsCased && !followedByCased[i]) {
        output.write('\u03c2');
      } else if (character == '\u0130') {
        output.write('i\u0307');
      } else {
        output.write(character.toLowerCase());
      }
      if (!_caseIgnorable.hasMatch(character)) {
        previousIsCased = _cased.hasMatch(character);
      }
    }
    return output.toString();
  }

  static String _foldArabic(String text) => text
      .replaceAll(_arabicMarks, '')
      .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627')
      .replaceAll('\u0649', '\u064a')
      .replaceAll('\u06cc', '\u064a')
      .replaceAll('\u06a9', '\u0643');
}
