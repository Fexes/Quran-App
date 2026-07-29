import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../entities/azkar_category.dart';
import '../entities/dhikr_item.dart';

abstract interface class AzkarRepository {
  Future<List<ContentSource>> getContentSources();

  Future<List<AzkarCategory>> getCategories();

  Future<List<String>> availableTranslationLanguages();

  Future<bool> hasFullTranslation(String languageCode);

  Stream<AzkarTranslationDownloadProgress> downloadTranslation(
    String languageCode,
  );

  Future<List<DhikrItem>> getDhikr({
    String? categoryId,
    String? languageCode,
    int offset = 0,
    int limit = 100,
  });

  Future<DhikrItem?> getDhikrById(String id);

  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords();

  Future<List<DhikrItem>> search(String query, {int limit = 30});
}

class AzkarTranslationDownloadProgress {
  const AzkarTranslationDownloadProgress({
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
