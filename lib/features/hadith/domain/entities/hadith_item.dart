import 'package:equatable/equatable.dart';

class HadithItem extends Equatable {
  const HadithItem({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.hadithNumber,
    required this.arabic,
    required this.translation,
    required this.grade,
    required this.reference,
    required this.sourceId,
    this.bookSlug = '',
    this.chapterNumber = 0,
    this.bookNumber = 0,
    this.arabicNumber = '',
    this.englishEdition = '',
    this.arabicEdition = '',
    this.grades = const [],
    this.collectionName = '',
    this.cleanReference = '',
  });

  final String id;
  final String bookId;
  final String chapterId;
  final String hadithNumber;
  final String arabic;
  final String translation;
  final String grade;
  final String reference;
  final String sourceId;
  final String bookSlug;
  final int chapterNumber;
  final int bookNumber;
  final String arabicNumber;
  final String englishEdition;
  final String arabicEdition;
  final List<Object?> grades;
  final String collectionName;
  final String cleanReference;

  factory HadithItem.fromMap(Map<String, dynamic> map) {
    return HadithItem(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      chapterId: map['chapterId'] as String? ?? '',
      hadithNumber: map['hadithNumber'] as String? ?? '',
      arabic: map['arabic'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      grade: map['grade'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      bookSlug: map['bookSlug'] as String? ?? '',
      chapterNumber: map['chapterNumber'] as int? ?? 0,
      bookNumber: map['bookNumber'] as int? ?? 0,
      arabicNumber: map['arabicNumber'] as String? ?? '',
      englishEdition: map['englishEdition'] as String? ?? '',
      arabicEdition: map['arabicEdition'] as String? ?? '',
      grades: List<Object?>.unmodifiable(map['grades'] as List? ?? const []),
      collectionName: map['collectionName'] as String? ?? '',
      cleanReference: map['cleanReference'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [
    id,
    bookId,
    chapterId,
    hadithNumber,
    arabic,
    translation,
    grade,
    reference,
    sourceId,
    bookSlug,
    chapterNumber,
    bookNumber,
    arabicNumber,
    englishEdition,
    arabicEdition,
    grades,
    collectionName,
    cleanReference,
  ];
}
