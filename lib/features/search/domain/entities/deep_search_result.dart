import 'package:equatable/equatable.dart';

enum DeepSearchCategory {
  quran,
  surah,
  translation,
  tafsir,
  notes,
  hadith,
  azkar,
}

enum DeepSearchTargetType { quranAyah, surah, note, hadith, azkar }

class DeepSearchTarget extends Equatable {
  const DeepSearchTarget({
    required this.type,
    this.surahNumber,
    this.ayahNumber,
    this.noteId,
    this.itemId,
    this.translationResourceId,
  });

  final DeepSearchTargetType type;
  final int? surahNumber;
  final int? ayahNumber;
  final String? noteId;
  final String? itemId;
  final int? translationResourceId;

  String? get verseKey {
    final surah = surahNumber;
    final ayah = ayahNumber;
    if (surah == null || ayah == null) {
      return null;
    }
    return '$surah:$ayah';
  }

  @override
  List<Object?> get props => [
    type,
    surahNumber,
    ayahNumber,
    noteId,
    itemId,
    translationResourceId,
  ];
}

class DeepSearchResult extends Equatable {
  const DeepSearchResult({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.secondaryText,
    required this.matchedField,
    required this.score,
    required this.target,
  });

  final String id;
  final DeepSearchCategory category;
  final String title;
  final String subtitle;
  final String primaryText;
  final String secondaryText;
  final String matchedField;
  final int score;
  final DeepSearchTarget target;

  @override
  List<Object> get props => [
    id,
    category,
    title,
    subtitle,
    primaryText,
    secondaryText,
    matchedField,
    score,
    target,
  ];
}

class DeepSearchSection extends Equatable {
  const DeepSearchSection({
    required this.category,
    required this.totalCount,
    required this.results,
  });

  final DeepSearchCategory category;
  final int totalCount;
  final List<DeepSearchResult> results;

  @override
  List<Object> get props => [category, totalCount, results];
}
