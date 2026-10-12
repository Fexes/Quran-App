import 'package:equatable/equatable.dart';

import '../../../../core/constants/quran_arabic_script.dart';
import 'quran_ayah.dart';

class QuranWord extends Equatable {
  const QuranWord({
    required this.verseKey,
    required this.ayahNumber,
    required this.wordIndex,
    required this.arabicText,
    required this.translation,
    required this.page,
    required this.lineNumber,
  });

  factory QuranWord.fromJson(Map<dynamic, dynamic> json) {
    return QuranWord(
      verseKey: _string(json['verseKey']),
      ayahNumber: _int(json['ayahNumber']),
      wordIndex: _int(json['wordIndex']),
      arabicText: _string(json['arabicText']),
      translation: _string(json['translation']),
      page: _int(json['page']),
      lineNumber: _int(json['lineNumber']),
    );
  }

  final String verseKey;
  final int ayahNumber;
  final int wordIndex;
  final String arabicText;
  final String translation;
  final int page;
  final int lineNumber;

  static List<QuranWord> forAyahText(
    QuranAyah ayah,
    List<QuranWord> words,
    QuranArabicScript script,
  ) {
    if (words.isEmpty) return const [];
    final display = QuranArabicScript.wordSpans(ayah.textForScript(script));
    final byPosition = {for (final word in words) word.wordIndex: word};
    final isIndoPak =
        script == QuranArabicScript.indoPak && ayah.indoPakText != null;
    final positions = isIndoPak
        ? ayah.indoPakWordPositions
        : List.generate(display.length, (index) => index + 1);
    // Never attach meanings to a mismatched canonical word sequence.
    final aligned =
        positions.length == display.length &&
        (isIndoPak ||
            (byPosition.length == display.length &&
                positions.every(byPosition.containsKey)));
    return [
      for (var index = 0; index < display.length; index++)
        QuranWord(
          verseKey: ayah.verseKey,
          ayahNumber: ayah.number,
          wordIndex: index + 1,
          arabicText: display[index].trimRight(),
          translation: aligned
              ? byPosition[positions[index]]?.translation ?? ''
              : '',
          page: ayah.page,
          lineNumber: words.first.lineNumber,
        ),
    ];
  }

  Map<String, Object> toJson() {
    return {
      'verseKey': verseKey,
      'ayahNumber': ayahNumber,
      'wordIndex': wordIndex,
      'arabicText': arabicText,
      'translation': translation,
      'page': page,
      'lineNumber': lineNumber,
    };
  }

  @override
  List<Object> get props => [
    verseKey,
    ayahNumber,
    wordIndex,
    arabicText,
    translation,
    page,
    lineNumber,
  ];

  static String _string(Object? value) {
    return value is String ? value : '';
  }

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class QuranInterlinearLine extends Equatable {
  const QuranInterlinearLine({
    required this.words,
    required this.displayArabic,
    required this.displayTranslation,
    required this.arabicWidth,
    required this.gapCount,
    required this.wordSpacing,
  });

  final List<QuranWord> words;
  final String displayArabic;
  final String displayTranslation;
  final double arabicWidth;
  final int gapCount;
  final double wordSpacing;

  Set<String> get verseKeys => words.map((word) => word.verseKey).toSet();

  bool containsVerse(String? verseKey) {
    return verseKey != null && verseKeys.contains(verseKey);
  }

  @override
  List<Object> get props => [
    words,
    displayArabic,
    displayTranslation,
    arabicWidth,
    gapCount,
    wordSpacing,
  ];
}

class QuranInterlinearDownloadProgress extends Equatable {
  const QuranInterlinearDownloadProgress({
    required this.completedPages,
    required this.totalPages,
    required this.failedPages,
    this.isComplete = false,
  });

  final int completedPages;
  final int totalPages;
  final int failedPages;
  final bool isComplete;

  double get percent {
    if (totalPages <= 0) {
      return 0;
    }
    return (completedPages / totalPages).clamp(0, 1).toDouble();
  }

  @override
  List<Object> get props => [
    completedPages,
    totalPages,
    failedPages,
    isComplete,
  ];
}
