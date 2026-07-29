import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/azkar/data/datasources/local_azkar_data_source.dart';
import 'package:quran/features/azkar/domain/entities/dhikr_item.dart';

void main() {
  group('LocalAzkarDataSource', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('loads production categories, dhikr, and source metadata', () async {
      final dataSource = LocalAzkarDataSource();

      final sources = await dataSource.getContentSources();
      final categories = await dataSource.getCategories();
      final dhikr = await dataSource.getDhikr(categoryId: categories.first.id);

      expect(sources, hasLength(1));
      expect(sources.single.id, 'muslim_data_android');
      expect(categories.length, greaterThanOrEqualTo(10));
      expect(dhikr, isNotEmpty);
      expect(dhikr.first.repeatCount, greaterThanOrEqualTo(1));
      expect(dhikr.first.sourceId, sources.single.id);
    });

    test('loads compact search records without loading every category', () async {
      final dataSource = LocalAzkarDataSource();

      final records = await dataSource.getSearchIndexRecords();

      expect(records.length, greaterThan(100));
      expect(records.first.id, startsWith('azkar:'));
      expect(records.first.normalizedText, isNotEmpty);
    });

    test(
      'searches translation, transliteration, Arabic text, and reference',
      () async {
        final dataSource = LocalAzkarDataSource();

        expect(await dataSource.search('Allah'), isNotEmpty);
        expect(await dataSource.search('Praise'), isNotEmpty);
        expect(await dataSource.search('اللَّهِ'), isNotEmpty);
        expect(await dataSource.search('Bukhari'), isNotEmpty);
        expect(await dataSource.search('missing-never-match'), isEmpty);
      },
    );

    test('search folds Latin-looking Unicode text', () async {
      final dataSource = LocalAzkarDataSource(
        dhikr: [
          DhikrItem(
            id: 'folded',
            categoryId: 'morning',
            arabic: 'ذكر',
            translation: 'Remember Allāh on the Ṣirāṭ.',
            transliteration: 'dhikr',
            reference: 'Qurʾān reference',
            repeatCount: 1,
            sourceId: 'test',
          ),
        ],
      );

      expect(await dataSource.search('Allah'), hasLength(1));
      expect(await dataSource.search('Sirat'), hasLength(1));
      expect(await dataSource.search('Quran'), hasLength(1));
    });
  });
}
