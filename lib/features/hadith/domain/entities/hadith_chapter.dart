import 'package:equatable/equatable.dart';

class HadithChapter extends Equatable {
  const HadithChapter({
    required this.id,
    required this.bookId,
    required this.number,
    required this.englishTitle,
    required this.arabicTitle,
    this.hadithCount = 0,
    this.startHadithNumber = '',
    this.endHadithNumber = '',
  });

  final String id;
  final String bookId;
  final int number;
  final String englishTitle;
  final String arabicTitle;
  final int hadithCount;
  final String startHadithNumber;
  final String endHadithNumber;

  factory HadithChapter.fromMap(Map<String, dynamic> map) {
    return HadithChapter(
      id: map['id'] as String? ?? '',
      bookId: map['bookId'] as String? ?? '',
      number: map['number'] as int? ?? 0,
      englishTitle: map['englishTitle'] as String? ?? '',
      arabicTitle: map['arabicTitle'] as String? ?? '',
      hadithCount: map['hadithCount'] as int? ?? 0,
      startHadithNumber: map['startHadithNumber'] as String? ?? '',
      endHadithNumber: map['endHadithNumber'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [
    id,
    bookId,
    number,
    englishTitle,
    arabicTitle,
    hadithCount,
    startHadithNumber,
    endHadithNumber,
  ];
}
