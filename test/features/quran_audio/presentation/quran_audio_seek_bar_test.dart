import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/presentation/widgets/quran_audio_seek_bar.dart';

void main() {
  testWidgets('tap seeks to the proportional ayah position', (tester) async {
    Duration? soughtPosition;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: QuranAudioSeekBar(
                state: const QuranAudioState.initial().copyWith(
                  position: const Duration(seconds: 10),
                  bufferedPosition: const Duration(seconds: 40),
                  duration: const Duration(seconds: 100),
                ),
                onSeek: (position) => soughtPosition = position,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(QuranAudioSeekBar));
    await tester.tapAt(Offset(center.dx + 50, center.dy));

    expect(soughtPosition, const Duration(seconds: 75));
  });

  testWidgets('drag seeks through the current ayah', (tester) async {
    Duration? soughtPosition;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: QuranAudioSeekBar(
                state: const QuranAudioState.initial().copyWith(
                  duration: const Duration(seconds: 100),
                ),
                onSeek: (position) => soughtPosition = position,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(GestureDetector),
      const Offset(80, 0),
      touchSlopY: 0,
    );

    expect(soughtPosition, isNotNull);
  });
}
