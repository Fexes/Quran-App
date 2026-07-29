import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_bookmark.dart';

enum QuranBookmarksStatus { initial, loading, success, failure }

class QuranBookmarkSummary extends Equatable {
  const QuranBookmarkSummary({
    required this.surah,
    required this.ayah,
    required this.translation,
    this.translationResource,
    this.collectionId = QuranBookmarkCollection.defaultId,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String translation;
  final QuranTranslationResource? translationResource;
  final String collectionId;

  @override
  List<Object?> get props => [
    surah,
    ayah,
    translation,
    translationResource,
    collectionId,
  ];
}

class QuranBookmarksState extends Equatable {
  const QuranBookmarksState({
    required this.status,
    required this.bookmarks,
    this.collections = const [],
    this.selectedCollectionId,
    this.errorMessage,
  });

  const QuranBookmarksState.initial()
    : status = QuranBookmarksStatus.initial,
      bookmarks = const [],
      collections = const [],
      selectedCollectionId = null,
      errorMessage = null;

  final QuranBookmarksStatus status;
  final List<QuranBookmarkSummary> bookmarks;
  final List<QuranBookmarkCollection> collections;
  final String? selectedCollectionId;
  final String? errorMessage;

  QuranBookmarksState copyWith({
    QuranBookmarksStatus? status,
    List<QuranBookmarkSummary>? bookmarks,
    List<QuranBookmarkCollection>? collections,
    String? selectedCollectionId,
    bool clearSelectedCollection = false,
    String? errorMessage,
  }) {
    return QuranBookmarksState(
      status: status ?? this.status,
      bookmarks: bookmarks ?? this.bookmarks,
      collections: collections ?? this.collections,
      selectedCollectionId: clearSelectedCollection
          ? null
          : selectedCollectionId ?? this.selectedCollectionId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bookmarks,
    collections,
    selectedCollectionId,
    errorMessage,
  ];
}
