import '../entities/deep_search_result.dart';

abstract interface class DeepSearchRepository {
  Future<void> warmUp();

  Future<List<DeepSearchSection>> search(
    String query, {
    int limitPerCategory = 20,
  });
}

abstract interface class DisposableDeepSearchRepository {
  Future<void> dispose();
}
