import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/presentation/widgets/hadith_narration_chain_view.dart';

void main() {
  testWidgets('hides chain of narration for a hadith', (tester) async {
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

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HadithNarrationChainView(hadith: hadith)),
      ),
    );

    expect(find.text('Chain of narration'), findsNothing);
    expect(find.text('Narrated Umar bin Al-Khattab'), findsNothing);
  });
}
