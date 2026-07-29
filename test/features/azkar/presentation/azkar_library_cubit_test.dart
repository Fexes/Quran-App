import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/search/deep_search_index_record.dart';
import 'package:quran/features/azkar/domain/entities/azkar_category.dart';
import 'package:quran/features/azkar/domain/entities/dhikr_item.dart';
import 'package:quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:quran/features/azkar/presentation/bloc/azkar_library_cubit.dart';
import 'package:quran/features/azkar/presentation/bloc/azkar_library_state.dart';

void main() {
  group('AzkarLibraryCubit', () {
    test('loads categories, dhikr, and source metadata', () async {
      final cubit = AzkarLibraryCubit(repository: _FakeAzkarRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AzkarLibraryState>().having(
            (state) => state.status,
            'status',
            AzkarLibraryStatus.loading,
          ),
          isA<AzkarLibraryState>()
              .having(
                (state) => state.status,
                'status',
                AzkarLibraryStatus.success,
              )
              .having((state) => state.categories, 'categories', hasLength(1))
              .having((state) => state.dhikr, 'dhikr', hasLength(1))
              .having(
                (state) => state.contentSources,
                'contentSources',
                hasLength(1),
              ),
        ]),
      );

      await cubit.load(categoryId: 'morning');
      await expectation;
      await cubit.close();
    });

    test('searches dhikr text', () async {
      final cubit = AzkarLibraryCubit(repository: _FakeAzkarRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AzkarLibraryState>().having(
            (state) => state.status,
            'status',
            AzkarLibraryStatus.loading,
          ),
          isA<AzkarLibraryState>()
              .having(
                (state) => state.status,
                'status',
                AzkarLibraryStatus.success,
              )
              .having((state) => state.query, 'query', 'glory')
              .having((state) => state.dhikr, 'dhikr', hasLength(1)),
        ]),
      );

      await cubit.search('glory');
      await expectation;
      await cubit.close();
    });
  });
}

class _FakeAzkarRepository implements AzkarRepository {
  static const _source = ContentSource(
    id: 'test_azkar_source',
    name: 'Test Azkar Source',
    attribution: 'Used by Azkar cubit tests.',
  );

  static const _category = AzkarCategory(
    id: 'morning',
    slug: 'morning',
    englishName: 'Morning',
    arabicName: 'أذكار الصباح',
    sourceId: 'test_azkar_source',
  );

  static const _dhikr = DhikrItem(
    id: 'morning_1',
    categoryId: 'morning',
    arabic: 'سُبْحَانَ اللَّهِ',
    translation: 'Glory is to Allah.',
    transliteration: 'SubhanAllah',
    reference: 'Test reference',
    repeatCount: 33,
    sourceId: 'test_azkar_source',
  );

  @override
  Future<List<ContentSource>> getContentSources() async => const [_source];

  @override
  Future<List<AzkarCategory>> getCategories() async => const [_category];

  @override
  Future<List<DhikrItem>> getDhikr({
    String? categoryId,
    int offset = 0,
    int limit = 100,
  }) async {
    return categoryId == null || categoryId == _category.id
        ? const [_dhikr]
        : const [];
  }

  @override
  Future<DhikrItem?> getDhikrById(String id) async {
    return id == _dhikr.id ? _dhikr : null;
  }

  @override
  Future<List<DeepSearchIndexRecord>> getSearchIndexRecords() async {
    return const [
      DeepSearchIndexRecord(
        id: 'azkar:morning_1',
        category: 'azkar',
        title: 'Test reference',
        subtitle: 'Repeat 33x',
        primaryPreview: 'سُبْحَانَ اللَّهِ',
        secondaryPreview: 'Glory is to Allah.',
        normalizedText: 'test reference glory is to allah',
        targetType: 'azkar',
        targetId: 'morning_1',
        categoryId: 'morning',
      ),
    ];
  }

  @override
  Future<List<DhikrItem>> search(String query, {int limit = 30}) async {
    if (_dhikr.translation.toLowerCase().contains(query.toLowerCase())) {
      return const [_dhikr];
    }
    return const [];
  }
}
