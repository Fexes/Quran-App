import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/datasources/hadeeth_enc_data_source.dart';
import 'package:quran/features/hadith/domain/entities/hadeeth_enc_item.dart';

void main() {
  group('HadeethEncDataSource', () {
    test('loads languages and imports a downloaded language', () async {
      final dataSource = HadeethEncDataSource(
        languagesFetcher: () async => const [
          {'code': 'en', 'native': 'English'},
        ],
        excelFetcher: (code) async {
          expect(code, 'en');
          return Uint8List.fromList([1, 2, 3]);
        },
        excelParser: ({required bytes, required languageCode}) {
          expect(bytes, [1, 2, 3]);
          return const HadeethEncImportResult(
            languageCode: 'en',
            version: 'v1',
            items: [
              HadeethEncItem(
                id: '1',
                languageCode: 'en',
                title: 'Intentions',
                titleArabic: '',
                hadithText: 'Actions are by intentions.',
                hadithTextArabic: '',
                explanation: '',
                explanationArabic: '',
                benefits: [],
                benefitsArabic: [],
                grade: 'Authentic',
                gradeArabic: '',
                attribution: 'Agreed upon',
                attributionArabic: '',
                link: '',
              ),
            ],
          );
        },
      );

      final languages = await dataSource.languages();
      final result = await dataSource.downloadLanguage('en');

      expect(languages.single.code, 'en');
      expect(result.items.single.hadithText, contains('intentions'));
    });
  });
}
