import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_bookmark.dart';

enum QuranBookmarksStatus { initial, loading, success, failure }

enum QuranBookmarkSort { recent, quranOrder }

class QuranBookmarkSummary extends Equatable {
  const QuranBookmarkSummary({
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.createdAt,
    this.translationResource,
    this.collectionId = QuranBookmarkCollection.defaultId,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String translation;
  final DateTime createdAt;
  final QuranTranslationResource? translationResource;
  final String collectionId;

  @override
  List<Object?> get props => [
    surah,
    ayah,
    translation,
    createdAt,
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
    this.query = '',
    this.sort = QuranBookmarkSort.recent,
    this.isRefreshing = false,
    this.isUpdating = false,
  });

  const QuranBookmarksState.initial()
    : status = QuranBookmarksStatus.initial,
      bookmarks = const [],
      collections = const [],
      selectedCollectionId = null,
      errorMessage = null,
      query = '',
      sort = QuranBookmarkSort.recent,
      isRefreshing = false,
      isUpdating = false;

  final QuranBookmarksStatus status;
  final List<QuranBookmarkSummary> bookmarks;
  final List<QuranBookmarkCollection> collections;
  final String? selectedCollectionId;
  final String? errorMessage;
  final String query;
  final QuranBookmarkSort sort;
  final bool isRefreshing;
  final bool isUpdating;

  List<QuranBookmarkSummary> get visibleBookmarks {
    final search = query.trim().toLowerCase();
    final visible = bookmarks.where((item) {
      if (selectedCollectionId != null &&
          item.collectionId != selectedCollectionId) {
        return false;
      }
      return search.isEmpty ||
          item.surah.englishName.toLowerCase().contains(search) ||
          item.surah.arabicName.contains(search) ||
          item.ayah.verseKey.contains(search) ||
          item.ayah.text.contains(search) ||
          item.translation.toLowerCase().contains(search);
    }).toList();
    visible.sort((a, b) {
      if (sort == QuranBookmarkSort.recent) {
        final dateOrder = b.createdAt.compareTo(a.createdAt);
        if (dateOrder != 0) return dateOrder;
      }
      final surahOrder = a.surah.number.compareTo(b.surah.number);
      return surahOrder != 0
          ? surahOrder
          : a.ayah.number.compareTo(b.ayah.number);
    });
    return visible;
  }

  QuranBookmarksState copyWith({
    QuranBookmarksStatus? status,
    List<QuranBookmarkSummary>? bookmarks,
    List<QuranBookmarkCollection>? collections,
    String? selectedCollectionId,
    bool clearSelectedCollection = false,
    String? errorMessage,
    String? query,
    QuranBookmarkSort? sort,
    bool? isRefreshing,
    bool? isUpdating,
  }) {
    return QuranBookmarksState(
      status: status ?? this.status,
      bookmarks: bookmarks ?? this.bookmarks,
      collections: collections ?? this.collections,
      selectedCollectionId: clearSelectedCollection
          ? null
          : selectedCollectionId ?? this.selectedCollectionId,
      errorMessage: errorMessage,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
    status,
    bookmarks,
    collections,
    selectedCollectionId,
    errorMessage,
    query,
    sort,
    isRefreshing,
    isUpdating,
  ];
}
