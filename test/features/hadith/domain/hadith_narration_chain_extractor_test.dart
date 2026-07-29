import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/domain/services/hadith_narration_chain_extractor.dart';

void main() {
  group('HadithNarrationChainExtractor', () {
    test('extracts an English narration chain from narrated text', () {
      const hadith = HadithItem(
        id: 'hadith:bukhari:1',
        bookId: 'bukhari',
        chapterId: 'bukhari_1',
        hadithNumber: '1',
        arabic: 'عَنْ عُمَرَ بْنِ الْخَطَّابِ قَالَ سَمِعْتُ رَسُولَ اللَّهِ',
        translation:
            'Narrated Umar bin Al-Khattab: I heard Allah\'s Messenger saying actions are by intentions.',
        grade: 'Sahih',
        reference: 'Bukhari 1',
        sourceId: 'test',
      );

      final chain = HadithNarrationChainExtractor.extract(hadith);

      expect(chain.english, 'Narrated Umar bin Al-Khattab');
      expect(chain.hasAny, isTrue);
    });

    test('extracts an authority chain before who said', () {
      const hadith = HadithItem(
        id: 'hadith:nawawi:1',
        bookId: 'nawawi',
        chapterId: 'nawawi_1',
        hadithNumber: '1',
        arabic: 'عَنْ عُمَرَ بْنِ الْخَطَّابِ قَالَ',
        translation:
            'It is narrated on the authority of Umar bin al-Khattab who said: I heard the Messenger of Allah say.',
        grade: '',
        reference: 'Nawawi 1',
        sourceId: 'test',
      );

      final chain = HadithNarrationChainExtractor.extract(hadith);

      expect(
        chain.english,
        'It is narrated on the authority of Umar bin al-Khattab',
      );
    });

    test('extracts a compact Arabic chain without matn quote text', () {
      const hadith = HadithItem(
        id: 'hadith:abudawud:1',
        bookId: 'abudawud',
        chapterId: 'abudawud_1',
        hadithNumber: '1',
        arabic:
            'حَدَّثَنَا عَبْدُ اللَّهِ، عَنْ أَبِي سَلَمَةَ، أَنَّ النَّبِيَّ صلى الله عليه وسلم قَالَ "الأعمال بالنيات"',
        translation: 'Narrated Abu Salamah: actions are by intentions.',
        grade: 'Sahih',
        reference: 'Abu Dawud 1',
        sourceId: 'test',
      );

      final chain = HadithNarrationChainExtractor.extract(hadith);

      expect(chain.arabic, contains('حَدَّثَنَا عَبْدُ اللَّهِ'));
      expect(chain.arabic, isNot(contains('الأعمال بالنيات')));
    });

    test('removes Arabic content after the narration chain', () {
      const hadith = HadithItem(
        id: 'hadith:bukhari:1',
        bookId: 'bukhari',
        chapterId: 'bukhari_1',
        hadithNumber: '1',
        arabic:
            'حَدَّثَنَا الْحُمَيْدِيُّ، قَالَ : حَدَّثَنَا سُفْيَانُ، قَالَ : حَدَّثَنَا يَحْيَى، أَخْبَرَنِي مُحَمَّدُ، أَنَّهُ سَمِعَ عَلْقَمَةَ، يَقُولُ سَمِعْتُ عُمَرَ بْنَ الْخَطَّابِ قَالَ سَمِعْتُ رَسُولَ اللَّهِ صلى الله عليه وسلم يَقُولُ "الأعمال بالنيات"',
        translation:
            'Narrated Umar bin Al-Khattab: I heard Allah\'s Messenger saying actions are by intentions.',
        grade: 'Sahih',
        reference: 'Bukhari 1',
        sourceId: 'test',
      );

      final chain = HadithNarrationChainExtractor.extract(hadith);

      expect(chain.arabic, contains('أَخْبَرَنِي مُحَمَّدُ'));
      expect(chain.arabic, isNot(contains('سَمِعْتُ رَسُولَ اللَّهِ')));
      expect(chain.arabic, isNot(contains('الأعمال بالنيات')));
    });

    test('removes English content after chain wording', () {
      const hadith = HadithItem(
        id: 'hadith:qudsi:1',
        bookId: 'qudsi',
        chapterId: 'qudsi_1',
        hadithNumber: '1',
        arabic: 'عَنْ أَبِي هُرَيْرَةَ قَالَ',
        translation:
            'On the authority of Abu Hurayrah, who said that the Messenger of Allah said: When Allah decreed the Creation.',
        grade: '',
        reference: 'Qudsi 1',
        sourceId: 'test',
      );

      final chain = HadithNarrationChainExtractor.extract(hadith);

      expect(chain.english, 'On the authority of Abu Hurayrah');
      expect(chain.english, isNot(contains('Messenger of Allah')));
      expect(chain.english, isNot(contains('Creation')));
    });
  });
}
