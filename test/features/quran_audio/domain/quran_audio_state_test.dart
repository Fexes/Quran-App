import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';

void main() {
  group('QuranAudioState', () {
    test('stores and clears range playback metadata', () {
      const state = QuranAudioState.initial();

      final ranged = state.copyWith(rangeStartAyah: 255, rangeEndAyah: 257);

      expect(ranged.rangeStartAyah, 255);
      expect(ranged.rangeEndAyah, 257);

      final cleared = ranged.copyWith(clearRange: true);

      expect(cleared.rangeStartAyah, isNull);
      expect(cleared.rangeEndAyah, isNull);
    });

    test('stores repeat count', () {
      const state = QuranAudioState.initial();

      final repeated = state.copyWith(repeatCount: 5);

      expect(repeated.repeatCount, 5);
    });

    test('stores playback scope and verse-key ranges', () {
      const state = QuranAudioState.initial();

      final page = state.copyWith(
        playbackScope: QuranAudioPlaybackScope.page,
        scopeLabel: 'Page 2',
        rangeStartVerseKey: '2:1',
        rangeEndVerseKey: '2:5',
      );

      expect(page.playbackScope, QuranAudioPlaybackScope.page);
      expect(page.scopeLabel, 'Page 2');
      expect(page.rangeStartVerseKey, '2:1');
      expect(page.rangeEndVerseKey, '2:5');

      final cleared = page.copyWith(clearRange: true);

      expect(cleared.rangeStartVerseKey, isNull);
      expect(cleared.rangeEndVerseKey, isNull);
    });

    test('exposes control availability from current item', () {
      const state = QuranAudioState.initial();

      expect(state.canPause, false);
      expect(state.canStop, false);
      expect(state.canSeek, false);
    });

    test('stores translation audio playback preference', () {
      const state = QuranAudioState.initial();

      final translated = state.copyWith(
        playTranslationAudio: true,
        translationReciterId: 'alqurancloud:en.walk',
        translationReciterName: 'Ibrahim Walk',
      );

      expect(translated.playTranslationAudio, true);
      expect(translated.translationReciterId, 'alqurancloud:en.walk');
      expect(translated.translationReciterName, 'Ibrahim Walk');
    });
  });
}
