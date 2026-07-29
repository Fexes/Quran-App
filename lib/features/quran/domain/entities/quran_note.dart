import 'package:equatable/equatable.dart';

class QuranNote extends Equatable {
  const QuranNote({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.verseKey,
    this.translationResourceId,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? verseKey;
  final int? translationResourceId;

  QuranNote copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? verseKey,
    int? translationResourceId,
  }) {
    return QuranNote(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verseKey: verseKey ?? this.verseKey,
      translationResourceId:
          translationResourceId ?? this.translationResourceId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    createdAt,
    updatedAt,
    verseKey,
    translationResourceId,
  ];
}
