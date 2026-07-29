import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/datasources/hadeeth_enc_data_source.dart';
import 'package:quran/features/hadith/data/datasources/local_hadith_data_source.dart';
import 'package:quran/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:quran/features/hadith/data/stores/hadeeth_enc_store.dart';
import 'package:quran/features/hadith/domain/entities/hadeeth_enc_item.dart';

void main() {
  group('HadithRepositoryImpl HadeethEnc', () {
    test(
      'exposes downloaded HadeethEnc items to lookup, search, and index',
      () async {
        final store = HadeethEncStore.memory();
        await store.saveLanguageItems(
          languageCode: 'en',
          version: 'v1.24.0',
          items: const [
            HadeethEncItem(
              id: '1',
              languageCode: 'en',
              title: 'Mercy',
              titleArabic: 'الرحمة',
              hadithText: 'Mercy is shown to the merciful.',
              hadithTextArabic: 'إنما يرحم الله من عباده الرحماء',
              explanation: 'A hadith about mercy.',
              explanationArabic: '',
              benefits: [],
              benefitsArabic: [],
              grade: 'Authentic',
              gradeArabic: 'صحيح',
              attribution: 'Agreed upon',
              attributionArabic: '',
              link: 'https://hadeethenc.com/en/browse/hadith/1',
            ),
          ],
        );
        final repository = HadithRepositoryImpl(
          localDataSource: LocalHadithDataSource(
            sources: const [],
            books: const [],
            chapters: const [],
            hadiths: const [],
          ),
          hadeethEncDataSource: HadeethEncDataSource(
            languagesFetcher: () async => const [],
            excelFetcher: (_) async => Uint8List(0),
            excelParser: ({required bytes, required languageCode}) =>
                HadeethEncImportResult(
                  languageCode: languageCode,
                  version: '',
                  items: const [],
                ),
          ),
          hadeethEncStore: store,
        );

        final item = await repository.getHadithById('hadeethenc:en:1');
        final search = await repository.search('mercy');
        final records = await repository.getSearchIndexRecords();

        expect(item?.translation, 'Mercy is shown to the merciful.');
        expect(search, hasLength(1));
        expect(records.map((record) => record.targetId), contains(item?.id));
      },
    );
  });
}
