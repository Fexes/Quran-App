import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/constants/quran_arabic_script.dart';
import 'package:quran/core/theme/quran_theme.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_queue_item.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/presentation/widgets/quran_audio_seek_bar.dart';
import 'package:quran/features/quran/presentation/widgets/quran_reader_floating_controls.dart';
import 'package:quran/features/quran/presentation/widgets/surah_image_avatar.dart';

void main() {
  testWidgets(
    'Arabic text uses the same renderer with and without word highlight',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuranTheme.buildTheme(
            preset: QuranTheme.presetById('white-glass'),
            fontWeightScale: 1,
          ),
          home: const Scaffold(
            body: Column(
              children: [
                QuranReaderArabicText(
                  key: ValueKey('normal'),
                  text: 'بسم الله',
                  arabicFontScale: 1,
                ),
                QuranReaderArabicText(
                  key: ValueKey('active_word'),
                  text: 'بسم الله',
                  arabicFontScale: 1,
                  highlighterActive: true,
                  activeWordIndex: 2,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('normal')),
          matching: find.byType(RichText),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('active_word')),
          matching: find.byType(RichText),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('active word uses the white theme word highlight color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: QuranReaderArabicText(
            text: 'بسم الله',
            arabicFontScale: 1,
            activeWordIndex: 2,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final rootSpan = richText.text as TextSpan;
    final wordSpans = rootSpan.children!.whereType<TextSpan>().toList();

    expect(wordSpans[1].style?.color, const Color(0xFF8A5A00));
  });

  testWidgets('active word changes color only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: QuranReaderArabicText(
            text: 'بسم الله',
            arabicFontScale: 1,
            activeWordIndex: 2,
            highlighterActive: true,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final rootSpan = richText.text as TextSpan;
    final wordSpans = rootSpan.children!.whereType<TextSpan>().toList();
    final activeWord = wordSpans[1];
    final inactiveWord = wordSpans[0];

    expect(
      activeWord.style?.color,
      QuranTheme.wordHighlight(tester.element(find.byType(RichText))),
    );
    expect(
      rootSpan.style?.color,
      QuranTheme.quranTextSelected(tester.element(find.byType(RichText))),
    );
    expect(inactiveWord.style, isNull);
    expect(activeWord.style?.fontSize, isNull);
    expect(activeWord.style?.fontWeight, isNull);
    expect(activeWord.style?.height, isNull);
  });

  testWidgets('active ayah text does not paint a highlighter background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: QuranReaderArabicText(
            text: 'بسم الله',
            arabicFontScale: 1,
            highlighterActive: true,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final rootSpan = richText.text as TextSpan;

    expect(rootSpan.style?.backgroundColor, isNull);
  });

  testWidgets('selected ayah text changes color only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: Column(
            children: [
              QuranReaderArabicText(
                key: ValueKey('normal'),
                text: 'بسم الله',
                arabicFontScale: 1,
              ),
              QuranReaderArabicText(
                key: ValueKey('selected'),
                text: 'بسم الله',
                arabicFontScale: 1,
                selected: true,
              ),
            ],
          ),
        ),
      ),
    );

    TextSpan rootSpanFor(String key) {
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(RichText),
        ),
      );
      return richText.text as TextSpan;
    }

    final normal = rootSpanFor('normal');
    final selected = rootSpanFor('selected');
    final context = tester.element(find.byKey(const ValueKey('selected')));

    expect(normal.style?.fontSize, selected.style?.fontSize);
    expect(normal.style?.height, selected.style?.height);
    expect(normal.style?.fontWeight, selected.style?.fontWeight);
    expect(selected.style?.color, QuranTheme.quranTextSelected(context));
  });

  testWidgets('reader Arabic size applies equally in every ayah state', (
    tester,
  ) async {
    const fontScale = 1.25;
    const expectedFontSize = 24 * fontScale;

    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: Column(
            children: [
              QuranReaderArabicText(
                key: ValueKey('normal'),
                text: 'بسم الله',
                arabicFontScale: fontScale,
              ),
              QuranReaderArabicText(
                key: ValueKey('selected'),
                text: 'بسم الله',
                arabicFontScale: fontScale,
                selected: true,
              ),
              QuranReaderArabicText(
                key: ValueKey('playing'),
                text: 'بسم الله',
                arabicFontScale: fontScale,
                highlighterActive: true,
              ),
              QuranReaderArabicText(
                key: ValueKey('active_word'),
                text: 'بسم الله',
                arabicFontScale: fontScale,
                highlighterActive: true,
                activeWordIndex: 2,
              ),
            ],
          ),
        ),
      ),
    );

    TextSpan rootSpanFor(String key) {
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(RichText),
        ),
      );
      return richText.text as TextSpan;
    }

    final normal = rootSpanFor('normal');
    final selected = rootSpanFor('selected');
    final playing = rootSpanFor('playing');
    final activeWordRichText = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const ValueKey('active_word')),
        matching: find.byType(RichText),
      ),
    );
    final activeWordRoot = activeWordRichText.text as TextSpan;
    final activeWordSpans = activeWordRoot.children!.whereType<TextSpan>();

    expect(activeWordRoot.toPlainText(), 'بسم الله');
    for (final style in [normal.style, selected.style, playing.style]) {
      expect(style?.fontSize, expectedFontSize);
      expect(style?.height, QuranArabicScript.uthmani.readerLineHeight);
      expect(style?.fontWeight, FontWeight.w700);
    }
    expect(activeWordRoot.style?.fontSize, expectedFontSize);
    expect(
      activeWordRoot.style?.height,
      QuranArabicScript.uthmani.readerLineHeight,
    );
    expect(activeWordRoot.style?.fontWeight, FontWeight.w700);
    for (final span in activeWordSpans) {
      expect(span.style?.fontSize, isNull);
      expect(span.style?.height, isNull);
      expect(span.style?.fontWeight, isNull);
    }
  });

  testWidgets('expanded Arabic line height keeps font size and weight stable', (
    tester,
  ) async {
    const fontScale = 1.42;
    const lineHeight = 1.74;

    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: QuranReaderArabicText(
            text: 'بسم الله الرحمن الرحيم الحمد لله رب العالمين',
            arabicFontScale: fontScale,
            highlighterActive: true,
            activeWordIndex: 3,
            lineHeight: lineHeight,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final rootSpan = richText.text as TextSpan;
    final wordSpans = rootSpan.children!.whereType<TextSpan>();

    expect(rootSpan.style?.fontSize, 24 * fontScale);
    expect(rootSpan.style?.height, QuranArabicScript.uthmani.readerLineHeight);
    expect(rootSpan.style?.fontWeight, FontWeight.w700);
    for (final span in wordSpans) {
      expect(span.style?.fontSize, isNull);
      expect(span.style?.height, isNull);
      expect(span.style?.fontWeight, isNull);
    }
  });

  testWidgets('active word keeps the same rendered text box size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuranTheme.buildTheme(
          preset: QuranTheme.presetById('white-glass'),
          fontWeightScale: 1,
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 280,
            child: Column(
              children: [
                QuranReaderArabicText(
                  key: ValueKey('normal'),
                  text: 'بسم الله الرحمن الرحيم',
                  arabicFontScale: 1.2,
                ),
                QuranReaderArabicText(
                  key: ValueKey('active_word'),
                  text: 'بسم الله الرحمن الرحيم',
                  arabicFontScale: 1.2,
                  highlighterActive: true,
                  activeWordIndex: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final normalSize = tester
        .getSize(find.byKey(const ValueKey('normal')))
        .height;
    final activeSize = tester
        .getSize(find.byKey(const ValueKey('active_word')))
        .height;

    expect(activeSize, normalSize);
  });

  testWidgets(
    'selected ayah controls hide Arabic, translation, and range chips',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranReaderFloatingControls(
              selectedAyah: const QuranAyah(
                surahNumber: 1,
                number: 1,
                text: 'بسم الله الرحمن الرحيم',
                translation: 'In the name of Allah.',
                page: 1,
                juz: 1,
                isSajda: false,
              ),
              audioState: const QuranAudioState.initial(),
              showTranslation: true,
              isBookmarked: false,
              arabicFontScale: 1,
              onPrimaryPlay: () {},
              onStop: () {},
              onBookmark: () {},
              onTafsir: null,
              onPlaybackMenu: () {},
            ),
          ),
        ),
      );

      expect(find.text('بسم الله الرحمن الرحيم'), findsNothing);
      expect(find.text('In the name of Allah.'), findsNothing);
      expect(find.text('Ayah 1 selected'), findsOneWidget);
      expect(find.text('This ayah'), findsNothing);
      expect(find.text('To end'), findsNothing);
      expect(find.text('Page'), findsNothing);
      expect(find.textContaining('Mark'), findsNothing);
    },
  );

  testWidgets('hides Arabic and translation while audio view is visible', (
    tester,
  ) async {
    const item = QuranAudioQueueItem(
      surahNumber: 1,
      ayahNumber: 1,
      verseKey: '1:1',
      page: 1,
      surahName: 'Al-Fatihah',
      arabicText: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      reciterId: 'test',
      reciterName: 'Mishary Alafasy',
      remoteAudioUrl: 'https://example.com/001001.mp3',
      playbackUri: 'https://example.com/001001.mp3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranReaderFloatingControls(
            selectedAyah: null,
            audioState: const QuranAudioState.initial().copyWith(
              status: QuranAudioStatus.playing,
              currentItem: item,
              queue: [item],
              currentIndex: 0,
            ),
            showTranslation: true,
            isBookmarked: false,
            arabicFontScale: 1,
            onPrimaryPlay: () {},
            onStop: () {},
            onBookmark: () {},
            onTafsir: null,
            onPlaybackMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text('بسم الله الرحمن الرحيم'), findsNothing);
    expect(find.text('In the name of Allah.'), findsNothing);
    expect(find.text('Al-Fatihah'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('Mishary Alafasy'), findsNothing);
    expect(find.byType(SurahImageAvatar), findsOneWidget);
    expect(find.byTooltip('Playback options'), findsOneWidget);
    expect(find.byTooltip('Bookmark ayah'), findsOneWidget);
    expect(find.byTooltip('Open tafsir'), findsOneWidget);
  });

  testWidgets('audio view shows play selected when another ayah is selected', (
    tester,
  ) async {
    var playSelected = false;
    const item = QuranAudioQueueItem(
      surahNumber: 1,
      ayahNumber: 1,
      verseKey: '1:1',
      page: 1,
      surahName: 'Al-Fatihah',
      arabicText: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      reciterId: 'test',
      reciterName: 'Mishary Alafasy',
      remoteAudioUrl: 'https://example.com/001001.mp3',
      playbackUri: 'https://example.com/001001.mp3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuranReaderFloatingControls(
            selectedAyah: const QuranAyah(
              surahNumber: 1,
              number: 2,
              text: 'الحمد لله رب العالمين',
              translation: 'All praise is for Allah.',
              page: 1,
              juz: 1,
              isSajda: false,
            ),
            audioState: const QuranAudioState.initial().copyWith(
              status: QuranAudioStatus.playing,
              currentItem: item,
              queue: [item],
              currentIndex: 0,
            ),
            showTranslation: true,
            isBookmarked: false,
            arabicFontScale: 1,
            onPrimaryPlay: () {},
            onPlaySelected: () => playSelected = true,
            onStop: () {},
            onBookmark: () {},
            onTafsir: null,
            onPlaybackMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text('Play selected'), findsOneWidget);
    expect(find.text('Selected 1:2'), findsNothing);

    await tester.tap(find.text('Play selected'));
    expect(playSelected, true);
  });

  testWidgets('audio view seekbar seeks within the current ayah', (
    tester,
  ) async {
    Duration? soughtPosition;
    const item = QuranAudioQueueItem(
      surahNumber: 1,
      ayahNumber: 1,
      verseKey: '1:1',
      page: 1,
      surahName: 'Al-Fatihah',
      arabicText: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      reciterId: 'test',
      reciterName: 'Mishary Alafasy',
      remoteAudioUrl: 'https://example.com/001001.mp3',
      playbackUri: 'https://example.com/001001.mp3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: QuranReaderFloatingControls(
              selectedAyah: null,
              audioState: const QuranAudioState.initial().copyWith(
                status: QuranAudioStatus.playing,
                currentItem: item,
                queue: [item],
                currentIndex: 0,
                position: const Duration(seconds: 10),
                duration: const Duration(seconds: 100),
              ),
              showTranslation: true,
              isBookmarked: false,
              arabicFontScale: 1,
              onPrimaryPlay: () {},
              onStop: () {},
              onBookmark: () {},
              onTafsir: null,
              onPlaybackMenu: () {},
              onSeek: (position) => soughtPosition = position,
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(QuranAudioSeekBar));
    await tester.tapAt(Offset(center.dx + 90, center.dy));

    expect(soughtPosition, isNotNull);
  });
}
