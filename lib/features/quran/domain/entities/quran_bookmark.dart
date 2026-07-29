import 'package:equatable/equatable.dart';

class QuranBookmark extends Equatable {
  const QuranBookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.createdAt,
    this.collectionId = QuranBookmarkCollection.defaultId,
  });

  final int surahNumber;
  final int ayahNumber;
  final DateTime createdAt;
  final String collectionId;

  String get verseKey => '$surahNumber:$ayahNumber';

  @override
  List<Object> get props => [surahNumber, ayahNumber, createdAt, collectionId];
}

class QuranBookmarkCollection extends Equatable {
  const QuranBookmarkCollection({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    this.description = '',
  });

  static const defaultId = 'default';

  factory QuranBookmarkCollection.fromJson(Map<dynamic, dynamic> json) {
    return QuranBookmarkCollection(
      id: json['id'] as String? ?? defaultId,
      name: json['name'] as String? ?? 'Saved ayahs',
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF2E7D5B,
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe0bb,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String name;
  final String description;
  final int colorValue;
  final int iconCodePoint;
  final DateTime createdAt;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    name,
    description,
    colorValue,
    iconCodePoint,
    createdAt,
  ];
}
