import '../../../../core/content/content_source.dart';
import '../../../../core/search/deep_search_index_record.dart';
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/dhikr_item.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../datasources/local_azkar_data_source.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  const AzkarRepositoryImpl({required LocalAzkarDataSource localDataSource})
    : _localDataSource = localDataSource;

  final LocalAzkarDataSource _localDataSource;

  @override
  Future<List<ContentSource>> getContentSources() async {
    return _localDataSource.getContentSources();
  }

  @override
  Future<List<AzkarCategory>> getCategories() async {
    return _localDataSource.getCategories();
  }

  @override
  Future<List<String>> availableTranslationLanguages() {
    return _localDataSource.availableTranslationLanguages();
  }

  @override
  Future<bool> hasFullTranslation(String languageCode) {
    return _localDataSource.hasFullTranslation(languageCode);
  }

  @override
  Stream<AzkarTranslationDownloadProgress> downloadTranslation(
    String languageCode,
  ) async* {
    final available = await hasFullTranslation(languageCode);
    yield AzkarTranslationDownloadProgress(
      languageCode: languageCode,
      completedItems: available ? 1 : 0,
      totalItems: 1,
      isComplete: available,
      hasFailed: !available,
    );
  }

  @override
  Future<List<DhikrItem>> getDhikr({
    String? categoryId,
    String? languageCode,
    int offset = 0,
    int limit = 100,
  }) async {
    return _localDataSource.getDhikr(
      categoryId: categoryId,
      languageCode: languageCode,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<DhikrItem?> getDhikrById(String id) async {
    return _localDataSource.getDhikrById(id);
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() {
    return _localDataSource.getSearchIndexRecords();
  }

  @override
  Future<List<DhikrItem>> search(String query, {int limit = 30}) async {
    return _localDataSource.search(query, limit: limit);
  }
}
