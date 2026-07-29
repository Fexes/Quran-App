import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran_audio/presentation/pages/quran_downloads_page.dart';

void main() {
  test('uses selected language in unavailable tafsir download copy', () {
    const translation = QuranTranslationResource(
      id: 135,
      languageName: 'Pashto',
      name: 'Pashto translation',
      authorName: 'Author',
      slug: 'pashto',
    );

    expect(
      quranTafsirUnavailableLabel(translation),
      'No tafsir available for Pashto',
    );
  });
}
