import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/datasources/fawaz_hadith_translation_data_source.dart';
import 'package:quran/features/hadith/data/datasources/hadeeth_enc_data_source.dart';
import 'package:quran/features/hadith/data/datasources/local_hadith_data_source.dart';
import 'package:quran/features/hadith/data/repositories/hadith_repository_impl.dart';
import 'package:quran/features/hadith/data/stores/hadeeth_enc_store.dart';
import 'package:quran/features/hadith/data/stores/hadith_translation_store.dart';
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
          items: [
            const HadeethEncItem(
              id: '1',
              languageCode: 'en',
              title: 'Mercy',
              titleArabic: 'الرحمة',
              hadithText:
                  'Narrated Usama bin Zaid: Mercy is shown to the merciful.',
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
            HadeethEncItem.fromJson({
              'id': 'weak',
              'languageCode': 'en',
              'title': 'Mercy',
              'hadithText': 'Narrated: a weak test report about mercy.',
              'hadithTextArabic': 'عَنْ فُلَانٍ',
              'grade': 'Weak',
              'gradeArabic': 'ضعيف',
            }),
            HadeethEncItem.fromJson({
              'id': 'missing-chain',
              'languageCode': 'en',
              'title': 'Mercy',
              'hadithText': 'Mercy without a narration chain in the source.',
              'hadithTextArabic': 'الرحمة',
              'grade': 'Authentic',
              'gradeArabic': 'صحيح',
            }),
          ],
        );
        final repository = HadithRepositoryImpl(
          translationDataSource: FawazHadithTranslationDataSource(
            fetcher: (_) async =>
                throw StateError('No network during cached lookup'),
          ),
          translationStore: HadithTranslationStore.memory(),
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

        expect(
          item?.translation,
          'Narrated Usama bin Zaid: Mercy is shown to the merciful.',
        );
        expect(search, hasLength(1));
        expect(records.map((record) => record.targetId), [item?.id]);
        expect(await repository.getHadithById('hadeethenc:en:weak'), isNull);
        expect(
          await repository.getHadithById('hadeethenc:en:missing-chain'),
          isNull,
        );
        expect(
          (await repository.getHadeethEncItems(
            languageCode: 'en',
          )).map((item) => item.id),
          ['1'],
        );
        expect(
          (await repository.searchHadeethEnc(
            languageCode: 'en',
            query: 'mercy',
          )).map((item) => item.id),
          ['1'],
        );
      },
    );
  });
}
