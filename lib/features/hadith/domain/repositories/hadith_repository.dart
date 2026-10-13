import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../entities/hadeeth_enc_item.dart';
import '../entities/hadith_book.dart';
import '../entities/hadith_chapter.dart';
import '../entities/hadith_item.dart';

abstract interface class HadithRepository {
  Future<List<ContentSource>> getContentSources();

  Future<List<HadithBook>> getBooks();

  Future<HadithBook?> getBook(String bookId);

  Future<List<HadithChapter>> getChapters(String bookId);

  Future<List<String>> availableTranslationLanguagesForBook(String bookId);

  Future<bool> hasFullTranslation(String bookId, String languageCode);

  Stream<HadithTranslationDownloadProgress> downloadBookTranslation(
    String bookId,
    String languageCode,
  );

  Future<List<HadithItem>> getHadiths({
    String? bookId,
    String? chapterId,
    String? languageCode,
    int offset = 0,
    int limit = 50,
  });

  Future<HadithItem?> getHadithById(String id, {String? languageCode});

  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords();

  Future<List<HadithItem>> search(String query, {int limit = 30});

  Future<List<HadeethEncLanguage>> getHadeethEncLanguages();

  Future<bool> hasHadeethEncLanguage(String languageCode);

  Stream<HadeethEncDownloadProgress> downloadHadeethEncLanguage(
    String languageCode,
  );

  Future<List<HadeethEncItem>> getHadeethEncItems({
    required String languageCode,
    int offset = 0,
    int limit = 50,
  });

  Future<List<HadeethEncItem>> searchHadeethEnc({
    required String languageCode,
    required String query,
    int limit = 30,
  });
}

abstract interface class HadithScopedSearchRepository {
  Future<List<HadithItem>> searchInBook({
    required String bookId,
    required String query,
    String? languageCode,
    int limit = 50,
  });
}

abstract interface class HadithTranslationPackRepository {
  Future<HadithTranslationPackStatus> translationPackStatus(
    String bookId,
    String languageCode,
  );
}

class HadithTranslationPackStatus {
  const HadithTranslationPackStatus({
    required this.isDownloaded,
    required this.totalHadiths,
    required this.translatedHadiths,
  });
  final bool isDownloaded;
  final int totalHadiths;
  final int translatedHadiths;
  int get unavailableTranslations =>
      (totalHadiths - translatedHadiths).clamp(0, totalHadiths);
}

extension HadithLanguageDownloads on HadithRepository {
  Future<HadithTranslationPackStatus> downloadedTranslationStatus(
    String bookId,
    String languageCode,
  ) async {
    if (this is HadithTranslationPackRepository) {
      return (this as HadithTranslationPackRepository).translationPackStatus(
        bookId,
        languageCode,
      );
    }
    final ready = await hasFullTranslation(bookId, languageCode);
    final count = (await getBook(bookId))?.hadithCount ?? 0;
    return HadithTranslationPackStatus(
      isDownloaded: ready,
      totalHadiths: count,
      translatedHadiths: ready ? count : 0,
    );
  }

  Future<bool> hasDownloadedTranslation(
    String bookId,
    String languageCode,
  ) async =>
      (await downloadedTranslationStatus(bookId, languageCode)).isDownloaded;

  Future<Map<String, List<HadithBook>>> bookTranslationCatalog() async {
    final catalog = <String, List<HadithBook>>{};
    for (final book in await getBooks()) {
      for (final code in await availableTranslationLanguagesForBook(book.id)) {
        (catalog[code] ??= []).add(book);
      }
    }
    return catalog;
  }

  Stream<HadithLanguageDownloadProgress> downloadTranslationLanguage(
    String languageCode,
  ) async* {
    final code = languageCode.trim().toLowerCase();
    final books = (await bookTranslationCatalog())[code] ?? const [];
    final statuses = <String, HadithTranslationPackStatus>{};
    final fractions = <String, double>{};
    final weights = {
      for (final book in books)
        book.id: book.hadithCount > 0 ? book.hadithCount : 1,
    };
    for (final book in books) {
      final status = await downloadedTranslationStatus(book.id, code);
      statuses[book.id] = status;
      fractions[book.id] = status.isDownloaded ? 1 : 0;
    }
    final totalWeight = weights.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final failed = <String, String>{};
    HadithLanguageDownloadProgress snapshot({
      HadithBook? current,
      String? stage,
      bool finished = false,
    }) {
      final ready = statuses.values.where((status) => status.isDownloaded);
      return HadithLanguageDownloadProgress(
        completedBooks: ready.length,
        totalBooks: books.length,
        currentBook: current?.englishName,
        currentBookProgress: current == null ? 0 : fractions[current.id] ?? 0,
        currentStage: stage,
        failedBooks: List.unmodifiable(failed.keys),
        failureDetails: Map.unmodifiable(failed),
        isFinished: finished,
        overallProgress: totalWeight == 0
            ? 0
            : books.fold<double>(
                    0,
                    (sum, book) =>
                        sum + weights[book.id]! * fractions[book.id]!,
                  ) /
                  totalWeight,
        totalHadiths: books.fold<int>(
          0,
          (sum, book) => sum + statuses[book.id]!.totalHadiths,
        ),
        downloadedHadiths: ready.fold<int>(
          0,
          (sum, status) => sum + status.totalHadiths,
        ),
        unavailableTranslations: ready.fold<int>(
          0,
          (sum, status) => sum + status.unavailableTranslations,
        ),
      );
    }

    yield snapshot();
    for (final book in books) {
      if (statuses[book.id]!.isDownloaded) continue;
      yield snapshot(current: book, stage: 'Downloading');
      String? failure;
      try {
        await for (final progress in downloadBookTranslation(book.id, code)) {
          final fraction = progress.percent.clamp(0.0, 0.98);
          if (fraction > fractions[book.id]!) fractions[book.id] = fraction;
          if (progress.hasFailed) failure = progress.errorMessage;
          yield snapshot(current: book, stage: progress.stage);
        }
        statuses[book.id] = await downloadedTranslationStatus(book.id, code);
      } catch (error) {
        failure = error.toString();
      }
      if (statuses[book.id]!.isDownloaded) {
        fractions[book.id] = 1;
      } else {
        failed[book.englishName] =
            failure ?? 'The saved edition could not be verified.';
      }
      yield snapshot();
    }
    // Completion is based on saved packs, never a network transfer percentage.
    for (final book in books) {
      statuses[book.id] = await downloadedTranslationStatus(book.id, code);
      if (!statuses[book.id]!.isDownloaded) {
        failed.putIfAbsent(
          book.englishName,
          () => 'The saved edition could not be verified.',
        );
      }
    }
    yield snapshot(finished: true);
  }
}

class HadithLanguageDownloadProgress {
  const HadithLanguageDownloadProgress({
    required this.completedBooks,
    required this.totalBooks,
    this.currentBook,
    this.currentBookProgress = 0,
    this.currentStage,
    this.failedBooks = const [],
    this.isFinished = false,
    this.overallProgress,
    this.totalHadiths = 0,
    this.downloadedHadiths = 0,
    this.unavailableTranslations = 0,
    this.failureDetails = const {},
  });

  final int completedBooks;
  final int totalBooks;
  final String? currentBook;
  final double currentBookProgress;
  final String? currentStage;
  final List<String> failedBooks;
  final bool isFinished;
  final double? overallProgress;
  final int totalHadiths;
  final int downloadedHadiths;
  final int unavailableTranslations;
  final Map<String, String> failureDetails;

  bool get isComplete =>
      isFinished &&
      totalBooks > 0 &&
      completedBooks == totalBooks &&
      failedBooks.isEmpty;

  double get percent => isComplete
      ? 1
      : (overallProgress ??
                (totalBooks == 0
                    ? 0
                    : (completedBooks + currentBookProgress) / totalBooks))
            .clamp(0, 0.99);
}

class HadeethEncDownloadProgress {
  const HadeethEncDownloadProgress({
    required this.languageCode,
    required this.completedItems,
    required this.totalItems,
    this.isComplete = false,
    this.hasFailed = false,
    this.downloadProgress,
    this.stage,
  });

  final String languageCode;
  final int completedItems;
  final int totalItems;
  final bool isComplete;
  final bool hasFailed;
  final double? downloadProgress;
  final String? stage;

  double get percent {
    if (downloadProgress != null) return downloadProgress!.clamp(0, 1);
    if (totalItems <= 0) {
      return isComplete ? 1 : 0;
    }
    return (completedItems / totalItems).clamp(0, 1).toDouble();
  }
}

class HadithTranslationDownloadProgress {
  const HadithTranslationDownloadProgress({
    required this.bookId,
    required this.languageCode,
    required this.completedItems,
    required this.totalItems,
    this.isComplete = false,
    this.hasFailed = false,
    this.downloadProgress,
    this.stage,
    this.unavailableTranslations = 0,
    this.errorMessage,
  });

  final String bookId;
  final String languageCode;
  final int completedItems;
  final int totalItems;
  final bool isComplete;
  final bool hasFailed;
  final double? downloadProgress;
  final String? stage;
  final int unavailableTranslations;
  final String? errorMessage;

  double get percent {
    if (downloadProgress != null) return downloadProgress!.clamp(0, 1);
    if (totalItems <= 0) {
      return isComplete ? 1 : 0;
    }
    return (completedItems / totalItems).clamp(0, 1).toDouble();
  }
}
