import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/constants/quran_arabic_script.dart';
import 'package:quran/core/theme/quran_theme.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/entities/quran_word.dart';
import 'package:quran/features/quran/presentation/widgets/quran_book_text.dart';

void main() {
  testWidgets('interlinear layout creates more lines on narrow width', (
    tester,
  ) async {
    final style = const TextStyle(fontSize: 24, height: 1.55);
    final narrow = QuranInterlinearLineBuilder.buildLines(
      words: _words,
      maxWidth: 180,
      arabicStyle: style,
    );
    final wide = QuranInterlinearLineBuilder.buildLines(
      words: _words,
      maxWidth: 520,
      arabicStyle: style,
    );

    expect(narrow.length, greaterThan(wide.length));
  });

  testWidgets(
    'book fallback renders pretext Arabic lines with ayah translation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuranTheme.buildTheme(
            preset: QuranTheme.presetById('white-glass'),
            fontWeightScale: 1,
          ),
          home: Scaffold(
            body: CombinedPageText(
              ayahs: const [
                QuranAyah(
                  surahNumber: 1,
                  number: 1,
                  text: 'بسم الله الرحمن الرحيم',
                  translation: 'In the name of Allah.',
                  page: 1,
                  juz: 1,
                  isSajda: false,
                ),
              ],
              pageWords: const [],
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              showTranslation: true,
              translationsByVerse: const {'1:1': 'In the name of Allah.'},
              onAyahTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('In the name of Allah.'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('بسم الله الرحمن الرحيم'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('line builder can keep words from multiple ayahs on one line', (
    tester,
  ) async {
    final lines = QuranInterlinearLineBuilder.buildLines(
      words: const [
        QuranWord(
          verseKey: '1:1',
          ayahNumber: 1,
          wordIndex: 1,
          arabicText: 'بسم',
          translation: 'In',
          page: 1,
          lineNumber: 1,
        ),
        QuranWord(
          verseKey: '1:2',
          ayahNumber: 2,
          wordIndex: 1,
          arabicText: 'الحمد',
          translation: 'Praise',
          page: 1,
          lineNumber: 1,
        ),
      ],
      maxWidth: 520,
      arabicStyle: const TextStyle(fontSize: 24, height: 1.55),
    );

    expect(lines, hasLength(1));
    expect(lines.single.verseKeys, {'1:1', '1:2'});
    expect(lines.single.displayArabic, contains('﴿1﴾'));
  });

  testWidgets('long translation does not shorten Arabic line packing', (
    tester,
  ) async {
    final lines = QuranInterlinearLineBuilder.buildLines(
      words: const [
        QuranWord(
          verseKey: '1:1',
          ayahNumber: 1,
          wordIndex: 1,
          arabicText: 'بسم',
          translation: 'In the name',
          page: 1,
          lineNumber: 1,
        ),
        QuranWord(
          verseKey: '1:1',
          ayahNumber: 1,
          wordIndex: 2,
          arabicText: 'الله',
          translation:
              'of Allah the Most Merciful the Entirely Compassionate Sustainer of all worlds and every heart',
          page: 1,
          lineNumber: 1,
        ),
      ],
      maxWidth: 420,
      arabicStyle: const TextStyle(fontSize: 24, height: 1.55),
    );

    expect(lines, hasLength(1));
    expect(lines.single.words.map((word) => word.arabicText), ['بسم', 'الله']);
    expect(lines.single.displayTranslation, contains('Entirely Compassionate'));
  });

  testWidgets('long Combined translation wraps under its Arabic line', (
    tester,
  ) async {
    const longWords = [
      QuranWord(
        verseKey: '1:1',
        ayahNumber: 1,
        wordIndex: 1,
        arabicText: 'بسم',
        translation:
            'This is a very long translated phrase that must wrap under the same Arabic line before another Arabic line appears',
        page: 1,
        lineNumber: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 130,
            child: InterlinearBookPageText(
              words: longWords,
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final translationFinder = find.textContaining('very long translated');
    final translation = tester.widget<Text>(translationFinder);
    final translationParagraph = tester.renderObject<RenderParagraph>(
      translationFinder,
    );

    expect(translation.maxLines, isNull);
    expect(translation.overflow, isNull);
    expect(translationParagraph.size.height, greaterThan(24));
  });

  testWidgets('rendered Arabic lines do not wrap inside padded line rows', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 26, height: 1.55);
    final painter = TextPainter(
      text: const TextSpan(
        text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ﴿1﴾',
        style: style,
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    addTearDown(painter.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: painter.width + 2,
            child: InterlinearBookPageText(
              words: _words,
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    );

    for (final paragraph in paragraphs) {
      expect(
        paragraph.size.height,
        lessThanOrEqualTo(26 * QuranArabicScript.uthmani.readerLineHeight + 1),
      );
    }
  });

  testWidgets('renders small translation under each interlinear line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: InterlinearBookPageText(
              words: _words,
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final translation = tester.widget<Text>(find.textContaining('In').first);

    expect(translation.style?.fontSize, lessThanOrEqualTo(12.5));
  });

  testWidgets('renders interlinear translation with selected RTL direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: InterlinearBookPageText(
              words: const [
                QuranWord(
                  verseKey: '1:1',
                  ayahNumber: 1,
                  wordIndex: 1,
                  arabicText: 'بِسْمِ',
                  translation: 'نام',
                  page: 1,
                  lineNumber: 1,
                ),
              ],
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              translationResource: _urduTranslation,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final translation = tester.widget<Text>(find.text('نام'));

    expect(translation.textDirection, TextDirection.rtl);
    expect(translation.textAlign, TextAlign.right);
  });

  testWidgets('translation font scale changes interlinear translation size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: InterlinearBookPageText(
              words: _words,
              selectedVerseKey: null,
              activeAudioVerseKey: null,
              activeWordVerseKey: null,
              activeWordIndex: null,
              currentVerseKey: null,
              arabicFontScale: 1,
              translationFontScale: 1.25,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final translation = tester.widget<Text>(find.textContaining('In').first);

    expect(translation.style?.fontSize, 15);
  });

  testWidgets(
    'interlinear active word keeps font metrics with light ayah fill',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuranTheme.buildTheme(
            preset: QuranTheme.presetById('white-glass'),
            fontWeightScale: 1,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 260,
              child: InterlinearBookPageText(
                words: _words,
                selectedVerseKey: null,
                activeAudioVerseKey: '1:1',
                activeWordVerseKey: '1:1',
                activeWordIndex: 2,
                currentVerseKey: null,
                arabicFontScale: 1,
                onAyahTap: (_, _) {},
              ),
            ),
          ),
        ),
      );

      final richText = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((widget) => widget.text.toPlainText().contains('بِسْمِ'));
      final rootSpan = richText.text as TextSpan;
      final wordSpan = rootSpan.children!.whereType<TextSpan>().firstWhere(
        (span) => span.text?.contains('ٱللَّهِ') ?? false,
      );
      final inactiveSpan = rootSpan.children!.whereType<TextSpan>().firstWhere(
        (span) => span.text?.contains('بِسْمِ') ?? false,
      );

      expect(wordSpan.style?.color, const Color(0xFF8A5A00));
      expect(wordSpan.style?.backgroundColor, isNotNull);
      expect(
        wordSpan.style?.backgroundColor,
        inactiveSpan.style?.backgroundColor,
      );
      expect(
        wordSpan.style!.backgroundColor!.toARGB32() >> 24,
        greaterThanOrEqualTo(32),
      );
      expect(wordSpan.style?.fontSize, inactiveSpan.style?.fontSize);
      expect(wordSpan.style?.fontWeight, inactiveSpan.style?.fontWeight);
    },
  );

  testWidgets(
    'interlinear selected ayah highlight does not bleed across line',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuranTheme.buildTheme(
            preset: QuranTheme.presetById('white-glass'),
            fontWeightScale: 1,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 520,
              child: InterlinearBookPageText(
                words: const [
                  QuranWord(
                    verseKey: '1:1',
                    ayahNumber: 1,
                    wordIndex: 1,
                    arabicText: 'بسم',
                    translation: 'In',
                    page: 1,
                    lineNumber: 1,
                  ),
                  QuranWord(
                    verseKey: '1:2',
                    ayahNumber: 2,
                    wordIndex: 1,
                    arabicText: 'الحمد',
                    translation: 'Praise',
                    page: 1,
                    lineNumber: 1,
                  ),
                ],
                selectedVerseKey: '1:2',
                activeAudioVerseKey: null,
                activeWordVerseKey: null,
                activeWordIndex: null,
                currentVerseKey: null,
                arabicFontScale: 1,
                onAyahTap: (_, _) {},
              ),
            ),
          ),
        ),
      );

      final richText = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((widget) => widget.text.toPlainText().contains('بسم'));
      final rootSpan = richText.text as TextSpan;
      final firstAyahSpan = rootSpan.children!.whereType<TextSpan>().firstWhere(
        (span) => span.text?.contains('بسم') ?? false,
      );
      final selectedTextSpan = rootSpan.children!
          .whereType<TextSpan>()
          .firstWhere((span) => span.text?.contains('الحمد') ?? false);

      expect(firstAyahSpan.style?.backgroundColor, isNull);
      expect(
        firstAyahSpan.style?.color,
        QuranTheme.quranTextNormal(tester.element(find.byType(RichText).first)),
      );
      expect(selectedTextSpan.style?.backgroundColor, isNotNull);
      expect(
        selectedTextSpan.style!.backgroundColor!.toARGB32() >> 24,
        greaterThanOrEqualTo(32),
      );
      expect(
        selectedTextSpan.style?.color,
        QuranTheme.quranTextSelected(
          tester.element(find.byType(RichText).first),
        ),
      );
    },
  );

  testWidgets('active word does not change font weight from normal words', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 520,
            child: InterlinearBookPageText(
              words: const [
                QuranWord(
                  verseKey: '1:1',
                  ayahNumber: 1,
                  wordIndex: 1,
                  arabicText: 'بسم',
                  translation: 'In',
                  page: 1,
                  lineNumber: 1,
                ),
                QuranWord(
                  verseKey: '1:2',
                  ayahNumber: 2,
                  wordIndex: 1,
                  arabicText: 'الحمد',
                  translation: 'Praise',
                  page: 1,
                  lineNumber: 1,
                ),
              ],
              selectedVerseKey: null,
              activeAudioVerseKey: '1:2',
              activeWordVerseKey: '1:2',
              activeWordIndex: 1,
              currentVerseKey: null,
              arabicFontScale: 1,
              onAyahTap: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final richText = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) => widget.text.toPlainText().contains('الحمد'));
    final rootSpan = richText.text as TextSpan;
    final normalSpan = rootSpan.children!.whereType<TextSpan>().firstWhere(
      (span) => span.text?.contains('بسم') ?? false,
    );
    final activeSpan = rootSpan.children!.whereType<TextSpan>().firstWhere(
      (span) => span.text?.contains('الحمد') ?? false,
    );

    expect(activeSpan.style?.color, const Color(0xFF8A5A00));
    expect(activeSpan.style?.fontWeight, normalSpan.style?.fontWeight);
    expect(activeSpan.style?.fontSize, normalSpan.style?.fontSize);
  });
}

const _words = [
  QuranWord(
    verseKey: '1:1',
    ayahNumber: 1,
    wordIndex: 1,
    arabicText: 'بِسْمِ',
    translation: 'In',
    page: 1,
    lineNumber: 1,
  ),
  QuranWord(
    verseKey: '1:1',
    ayahNumber: 1,
    wordIndex: 2,
    arabicText: 'ٱللَّهِ',
    translation: 'Allah',
    page: 1,
    lineNumber: 1,
  ),
  QuranWord(
    verseKey: '1:1',
    ayahNumber: 1,
    wordIndex: 3,
    arabicText: 'ٱلرَّحْمَٰنِ',
    translation: 'the Merciful',
    page: 1,
    lineNumber: 1,
  ),
  QuranWord(
    verseKey: '1:1',
    ayahNumber: 1,
    wordIndex: 4,
    arabicText: 'ٱلرَّحِيمِ',
    translation: 'the Compassionate',
    page: 1,
    lineNumber: 1,
  ),
];

const _urduTranslation = QuranTranslationResource(
  id: 234,
  languageName: 'urdu',
  name: 'Fatah Muhammad Jalandhari',
  authorName: 'Fatah Muhammad Jalandhari',
  slug: 'ur-fatah-muhammad-jalandhari',
);
