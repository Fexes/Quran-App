import 'package:equatable/equatable.dart';

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
  ];
}
