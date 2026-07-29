import 'package:equatable/equatable.dart';

class QuranSurah extends Equatable {
  const QuranSurah({
    required this.number,
    required this.englishName,
    required this.arabicName,
    required this.ayahCount,
    required this.revelationType,
  });

  final int number;
  final String englishName;
  final String arabicName;
  final int ayahCount;
  final String revelationType;

  bool get isMeccan => revelationType.toLowerCase() == 'meccan';

  @override
  List<Object> get props => [
    number,
    englishName,
    arabicName,
    ayahCount,
    revelationType,
  ];
}
