import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/stores/hadeeth_enc_store.dart';
import 'package:quran/features/hadith/domain/entities/hadeeth_enc_item.dart';

void main() {
  group('HadeethEncStore', () {
    test('caches language metadata and full language items', () async {
      final store = HadeethEncStore.memory();

      await store.saveLanguages(const [
        HadeethEncLanguage(code: 'en', nativeName: 'English'),
      ]);
      await store.saveLanguageItems(
        languageCode: 'en',
        version: 'v1.24.0',
        items: const [
          HadeethEncItem(
            id: '1',
            languageCode: 'en',
            title: 'Intentions',
            titleArabic: 'النيات',
            hadithText: 'Actions are by intentions.',
            hadithTextArabic: 'إنما الأعمال بالنيات',
            explanation: '',
            explanationArabic: '',
            benefits: [],
            benefitsArabic: [],
            grade: 'Authentic',
            gradeArabic: 'صحيح',
            attribution: 'Agreed upon',
            attributionArabic: 'متفق عليه',
            link: 'https://hadeethenc.com/en/browse/hadith/1',
          ),
        ],
      );

      expect(store.languages(), hasLength(1));
      expect(store.hasFullLanguage('en'), isTrue);
      expect(store.downloadedLanguageCodes(), const ['en']);
      expect(store.itemsForLanguage('en'), hasLength(1));
      expect(
        store.search(languageCode: 'en', query: 'intentions'),
        hasLength(1),
      );
      expect(store.search(languageCode: 'en', query: 'missing'), isEmpty);
    });
  });
}
