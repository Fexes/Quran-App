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

class HadeethEncDownloadProgress {
  const HadeethEncDownloadProgress({
    required this.languageCode,
    required this.completedItems,
    required this.totalItems,
    this.isComplete = false,
    this.hasFailed = false,
  });

  final String languageCode;
  final int completedItems;
  final int totalItems;
  final bool isComplete;
  final bool hasFailed;

  double get percent {
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
  });

  final String bookId;
  final String languageCode;
  final int completedItems;
  final int totalItems;
  final bool isComplete;
  final bool hasFailed;

  double get percent {
    if (totalItems <= 0) {
      return isComplete ? 1 : 0;
    }
    return (completedItems / totalItems).clamp(0, 1).toDouble();
  }
}
