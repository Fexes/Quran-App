import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/quran_audio_queue_item.dart';
import '../../domain/entities/quran_audio_state.dart';

abstract interface class QuranAudioFiniteRepeatPort {
  Future<void> setAyahRepeatCount(int count);
}

abstract interface class QuranAudioPlaybackPort {
  Stream<PlaybackState> get playbackState;
  Stream<MediaItem?> get mediaItem;
  Stream<List<MediaItem>> get queue;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<Duration?> get durationStream;
  Stream<int?> get currentIndexStream;
  Stream<double> get speedStream;
  Stream<PlayerState> get playerStateStream;

  int? get currentIndex;
  bool get playing;
  List<QuranAudioQueueItem> get currentQueue;

  Future<void> loadAndPlay(
    List<QuranAudioQueueItem> items, {
    int startIndex = 0,
    Duration initialPosition = Duration.zero,
    bool autoPlay = true,
  });

  Future<void> setQuranRepeatMode(QuranAudioRepeatMode mode);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
