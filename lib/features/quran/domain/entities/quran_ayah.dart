import 'package:equatable/equatable.dart';

import '../../../../core/constants/quran_arabic_script.dart';

class QuranAyah extends Equatable {
  const QuranAyah({
    required this.surahNumber,
    required this.number,
    required this.text,
    required this.translation,
    required this.page,
    required this.juz,
    required this.isSajda,
    this.isPageStart = false,
    this.isJuzStart = false,
    this.rubIndex,
    this.manzil,
    this.globalNumber = 0,
    this.tafsir,
    this.indoPakText,
    this.indoPakWordPositions = const [],
  });

  final int surahNumber;
  final int number;
  final String text;
  final String translation;
  final int page;
  final int juz;
  final bool isSajda;
  final bool isPageStart;
  final bool isJuzStart;
  final int? rubIndex;
  final int? manzil;
  final int globalNumber;
  final String? tafsir;
  final String? indoPakText;
  final List<int> indoPakWordPositions;

  String textForScript(QuranArabicScript script) =>
      script == QuranArabicScript.indoPak
      ? indoPakText ?? QuranArabicScript.cleanUthmaniText(text)
      : QuranArabicScript.cleanUthmaniText(text);

  int? wordIndexForScript(QuranArabicScript script, int? wordIndex) {
    if (wordIndex == null || script == QuranArabicScript.uthmani) {
      return wordIndex;
    }
    final index = indoPakWordPositions.indexOf(wordIndex);
    return index < 0 ? null : index + 1;
  }

  QuranAyah forScript(QuranArabicScript script) {
    if (script == QuranArabicScript.uthmani) return this;
    return QuranAyah(
      surahNumber: surahNumber,
      number: number,
      text: textForScript(script),
      translation: translation,
      page: page,
      juz: juz,
      isSajda: isSajda,
      isPageStart: isPageStart,
      isJuzStart: isJuzStart,
      rubIndex: rubIndex,
      manzil: manzil,
      globalNumber: globalNumber,
      tafsir: tafsir,
      indoPakText: indoPakText,
      indoPakWordPositions: indoPakWordPositions,
    );
  }

  String get verseKey => '$surahNumber:$number';
  bool get isRubBoundary => rubIndex != null;
  bool get isHizbBoundary => rubIndex != null && ((rubIndex! - 1) % 4 == 0);
  int? get hizb => isHizbBoundary ? ((rubIndex! - 1) ~/ 4) + 1 : null;

  @override
  List<Object?> get props => [
    surahNumber,
    number,
    text,
    translation,
    page,
    juz,
    isSajda,
    isPageStart,
    isJuzStart,
    rubIndex,
    manzil,
    globalNumber,
    tafsir,
    indoPakText,
    indoPakWordPositions,
  ];
}
