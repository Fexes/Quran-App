class SearchTextNormalizer {
  const SearchTextNormalizer._();

  static String normalize(String value) {
    final ascii = _normalizePlainAscii(value);
    if (ascii != null) {
      return ascii;
    }
    return _collapseWhitespace(
      _normalizeArabic(
        _foldLatinToAscii(
          _normalizePunctuation(
            _removeCombiningMarks(
              _foldFullWidthAscii(
                _decodeEntities(_stripHtml(value)),
              ).toLowerCase(),
            ),
          ),
        ),
      ),
    );
  }

  static String cleanVisibleText(String value) {
    if (_isSafePlainAscii(value)) {
      return _collapseWhitespace(value);
    }
    return _collapseWhitespace(_decodeEntities(_stripHtml(value)));
  }

  static String? _normalizePlainAscii(String value) {
    final buffer = StringBuffer();
    var lastWasSpace = true;
    for (final codeUnit in value.codeUnits) {
      if (codeUnit > 0x7F || codeUnit == 0x26 || codeUnit == 0x3C) {
        return null;
      }
      final lower = codeUnit >= 0x41 && codeUnit <= 0x5A
          ? codeUnit + 0x20
          : codeUnit;
      final keep =
          (lower >= 0x61 && lower <= 0x7A) ||
          (lower >= 0x30 && lower <= 0x39) ||
          lower == 0x3A;
      if (keep) {
        buffer.writeCharCode(lower);
        lastWasSpace = false;
        continue;
      }
      if (lower <= 0x20 || lower == 0x7F || lower != 0x3A) {
        if (!lastWasSpace) {
          buffer.write(' ');
          lastWasSpace = true;
        }
      }
    }
    final result = buffer.toString();
    return lastWasSpace && result.isNotEmpty
        ? result.substring(0, result.length - 1)
        : result;
  }

  static bool _isSafePlainAscii(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit > 0x7F || codeUnit == 0x26 || codeUnit == 0x3C) {
        return false;
      }
    }
    return true;
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), ' ');
  }

  static String _decodeEntities(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
          final codePoint = int.tryParse(match.group(1) ?? '');
          return codePoint == null
              ? match.group(0)!
              : String.fromCharCode(codePoint);
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
          final codePoint = int.tryParse(match.group(1) ?? '', radix: 16);
          return codePoint == null
              ? match.group(0)!
              : String.fromCharCode(codePoint);
        });
  }

  static String _foldFullWidthAscii(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune == 0x3000) {
        buffer.write(' ');
      } else if (rune >= 0xFF01 && rune <= 0xFF5E) {
        buffer.writeCharCode(rune - 0xFEE0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static String _normalizePunctuation(String value) {
    final stripped = value
        .replaceAll(RegExp(r'[ʿʾʼʻ’‘`´ʽʹ]'), '')
        .replaceAll(RegExp(r'[“”„‟]'), '"')
        .replaceAll(RegExp(r'[‐‑‒–—―−]'), '-');
    final buffer = StringBuffer();
    for (final rune in stripped.runes) {
      if (_isSearchLetterOrDigit(rune) || rune == 0x3A) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static bool _isSearchLetterOrDigit(int rune) {
    return (rune >= 0x30 && rune <= 0x39) ||
        (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0x00C0 && rune <= 0x024F) ||
        (rune >= 0x1E00 && rune <= 0x1EFF) ||
        (rune >= 0x0400 && rune <= 0x052F) ||
        (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF);
  }

  static String _foldLatinToAscii(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      buffer.write(_latinFold(rune));
    }
    return buffer.toString();
  }

  static String _latinFold(int rune) {
    switch (rune) {
      // Match the decomposed Cyrillic text in bundled search indexes.
      case 0x0451:
        return '\u0435';
      case 0x0439:
        return '\u0438';
      case 0x00E0:
      case 0x00E1:
      case 0x00E2:
      case 0x00E3:
      case 0x00E4:
      case 0x00E5:
      case 0x0101:
      case 0x0103:
      case 0x0105:
      case 0x01CE:
      case 0x0201:
      case 0x0203:
      case 0x1EA1:
      case 0x1EA3:
      case 0x1EA5:
      case 0x1EA7:
      case 0x1EA9:
      case 0x1EAB:
      case 0x1EAD:
      case 0x1EAF:
      case 0x1EB1:
      case 0x1EB3:
      case 0x1EB5:
      case 0x1EB7:
        return 'a';
      case 0x00E6:
        return 'ae';
      case 0x00E7:
      case 0x0107:
      case 0x0109:
      case 0x010B:
      case 0x010D:
        return 'c';
      case 0x010F:
      case 0x0111:
      case 0x1E0B:
      case 0x1E0D:
      case 0x1E0F:
      case 0x1E11:
      case 0x1E13:
        return 'd';
      case 0x00E8:
      case 0x00E9:
      case 0x00EA:
      case 0x00EB:
      case 0x0113:
      case 0x0115:
      case 0x0117:
      case 0x0119:
      case 0x011B:
      case 0x0205:
      case 0x0207:
      case 0x1EB9:
      case 0x1EBB:
      case 0x1EBD:
      case 0x1EBF:
      case 0x1EC1:
      case 0x1EC3:
      case 0x1EC5:
      case 0x1EC7:
        return 'e';
      case 0x011D:
      case 0x011F:
      case 0x0121:
      case 0x0123:
      case 0x01E7:
      case 0x1E21:
        return 'g';
      case 0x0125:
      case 0x0127:
      case 0x1E23:
      case 0x1E25:
      case 0x1E27:
      case 0x1E29:
      case 0x1E2B:
        return 'h';
      case 0x00EC:
      case 0x00ED:
      case 0x00EE:
      case 0x00EF:
      case 0x0129:
      case 0x012B:
      case 0x012D:
      case 0x012F:
      case 0x01D0:
      case 0x0209:
      case 0x020B:
      case 0x1EC9:
      case 0x1ECB:
        return 'i';
      case 0x0135:
        return 'j';
      case 0x0137:
      case 0x1E31:
      case 0x1E33:
      case 0x1E35:
        return 'k';
      case 0x013A:
      case 0x013C:
      case 0x013E:
      case 0x0140:
      case 0x0142:
      case 0x1E37:
      case 0x1E39:
      case 0x1E3B:
      case 0x1E3D:
        return 'l';
      case 0x1E3F:
      case 0x1E41:
      case 0x1E43:
        return 'm';
      case 0x00F1:
      case 0x0144:
      case 0x0146:
      case 0x0148:
      case 0x1E45:
      case 0x1E47:
      case 0x1E49:
      case 0x1E4B:
        return 'n';
      case 0x00F2:
      case 0x00F3:
      case 0x00F4:
      case 0x00F5:
      case 0x00F6:
      case 0x00F8:
      case 0x014D:
      case 0x014F:
      case 0x0151:
      case 0x01D2:
      case 0x020D:
      case 0x020F:
      case 0x1ECD:
      case 0x1ECF:
      case 0x1ED1:
      case 0x1ED3:
      case 0x1ED5:
      case 0x1ED7:
      case 0x1ED9:
      case 0x1EDB:
      case 0x1EDD:
      case 0x1EDF:
      case 0x1EE1:
      case 0x1EE3:
        return 'o';
      case 0x0153:
        return 'oe';
      case 0x1E55:
      case 0x1E57:
        return 'p';
      case 0x0155:
      case 0x0157:
      case 0x0159:
      case 0x1E59:
      case 0x1E5B:
      case 0x1E5D:
      case 0x1E5F:
        return 'r';
      case 0x015B:
      case 0x015D:
      case 0x015F:
      case 0x0161:
      case 0x1E61:
      case 0x1E63:
      case 0x1E65:
      case 0x1E67:
      case 0x1E69:
        return 's';
      case 0x00DF:
        return 'ss';
      case 0x0163:
      case 0x0165:
      case 0x0167:
      case 0x1E6B:
      case 0x1E6D:
      case 0x1E6F:
      case 0x1E71:
      case 0x1E97:
        return 't';
      case 0x00F9:
      case 0x00FA:
      case 0x00FB:
      case 0x00FC:
      case 0x0169:
      case 0x016B:
      case 0x016D:
      case 0x016F:
      case 0x0171:
      case 0x0173:
      case 0x01D4:
      case 0x0215:
      case 0x0217:
      case 0x1EE5:
      case 0x1EE7:
      case 0x1EE9:
      case 0x1EEB:
      case 0x1EED:
      case 0x1EEF:
      case 0x1EF1:
        return 'u';
      case 0x1E7D:
      case 0x1E7F:
        return 'v';
      case 0x0175:
      case 0x1E81:
      case 0x1E83:
      case 0x1E85:
      case 0x1E87:
      case 0x1E89:
        return 'w';
      case 0x00FD:
      case 0x00FF:
      case 0x0177:
      case 0x1E8F:
      case 0x1E99:
      case 0x1EF3:
      case 0x1EF5:
      case 0x1EF7:
      case 0x1EF9:
        return 'y';
      case 0x017A:
      case 0x017C:
      case 0x017E:
      case 0x1E91:
      case 0x1E93:
      case 0x1E95:
        return 'z';
      default:
        return String.fromCharCode(rune);
    }
  }

  static String _removeCombiningMarks(String value) {
    return value
        .replaceAll(RegExp(r'[\u0300-\u036F\u1AB0-\u1AFF\u1DC0-\u1DFF]'), '')
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        );
  }

  static String _normalizeArabic(String value) {
    return value
        .replaceAll('\u0640', '')
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه');
  }

  static String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
