import 'package:equatable/equatable.dart';

class AzkarCategory extends Equatable {
  const AzkarCategory({
    required this.id,
    required this.slug,
    required this.englishName,
    required this.arabicName,
    required this.sourceId,
    this.description = '',
    this.itemCount = 0,
    this.sortOrder = 0,
    this.iconKey = '',
  });

  final String id;
  final String slug;
  final String englishName;
  final String arabicName;
  final String sourceId;
  final String description;
  final int itemCount;
  final int sortOrder;
  final String iconKey;

  factory AzkarCategory.fromMap(Map<String, dynamic> map) {
    return AzkarCategory(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      englishName: map['englishName'] as String? ?? '',
      arabicName: map['arabicName'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      itemCount: map['itemCount'] as int? ?? 0,
      sortOrder: map['sortOrder'] as int? ?? 0,
      iconKey: map['iconKey'] as String? ?? '',
    );
  }

  @override
  List<Object> get props => [
    id,
    slug,
    englishName,
    arabicName,
    sourceId,
    description,
    itemCount,
    sortOrder,
    iconKey,
  ];
}
