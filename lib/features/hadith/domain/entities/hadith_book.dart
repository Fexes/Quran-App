import 'package:equatable/equatable.dart';

class HadithBook extends Equatable {
  const HadithBook({
    required this.id,
    required this.slug,
    required this.englishName,
    required this.arabicName,
    required this.sourceId,
    this.shortName = '',
    this.description = '',
    this.hadithCount = 0,
    this.chapterCount = 0,
    this.sortOrder = 0,
    this.availableLanguages = const [],
  });

  final String id;
  final String slug;
  final String englishName;
  final String arabicName;
  final String sourceId;
  final String shortName;
  final String description;
  final int hadithCount;
  final int chapterCount;
  final int sortOrder;
  final List<String> availableLanguages;

  factory HadithBook.fromMap(Map<String, dynamic> map) {
    return HadithBook(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      englishName: map['englishName'] as String? ?? '',
      arabicName: map['arabicName'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      shortName: map['shortName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      hadithCount: map['hadithCount'] as int? ?? 0,
      chapterCount: map['chapterCount'] as int? ?? 0,
      sortOrder: map['sortOrder'] as int? ?? 0,
      availableLanguages: [
        for (final language in map['availableLanguages'] as List? ?? const [])
          language.toString(),
      ],
    );
  }

  @override
  List<Object> get props => [
    id,
    slug,
    englishName,
    arabicName,
    sourceId,
    shortName,
    description,
    hadithCount,
    chapterCount,
    sortOrder,
    availableLanguages,
  ];
}
