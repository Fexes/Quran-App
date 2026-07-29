import 'package:equatable/equatable.dart';

enum QuranStructureKind { surah, juz, hizb, rub, page, sajdah, manzil }

class QuranNavigationPoint extends Equatable {
  const QuranNavigationPoint({
    required this.kind,
    required this.index,
    required this.label,
    required this.surahNumber,
    required this.ayahNumber,
    required this.page,
    required this.juz,
    this.rubIndex,
  });

  final QuranStructureKind kind;
  final int index;
  final String label;
  final int surahNumber;
  final int ayahNumber;
  final int page;
  final int juz;
  final int? rubIndex;

  String get verseKey => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [
    kind,
    index,
    label,
    surahNumber,
    ayahNumber,
    page,
    juz,
    rubIndex,
  ];
}
