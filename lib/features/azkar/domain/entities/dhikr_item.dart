import 'package:equatable/equatable.dart';

class DhikrItem extends Equatable {
  const DhikrItem({
    required this.id,
    required this.categoryId,
    required this.arabic,
    required this.translation,
    required this.transliteration,
    required this.reference,
    required this.repeatCount,
    required this.sourceId,
    this.title = '',
    this.notes = '',
    this.benefit = '',
    this.categorySortOrder = 0,
    this.itemSortOrder = 0,
  });

  final String id;
  final String categoryId;
  final String arabic;
  final String translation;
  final String transliteration;
  final String reference;
  final int repeatCount;
  final String sourceId;
  final String title;
  final String notes;
  final String benefit;
  final int categorySortOrder;
  final int itemSortOrder;

  DhikrItem withTranslation({
    required String translation,
    String? title,
    String? reference,
  }) {
    return DhikrItem(
      id: id,
      categoryId: categoryId,
      arabic: arabic,
      translation: translation,
      transliteration: transliteration,
      reference: reference?.isNotEmpty == true ? reference! : this.reference,
      repeatCount: repeatCount,
      sourceId: sourceId,
      title: title?.isNotEmpty == true ? title! : this.title,
      notes: notes,
      benefit: benefit,
      categorySortOrder: categorySortOrder,
      itemSortOrder: itemSortOrder,
    );
  }

  factory DhikrItem.fromMap(Map<String, dynamic> map) {
    return DhikrItem(
      id: map['id'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      arabic: map['arabic'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      repeatCount: map['repeatCount'] as int? ?? 1,
      sourceId: map['sourceId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      benefit: map['benefit'] as String? ?? '',
      categorySortOrder: map['categorySortOrder'] as int? ?? 0,
      itemSortOrder: map['itemSortOrder'] as int? ?? 0,
    );
  }

  @override
  List<Object> get props => [
    id,
    categoryId,
    arabic,
    translation,
    transliteration,
    reference,
    repeatCount,
    sourceId,
    title,
    notes,
    benefit,
    categorySortOrder,
    itemSortOrder,
  ];
}
