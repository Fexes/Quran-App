import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../data/repositories/quran_audio_download_repository.dart';
import '../../data/services/quran_audio_download_service.dart';
import '../../data/services/quran_audio_playback_port.dart';
import '../../domain/entities/quran_audio_download_item.dart';
import '../../domain/entities/quran_audio_queue_item.dart';
import '../../domain/entities/quran_audio_state.dart';
import '../../domain/entities/quran_word_timing.dart';
import '../../domain/repositories/quran_word_timing_repository.dart';
import '../../domain/services/quran_translation_audio_selector.dart';

typedef _AudioAyahContext = ({QuranAyah ayah, QuranSurah surah});

class QuranAudioCubit extends Cubit<QuranAudioState> {
  QuranAudioCubit({
    required QuranAudioPlaybackPort audioHandler,
    required QuranRepository quranRepository,
    QuranTranslationRepository? translationRepository,
    required QuranAudioDownloadRepository downloadRepository,
    required QuranAudioDownloadService downloadService,
    required SettingsStore settingsStore,
    required QuranWordTimingRepository wordTimingRepository,
  }) : _audioHandler = audioHandler,
       _quranRepository = quranRepository,
       _translationRepository = translationRepository,
       _downloadRepository = downloadRepository,
       _downloadService = downloadService,
       _settingsStore = settingsStore,
       _wordTimingRepository = wordTimingRepository,
       super(const QuranAudioState.initial()) {
    final savedTranslationReciterId = _settingsStore.audioTranslationReciterId
        .trim();
    if (_settingsStore.audioPlayTranslationEnabled ||
        savedTranslationReciterId.isNotEmpty) {
      emit(
        state.copyWith(
          playTranslationAudio: _settingsStore.audioPlayTranslationEnabled,
          translationReciterId: savedTranslationReciterId.isEmpty
              ? null
              : savedTranslationReciterId,
        ),
      );
    }
    _subscriptions = [
      _audioHandler.playbackState.listen(_onPlaybackStateChanged),
      _audioHandler.mediaItem.listen(_onMediaItemChanged),
      _audioHandler.queue.listen(_onQueueChanged),
      _audioHandler.positionStream.listen(_onPositionChanged),
      _audioHandler.bufferedPositionStream.listen(
        (position) => emit(state.copyWith(bufferedPosition: position)),
      ),
      _audioHandler.durationStream.listen(
        (duration) => emit(
          state.copyWith(duration: duration, clearDuration: duration == null),
        ),
      ),
      _audioHandler.currentIndexStream.listen(_onCurrentIndexChanged),
      _audioHandler.speedStream.listen(
        (speed) => emit(state.copyWith(speed: speed)),
      ),
      _audioHandler.playerStateStream.listen(_onPlayerStateChanged),
    ];
    unawaited(_restoreAudioSnapshot());
  }

  final QuranAudioPlaybackPort _audioHandler;
  final QuranRepository _quranRepository;
  final QuranTranslationRepository? _translationRepository;
  final QuranAudioDownloadRepository _downloadRepository;
  final QuranAudioDownloadService _downloadService;
  final SettingsStore _settingsStore;
  final QuranWordTimingRepository _wordTimingRepository;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  QuranSurah? _activeSurah;
  QuranAudioReciter? _activeReciter;
  QuranAudioReciter? _translationReciter;
  QuranWordTimingResult? _activeWordTiming;
  String? _lastCompletedVerseKey;
  int _wordTimingRequestId = 0;
  int _currentRepeatIteration = 1;
  bool _ayahRepeatArmed = true;
  int? _lastRestoreSnapshotIndex;
  int? _lastRestoreSnapshotPositionMs;
  final Set<String> _autoCacheQueuedIds = <String>{};

  Future<void> playAyah({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
  }) async {
    final queue = await _buildQueueForAyahs([
      (ayah: ayah, surah: surah),
    ], reciter: reciter);
    if (!await _canStartQueue(queue, 0)) {
      return;
    }
    _activeSurah = surah;
    _activeReciter = reciter;
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue.first,
        currentIndex: 0,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.ayah,
        scopeLabel: ayah.verseKey,
        rangeStartAyah: ayah.number,
        rangeEndAyah: ayah.number,
        rangeStartVerseKey: ayah.verseKey,
        rangeEndVerseKey: ayah.verseKey,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(queue);
  }

  Future<void> playSurah({
    required List<QuranAyah> ayahs,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
    String? startVerseKey,
  }) async {
    if (ayahs.isEmpty) {
      return;
    }
    final queue = await _buildQueueForAyahs([
      for (final ayah in ayahs) (ayah: ayah, surah: surah),
    ], reciter: reciter);
    _activeSurah = surah;
    _activeReciter = reciter;
    final startIndex = _startIndex(queue, startVerseKey);
    if (!await _canStartQueue(queue, startIndex)) {
      return;
    }
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue[startIndex],
        currentIndex: startIndex,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.surah,
        scopeLabel: surah.englishName,
        rangeStartVerseKey: queue.first.verseKey,
        rangeEndVerseKey: queue.last.verseKey,
        clearError: true,
        rangeStartAyah: queue.first.ayahNumber,
        rangeEndAyah: queue.last.ayahNumber,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(queue, startIndex: startIndex);
  }

  Future<void> playFromAyahToSurahEnd({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
  }) async {
    final ayahs = await _quranRepository.getAyahs(surah.number);
    final selectedAyahs = ayahs
        .where((candidate) => candidate.number >= ayah.number)
        .toList(growable: false);
    if (selectedAyahs.isEmpty) {
      return;
    }
    final queue = await _buildQueueForAyahs([
      for (final selectedAyah in selectedAyahs)
        (ayah: selectedAyah, surah: surah),
    ], reciter: reciter);
    if (!await _canStartQueue(queue, 0)) {
      return;
    }
    _activeSurah = surah;
    _activeReciter = reciter;
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue.first,
        currentIndex: 0,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.surah,
        scopeLabel: '${surah.englishName} from ${ayah.verseKey}',
        rangeStartAyah: queue.first.ayahNumber,
        rangeEndAyah: queue.last.ayahNumber,
        rangeStartVerseKey: queue.first.verseKey,
        rangeEndVerseKey: queue.last.verseKey,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(queue);
  }

  Future<void> playPage({
    required List<QuranAyah> ayahs,
    required QuranAudioReciter reciter,
    String? startVerseKey,
  }) async {
    if (ayahs.isEmpty) {
      return;
    }
    final surahs = <int, QuranSurah>{};
    final contexts = <_AudioAyahContext>[];
    for (final ayah in ayahs) {
      final surah =
          surahs[ayah.surahNumber] ??
          await _quranRepository.getSurah(ayah.surahNumber);
      surahs[ayah.surahNumber] = surah;
      contexts.add((ayah: ayah, surah: surah));
    }
    final queue = await _buildQueueForAyahs(contexts, reciter: reciter);
    _activeSurah = surahs[queue.first.surahNumber];
    _activeReciter = reciter;
    final startIndex = _startIndex(queue, startVerseKey);
    if (!await _canStartQueue(queue, startIndex)) {
      return;
    }
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue[startIndex],
        currentIndex: startIndex,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.page,
        scopeLabel: 'Page ${queue[startIndex].page}',
        rangeStartAyah: queue.first.ayahNumber,
        rangeEndAyah: queue.last.ayahNumber,
        rangeStartVerseKey: queue.first.verseKey,
        rangeEndVerseKey: queue.last.verseKey,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(queue, startIndex: startIndex);
  }

  Future<void> playRange({
    required int startAyah,
    required int endAyah,
    String? startVerseKey,
  }) async {
    final surah = _activeSurah;
    final reciter = _activeReciter;
    if (surah == null || reciter == null) {
      return;
    }
    final normalizedStart = startAyah <= endAyah ? startAyah : endAyah;
    final normalizedEnd = endAyah >= startAyah ? endAyah : startAyah;
    final ayahs = await _quranRepository.getAyahs(surah.number);
    final selectedAyahs = ayahs
        .where(
          (ayah) =>
              ayah.number >= normalizedStart && ayah.number <= normalizedEnd,
        )
        .toList(growable: false);
    if (selectedAyahs.isEmpty) {
      return;
    }
    final queue = await _buildQueueForAyahs([
      for (final ayah in selectedAyahs) (ayah: ayah, surah: surah),
    ], reciter: reciter);
    final startIndex = _startIndex(queue, startVerseKey);
    if (!await _canStartQueue(queue, startIndex)) {
      return;
    }
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue[startIndex],
        currentIndex: startIndex,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.range,
        scopeLabel: '${queue.first.verseKey}-${queue.last.verseKey}',
        rangeStartAyah: normalizedStart,
        rangeEndAyah: normalizedEnd,
        rangeStartVerseKey: queue.first.verseKey,
        rangeEndVerseKey: queue.last.verseKey,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(queue, startIndex: startIndex);
  }

  Future<void> playCurrentAyahRange() async {
    final current = state.currentItem;
    if (current == null) {
      return;
    }
    await playRange(startAyah: current.ayahNumber, endAyah: current.ayahNumber);
  }

  Future<void> playCurrentPageRange() async {
    final current = state.currentItem;
    if (current == null) {
      return;
    }
    final pageQueue = state.queue
        .where((item) => item.page == current.page)
        .toList(growable: false);
    if (pageQueue.isEmpty) {
      return;
    }
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: pageQueue,
        currentItem: pageQueue.first,
        currentIndex: 0,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.page,
        scopeLabel: 'Page ${pageQueue.first.page}',
        rangeStartAyah: pageQueue.first.ayahNumber,
        rangeEndAyah: pageQueue.last.ayahNumber,
        rangeStartVerseKey: pageQueue.first.verseKey,
        rangeEndVerseKey: pageQueue.last.verseKey,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    _resetRepeatProgress();
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(pageQueue);
  }

  Future<void> playFromCurrentToEndRange() async {
    final current = state.currentItem;
    final surah = _activeSurah;
    if (current == null || surah == null) {
      return;
    }
    await playRange(startAyah: current.ayahNumber, endAyah: surah.ayahCount);
  }

  Future<void> playFullSurahRange() async {
    final surah = _activeSurah;
    if (surah == null) {
      return;
    }
    await playRange(startAyah: 1, endAyah: surah.ayahCount);
  }

  Future<void> playOrPause() async {
    if (!state.hasItem) {
      return;
    }
    if (state.isPlaying) {
      await _audioHandler.pause();
      return;
    }
    if (_audioHandler.currentQueue.isEmpty && state.queue.isNotEmpty) {
      final startIndex = (state.currentIndex ?? 0)
          .clamp(0, state.queue.length - 1)
          .toInt();
      final restorePosition = state.position;
      emit(state.copyWith(status: QuranAudioStatus.loading, clearError: true));
      await _audioHandler.setQuranRepeatMode(state.repeatMode);
      await _audioHandler.loadAndPlay(state.queue, startIndex: startIndex);
      if (restorePosition > Duration.zero) {
        await _audioHandler.seek(restorePosition);
      }
      return;
    }
    await _audioHandler.play();
  }

  Future<void> pause() async {
    if (state.hasItem) {
      await _audioHandler.pause();
    }
  }

  Future<void> resume() async {
    if (state.hasItem) {
      await _audioHandler.play();
    }
  }

  Future<void> togglePlayPause() => playOrPause();

  Future<void> replayQueue() async {
    if (state.queue.isEmpty) {
      return;
    }
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        currentItem: state.queue.first,
        currentIndex: 0,
        position: Duration.zero,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.setQuranRepeatMode(state.repeatMode);
    await _audioHandler.loadAndPlay(state.queue);
  }

  Future<void> stopAndClear() async {
    await _settingsStore.clearAudioRestoreState();
    await _audioHandler.stop();
    emit(
      const QuranAudioState.initial().copyWith(
        playTranslationAudio: state.playTranslationAudio,
        translationReciterId: state.translationReciterId,
        translationReciterName: state.translationReciterName,
      ),
    );
  }

  Future<void> stop() => stopAndClear();

  Future<void> seek(Duration position) => _audioHandler.seek(position);

  Future<void> seekRelative(Duration delta) {
    final next = state.position + delta;
    final duration = state.duration;
    final clamped = duration == null
        ? next
        : Duration(
            milliseconds: next.inMilliseconds.clamp(0, duration.inMilliseconds),
          );
    return seek(clamped.isNegative ? Duration.zero : clamped);
  }

  Future<void> skipNext() => _audioHandler.skipToNext();

  Future<void> skipPrevious() => _audioHandler.skipToPrevious();

  Future<void> setSpeed(double speed) => _audioHandler.setSpeed(speed);

  Future<void> setRepeatMode(QuranAudioRepeatMode repeatMode) async {
    await _audioHandler.setQuranRepeatMode(repeatMode);
    _resetRepeatProgress();
    emit(state.copyWith(repeatMode: repeatMode));
  }

  void setRepeatCount(int repeatCount) {
    _resetRepeatProgress();
    emit(state.copyWith(repeatCount: repeatCount.clamp(1, 10)));
  }

  void setRepeatAfterAction(QuranAudioRepeatAfterAction action) {
    _resetRepeatProgress();
    emit(state.copyWith(repeatAfterAction: action));
  }

  void setRangeDraft({required int startAyah, required int endAyah}) {
    emit(state.copyWith(rangeStartAyah: startAyah, rangeEndAyah: endAyah));
  }

  Future<void> changeReciter(String reciterId) async {
    final current = state.currentItem;
    final surah = _activeSurah;
    if (current == null || surah == null) {
      return;
    }
    final reciters = await _quranRepository.getAudioReciters();
    QuranAudioReciter? selected;
    for (final reciter in reciters) {
      if (reciter.id == reciterId) {
        selected = reciter;
        break;
      }
    }
    if (selected == null) {
      return;
    }
    if (selected.isTranslation) {
      await changeTranslationReciter(selected.id);
      return;
    }

    await _quranRepository.saveSelectedAudioReciterId(selected.id);
    _activeReciter = selected;
    final queuePages = state.queue.map((item) => item.page).toSet();
    if (queuePages.length == 1 && current.page > 0 && state.queue.length > 1) {
      final pageAyahs = await _quranRepository.getPageAyahs(
        current.page,
        includeTranslation: true,
      );
      await playPage(
        ayahs: pageAyahs,
        reciter: selected,
        startVerseKey: current.verseKey,
      );
      return;
    }
    final ayahs = await _quranRepository.getAyahs(surah.number);
    if (state.playbackScope == QuranAudioPlaybackScope.surah &&
        state.rangeEndAyah == surah.ayahCount) {
      final ayah = _ayahForVerseKey(ayahs, current.verseKey);
      if (ayah != null) {
        await playFromAyahToSurahEnd(
          ayah: ayah,
          surah: surah,
          reciter: selected,
        );
        return;
      }
    }
    if (state.rangeStartAyah != null && state.rangeEndAyah != null) {
      await playRange(
        startAyah: state.rangeStartAyah!,
        endAyah: state.rangeEndAyah!,
      );
      return;
    }
    if (state.queue.length <= 1) {
      final ayah = _ayahForVerseKey(ayahs, current.verseKey);
      if (ayah != null) {
        await playAyah(ayah: ayah, surah: surah, reciter: selected);
      }
      return;
    }
    await playSurah(
      ayahs: ayahs,
      surah: surah,
      reciter: selected,
      startVerseKey: current.verseKey,
    );
  }

  Future<List<QuranAudioReciter>> getAudioReciters() {
    return _quranRepository.getAudioReciters();
  }

  Future<List<QuranAudioReciter>> getArabicAudioReciters() async {
    final reciters = await _quranRepository.getAudioReciters();
    return reciters.where((reciter) => !reciter.isTranslation).toList();
  }

  Future<List<QuranAudioReciter>> getTranslationAudioReciters() async {
    final reciters = await _quranRepository.getAudioReciters();
    return reciters.where((reciter) => reciter.isTranslation).toList();
  }

  Future<void> setPlayTranslationAudio(bool enabled) async {
    if (!enabled) {
      await _settingsStore.setAudioPlayTranslationEnabled(false);
      emit(state.copyWith(playTranslationAudio: false, clearError: true));
      await _reloadCurrentScope();
      return;
    }

    final reciter = await _ensureTranslationReciter();
    if (reciter == null) {
      emit(
        state.copyWith(
          playTranslationAudio: false,
          status: QuranAudioStatus.failure,
          errorMessage: 'No translation voice is available.',
        ),
      );
      return;
    }

    await _settingsStore.setAudioPlayTranslationEnabled(true);
    await _settingsStore.setAudioTranslationReciterId(reciter.id);
    emit(
      state.copyWith(
        playTranslationAudio: true,
        translationReciterId: reciter.id,
        translationReciterName: reciter.name,
        clearError: true,
      ),
    );
    await _reloadCurrentScope();
  }

  Future<void> changeTranslationReciter(String reciterId) async {
    final reciter = await _translationReciterById(
      reciterId,
      selectedLanguageOnly: true,
    );
    if (reciter == null) {
      return;
    }
    _translationReciter = reciter;
    await _settingsStore.setAudioTranslationReciterId(reciter.id);
    await _settingsStore.setAudioMeaningLanguageCode(reciter.languageCode);
    emit(
      state.copyWith(
        translationReciterId: reciter.id,
        translationReciterName: reciter.name,
        clearError: true,
      ),
    );
    if (state.playTranslationAudio) {
      await _reloadCurrentScope();
    }
  }

  QuranSurah? get activeSurah => _activeSurah;

  QuranAudioReciter? get activeReciter => _activeReciter;

  void _onPlaybackStateChanged(PlaybackState playbackState) {
    final status = switch (playbackState.processingState) {
      AudioProcessingState.idle => QuranAudioStatus.idle,
      AudioProcessingState.loading => QuranAudioStatus.loading,
      AudioProcessingState.buffering => QuranAudioStatus.buffering,
      AudioProcessingState.ready =>
        playbackState.playing
            ? QuranAudioStatus.playing
            : QuranAudioStatus.paused,
      AudioProcessingState.completed => QuranAudioStatus.completed,
      AudioProcessingState.error => QuranAudioStatus.failure,
    };
    final clearActiveWord =
        status == QuranAudioStatus.idle ||
        status == QuranAudioStatus.paused ||
        status == QuranAudioStatus.completed ||
        status == QuranAudioStatus.failure;
    emit(
      state.copyWith(
        status: status,
        position: playbackState.updatePosition,
        bufferedPosition: playbackState.bufferedPosition,
        speed: playbackState.speed,
        errorMessage: playbackState.errorMessage,
        clearError: playbackState.errorMessage == null,
        clearActiveWord: clearActiveWord,
      ),
    );
    if (status == QuranAudioStatus.paused ||
        status == QuranAudioStatus.playing ||
        status == QuranAudioStatus.loading ||
        status == QuranAudioStatus.buffering) {
      _persistAudioRestoreSnapshot(force: status == QuranAudioStatus.paused);
    }
  }

  void _onPositionChanged(Duration position) {
    _maybeRepeatActiveAyah(position);

    final timing = _activeWordTiming;
    if (timing == null || !timing.hasSegments) {
      emit(state.copyWith(position: position, clearActiveWord: true));
      _persistAudioRestoreSnapshot();
      return;
    }

    final segment = timing.segmentAt(position);
    if (segment == null) {
      emit(state.copyWith(position: position, clearActiveWord: true));
      _persistAudioRestoreSnapshot();
      return;
    }

    if (state.activeWordVerseKey == segment.verseKey &&
        state.activeWordIndex == segment.wordIndex) {
      emit(state.copyWith(position: position));
      _persistAudioRestoreSnapshot();
      return;
    }

    emit(
      state.copyWith(
        position: position,
        activeWordVerseKey: segment.verseKey,
        activeWordIndex: segment.wordIndex,
      ),
    );
    _persistAudioRestoreSnapshot();
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    if (playerState.processingState != ProcessingState.completed) {
      if (state.status != QuranAudioStatus.completed) {
        _lastCompletedVerseKey = null;
      }
      return;
    }

    final current = state.currentItem;
    if (current == null || _lastCompletedVerseKey == current.verseKey) {
      return;
    }
    _lastCompletedVerseKey = current.verseKey;

    if (state.repeatMode == QuranAudioRepeatMode.queue &&
        state.repeatCount > 1 &&
        _currentRepeatIteration < state.repeatCount) {
      _currentRepeatIteration += 1;
      _lastCompletedVerseKey = null;
      emit(
        state.copyWith(
          status: QuranAudioStatus.loading,
          currentItem: state.queue.first,
          currentIndex: 0,
          position: Duration.zero,
          clearError: true,
          clearActiveWord: true,
        ),
      );
      _audioHandler.loadAndPlay(state.queue);
      return;
    }

    if (state.repeatMode == QuranAudioRepeatMode.queue) {
      unawaited(_finishRepeatedRange());
      return;
    }

    _resetRepeatProgress();
    emit(state.copyWith(status: QuranAudioStatus.completed));
    unawaited(_settingsStore.clearAudioRestoreState());
  }

  void _onMediaItemChanged(MediaItem? item) {
    final queueItem = QuranAudioQueueItem.fromMediaItem(item);
    if (queueItem == null) {
      _activeWordTiming = null;
      emit(
        state.copyWith(
          wordTimingStatus: QuranAudioWordTimingStatus.unavailable,
          clearItem: true,
          clearDuration: true,
          clearActiveWord: true,
        ),
      );
      return;
    }
    _activeWordTiming = null;
    emit(
      state.copyWith(
        currentItem: queueItem,
        wordTimingStatus:
            queueItem.timingProvider == QuranAudioTimingProvider.none
            ? QuranAudioWordTimingStatus.unavailable
            : QuranAudioWordTimingStatus.loading,
        clearActiveWord: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    unawaited(_loadWordTimings(queueItem));
    _autoCacheAroundCurrentItem(queueItem);
  }

  void _onQueueChanged(List<MediaItem> mediaItems) {
    if (mediaItems.isEmpty) {
      unawaited(_settingsStore.clearAudioRestoreState());
      emit(state.copyWith(queue: const [], clearItem: true));
      return;
    }
    final queue = mediaItems
        .map(QuranAudioQueueItem.fromMediaItem)
        .whereType<QuranAudioQueueItem>()
        .toList(growable: false);
    emit(state.copyWith(queue: queue));
    _persistAudioRestoreSnapshot(force: true);
    final currentItem = state.currentItem;
    if (currentItem != null) {
      _autoCacheAroundCurrentItem(currentItem);
    }
  }

  void _onCurrentIndexChanged(int? index) {
    if (index != state.currentIndex) {
      _resetRepeatProgress();
    }
    QuranAudioQueueItem? currentItem;
    if (index != null && index >= 0 && index < state.queue.length) {
      currentItem = state.queue[index];
    }
    emit(
      state.copyWith(
        currentIndex: index,
        currentItem: currentItem,
        clearActiveWord: currentItem == null,
      ),
    );
    _persistAudioRestoreSnapshot(force: currentItem != null);
    if (currentItem != null) {
      _autoCacheAroundCurrentItem(currentItem);
    }
  }

  void _resetRepeatProgress() {
    _currentRepeatIteration = 1;
    _ayahRepeatArmed = true;
    _lastCompletedVerseKey = null;
  }

  Future<void> _finishRepeatedRange() async {
    final action = state.repeatAfterAction;
    _resetRepeatProgress();
    if (action == QuranAudioRepeatAfterAction.continuePlayback) {
      await _continueAfterRepeatedRange();
      return;
    }
    await stopAndClear();
  }

  Future<void> _continueAfterRepeatedRange() async {
    final surah = _activeSurah;
    final reciter = _activeReciter;
    final completedRangeEnd = state.rangeEndAyah;
    if (surah == null || reciter == null || completedRangeEnd == null) {
      await stopAndClear();
      return;
    }
    if (completedRangeEnd >= surah.ayahCount) {
      await stopAndClear();
      return;
    }

    final ayahs = await _quranRepository.getAyahs(surah.number);
    final remainingAyahs = ayahs
        .where((ayah) => ayah.number > completedRangeEnd)
        .toList(growable: false);
    if (remainingAyahs.isEmpty) {
      await stopAndClear();
      return;
    }

    final queue = await _buildQueueForAyahs([
      for (final ayah in remainingAyahs) (ayah: ayah, surah: surah),
    ], reciter: reciter);
    if (!await _canStartQueue(queue, 0)) {
      return;
    }

    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: QuranAudioStatus.loading,
        queue: queue,
        currentItem: queue.first,
        currentIndex: 0,
        position: Duration.zero,
        playbackScope: QuranAudioPlaybackScope.surah,
        scopeLabel: '${surah.englishName} continued',
        rangeStartAyah: queue.first.ayahNumber,
        rangeEndAyah: queue.last.ayahNumber,
        rangeStartVerseKey: queue.first.verseKey,
        rangeEndVerseKey: queue.last.verseKey,
        repeatMode: QuranAudioRepeatMode.off,
        repeatCount: 1,
        repeatAfterAction: QuranAudioRepeatAfterAction.stop,
        clearError: true,
        clearActiveWord: true,
      ),
    );
    await _audioHandler.setQuranRepeatMode(QuranAudioRepeatMode.off);
    await _audioHandler.loadAndPlay(queue);
  }

  void _maybeRepeatActiveAyah(Duration position) {
    if (state.repeatMode != QuranAudioRepeatMode.ayah ||
        state.repeatCount <= 1 ||
        state.currentItem == null) {
      return;
    }
    final duration = state.duration;
    if (duration == null || duration.inMilliseconds <= 0) {
      return;
    }
    final rearmWindowMs = duration.inMilliseconds < 1000 ? 80 : 180;
    if (position.inMilliseconds <= rearmWindowMs) {
      _ayahRepeatArmed = true;
      return;
    }
    if (!_ayahRepeatArmed) {
      return;
    }
    final thresholdMs = duration.inMilliseconds < 1500
        ? 120
        : duration.inMilliseconds < 4000
        ? 260
        : 420;
    final remainingMs = duration.inMilliseconds - position.inMilliseconds;
    if (remainingMs > thresholdMs) {
      return;
    }
    _ayahRepeatArmed = false;
    if (_currentRepeatIteration >= state.repeatCount) {
      return;
    }
    _currentRepeatIteration += 1;
    unawaited(
      _audioHandler.seek(Duration.zero).then((_) => _audioHandler.play()),
    );
  }

  Future<void> _loadWordTimings(QuranAudioQueueItem item) async {
    final requestId = ++_wordTimingRequestId;
    if (item.timingProvider == QuranAudioTimingProvider.none) {
      if (!isClosed) {
        emit(
          state.copyWith(
            wordTimingStatus: QuranAudioWordTimingStatus.unavailable,
            clearActiveWord: true,
          ),
        );
      }
      return;
    }

    final reciter = _activeReciter?.id == item.reciterId
        ? _activeReciter!
        : QuranAudioReciter(
            id: item.reciterId,
            name: item.reciterName,
            provider: QuranAudioProvider.everyAyah,
            identifier: '',
            timingProvider: item.timingProvider,
            timingRecitationId: item.timingRecitationId,
            timingChapterReciterId: item.timingChapterReciterId,
          );
    final result = await _wordTimingRepository.timingsFor(
      reciter: reciter,
      item: item,
    );
    if (isClosed ||
        requestId != _wordTimingRequestId ||
        state.currentItem?.verseKey != item.verseKey) {
      return;
    }

    _activeWordTiming = result.hasSegments ? result : null;
    emit(
      state.copyWith(
        wordTimingStatus: result.hasSegments
            ? QuranAudioWordTimingStatus.ready
            : QuranAudioWordTimingStatus.unavailable,
        clearActiveWord: true,
      ),
    );
    _onPositionChanged(state.position);
  }

  int _startIndex(List<QuranAudioQueueItem> queue, String? startVerseKey) {
    if (startVerseKey == null) {
      return 0;
    }
    final index = queue.indexWhere((item) => item.verseKey == startVerseKey);
    return index < 0 ? 0 : index;
  }

  QuranAyah? _ayahForVerseKey(List<QuranAyah> ayahs, String verseKey) {
    for (final ayah in ayahs) {
      if (ayah.verseKey == verseKey) {
        return ayah;
      }
    }
    return null;
  }

  Future<List<QuranAudioQueueItem>> _buildQueueForAyahs(
    List<_AudioAyahContext> contexts, {
    required QuranAudioReciter reciter,
  }) async {
    final translationReciter = state.playTranslationAudio
        ? await _ensureTranslationReciter()
        : null;
    final queue = <QuranAudioQueueItem>[];
    for (final context in contexts) {
      queue.add(
        QuranAudioQueueItem.fromAyah(
          ayah: context.ayah,
          surah: context.surah,
          reciter: reciter,
          segmentType: QuranAudioSegmentType.arabic,
        ),
      );
      if (translationReciter != null) {
        queue.add(
          QuranAudioQueueItem.fromAyah(
            ayah: context.ayah,
            surah: context.surah,
            reciter: translationReciter,
            segmentType: QuranAudioSegmentType.translation,
          ),
        );
      }
    }
    return _resolveQueue(queue);
  }

  Future<QuranAudioReciter?> _ensureTranslationReciter() async {
    final cached = _translationReciter;
    final reciters = await _selectedTranslationAudioReciters();
    if (cached != null && reciters.any((reciter) => reciter.id == cached.id)) {
      return cached;
    }

    final savedId =
        state.translationReciterId ?? _settingsStore.audioTranslationReciterId;
    final saved = _translationReciterByIdFrom(savedId, reciters);
    if (saved != null) {
      _translationReciter = saved;
      return saved;
    }

    if (reciters.isEmpty) {
      return null;
    }
    final selected = reciters.first;
    _translationReciter = selected;
    await _settingsStore.setAudioTranslationReciterId(selected.id);
    emit(
      state.copyWith(
        translationReciterId: selected.id,
        translationReciterName: selected.name,
      ),
    );
    return selected;
  }

  Future<List<QuranAudioReciter>> _selectedTranslationAudioReciters() async {
    final reciters = await getTranslationAudioReciters();
    var languageCode = _settingsStore.audioMeaningLanguageCodeOrNull;
    final selectedTranslation = await _translationRepository
        ?.selectedTranslation();
    if (languageCode == null) {
      languageCode = selectedTranslation?.wordTranslationLanguageCode;
      if (languageCode != null) {
        await _settingsStore.setAudioMeaningLanguageCode(languageCode);
      }
    }
    return quranTranslationAudioRecitersFor(
      reciters: reciters,
      selectedTranslation: selectedTranslation,
      preferredLanguageCode: languageCode,
    );
  }

  Future<QuranAudioReciter?> _translationReciterById(
    String? reciterId, {
    bool selectedLanguageOnly = false,
  }) async {
    final reciters = selectedLanguageOnly
        ? await _selectedTranslationAudioReciters()
        : await getTranslationAudioReciters();
    return _translationReciterByIdFrom(reciterId, reciters);
  }

  QuranAudioReciter? _translationReciterByIdFrom(
    String? reciterId,
    List<QuranAudioReciter> reciters,
  ) {
    final normalized = reciterId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final reciter in reciters) {
      if (reciter.id == normalized) {
        return reciter;
      }
    }
    return null;
  }

  Future<void> _reloadCurrentScope() async {
    final current = state.currentItem;
    final surah = _activeSurah;
    final reciter = _activeReciter;
    if (current == null || surah == null || reciter == null) {
      return;
    }

    if (state.playbackScope == QuranAudioPlaybackScope.page &&
        current.page > 0) {
      final pageAyahs = await _quranRepository.getPageAyahs(
        current.page,
        includeTranslation: true,
      );
      await playPage(
        ayahs: pageAyahs,
        reciter: reciter,
        startVerseKey: current.verseKey,
      );
      return;
    }

    if (state.playbackScope == QuranAudioPlaybackScope.range &&
        state.rangeStartAyah != null &&
        state.rangeEndAyah != null) {
      await playRange(
        startAyah: state.rangeStartAyah!,
        endAyah: state.rangeEndAyah!,
        startVerseKey: current.verseKey,
      );
      return;
    }

    final ayahs = await _quranRepository.getAyahs(surah.number);
    final currentAyah = _ayahForVerseKey(ayahs, current.verseKey);
    if (currentAyah == null) {
      return;
    }

    if (state.playbackScope == QuranAudioPlaybackScope.ayah) {
      await playAyah(ayah: currentAyah, surah: surah, reciter: reciter);
      return;
    }

    await playFromAyahToSurahEnd(
      ayah: currentAyah,
      surah: surah,
      reciter: reciter,
    );
  }

  Future<List<QuranAudioQueueItem>> _resolveQueue(
    List<QuranAudioQueueItem> queue,
  ) {
    return _downloadRepository.resolveQueue(queue);
  }

  Future<void> _restoreAudioSnapshot() async {
    final snapshot = _settingsStore.audioRestoreState;
    if (snapshot.isEmpty) {
      return;
    }

    final rawQueue = snapshot['queue'];
    if (rawQueue is! List) {
      await _settingsStore.clearAudioRestoreState();
      return;
    }

    final cachedQueue = rawQueue
        .map(QuranAudioQueueItem.fromCacheMap)
        .whereType<QuranAudioQueueItem>()
        .toList(growable: false);
    if (cachedQueue.isEmpty) {
      await _settingsStore.clearAudioRestoreState();
      return;
    }

    final restoredQueue = await _resolveQueue(cachedQueue);
    if (isClosed || restoredQueue.isEmpty) {
      return;
    }

    final currentIndex = _clampedIndex(
      snapshot['currentIndex'],
      restoredQueue.length,
    );
    final currentItem = restoredQueue[currentIndex];
    await _hydrateRestoredAudioContext(restoredQueue, currentItem);
    if (isClosed) {
      return;
    }

    final position = Duration(
      milliseconds: _intFromSnapshot(snapshot['positionMs']) ?? 0,
    );
    emit(
      state.copyWith(
        status: QuranAudioStatus.paused,
        queue: restoredQueue,
        currentItem: currentItem,
        currentIndex: currentIndex,
        position: position,
        bufferedPosition: Duration.zero,
        playbackScope: _playbackScopeFromSnapshot(snapshot['playbackScope']),
        scopeLabel: snapshot['scopeLabel'] as String? ?? currentItem.verseKey,
        rangeStartAyah: _intFromSnapshot(snapshot['rangeStartAyah']),
        rangeEndAyah: _intFromSnapshot(snapshot['rangeEndAyah']),
        rangeStartVerseKey: snapshot['rangeStartVerseKey'] as String?,
        rangeEndVerseKey: snapshot['rangeEndVerseKey'] as String?,
        playTranslationAudio:
            snapshot['playTranslationAudio'] as bool? ??
            state.playTranslationAudio,
        translationReciterId:
            snapshot['translationReciterId'] as String? ??
            state.translationReciterId,
        translationReciterName:
            snapshot['translationReciterName'] as String? ??
            state.translationReciterName,
        wordTimingStatus: QuranAudioWordTimingStatus.unavailable,
        clearDuration: true,
        clearError: true,
        clearActiveWord: true,
      ),
    );
    _lastRestoreSnapshotIndex = currentIndex;
    _lastRestoreSnapshotPositionMs = position.inMilliseconds;
  }

  Future<void> _hydrateRestoredAudioContext(
    List<QuranAudioQueueItem> queue,
    QuranAudioQueueItem currentItem,
  ) async {
    try {
      _activeSurah = await _quranRepository.getSurah(currentItem.surahNumber);
    } catch (_) {
      _activeSurah = null;
    }

    final reciters = await _quranRepository.getAudioReciters();
    final arabicItem = queue.cast<QuranAudioQueueItem?>().firstWhere(
      (item) => item != null && !item.isTranslationSegment,
      orElse: () => currentItem.isTranslationSegment ? null : currentItem,
    );
    _activeReciter = _reciterById(reciters, arabicItem?.reciterId);
    final translationItem = queue.cast<QuranAudioQueueItem?>().firstWhere(
      (item) => item != null && item.isTranslationSegment,
      orElse: () => currentItem.isTranslationSegment ? currentItem : null,
    );
    _translationReciter = _reciterById(reciters, translationItem?.reciterId);
  }

  QuranAudioReciter? _reciterById(
    List<QuranAudioReciter> reciters,
    String? reciterId,
  ) {
    if (reciterId == null || reciterId.isEmpty) {
      return null;
    }
    for (final reciter in reciters) {
      if (reciter.id == reciterId) {
        return reciter;
      }
    }
    return null;
  }

  void _persistAudioRestoreSnapshot({bool force = false}) {
    if (isClosed ||
        state.queue.isEmpty ||
        state.currentItem == null ||
        state.status == QuranAudioStatus.idle ||
        state.status == QuranAudioStatus.completed ||
        state.status == QuranAudioStatus.failure) {
      return;
    }

    final currentIndex = _currentSnapshotIndex();
    final positionMs = state.position.inMilliseconds;
    if (!force &&
        _lastRestoreSnapshotIndex == currentIndex &&
        _lastRestoreSnapshotPositionMs != null &&
        (positionMs - _lastRestoreSnapshotPositionMs!).abs() < 5000) {
      return;
    }

    _lastRestoreSnapshotIndex = currentIndex;
    _lastRestoreSnapshotPositionMs = positionMs;
    unawaited(_settingsStore.setAudioRestoreState(_audioRestoreSnapshot()));
  }

  int _currentSnapshotIndex() {
    final currentIndex = state.currentIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < state.queue.length) {
      return currentIndex;
    }
    final currentItem = state.currentItem;
    if (currentItem == null) {
      return 0;
    }
    final resolved = state.queue.indexWhere(
      (item) =>
          item.verseKey == currentItem.verseKey &&
          item.segmentType == currentItem.segmentType &&
          item.reciterId == currentItem.reciterId,
    );
    return resolved < 0 ? 0 : resolved;
  }

  Map<String, Object?> _audioRestoreSnapshot() {
    return {
      'version': 1,
      'queue': [for (final item in state.queue) item.toCacheMap()],
      'currentIndex': _currentSnapshotIndex(),
      'positionMs': state.position.inMilliseconds,
      'playbackScope': state.playbackScope.name,
      'scopeLabel': state.scopeLabel,
      'rangeStartAyah': state.rangeStartAyah,
      'rangeEndAyah': state.rangeEndAyah,
      'rangeStartVerseKey': state.rangeStartVerseKey,
      'rangeEndVerseKey': state.rangeEndVerseKey,
      'playTranslationAudio': state.playTranslationAudio,
      'translationReciterId': state.translationReciterId,
      'translationReciterName': state.translationReciterName,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  int _clampedIndex(Object? value, int length) {
    final index = _intFromSnapshot(value) ?? 0;
    return index.clamp(0, length - 1).toInt();
  }

  int? _intFromSnapshot(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return null;
  }

  QuranAudioPlaybackScope _playbackScopeFromSnapshot(Object? value) {
    if (value is String) {
      for (final scope in QuranAudioPlaybackScope.values) {
        if (scope.name == value) {
          return scope;
        }
      }
    }
    return QuranAudioPlaybackScope.ayah;
  }

  Future<bool> _canStartQueue(
    List<QuranAudioQueueItem> queue,
    int startIndex,
  ) async {
    if (queue.isEmpty) {
      return false;
    }
    final pendingQueue = queue
        .skip(startIndex.clamp(0, queue.length - 1))
        .toList(growable: false);
    if (pendingQueue.every((item) => item.isDownloaded)) {
      return true;
    }
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        final missingTranslation = pendingQueue.any(
          (item) => item.isTranslationSegment && !item.isDownloaded,
        );
        emit(
          state.copyWith(
            status: QuranAudioStatus.failure,
            errorMessage: missingTranslation
                ? 'Translation audio is not downloaded for offline playback.'
                : 'Audio is not downloaded for offline playback.',
          ),
        );
        return false;
      }
    } catch (_) {
      return true;
    }
    return true;
  }

  Future<void> _autoCacheIfNeeded(QuranAudioQueueItem item) async {
    if (!_settingsStore.audioAutoCachePlayedAyahs ||
        item.isDownloaded ||
        item.playbackUri != item.remoteAudioUrl) {
      return;
    }
    final id = QuranAudioDownloadItem.idFor(
      reciterId: item.reciterId,
      surahNumber: item.surahNumber,
      ayahNumber: item.ayahNumber,
    );
    if (!_autoCacheQueuedIds.add(id)) {
      return;
    }
    final downloadItem = await _downloadRepository.itemForQueueItem(item);
    try {
      await _downloadService.enqueueItems([downloadItem]);
    } catch (_) {
      _autoCacheQueuedIds.remove(id);
    }
  }

  void _autoCacheAroundCurrentItem(QuranAudioQueueItem currentItem) {
    unawaited(_autoCacheIfNeeded(currentItem));

    final queue = state.queue;
    final currentIndex = _autoCacheCurrentIndex(queue, currentItem);
    if (currentIndex == null) {
      return;
    }

    for (final upcoming in queue.skip(currentIndex + 1).take(2)) {
      unawaited(_autoCacheIfNeeded(upcoming));
    }
  }

  int? _autoCacheCurrentIndex(
    List<QuranAudioQueueItem> queue,
    QuranAudioQueueItem currentItem,
  ) {
    final currentIndex = state.currentIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < queue.length &&
        _sameQueueItem(queue[currentIndex], currentItem)) {
      return currentIndex;
    }

    final matchedIndex = queue.indexWhere(
      (item) => _sameQueueItem(item, currentItem),
    );
    return matchedIndex < 0 ? null : matchedIndex;
  }

  bool _sameQueueItem(QuranAudioQueueItem a, QuranAudioQueueItem b) {
    return a.verseKey == b.verseKey &&
        a.reciterId == b.reciterId &&
        a.segmentType == b.segmentType &&
        a.remoteAudioUrl == b.remoteAudioUrl;
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _audioHandler.dispose();
    return super.close();
  }
}
