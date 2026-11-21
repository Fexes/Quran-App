import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/quran_translation.dart';

class QuranTranslationText extends StatelessWidget {
  const QuranTranslationText({
    super.key,
    required this.text,
    required this.style,
    this.resource,
    this.languageCode,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final QuranTranslationResource? resource;
  final String? languageCode;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = _translationDirection(
      resource: resource,
      languageCode: languageCode,
      text: text,
    );
    final align =
        textAlign ??
        (direction == TextDirection.rtl ? TextAlign.right : TextAlign.left);
    return Directionality(
      textDirection: direction,
      child: Text(
        text,
        textAlign: align,
        textDirection: direction,
        style: QuranTheme.translationStyle(
          style,
          languageCode ?? resource?.resolvedLanguageCode,
        ),
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  static TextDirection _translationDirection({
    required QuranTranslationResource? resource,
    required String? languageCode,
    required String text,
  }) {
    final code = languageCode?.trim().replaceAll('_', '-').toLowerCase();
    if (code != null && code.isNotEmpty) {
      // Kurdish can use Arabic or Latin script when no script tag is supplied.
      if (code == 'ku') {
        return _hasStrongRtlText(text) ? TextDirection.rtl : TextDirection.ltr;
      }
      return Bidi.isRtlLanguage(code) ? TextDirection.rtl : TextDirection.ltr;
    }
    if (resource != null) {
      return resource.textDirection;
    }
    return _hasStrongRtlText(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static bool _hasStrongRtlText(String text) {
    // Brackets and devotional symbols must not flip an English paragraph.
    final withoutDecorations = text.replaceAll(
      RegExp(r'[\uFD3E\uFD3F\uFDFA\uFDFB]'),
      '',
    );
    return Bidi.startsWithRtl(withoutDecorations);
  }
}
