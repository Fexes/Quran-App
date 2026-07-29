import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../quran/data/services/surah_cover_cache.dart';
import '../../../quran/domain/entities/surah_image_catalog.dart';
import '../../domain/entities/quran_audio_queue_item.dart';
import '../../domain/entities/quran_audio_state.dart';
import 'quran_audio_playback_port.dart';

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements QuranAudioPlaybackPort {
  QuranAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: _broadcastPlaybackError,
    );
    _player.errorStream.listen((error) {
      _broadcastPlaybackError(error, StackTrace.current);
    });
    _player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index != null && index >= 0 && index < items.length) {
        mediaItem.add(items[index]);
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<QuranAudioQueueItem> _items = const [];
  final Map<int, String?> _artworkUriBySurah = {};

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  @override
  Stream<double> get speedStream => _player.speedStream;
  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  int? get currentIndex => _player.currentIndex;
  @override
  bool get playing => _player.playing;

  @override
  List<QuranAudioQueueItem> get currentQueue => _items;

  @override
  Future<void> loadAndPlay(
    List<QuranAudioQueueItem> items, {
    int startIndex = 0,
  }) async {
    if (items.isEmpty) {
      return;
    }
    _items = List.unmodifiable(await _withSurahArtwork(items));
    final mediaItems = _items.map((item) => item.toMediaItem()).toList();
    queue.add(mediaItems);
    mediaItem.add(mediaItems[startIndex.clamp(0, mediaItems.length - 1)]);

    final sources = [
      for (final item in _items)
        AudioSource.uri(Uri.parse(item.playbackUri), tag: item.toMediaItem()),
    ];
    await _player.setAudioSources(
      sources,
      initialIndex: startIndex.clamp(0, sources.length - 1),
    );
    await play();
  }

  Future<List<QuranAudioQueueItem>> _withSurahArtwork(
    List<QuranAudioQueueItem> items,
  ) async {
    final prepared = <QuranAudioQueueItem>[];
    for (final item in items) {
      prepared.add(
        item.copyWithArtwork(surahArtworkUri: await _localArtworkUriFor(item)),
      );
    }
    return prepared;
  }

  Future<String?> _localArtworkUriFor(QuranAudioQueueItem item) async {
    final cached = _artworkUriBySurah[item.surahNumber];
    if (_artworkUriBySurah.containsKey(item.surahNumber)) {
      return cached;
    }

    final imageUrl =
        item.surahImageAssetPath ??
        SurahImageCatalog.imageUrlFor(item.surahNumber);
    final cachedUri = await SurahCoverCache.instance.uriFor(item.surahNumber);
    if (cachedUri != null) {
      _artworkUriBySurah[item.surahNumber] = cachedUri;
      return cachedUri;
    }
    final uri = Uri.tryParse(imageUrl);
    final artworkUri = uri == null || !uri.hasScheme ? null : imageUrl;
    _artworkUriBySurah[item.surahNumber] = artworkUri;
    return artworkUri;
  }

  @override
  Future<void> setQuranRepeatMode(QuranAudioRepeatMode _) async {
    await _player.setLoopMode(LoopMode.off);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    _items = const [];
    queue.add(const []);
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        controls: const [],
        systemActions: const {},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: _player.speed,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  void _broadcastPlaybackState(PlaybackEvent event) {
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (_player.playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _processingState(),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  void _broadcastPlaybackError(Object error, StackTrace stackTrace) {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: error.toString(),
      ),
    );
  }

  AudioProcessingState _processingState() {
    return switch (_player.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}
