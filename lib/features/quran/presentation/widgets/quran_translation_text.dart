import 'package:flutter/material.dart';

import '../../domain/entities/quran_translation.dart';

class QuranTranslationText extends StatelessWidget {
  const QuranTranslationText({
    super.key,
    required this.text,
    required this.style,
    this.resource,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final QuranTranslationResource? resource;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final direction = _translationDirection(resource: resource, text: text);
    final align = direction == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
    return Directionality(
      textDirection: direction,
      child: Text(
        text,
        textAlign: align,
        textDirection: direction,
        style: style,
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
    return RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
  }
}
