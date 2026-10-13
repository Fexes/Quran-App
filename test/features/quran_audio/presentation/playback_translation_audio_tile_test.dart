import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran_audio/presentation/widgets/quran_playback_settings_sheet.dart';

void main() {
  const translationReciter = QuranAudioReciter(
    id: 'alqurancloud:en.walk',
    name: 'English Voice',
    provider: QuranAudioProvider.alQuranCloud,
    identifier: 'en.walk',
    languageCode: 'en',
    isTranslation: true,
  );

  testWidgets('translation audio tile hides voice selector when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackTranslationAudioTile(
            enabled: false,
            translationRecitersAvailable: true,
            languageLabel: 'English',
            selectedReciter: translationReciter,
            onEnabledChanged: (_) {},
            onVoiceTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Play translation'), findsOneWidget);
    expect(find.text('Translation voice'), findsNothing);
  });

  testWidgets('translation audio tile shows voice selector when enabled', (
    tester,
  ) async {
    var tappedVoice = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackTranslationAudioTile(
            enabled: true,
            translationRecitersAvailable: true,
            languageLabel: 'English',
            selectedReciter: translationReciter,
            onEnabledChanged: (_) {},
            onVoiceTap: () => tappedVoice = true,
          ),
        ),
      ),
    );

    expect(find.text('Translation voice'), findsOneWidget);
    expect(find.text('English Voice'), findsOneWidget);

    await tester.tap(find.text('Translation voice'));
    await tester.pumpAndSettle();

    expect(tappedVoice, true);
  });

  testWidgets('translation audio tile disables switch when no voice exists', (
    tester,
  ) async {
    var toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackTranslationAudioTile(
            enabled: true,
            translationRecitersAvailable: false,
            languageLabel: 'Indonesian',
            selectedReciter: null,
            selectedTranslation: const QuranTranslationResource(
              id: 33,
              languageName: 'indonesian',
              name: 'Indonesian Ministry of Religious Affairs',
              authorName: 'Indonesian Ministry of Religious Affairs',
              slug: 'indonesian',
            ),
            onEnabledChanged: (_) => toggled = true,
            onVoiceTap: () {},
          ),
        ),
      ),
    );

    final switchWidget = tester.widget<Switch>(find.byType(Switch));

    expect(
      find.text('Translation audio is unavailable in Indonesian.'),
      findsOneWidget,
    );
    expect(find.text('Translation voice'), findsNothing);
    expect(switchWidget.value, false);
    expect(switchWidget.onChanged, isNull);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(toggled, false);
  });
}
