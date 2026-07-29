import 'package:equatable/equatable.dart';

class QuranLastRead extends Equatable {
  const QuranLastRead({
    required this.surahNumber,
    required this.ayahNumber,
    required this.updatedAt,
    this.page,
    this.structureKind,
    this.structureIndex,
    this.ayahTextLayout,
  });

  final int surahNumber;
  final int ayahNumber;
  final DateTime updatedAt;
  final int? page;
  final String? structureKind;
  final int? structureIndex;
  final String? ayahTextLayout;

  String get verseKey => '$surahNumber:$ayahNumber';

  @override
  List<Object?> get props => [
    surahNumber,
    ayahNumber,
    updatedAt,
    page,
    structureKind,
    structureIndex,
    ayahTextLayout,
  ];
}
