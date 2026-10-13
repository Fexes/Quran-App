import 'package:equatable/equatable.dart';

class DeepSearchIndexRecord extends Equatable {
  const DeepSearchIndexRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.primaryPreview,
    required this.secondaryPreview,
    required this.normalizedText,
    required this.targetType,
    required this.targetId,
    this.bookId,
    this.categoryId,
    this.languageCode,
  });

  factory DeepSearchIndexRecord.fromMap(Map<String, dynamic> map) {
    return DeepSearchIndexRecord(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      primaryPreview: map['primaryPreview'] as String? ?? '',
      secondaryPreview: map['secondaryPreview'] as String? ?? '',
      normalizedText: map['normalizedText'] as String? ?? '',
      targetType: map['targetType'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      bookId: map['bookId'] as String?,
      categoryId: map['categoryId'] as String?,
      languageCode: map['languageCode'] as String?,
    );
  }

  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String primaryPreview;
  final String secondaryPreview;
  final String normalizedText;
  final String targetType;
  final String targetId;
  final String? bookId;
  final String? categoryId;
  final String? languageCode;

  @override
  List<Object?> get props => [
    id,
    category,
    title,
    subtitle,
    primaryPreview,
    secondaryPreview,
    normalizedText,
    targetType,
    targetId,
    bookId,
    categoryId,
    languageCode,
  ];
}
