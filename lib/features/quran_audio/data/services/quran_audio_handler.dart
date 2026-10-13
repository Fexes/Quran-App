import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import '../../../quran/data/services/surah_cover_cache.dart';
import '../../../quran/domain/entities/surah_image_catalog.dart';
import '../../domain/entities/quran_audio_queue_item.dart';
import '../../domain/entities/quran_audio_state.dart';
import 'quran_audio_playback_port.dart';

class QuranAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements QuranAudioPlaybackPort, QuranAudioFiniteRepeatPort {
  QuranAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      onError: _broadcastPlaybackError,
    );
    _player.errorStream.listen((error) {
      _broadcastPlaybackError(error, StackTrace.current);
    });
    _player.currentIndexStream.listen((index) {
      if (index != _repeatItemIndex) {
        _repeatItemIndex = index;
        _ayahRepeatIteration = 1;
        unawaited(_syncAyahLoopMode().catchError(_broadcastPlaybackError));
      }
      final items = queue.value;
      if (index != null && index >= 0 && index < items.length) {
        mediaItem.add(items[index]);
      }
    });
    _player.positionDiscontinuityStream.listen((event) {
      if (_repeatMode == QuranAudioRepeatMode.ayah &&
          event.reason == PositionDiscontinuityReason.autoAdvance &&
          event.previousEvent.currentIndex == event.event.currentIndex) {
        _ayahRepeatIteration++;
        unawaited(_syncAyahLoopMode().catchError(_broadcastPlaybackError));
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  List<QuranAudioQueueItem> _items = const [];
  final Map<int, String?> _artworkUriBySurah = {};
  int _loadRevision = 0;
  int _transportRevision = 0;
  QuranAudioRepeatMode _repeatMode = QuranAudioRepeatMode.off;
  int _ayahRepeatCount = 1;
  int _ayahRepeatIteration = 1;
  int? _repeatItemIndex;

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
    Duration initialPosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    if (items.isEmpty) {
      return;
    }
    final loadRevision = ++_loadRevision;
    final transportRevision = _transportRevision;
    if (!autoPlay) await _player.pause();
    _items = List.unmodifiable(items);
    _repeatItemIndex = startIndex.clamp(0, items.length - 1);
    _ayahRepeatIteration = 1;
    final mediaItems = _items.map((item) => item.toMediaItem()).toList();
    queue.add(mediaItems);
    mediaItem.add(mediaItems[startIndex.clamp(0, mediaItems.length - 1)]);
    unawaited(
      _refreshSurahArtwork(loadRevision).catchError((Object error) {
        debugPrint('Could not refresh audio artwork: $error');
      }),
    );
    await _syncAyahLoopMode();
    if (loadRevision != _loadRevision) return;

    final sources = [
      for (final item in _items)
        AudioSource.uri(Uri.parse(item.playbackUri), tag: item.toMediaItem()),
    ];
    try {
      await _player.setAudioSources(
        sources,
        initialIndex: startIndex.clamp(0, sources.length - 1),
        initialPosition: initialPosition,
      );
    } on PlayerInterruptedException {
      if (loadRevision != _loadRevision) return;
      rethrow;
    }
    if (loadRevision == _loadRevision &&
        transportRevision == _transportRevision &&
        autoPlay) {
      await play();
    }
  }

  Future<void> _refreshSurahArtwork(int revision) async {
    final surahs = <int>{};
    for (final item in _items) {
      if (!surahs.add(item.surahNumber)) continue;
      final uri = await _localArtworkUriFor(item);
      if (revision != _loadRevision) return;
      if (uri == null) continue;
      _items = List.unmodifiable([
        for (final queued in _items)
          if (queued.surahNumber == item.surahNumber)
            queued.copyWithArtwork(surahArtworkUri: uri)
          else
            queued,
      ]);
      queue.add(_items.map((entry) => entry.toMediaItem()).toList());
      final index = _player.currentIndex;
      if (index != null && index >= 0 && index < _items.length) {
        mediaItem.add(_items[index].toMediaItem());
      }
    }
  }

  Future<String?> _localArtworkUriFor(QuranAudioQueueItem item) async {
    final cached = _artworkUriBySurah[item.surahNumber];
    if (cached != null) {
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
    return artworkUri;
  }

  @override
  Future<void> setQuranRepeatMode(QuranAudioRepeatMode mode) async {
    _repeatMode = mode;
    _ayahRepeatIteration = 1;
    await _syncAyahLoopMode();
  }

  @override
  Future<void> setAyahRepeatCount(int count) async {
    _ayahRepeatCount = count.clamp(1, 10);
    _ayahRepeatIteration = 1;
    await _syncAyahLoopMode();
  }

  Future<void> _syncAyahLoopMode() {
    final index = _repeatItemIndex;
    final item = index != null && index >= 0 && index < _items.length
        ? _items[index]
        : null;
    // The native loop finishes the entire segment before repeating it.
    final repeat =
        _repeatMode == QuranAudioRepeatMode.ayah &&
        _ayahRepeatIteration < _ayahRepeatCount &&
        item != null &&
        !item.isBismillah;
    return _player.setLoopMode(repeat ? LoopMode.one : LoopMode.off);
  }

  @override
  Future<void> play() async {
    _transportRevision++;
    // just_audio's play future completes at the end of playback, not on start.
    unawaited(_player.play().catchError(_broadcastPlaybackError));
  }

  @override
  Future<void> pause() {
    _transportRevision++;
    return _player.pause();
  }

  @override
  Future<void> stop() async {
    _loadRevision++;
    _transportRevision++;
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
    _loadRevision++;
    return _player.dispose();
  }
}
