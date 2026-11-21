import '../entities/offline_search_result.dart';
import '../entities/search_document.dart';

abstract interface class OfflineSearchRepository {
  Future<void> warmUp();

  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  });

  Future<void> dispose();
}

abstract interface class MutableOfflineSearchRepository
    implements OfflineSearchRepository {
  Future<void> setIndexingEnabled(bool enabled);
  Future<Map<String, String>> completedSourceRevisions();
  Future<void> synchronizeSource(
    String sourceId,
    String revision,
    Stream<List<SearchDocument>> batches,
  );
}
