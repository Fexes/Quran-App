import 'package:equatable/equatable.dart';

import '../../../../core/content/content_source.dart';
import '../../domain/entities/hadeeth_enc_item.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_chapter.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/repositories/hadith_repository.dart';

enum HadithLibraryStatus { initial, loading, success, empty, failure }

class HadithLibraryState extends Equatable {
  const HadithLibraryState({
    required this.status,
    required this.books,
    required this.chapters,
    required this.hadiths,
    this.hadeethEncLanguages = const [],
    this.hadeethEncHadiths = const [],
    required this.contentSources,
    required this.query,
    this.selectedBookId,
    this.selectedChapterId,
    this.selectedTranslationLanguageCode,
    this.selectedHadeethEncLanguageCode,
    this.selectedHadeethEncLanguageDownloaded = false,
    this.hadeethEncLoading = false,
    this.hasMoreHadeethEncHadiths = false,
    this.hadeethEncDownloadProgress,
    this.hadeethEncErrorMessage,
    this.hasMoreHadiths = false,
    this.errorMessage,
  });

  const HadithLibraryState.initial()
    : status = HadithLibraryStatus.initial,
      books = const [],
      chapters = const [],
      hadiths = const [],
      hadeethEncLanguages = const [],
      hadeethEncHadiths = const [],
      contentSources = const [],
      query = '',
      selectedBookId = null,
      selectedChapterId = null,
      selectedTranslationLanguageCode = null,
      selectedHadeethEncLanguageCode = null,
      selectedHadeethEncLanguageDownloaded = false,
      hadeethEncLoading = false,
      hasMoreHadeethEncHadiths = false,
      hadeethEncDownloadProgress = null,
      hadeethEncErrorMessage = null,
      hasMoreHadiths = false,
      errorMessage = null;

  final HadithLibraryStatus status;
  final List<HadithBook> books;
  final List<HadithChapter> chapters;
  final List<HadithItem> hadiths;
  final List<HadeethEncLanguage> hadeethEncLanguages;
  final List<HadithItem> hadeethEncHadiths;
  final List<ContentSource> contentSources;
  final String query;
  final String? selectedBookId;
  final String? selectedChapterId;
  final String? selectedTranslationLanguageCode;
  final String? selectedHadeethEncLanguageCode;
  final bool selectedHadeethEncLanguageDownloaded;
  final bool hadeethEncLoading;
  final bool hasMoreHadeethEncHadiths;
  final HadeethEncDownloadProgress? hadeethEncDownloadProgress;
  final String? hadeethEncErrorMessage;
  final bool hasMoreHadiths;
  final String? errorMessage;

  HadithBook? get selectedBook {
    final id = selectedBookId;
    if (id == null) {
      return null;
    }
    for (final book in books) {
      if (book.id == id) {
        return book;
      }
    }
    return null;
  }

  HadithLibraryState copyWith({
    HadithLibraryStatus? status,
    List<HadithBook>? books,
    List<HadithChapter>? chapters,
    List<HadithItem>? hadiths,
    List<HadeethEncLanguage>? hadeethEncLanguages,
    List<HadithItem>? hadeethEncHadiths,
    List<ContentSource>? contentSources,
    String? query,
    Object? selectedBookId = _sentinel,
    Object? selectedChapterId = _sentinel,
    Object? selectedTranslationLanguageCode = _sentinel,
    Object? selectedHadeethEncLanguageCode = _sentinel,
    bool? selectedHadeethEncLanguageDownloaded,
    bool? hadeethEncLoading,
    bool? hasMoreHadeethEncHadiths,
    Object? hadeethEncDownloadProgress = _sentinel,
    String? hadeethEncErrorMessage,
    bool? hasMoreHadiths,
    String? errorMessage,
  }) {
    return HadithLibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      chapters: chapters ?? this.chapters,
      hadiths: hadiths ?? this.hadiths,
      hadeethEncLanguages: hadeethEncLanguages ?? this.hadeethEncLanguages,
      hadeethEncHadiths: hadeethEncHadiths ?? this.hadeethEncHadiths,
      contentSources: contentSources ?? this.contentSources,
      query: query ?? this.query,
      selectedBookId: selectedBookId == _sentinel
          ? this.selectedBookId
          : selectedBookId as String?,
      selectedChapterId: selectedChapterId == _sentinel
          ? this.selectedChapterId
          : selectedChapterId as String?,
      selectedTranslationLanguageCode:
          selectedTranslationLanguageCode == _sentinel
          ? this.selectedTranslationLanguageCode
          : selectedTranslationLanguageCode as String?,
      selectedHadeethEncLanguageCode:
          selectedHadeethEncLanguageCode == _sentinel
          ? this.selectedHadeethEncLanguageCode
          : selectedHadeethEncLanguageCode as String?,
      selectedHadeethEncLanguageDownloaded:
          selectedHadeethEncLanguageDownloaded ??
          this.selectedHadeethEncLanguageDownloaded,
      hadeethEncLoading: hadeethEncLoading ?? this.hadeethEncLoading,
      hasMoreHadeethEncHadiths:
          hasMoreHadeethEncHadiths ?? this.hasMoreHadeethEncHadiths,
      hadeethEncDownloadProgress: hadeethEncDownloadProgress == _sentinel
          ? this.hadeethEncDownloadProgress
          : hadeethEncDownloadProgress as HadeethEncDownloadProgress?,
      hadeethEncErrorMessage: hadeethEncErrorMessage,
      hasMoreHadiths: hasMoreHadiths ?? this.hasMoreHadiths,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    books,
    chapters,
    hadiths,
    hadeethEncLanguages,
    hadeethEncHadiths,
    contentSources,
    query,
    selectedBookId,
    selectedChapterId,
    selectedTranslationLanguageCode,
    selectedHadeethEncLanguageCode,
    selectedHadeethEncLanguageDownloaded,
    hadeethEncLoading,
    hasMoreHadeethEncHadiths,
    hadeethEncDownloadProgress,
    hadeethEncErrorMessage,
    hasMoreHadiths,
    errorMessage,
  ];
}

const _sentinel = Object();
