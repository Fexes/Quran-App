import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/presentation/widgets/quran_playback_settings_sheet.dart';

void main() {
  testWidgets('repeat tile collapses controls when repeat is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackRepeatTile(
            mode: QuranAudioRepeatMode.off,
            repeatCount: 1,
            repeatAfterAction: QuranAudioRepeatAfterAction.stop,
            rangeStartAyah: null,
            rangeEndAyah: null,
            rangeMinAyah: null,
            rangeMaxAyah: null,
            onRepeatEnabledChanged: (_) {},
            onModeChanged: (_) {},
            onRepeatCountChanged: (_) {},
            onRepeatAfterActionChanged: (_) {},
            onRangeChanged: ({required startAyah, required endAyah}) {},
          ),
        ),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Ayah'), findsNothing);
    expect(find.text('Range'), findsNothing);
    expect(find.text('Once'), findsNothing);
  });

  testWidgets('repeat tile expands controls when repeat is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackRepeatTile(
            mode: QuranAudioRepeatMode.ayah,
            repeatCount: 3,
            repeatAfterAction: QuranAudioRepeatAfterAction.stop,
            rangeStartAyah: null,
            rangeEndAyah: null,
            rangeMinAyah: null,
            rangeMaxAyah: null,
            onRepeatEnabledChanged: (_) {},
            onModeChanged: (_) {},
            onRepeatCountChanged: (_) {},
            onRepeatAfterActionChanged: (_) {},
            onRangeChanged: ({required startAyah, required endAyah}) {},
          ),
        ),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Ayah'), findsOneWidget);
    expect(find.text('Range'), findsOneWidget);
    expect(find.text('3x'), findsOneWidget);
  });

  testWidgets('repeat tile shows after-repeat options for range repeat', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackRepeatTile(
            mode: QuranAudioRepeatMode.queue,
            repeatCount: 2,
            repeatAfterAction: QuranAudioRepeatAfterAction.continuePlayback,
            rangeStartAyah: 2,
            rangeEndAyah: 4,
            rangeMinAyah: 1,
            rangeMaxAyah: 7,
            onRepeatEnabledChanged: (_) {},
            onModeChanged: (_) {},
            onRepeatCountChanged: (_) {},
            onRepeatAfterActionChanged: (_) {},
            onRangeChanged: ({required startAyah, required endAyah}) {},
          ),
        ),
      ),
    );

    expect(find.text('After repeat is done'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Repeat range'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('repeat tile applies the selected range', (tester) async {
    ({int startAyah, int endAyah})? appliedRange;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackRepeatTile(
            mode: QuranAudioRepeatMode.queue,
            repeatCount: 2,
            repeatAfterAction: QuranAudioRepeatAfterAction.stop,
            rangeStartAyah: 2,
            rangeEndAyah: 4,
            rangeMinAyah: 1,
            rangeMaxAyah: 7,
            onRepeatEnabledChanged: (_) {},
            onModeChanged: (_) {},
            onRepeatCountChanged: (_) {},
            onRepeatAfterActionChanged: (_) {},
            onRangeChanged: ({required startAyah, required endAyah}) {
              appliedRange = (startAyah: startAyah, endAyah: endAyah);
            },
          ),
        ),
      ),
    );

    expect(find.text('Apply range'), findsOneWidget);

    await tester.tap(find.text('Apply range'));
    await tester.pumpAndSettle();

    expect(appliedRange, isNotNull);
    expect(appliedRange!.startAyah, 2);
    expect(appliedRange!.endAyah, 4);
  });
}
