import 'package:equatable/equatable.dart';

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
