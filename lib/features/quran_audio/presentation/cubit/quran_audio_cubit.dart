import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/domain/services/quran_translation_audio_pairings.dart';
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
    if (translationRepository is QuranTranslationSelectionObservable) {
      _translationChanges =
          (translationRepository as QuranTranslationSelectionObservable)
              .selectionChanges;
      _translationChanges!.addListener(_onTranslationPreferenceChanged);
    }
    _settingsStore.beforePersonalDataErase.add(_prepareForPersonalDataErase);
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
  QuranWordTimingResult? _activeWordTiming;
  String? _lastCompletedVerseKey;
  int _wordTimingRequestId = 0;
  int _currentRepeatIteration = 1;
  bool _ayahRepeatArmed = true;
  int? _lastRestoreSnapshotIndex;
  int? _lastRestoreSnapshotPositionMs;
  final Set<String> _autoCacheQueuedIds = <String>{};
  int _settingsQueueRevision = 0;
  int _translationToggleRevision = 0;
  Listenable? _translationChanges;
  int _translationSelectionRevision = 0;
  bool _changingTranslationEdition = false;
  bool _translationResumeAfterUpdate = false;
  int _playbackIntentRevision = 0;
  bool _suppressSnapshots = false;
  Future<void> _snapshotWrite = Future.value();
  final Set<Future<void>> _preferenceOperations = {};

  Future<T> _trackPreferenceOperation<T>(Future<T> Function() action) async {
    final settled = Completer<void>();
    _preferenceOperations.add(settled.future);
    try {
      return await action();
    } finally {
      _preferenceOperations.remove(settled.future);
      settled.complete();
    }
  }

  Future<void> _prepareForPersonalDataErase() async {
    await stopAndClear();
    // Drain writes already started by a settings sheet before its stores clear.
    while (_preferenceOperations.isNotEmpty) {
      await Future.wait(_preferenceOperations.toList());
    }
    await stopAndClear();
    emit(const QuranAudioState.initial());
  }

  QuranTranslationRepository? get translationRepository =>
      _translationRepository;

  void _onTranslationPreferenceChanged() {
    if (!_changingTranslationEdition && !isClosed) {
      unawaited(
        synchronizeTranslationSelection().catchError((Object error) {
          _translationResumeAfterUpdate = false;
          if (!isClosed) {
            emit(
              state.copyWith(
                errorMessage: 'Could not update translation playback.',
              ),
            );
          }
        }),
      );
    }
  }

  Future<void> synchronizeTranslationSelection() =>
      _trackPreferenceOperation(_synchronizeTranslationSelection);

  Future<void> _synchronizeTranslationSelection() async {
    final revision = ++_translationSelectionRevision;
    final playbackIntent = _playbackIntentRevision;
    _translationResumeAfterUpdate =
        _translationResumeAfterUpdate || _audioHandler.playing;
    if (state.queue.any((item) => item.isTranslationSegment) &&
        _audioHandler.playing) {
      await _audioHandler.pause();
    }
    final voices = await _selectedTranslationAudioReciters();
    if (isClosed || revision != _translationSelectionRevision) return;
    final voice = preferredTranslationReciter(voices);
    final enabled = _settingsStore.audioPlayTranslationEnabled && voice != null;
    final oldId = state.translationReciterId;
    final oldEnabled = state.playTranslationAudio;
    emit(
      state.copyWith(
        playTranslationAudio: enabled,
        translationReciterId: voice?.id,
        translationReciterName: voice?.name,
        clearTranslationReciter: voice == null,
      ),
    );
    if (voice == null) {
      await _settingsStore.setAudioPlayTranslationEnabled(false);
    }
    final staleQueue = state.queue.any(
      (item) =>
          item.isTranslationSegment && (!enabled || item.reciterId != voice.id),
    );
    if (revision == _translationSelectionRevision &&
        (oldId != voice?.id || oldEnabled != enabled || staleQueue)) {
      await _reloadCurrentScope(
        autoPlayOverride:
            _translationResumeAfterUpdate &&
            playbackIntent == _playbackIntentRevision,
      );
    } else if (_translationResumeAfterUpdate &&
        playbackIntent == _playbackIntentRevision &&
        !_audioHandler.playing &&
        state.hasItem) {
      await _audioHandler.play();
    }
    if (revision == _translationSelectionRevision) {
      _translationResumeAfterUpdate = false;
    }
  }

  Future<void> playAyah({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
  }) async {
    final intent = ++_playbackIntentRevision;
    _suppressSnapshots = false;
    final queue = await _buildQueueForAyahs([
      (ayah: ayah, surah: surah),
    ], reciter: reciter);
    if (!await _canStartQueue(queue, 0) || intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(queue);
  }

  Future<void> playSurah({
    required List<QuranAyah> ayahs,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
    String? startVerseKey,
  }) async {
    final intent = ++_playbackIntentRevision;
    _suppressSnapshots = false;
    if (ayahs.isEmpty) {
      return;
    }
    final queue = await _buildQueueForAyahs([
      for (final ayah in ayahs) (ayah: ayah, surah: surah),
    ], reciter: reciter);
    _activeSurah = surah;
    _activeReciter = reciter;
    final startIndex = _startIndex(queue, startVerseKey);
    if (!await _canStartQueue(queue, startIndex) ||
        intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(queue, startIndex: startIndex);
  }

  Future<void> playFromAyahToSurahEnd({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
  }) async {
    final intent = ++_playbackIntentRevision;
    _suppressSnapshots = false;
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
    if (!await _canStartQueue(queue, 0) || intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(queue);
  }

  Future<void> playPage({
    required List<QuranAyah> ayahs,
    required QuranAudioReciter reciter,
    String? startVerseKey,
  }) async {
    final intent = ++_playbackIntentRevision;
    _suppressSnapshots = false;
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
    if (!await _canStartQueue(queue, startIndex) ||
        intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(queue, startIndex: startIndex);
  }

  Future<void> playRange({
    required int startAyah,
    required int endAyah,
    String? startVerseKey,
    bool autoPlay = true,
  }) async {
    final intent = ++_playbackIntentRevision;
    _suppressSnapshots = false;
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
    if (!await _canStartQueue(queue, startIndex) ||
        intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(
      queue,
      startIndex: startIndex,
      autoPlay: autoPlay,
    );
    if (!autoPlay && !isClosed) {
      emit(state.copyWith(status: QuranAudioStatus.paused));
    }
  }

  Future<void> playCurrentAyahRange() async {
    final current = state.currentItem;
    if (current == null) {
      return;
    }
    await playRange(startAyah: current.ayahNumber, endAyah: current.ayahNumber);
  }

  Future<void> playCurrentPageRange() async {
    final intent = _playbackIntentRevision;
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
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
    final intent = ++_playbackIntentRevision;
    if (!state.hasItem) {
      return;
    }
    if (state.isPlaying) {
      await _audioHandler.pause();
      return;
    }
    if (state.queue.any((item) => item.isTranslationSegment) &&
        !await _translationQueueMatchesSelection(state.queue)) {
      await _reloadCurrentScope(autoPlayOverride: false);
      if (!await _translationQueueMatchesSelection(state.queue)) return;
    }
    if (_audioHandler.currentQueue.isEmpty && state.queue.isNotEmpty) {
      final startIndex = (state.currentIndex ?? 0)
          .clamp(0, state.queue.length - 1)
          .toInt();
      final restorePosition = state.position;
      emit(state.copyWith(status: QuranAudioStatus.loading, clearError: true));
      await _applyRepeatSettings();
      if (intent != _playbackIntentRevision || isClosed) return;
      await _audioHandler.loadAndPlay(state.queue, startIndex: startIndex);
      if (restorePosition > Duration.zero &&
          intent == _playbackIntentRevision) {
        await _audioHandler.seek(restorePosition);
      }
      return;
    }
    if (intent == _playbackIntentRevision && !isClosed) {
      await _audioHandler.play();
    }
  }

  Future<void> pause() async {
    _playbackIntentRevision++;
    if (state.hasItem) {
      await _audioHandler.pause();
    }
  }

  Future<void> resume() async {
    if (state.hasItem && !state.isPlaying) {
      await playOrPause();
    }
  }

  Future<void> togglePlayPause() => playOrPause();

  Future<void> replayQueue() async {
    final intent = ++_playbackIntentRevision;
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(state.queue);
  }

  Future<void> stopAndClear() async {
    _suppressSnapshots = true;
    _playbackIntentRevision++;
    _translationSelectionRevision++;
    _translationToggleRevision++;
    _wordTimingRequestId++;
    _translationResumeAfterUpdate = false;
    _settingsQueueRevision++;
    await _audioHandler.stop();
    await _snapshotWrite;
    await _settingsStore.clearAudioRestoreState();
    _resetRepeatProgress();
    _activeSurah = null;
    _activeReciter = null;
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

  Future<void> setSpeed(double speed) {
    final next = speed.clamp(0.75, 2.0).toDouble();
    emit(state.copyWith(speed: next));
    return _audioHandler.setSpeed(next);
  }

  Future<void> setRepeatMode(QuranAudioRepeatMode repeatMode) async {
    _resetRepeatProgress();
    emit(state.copyWith(repeatMode: repeatMode));
    await _applyRepeatSettings();
  }

  void setRepeatCount(int repeatCount) {
    _resetRepeatProgress();
    emit(state.copyWith(repeatCount: repeatCount.clamp(1, 10)));
    unawaited(_applyRepeatSettings());
  }

  Future<void> _applyRepeatSettings() async {
    final handler = _audioHandler;
    if (handler is QuranAudioFiniteRepeatPort) {
      await (handler as QuranAudioFiniteRepeatPort).setAyahRepeatCount(
        state.repeatCount,
      );
    }
    await handler.setQuranRepeatMode(state.repeatMode);
  }

  void setRepeatAfterAction(QuranAudioRepeatAfterAction action) {
    _resetRepeatProgress();
    emit(state.copyWith(repeatAfterAction: action));
  }

  Future<void> setRepeatRange({required int startAyah, required int endAyah}) =>
      playRange(
        startAyah: startAyah,
        endAyah: endAyah,
        autoPlay: _audioHandler.playing,
      );

  Future<void> changeReciter(String reciterId) =>
      _trackPreferenceOperation(() => _changeReciter(reciterId));

  Future<void> _changeReciter(String reciterId) async {
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
    await _reloadCurrentScope();
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

  Future<void> setPlayTranslationAudio(bool enabled) =>
      _trackPreferenceOperation(() => _setPlayTranslationAudio(enabled));

  Future<void> _setPlayTranslationAudio(bool enabled) async {
    final revision = ++_translationToggleRevision;
    if (!enabled) {
      emit(state.copyWith(playTranslationAudio: false, clearError: true));
      await _settingsStore.setAudioPlayTranslationEnabled(false);
      if (isClosed || revision != _translationToggleRevision) return;
      await _reloadCurrentScope();
      return;
    }

    final reciter = await _ensureTranslationReciter();
    if (isClosed || revision != _translationToggleRevision) return;
    if (reciter == null) {
      emit(
        state.copyWith(
          playTranslationAudio: false,
          errorMessage: 'No verified audio is available for this translation.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        playTranslationAudio: true,
        translationReciterId: reciter.id,
        translationReciterName: reciter.name,
        clearError: true,
      ),
    );
    await _settingsStore.setAudioPlayTranslationEnabled(true);
    await _settingsStore.setAudioTranslationReciterId(reciter.id);
    if (isClosed || revision != _translationToggleRevision) return;
    await _reloadCurrentScope();
  }

  Future<void> changeTranslationReciter(String reciterId) =>
      _trackPreferenceOperation(() => _changeTranslationReciter(reciterId));

  Future<void> _changeTranslationReciter(String reciterId) async {
    final reciter = await _translationReciterById(reciterId);
    final pair = quranTranslationPairForVoice(reciterId);
    final repository = _translationRepository;
    if (reciter == null || pair == null || repository == null) {
      throw StateError('This voice has no verified translation edition.');
    }
    if (!await repository.hasFullTranslation(pair.resource.id)) {
      throw StateError(
        'Download ${pair.resource.name} before selecting this voice.',
      );
    }
    final previous = await repository.selectedTranslation();
    final previousState = state;
    final previousEnabled = _settingsStore.audioPlayTranslationEnabled;
    final previousVoice = _settingsStore.audioTranslationReciterId;
    final wasPlaying = _audioHandler.playing;
    final playbackIntent = _playbackIntentRevision;
    _changingTranslationEdition = true;
    ++_translationSelectionRevision;
    try {
      if (state.playTranslationAudio && wasPlaying) await _audioHandler.pause();
      await _settingsStore.setAudioMeaningLanguageCode(reciter.languageCode);
      await _settingsStore.setAudioTranslationReciterId(
        reciter.id,
        languageCode: reciter.languageCode,
      );
      await repository.setSelectedTranslation(pair.resource.id);
      if ((await repository.selectedTranslation())?.id != pair.resource.id) {
        throw StateError('Could not select the matching translation.');
      }
      emit(
        state.copyWith(
          translationReciterId: reciter.id,
          translationReciterName: reciter.name,
          clearError: true,
        ),
      );
      if (state.playTranslationAudio) {
        await _reloadCurrentScope(
          autoPlayOverride:
              wasPlaying && playbackIntent == _playbackIntentRevision,
        );
      }
    } catch (_) {
      await repository.setSelectedTranslation(previous?.id);
      await _settingsStore.setAudioTranslationReciterId(
        previousVoice,
        languageCode: previous?.resolvedLanguageCode,
      );
      await _settingsStore.setAudioPlayTranslationEnabled(previousEnabled);
      if (!isClosed && playbackIntent == _playbackIntentRevision) {
        emit(previousState);
      }
      if (wasPlaying &&
          playbackIntent == _playbackIntentRevision &&
          state.hasItem) {
        await _audioHandler.play();
      }
      rethrow;
    } finally {
      _changingTranslationEdition = false;
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
    final previous = state.currentItem;
    if (previous?.playbackUri == queueItem.playbackUri &&
        previous?.verseKey == queueItem.verseKey &&
        previous?.segmentType == queueItem.segmentType &&
        previous?.isBismillah == queueItem.isBismillah &&
        previous?.surahArtworkUri != queueItem.surahArtworkUri) {
      emit(state.copyWith(currentItem: queueItem));
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
      // A range iteration spans the entire queue, not each individual ayah.
      if (state.repeatMode != QuranAudioRepeatMode.queue) {
        _currentRepeatIteration = 1;
      }
      _ayahRepeatArmed = true;
      _lastCompletedVerseKey = null;
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
    final intent = _playbackIntentRevision;
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
    if (!await _canStartQueue(queue, 0) || intent != _playbackIntentRevision) {
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
    await _applyRepeatSettings();
    if (intent != _playbackIntentRevision || isClosed) return;
    await _audioHandler.loadAndPlay(queue);
  }

  void _maybeRepeatActiveAyah(Duration position) {
    if (_audioHandler is QuranAudioFiniteRepeatPort) return;
    if (!state.isPlaying ||
        state.repeatMode != QuranAudioRepeatMode.ayah ||
        state.repeatCount <= 1 ||
        state.currentItem == null ||
        state.currentItem!.isBismillah) {
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
    final remainingMs = duration.inMilliseconds - position.inMilliseconds;
    if (remainingMs > 0) {
      return;
    }
    _ayahRepeatArmed = false;
    if (_currentRepeatIteration >= state.repeatCount) {
      return;
    }
    _currentRepeatIteration += 1;
    final intent = _playbackIntentRevision;
    unawaited(
      _audioHandler.seek(Duration.zero).then((_) async {
        if (!isClosed && intent == _playbackIntentRevision && state.hasItem) {
          await _audioHandler.play();
        }
      }),
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
    QuranAyah? bismillah;
    for (final context in contexts) {
      if (context.ayah.number == 1 &&
          context.ayah.surahNumber != 1 &&
          context.ayah.surahNumber != 9) {
        bismillah ??= (await _quranRepository.getAyahs(
          1,
        )).firstWhere((ayah) => ayah.number == 1);
        queue.add(
          QuranAudioQueueItem.fromAyah(
            ayah: context.ayah,
            surah: context.surah,
            reciter: reciter,
            bismillah: bismillah,
          ),
        );
        if (translationReciter != null) {
          queue.add(
            QuranAudioQueueItem.fromAyah(
              ayah: context.ayah,
              surah: context.surah,
              reciter: translationReciter,
              bismillah: bismillah,
              segmentType: QuranAudioSegmentType.translation,
            ),
          );
        }
      }
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

  QuranAudioReciter? preferredTranslationReciter(
    List<QuranAudioReciter> reciters,
  ) => preferredQuranTranslationVoice(
    reciters,
    preferredId: _settingsStore.translationVoiceForLanguage(
      reciters.firstOrNull?.languageCode ?? '',
    ),
    legacyId: _settingsStore.audioTranslationReciterId,
  );

  Future<QuranAudioReciter?> _ensureTranslationReciter() =>
      _trackPreferenceOperation(_resolveTranslationReciter);

  Future<QuranAudioReciter?> _resolveTranslationReciter() async {
    final selected = preferredTranslationReciter(
      await _selectedTranslationAudioReciters(),
    );
    if (isClosed) return null;
    if (selected == null) {
      emit(
        state.copyWith(
          clearTranslationReciter: true,
          playTranslationAudio: false,
        ),
      );
      await _settingsStore.setAudioPlayTranslationEnabled(false);
      return null;
    }
    await _settingsStore.setAudioTranslationReciterId(
      selected.id,
      languageCode: selected.languageCode,
    );
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
    final selectedTranslation = await _translationRepository
        ?.selectedTranslation();
    if (selectedTranslation == null ||
        !await _translationRepository!.hasFullTranslation(
          selectedTranslation.id,
        )) {
      return const [];
    }
    return quranCompatibleTranslationAudioReciters(
      reciters: reciters,
      selectedTranslation: selectedTranslation,
    );
  }

  Future<QuranAudioReciter?> _translationReciterById(String? reciterId) async {
    final reciters = await getTranslationAudioReciters();
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

  Future<void> _reloadCurrentScope({bool? autoPlayOverride}) async {
    final playbackIntent = _playbackIntentRevision;
    final reciter = _activeReciter;
    if (!state.hasItem || state.queue.isEmpty || reciter == null) {
      return;
    }
    final revision = ++_settingsQueueRevision;
    final originalQueue = state.queue;
    final surahs = <int, QuranSurah>{};
    final ayahsBySurah = <int, List<QuranAyah>>{};
    final contexts = <_AudioAyahContext>[];
    for (final item in originalQueue) {
      if (item.isTranslationSegment || item.isBismillah) continue;
      final surah = surahs[item.surahNumber] ??= await _quranRepository
          .getSurah(item.surahNumber);
      final ayahs = ayahsBySurah[item.surahNumber] ??= await _quranRepository
          .getAyahs(item.surahNumber);
      final ayah = _ayahForVerseKey(ayahs, item.verseKey);
      if (ayah != null) contexts.add((ayah: ayah, surah: surah));
    }
    if (contexts.isEmpty) return;
    final queue = await _buildQueueForAyahs(contexts, reciter: reciter);
    if (isClosed ||
        revision != _settingsQueueRevision ||
        !state.hasItem ||
        state.queue.length != originalQueue.length ||
        state.queue.indexed.any(
          (entry) =>
              entry.$2.playbackUri != originalQueue[entry.$1].playbackUri,
        )) {
      return;
    }
    final current = state.currentItem!;
    var index = queue.indexWhere(
      (item) =>
          item.verseKey == current.verseKey &&
          item.segmentType == current.segmentType &&
          item.isBismillah == current.isBismillah,
    );
    if (index < 0) index = _startIndex(queue, current.verseKey);
    final position =
        queue[index].reciterId == current.reciterId &&
            queue[index].segmentType == current.segmentType &&
            queue[index].isBismillah == current.isBismillah
        ? state.position
        : Duration.zero;
    if (!await _canStartQueue(queue, index) ||
        isClosed ||
        revision != _settingsQueueRevision) {
      return;
    }
    final autoPlay = playbackIntent == _playbackIntentRevision
        ? autoPlayOverride ?? _audioHandler.playing
        : _audioHandler.playing;
    _resetRepeatProgress();
    emit(
      state.copyWith(
        status: autoPlay ? QuranAudioStatus.loading : QuranAudioStatus.paused,
        queue: queue,
        currentItem: queue[index],
        currentIndex: index,
        position: position,
        clearDuration: true,
        clearActiveWord: true,
        clearError: true,
      ),
    );
    _persistAudioRestoreSnapshot(force: true);
    await _audioHandler.loadAndPlay(
      queue,
      startIndex: index,
      initialPosition: position,
      autoPlay: autoPlay,
    );
  }

  Future<List<QuranAudioQueueItem>> _resolveQueue(
    List<QuranAudioQueueItem> queue,
  ) {
    return _downloadRepository.resolveQueue(queue);
  }

  Future<void> _restoreAudioSnapshot() async {
    final revision = _playbackIntentRevision;
    final snapshot = _settingsStore.audioRestoreState;
    if (snapshot.isEmpty) {
      return;
    }

    final rawQueue = snapshot['queue'];
    if (rawQueue is! List) {
      await _settingsStore.clearAudioRestoreState();
      return;
    }

    final compatibleVoices = await _selectedTranslationAudioReciters();
    final allowedVoiceIds = compatibleVoices.map((voice) => voice.id).toSet();
    final originalQueue = rawQueue
        .map(QuranAudioQueueItem.fromCacheMap)
        .whereType<QuranAudioQueueItem>()
        .toList(growable: false);
    final restoredItem = originalQueue.isEmpty
        ? null
        : originalQueue[_clampedIndex(
            snapshot['currentIndex'],
            originalQueue.length,
          )];
    final cachedQueue = originalQueue
        .where(
          (item) =>
              !item.isTranslationSegment ||
              (_settingsStore.audioPlayTranslationEnabled &&
                  allowedVoiceIds.contains(item.reciterId)),
        )
        .toList(growable: false);
    if (cachedQueue.isEmpty) {
      await _settingsStore.clearAudioRestoreState();
      return;
    }

    final restoredQueue = await _resolveQueue(cachedQueue);
    if (isClosed ||
        revision != _playbackIntentRevision ||
        restoredQueue.isEmpty) {
      return;
    }

    var currentIndex = restoredQueue.indexWhere(
      (item) => restoredItem != null && _sameQueueItem(item, restoredItem),
    );
    if (currentIndex < 0) {
      currentIndex = _startIndex(restoredQueue, restoredItem?.verseKey);
    }
    final currentItem = restoredQueue[currentIndex];
    await _hydrateRestoredAudioContext(restoredQueue, currentItem);
    if (isClosed || revision != _playbackIntentRevision) {
      return;
    }

    final position =
        restoredItem != null && _sameQueueItem(currentItem, restoredItem)
        ? Duration(milliseconds: _intFromSnapshot(snapshot['positionMs']) ?? 0)
        : Duration.zero;
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
            _settingsStore.audioPlayTranslationEnabled &&
            compatibleVoices.isNotEmpty,
        translationReciterId: preferredTranslationReciter(compatibleVoices)?.id,
        translationReciterName: preferredTranslationReciter(
          compatibleVoices,
        )?.name,
        clearTranslationReciter: compatibleVoices.isEmpty,
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
    if (_suppressSnapshots ||
        isClosed ||
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
    final snapshot = _audioRestoreSnapshot();
    _snapshotWrite = _snapshotWrite
        .then((_) async {
          if (!_suppressSnapshots) {
            await _settingsStore.setAudioRestoreState(snapshot);
          }
        })
        .catchError((Object _) {});
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
          item.isBismillah == currentItem.isBismillah &&
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
    if (!await _translationQueueMatchesSelection(queue)) {
      emit(
        state.copyWith(
          errorMessage: 'Translation changed. Please try playback again.',
        ),
      );
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

  Future<bool> _translationQueueMatchesSelection(
    List<QuranAudioQueueItem> queue,
  ) async {
    final translated = queue.where((item) => item.isTranslationSegment);
    if (translated.isEmpty) return true;
    if (!state.playTranslationAudio) return false;
    final compatible = await _selectedTranslationAudioReciters();
    final ids = compatible.map((voice) => voice.id).toSet();
    return translated.every((item) => ids.contains(item.reciterId));
  }

  Future<void> _autoCacheIfNeeded(QuranAudioQueueItem item) async {
    if (!_settingsStore.audioAutoCachePlayedAyahs ||
        item.isDownloaded ||
        item.playbackUri != item.remoteAudioUrl) {
      return;
    }
    final id = QuranAudioDownloadItem.idFor(
      reciterId: item.reciterId,
      surahNumber: item.audioSurahNumber,
      ayahNumber: item.audioAyahNumber,
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
    _settingsStore.beforePersonalDataErase.remove(_prepareForPersonalDataErase);
    _translationChanges?.removeListener(_onTranslationPreferenceChanged);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _audioHandler.dispose();
    return super.close();
  }
}
