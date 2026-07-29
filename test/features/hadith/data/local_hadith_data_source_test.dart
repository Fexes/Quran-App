import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/datasources/local_hadith_data_source.dart';
import 'package:quran/features/hadith/domain/entities/hadith_item.dart';

void main() {
  group('LocalHadithDataSource', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test(
      'loads production books, chapters, hadiths, and source metadata',
      () async {
        final dataSource = LocalHadithDataSource();

        final sources = await dataSource.getContentSources();
        final books = await dataSource.getBooks();
        final bukhari = books.firstWhere((book) => book.slug == 'bukhari');
        final chapters = await dataSource.getChapters(bukhari.id);
        final hadiths = await dataSource.getHadiths(
          bookId: bukhari.id,
          limit: 2,
        );

        expect(sources, hasLength(1));
        expect(sources.single.id, 'fawaz_hadith_api');
        expect(books, hasLength(10));
        expect(chapters.length, greaterThan(1));
        expect(hadiths, hasLength(2));
        expect(hadiths.first.sourceId, sources.single.id);
        expect(hadiths.first.translation, isNotEmpty);
        expect(hadiths.first.arabic, isNotEmpty);
      },
    );

    test('loads compact search records without loading full books', () async {
      final dataSource = LocalHadithDataSource();

      final records = await dataSource.getSearchIndexRecords();

      expect(records.length, greaterThan(10000));
      expect(records.first.id, startsWith('hadith:'));
      expect(records.first.normalizedText, isNotEmpty);
    });

    test('searches translation, Arabic text, and reference', () async {
      final dataSource = LocalHadithDataSource();

      expect(await dataSource.search('intentions'), isNotEmpty);
      expect(await dataSource.search('الأعمال'), isNotEmpty);
      expect(await dataSource.search('Bukhari 1'), isNotEmpty);
      expect(await dataSource.search('missing-never-match'), isEmpty);
    });

    test('search folds Latin-looking Unicode text', () async {
      final dataSource = LocalHadithDataSource(
        hadiths: [
          HadithItem(
            id: 'folded',
            bookId: 'sample',
            chapterId: 'sample',
            hadithNumber: '1',
            arabic: 'حَدَّثَنَا فُلَانٌ عَنْ فُلَانٍ',
            translation: 'Narrated: a Ḥadīth about mercy.',
            grade: 'Sahih',
            grades: [
              {'grade': 'Sahih', 'name': 'Verifier'},
            ],
            reference: 'Qurʾān reference',
            sourceId: 'test',
          ),
        ],
      );

      expect(await dataSource.search('Hadith'), hasLength(1));
      expect(await dataSource.search('Quran'), hasLength(1));
    });

    test('only exposes authentic hadiths with a narration chain', () async {
      const authentic = HadithItem(
        id: 'hadith:sample:1',
        bookId: 'sample',
        chapterId: 'sample_1',
        hadithNumber: '1',
        arabic: 'حَدَّثَنَا فُلَانٌ عَنْ فُلَانٍ',
        translation: 'Narrated by a companion: a sound report.',
        grade: 'Sahih',
        grades: [
          {'grade': 'Sahih', 'name': 'Verifier'},
        ],
        reference: 'Sample 1',
        sourceId: 'test',
      );
      const weak = HadithItem(
        id: 'hadith:sample:2',
        bookId: 'sample',
        chapterId: 'sample_1',
        hadithNumber: '2',
        arabic: 'حَدَّثَنَا فُلَانٌ عَنْ فُلَانٍ',
        translation: 'Narrated by a companion: a weak report.',
        grade: 'Daif',
        grades: [
          {'grade': 'Daif', 'name': 'Verifier'},
        ],
        reference: 'Sample 2',
        sourceId: 'test',
      );
      const ungraded = HadithItem(
        id: 'hadith:sample:3',
        bookId: 'sample',
        chapterId: 'sample_1',
        hadithNumber: '3',
        arabic: 'حَدَّثَنَا فُلَانٌ عَنْ فُلَانٍ',
        translation: 'Narrated by a companion: an ungraded report.',
        grade: '',
        reference: 'Sample 3',
        sourceId: 'test',
      );
      const noChain = HadithItem(
        id: 'hadith:sample:4',
        bookId: 'sample',
        chapterId: 'sample_1',
        hadithNumber: '4',
        arabic: 'حكمة مختصرة',
        translation: 'A short saying without narration chain.',
        grade: 'Sahih',
        grades: [
          {'grade': 'Sahih', 'name': 'Verifier'},
        ],
        reference: 'Sample 4',
        sourceId: 'test',
      );
      final dataSource = LocalHadithDataSource(
        hadiths: const [authentic, weak, ungraded, noChain],
      );

      final hadiths = await dataSource.getHadiths(bookId: 'sample');

      expect(hadiths, const [authentic]);
      expect(await dataSource.getHadithById(weak.id), isNull);
      expect(await dataSource.getHadithById(noChain.id), isNull);
      expect(await dataSource.search('weak report'), isEmpty);
      expect(await dataSource.search('sound report'), const [authentic]);
    });

    test(
      'keeps trusted sahih collections with chains when grades are absent',
      () async {
        const bukhari = HadithItem(
          id: 'hadith:bukhari:1',
          bookId: 'bukhari',
          chapterId: 'bukhari_1',
          hadithNumber: '1',
          arabic: 'عَنْ عُمَرَ بْنِ الْخَطَّابِ',
          translation: 'Narrated Umar: actions are by intentions.',
          grade: '',
          reference: 'Bukhari 1',
          sourceId: 'test',
        );
        final dataSource = LocalHadithDataSource(hadiths: const [bukhari]);

        expect(await dataSource.getHadiths(bookId: 'bukhari'), const [bukhari]);
        expect(await dataSource.getHadithById(bukhari.id), bukhari);
      },
    );
  });
}
