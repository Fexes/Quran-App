import 'package:flutter/material.dart';

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
    final direction = _translationDirection(resource: resource, text: text);
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
    required String text,
  }) {
    if (resource != null) {
      return resource.textDirection;
    }
    return _hasStrongRtlText(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  static bool _hasStrongRtlText(String text) {
    // Ayah brackets are also present in otherwise left-to-right translations.
    final withoutAyahBrackets = text.replaceAll(RegExp(r'[\uFD3E\uFD3F]'), '');
    return RegExp(
      r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(withoutAyahBrackets);
  }
}
