import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran/domain/repositories/quran_translation_repository.dart';
import 'package:quran/features/quran_audio/data/repositories/quran_audio_download_repository.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_download_service.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_playback_port.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_download_item.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_word_timing.dart';
import 'package:quran/features/quran_audio/domain/repositories/quran_word_timing_repository.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_queue_item.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/presentation/cubit/quran_audio_cubit.dart';

void main() {
  group('QuranAudioCubit', () {
    test('plays from selected ayah through the end of the surah', () async {
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_audio_cubit_test_'),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: SettingsStore.memory({
          'audio_auto_cache_played_ayahs': false,
        }),
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.playFromAyahToSurahEnd(
        ayah: _FakeQuranRepository.ayahs[1],
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );

      expect(playbackPort.loadedItems.map((item) => item.verseKey), [
        '1:2',
        '1:3',
      ]);
      expect(playbackPort.startIndex, 0);
      expect(cubit.state.playbackScope, QuranAudioPlaybackScope.surah);
      expect(cubit.state.scopeLabel, 'Al-Fatihah from 1:2');
      expect(cubit.state.rangeStartVerseKey, '1:2');
      expect(cubit.state.rangeEndVerseKey, '1:3');

      await cubit.close();
    });

    test(
      'interleaves Arabic and translation audio when enabled with selected language',
      () async {
        final playbackPort = _FakePlaybackPort();
        final quranRepository = _FakeQuranRepository();
        final downloadStore = QuranAudioDownloadStore.memory();
        final downloadRepository = QuranAudioDownloadRepository(
          quranRepository: quranRepository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_audio_translation_test_'),
        );
        final cubit = QuranAudioCubit(
          audioHandler: playbackPort,
          quranRepository: quranRepository,
          translationRepository: const _FakeTranslationRepository(
            selected: QuranTranslationResource(
              id: 20,
              languageName: 'English',
              name: 'English translation',
              authorName: 'Author',
              slug: 'english',
            ),
          ),
          downloadRepository: downloadRepository,
          downloadService: QuranAudioDownloadService(store: downloadStore),
          settingsStore: SettingsStore.memory({
            'audio_auto_cache_played_ayahs': false,
            'audio_play_translation_enabled': true,
            'audio_translation_reciter_id': 'translation:english',
          }),
          wordTimingRepository: const _EmptyWordTimingRepository(),
        );

        await cubit.playSurah(
          ayahs: _FakeQuranRepository.ayahs.take(2).toList(),
          surah: _FakeQuranRepository.surahs.first,
          reciter: _FakeQuranRepository.reciters.first,
        );

        expect(playbackPort.loadedItems.map((item) => item.verseKey), [
          '1:1',
          '1:1',
          '1:2',
          '1:2',
        ]);
        expect(playbackPort.loadedItems.map((item) => item.segmentType), [
          QuranAudioSegmentType.arabic,
          QuranAudioSegmentType.translation,
          QuranAudioSegmentType.arabic,
          QuranAudioSegmentType.translation,
        ]);
        expect(playbackPort.loadedItems[1].reciterId, 'translation:english');
        expect(
          playbackPort.loadedItems[1].timingProvider,
          QuranAudioTimingProvider.none,
        );
        expect(cubit.state.playTranslationAudio, true);
        expect(cubit.state.translationReciterId, 'translation:english');

        await cubit.close();
      },
    );

    test(
      'prefetches upcoming QuranEnc translation audio before it plays',
      () async {
        final playbackPort = _FakePlaybackPort();
        final quranRepository = _FakeQuranRepository();
        final downloadStore = QuranAudioDownloadStore.memory();
        final downloadRepository = QuranAudioDownloadRepository(
          quranRepository: quranRepository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_audio_quranenc_test_'),
        );
        final downloadService = _RecordingDownloadService(downloadStore);
        final cubit = QuranAudioCubit(
          audioHandler: playbackPort,
          quranRepository: quranRepository,
          translationRepository: const _FakeTranslationRepository(
            selected: QuranTranslationResource(
              id: 30,
              languageName: 'Portuguese',
              name: 'Portuguese translation',
              authorName: 'Author',
              slug: 'portuguese',
            ),
          ),
          downloadRepository: downloadRepository,
          downloadService: downloadService,
          settingsStore: SettingsStore.memory({
            'audio_auto_cache_played_ayahs': true,
            'audio_play_translation_enabled': true,
            'audio_translation_reciter_id': 'quranenc:portuguese_nasr',
          }),
          wordTimingRepository: const _EmptyWordTimingRepository(),
        );

        await cubit.playSurah(
          ayahs: _FakeQuranRepository.ayahs.take(2).toList(),
          surah: _FakeQuranRepository.surahs.first,
          reciter: _FakeQuranRepository.reciters.first,
        );
        await pumpEventQueue();

        expect(playbackPort.loadedItems.map((item) => item.segmentType), [
          QuranAudioSegmentType.arabic,
          QuranAudioSegmentType.translation,
          QuranAudioSegmentType.arabic,
          QuranAudioSegmentType.translation,
        ]);
        expect(
          playbackPort.loadedItems[1].remoteAudioUrl,
          'https://d.quranenc.com/data/audio/portuguese_nasr/001001.mp3',
        );
        expect(downloadService.enqueuedIds, contains('test_alafasy_001_001'));
        expect(
          downloadService.enqueuedIds,
          contains('quranenc_portuguese_nasr_001_001'),
        );

        await cubit.close();
      },
    );

    test(
      'does not play translation audio when no translation is selected',
      () async {
        final playbackPort = _FakePlaybackPort();
        final quranRepository = _FakeQuranRepository();
        final downloadStore = QuranAudioDownloadStore.memory();
        final downloadRepository = QuranAudioDownloadRepository(
          quranRepository: quranRepository,
          store: downloadStore,
          supportDirectoryProvider: () async => Directory.systemTemp.createTemp(
            'quran_audio_translation_missing_test_',
          ),
        );
        final cubit = QuranAudioCubit(
          audioHandler: playbackPort,
          quranRepository: quranRepository,
          translationRepository: const _FakeTranslationRepository(),
          downloadRepository: downloadRepository,
          downloadService: QuranAudioDownloadService(store: downloadStore),
          settingsStore: SettingsStore.memory({
            'audio_auto_cache_played_ayahs': false,
            'audio_play_translation_enabled': true,
            'audio_translation_reciter_id': 'translation:english',
          }),
          wordTimingRepository: const _EmptyWordTimingRepository(),
        );

        await cubit.playSurah(
          ayahs: _FakeQuranRepository.ayahs.take(2).toList(),
          surah: _FakeQuranRepository.surahs.first,
          reciter: _FakeQuranRepository.reciters.first,
        );

        expect(playbackPort.loadedItems.map((item) => item.segmentType), [
          QuranAudioSegmentType.arabic,
          QuranAudioSegmentType.arabic,
        ]);

        await cubit.close();
      },
    );

    test(
      'uses only selected translation language voice when enabled',
      () async {
        final playbackPort = _FakePlaybackPort();
        final quranRepository = _FakeQuranRepository();
        final downloadStore = QuranAudioDownloadStore.memory();
        final downloadRepository = QuranAudioDownloadRepository(
          quranRepository: quranRepository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_audio_language_test_'),
        );
        final cubit = QuranAudioCubit(
          audioHandler: playbackPort,
          quranRepository: quranRepository,
          translationRepository: const _FakeTranslationRepository(
            selected: QuranTranslationResource(
              id: 22,
              languageName: 'Urdu',
              name: 'Urdu translation',
              authorName: 'Author',
              slug: 'urdu',
            ),
          ),
          downloadRepository: downloadRepository,
          downloadService: QuranAudioDownloadService(store: downloadStore),
          settingsStore: SettingsStore.memory({
            'audio_auto_cache_played_ayahs': false,
            'audio_play_translation_enabled': true,
            'audio_translation_reciter_id': 'translation:english',
          }),
          wordTimingRepository: const _EmptyWordTimingRepository(),
        );

        await cubit.playSurah(
          ayahs: _FakeQuranRepository.ayahs.take(1).toList(),
          surah: _FakeQuranRepository.surahs.first,
          reciter: _FakeQuranRepository.reciters.first,
        );

        expect(playbackPort.loadedItems.map((item) => item.reciterId), [
          'test:alafasy',
          'translation:urdu',
        ]);
        expect(cubit.state.translationReciterId, 'translation:urdu');

        await cubit.close();
      },
    );

    test(
      'updates active word only when playback crosses word timing',
      () async {
        final playbackPort = _FakePlaybackPort();
        final quranRepository = _FakeQuranRepository();
        final downloadStore = QuranAudioDownloadStore.memory();
        final downloadRepository = QuranAudioDownloadRepository(
          quranRepository: quranRepository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_audio_word_test_'),
        );
        final cubit = QuranAudioCubit(
          audioHandler: playbackPort,
          quranRepository: quranRepository,
          downloadRepository: downloadRepository,
          downloadService: QuranAudioDownloadService(store: downloadStore),
          settingsStore: SettingsStore.memory({
            'audio_auto_cache_played_ayahs': false,
          }),
          wordTimingRepository: const _FakeWordTimingRepository(),
        );

        await cubit.playAyah(
          ayah: _FakeQuranRepository.ayahs.first,
          surah: _FakeQuranRepository.surahs.first,
          reciter: _FakeQuranRepository.reciters.first,
        );
        await pumpEventQueue();

        playbackPort.emitPosition(const Duration(milliseconds: 500));
        await pumpEventQueue();
        expect(cubit.state.activeWordVerseKey, '1:1');
        expect(cubit.state.activeWordIndex, 1);

        playbackPort.emitPosition(const Duration(milliseconds: 1250));
        await pumpEventQueue();
        expect(cubit.state.activeWordVerseKey, '1:1');
        expect(cubit.state.activeWordIndex, 2);

        playbackPort.emitPosition(const Duration(milliseconds: 2600));
        await pumpEventQueue();
        expect(cubit.state.activeWordIndex, isNull);

        await cubit.stopAndClear();
        expect(cubit.state.activeWordVerseKey, isNull);
        expect(cubit.state.activeWordIndex, isNull);

        await cubit.close();
      },
    );

    test('repeats the active ayah for the selected count', () async {
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_audio_repeat_ayah_test_'),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: SettingsStore.memory({
          'audio_auto_cache_played_ayahs': false,
        }),
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.setRepeatMode(QuranAudioRepeatMode.ayah);
      cubit.setRepeatCount(2);
      await cubit.playAyah(
        ayah: _FakeQuranRepository.ayahs.first,
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );

      playbackPort.emitDuration(const Duration(seconds: 2));
      playbackPort.emitPosition(const Duration(milliseconds: 1950));
      await pumpEventQueue();

      expect(playbackPort.seekedPositions, [Duration.zero]);
      expect(playbackPort.playCalls, 1);

      playbackPort.emitPosition(const Duration(milliseconds: 1950));
      await pumpEventQueue();

      expect(playbackPort.seekedPositions, [Duration.zero]);

      await cubit.close();
    });

    test('repeats the range for the selected count then stops', () async {
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_audio_repeat_queue_test_'),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: SettingsStore.memory({
          'audio_auto_cache_played_ayahs': false,
        }),
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.setRepeatMode(QuranAudioRepeatMode.queue);
      cubit.setRepeatCount(2);
      await cubit.playFromAyahToSurahEnd(
        ayah: _FakeQuranRepository.ayahs.first,
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );

      playbackPort.emitPlayerCompleted();
      await pumpEventQueue();

      expect(playbackPort.loadCalls, 2);
      expect(cubit.state.status, isNot(QuranAudioStatus.completed));

      playbackPort.emitPlayerCompleted();
      await pumpEventQueue();

      expect(playbackPort.loadCalls, 2);
      expect(playbackPort.stopCalls, 1);
      expect(cubit.state.status, QuranAudioStatus.idle);

      await cubit.close();
    });

    test('continues after range repeat when selected', () async {
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async => Directory.systemTemp.createTemp(
          'quran_audio_repeat_continue_test_',
        ),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: SettingsStore.memory({
          'audio_auto_cache_played_ayahs': false,
        }),
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.playFromAyahToSurahEnd(
        ayah: _FakeQuranRepository.ayahs.first,
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );
      await cubit.playRange(startAyah: 1, endAyah: 2);
      await cubit.setRepeatMode(QuranAudioRepeatMode.queue);
      cubit.setRepeatCount(2);
      cubit.setRepeatAfterAction(QuranAudioRepeatAfterAction.continuePlayback);

      playbackPort.emitPlayerCompleted();
      await pumpEventQueue();
      playbackPort.emitPlayerCompleted();
      await pumpEventQueue();

      expect(playbackPort.stopCalls, 0);
      expect(playbackPort.loadCalls, 4);
      expect(playbackPort.loadedItems.map((item) => item.verseKey), ['1:3']);
      expect(cubit.state.status, QuranAudioStatus.loading);

      await cubit.close();
    });

    test('restores saved audio as paused after app restart', () async {
      final settingsStore = SettingsStore.memory({
        'audio_auto_cache_played_ayahs': false,
      });
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_audio_restore_test_'),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.playAyah(
        ayah: _FakeQuranRepository.ayahs.first,
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );
      playbackPort.emitPosition(const Duration(seconds: 12));
      await pumpEventQueue();

      expect(settingsStore.audioRestoreState, isNotEmpty);

      await cubit.close();

      final restoredPlaybackPort = _FakePlaybackPort();
      final restoredCubit = QuranAudioCubit(
        audioHandler: restoredPlaybackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );
      await pumpEventQueue();

      expect(restoredCubit.state.status, QuranAudioStatus.paused);
      expect(restoredCubit.state.currentItem?.verseKey, '1:1');
      expect(restoredCubit.state.position, const Duration(seconds: 12));
      expect(restoredPlaybackPort.loadCalls, 0);

      await restoredCubit.togglePlayPause();

      expect(restoredPlaybackPort.loadCalls, 1);
      expect(restoredPlaybackPort.loadedItems.first.verseKey, '1:1');
      expect(restoredPlaybackPort.seekedPositions, [
        const Duration(seconds: 12),
      ]);

      await restoredCubit.close();
    });

    test('close button clears saved audio restore state', () async {
      final settingsStore = SettingsStore.memory({
        'audio_auto_cache_played_ayahs': false,
      });
      final playbackPort = _FakePlaybackPort();
      final quranRepository = _FakeQuranRepository();
      final downloadStore = QuranAudioDownloadStore.memory();
      final downloadRepository = QuranAudioDownloadRepository(
        quranRepository: quranRepository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_audio_clear_restore_test_'),
      );
      final cubit = QuranAudioCubit(
        audioHandler: playbackPort,
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );

      await cubit.playAyah(
        ayah: _FakeQuranRepository.ayahs.first,
        surah: _FakeQuranRepository.surahs.first,
        reciter: _FakeQuranRepository.reciters.first,
      );
      await pumpEventQueue();

      expect(settingsStore.audioRestoreState, isNotEmpty);

      await cubit.stopAndClear();

      expect(settingsStore.audioRestoreState, isEmpty);

      final restoredCubit = QuranAudioCubit(
        audioHandler: _FakePlaybackPort(),
        quranRepository: quranRepository,
        downloadRepository: downloadRepository,
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );
      await pumpEventQueue();

      expect(restoredCubit.state.hasItem, false);

      await restoredCubit.close();
      await cubit.close();
    });
  });
}

class _FakePlaybackPort implements QuranAudioPlaybackPort {
  final _mediaItemController = StreamController<MediaItem?>.broadcast();
  final _queueController = StreamController<List<MediaItem>>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _currentIndexController = StreamController<int?>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();

  List<QuranAudioQueueItem> loadedItems = const [];
  int startIndex = 0;
  int loadCalls = 0;
  int playCalls = 0;
  int stopCalls = 0;
  final seekedPositions = <Duration>[];

  @override
  Stream<PlaybackState> get playbackState => const Stream.empty();

  @override
  Stream<MediaItem?> get mediaItem => _mediaItemController.stream;

  @override
  Stream<List<MediaItem>> get queue => _queueController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  @override
  Stream<double> get speedStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  int? get currentIndex => startIndex;

  @override
  bool get playing => false;

  @override
  List<QuranAudioQueueItem> get currentQueue => loadedItems;

  @override
  Future<void> loadAndPlay(
    List<QuranAudioQueueItem> items, {
    int startIndex = 0,
  }) async {
    loadCalls += 1;
    loadedItems = items;
    this.startIndex = startIndex;
    final mediaItems = items.map((item) => item.toMediaItem()).toList();
    _queueController.add(mediaItems);
    _mediaItemController.add(mediaItems[startIndex]);
    _currentIndexController.add(startIndex);
  }

  @override
  Future<void> dispose() async {
    await _mediaItemController.close();
    await _queueController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentIndexController.close();
    await _playerStateController.close();
  }

  void emitPosition(Duration position) {
    _positionController.add(position);
  }

  void emitDuration(Duration duration) {
    _durationController.add(duration);
  }

  void emitPlayerCompleted() {
    _playerStateController.add(PlayerState(false, ProcessingState.completed));
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {
    playCalls += 1;
  }

  @override
  Future<void> seek(Duration position) async {
    seekedPositions.add(position);
  }

  @override
  Future<void> setQuranRepeatMode(QuranAudioRepeatMode mode) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }
}

class _RecordingDownloadService extends QuranAudioDownloadService {
  _RecordingDownloadService(this.store) : super(store: store);

  final QuranAudioDownloadStore store;
  final enqueuedIds = <String>[];

  @override
  Future<void> enqueueItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {
    for (final item in items) {
      enqueuedIds.add(item.id);
      await store.saveItem(
        item.copyWith(
          status: QuranAudioDownloadStatus.queued,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }
}

class _FakeQuranRepository implements QuranRepository {
  static const reciters = [
    QuranAudioReciter(
      id: 'test:alafasy',
      name: 'Test Alafasy',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Alafasy_128kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 7,
    ),
    QuranAudioReciter(
      id: 'translation:english',
      name: 'English Voice',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'en.walk',
      languageCode: 'en',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'translation:urdu',
      name: 'Urdu Voice',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ur.khan',
      languageCode: 'ur',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:portuguese_nasr',
      name: 'Portuguese Translation - Helmi Nasr',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'portuguese_nasr',
      languageCode: 'pt',
      isTranslation: true,
    ),
  ];

  static const surahs = [
    QuranSurah(
      number: 1,
      englishName: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      ayahCount: 3,
      revelationType: 'Meccan',
    ),
  ];

  static const ayahs = [
    QuranAyah(
      surahNumber: 1,
      number: 1,
      text: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 1,
      number: 2,
      text: 'الحمد لله رب العالمين',
      translation: 'All praise is for Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 1,
      number: 3,
      text: 'الرحمن الرحيم',
      translation: 'The Most Merciful.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
  ];

  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async => reciters;

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async => ayahs;

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async => ayahs;

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async => 1;

  @override
  Future<QuranSurah> getSurah(int surahNumber) async => surahs.first;

  @override
  Future<List<QuranSurah>> getSurahs() async => surahs;

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async =>
      QuranAyahTextLayout.separated;

  @override
  Future<String?> getSelectedAudioReciterId() async => reciters.first.id;

  @override
  Future<List<QuranBookmark>> getBookmarks() async => const [];

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async => false;

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {}

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) async {}

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) async {}

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async =>
      const [];

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async => true;
}

class _EmptyWordTimingRepository implements QuranWordTimingRepository {
  const _EmptyWordTimingRepository();

  @override
  Future<QuranWordTimingResult> timingsFor({
    required QuranAudioReciter reciter,
    required QuranAudioQueueItem item,
  }) async {
    return QuranWordTimingResult.empty(
      reciterId: reciter.id,
      verseKey: item.verseKey,
    );
  }
}

class _FakeTranslationRepository implements QuranTranslationRepository {
  const _FakeTranslationRepository({this.selected});

  final QuranTranslationResource? selected;

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async =>
      const [];

  @override
  Future<QuranTranslationResource?> selectedTranslation() async => selected;

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {}

  @override
  Future<bool> hasFullTranslation(int resourceId) async => true;

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {}

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async => null;

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async => const {};
}

class _FakeWordTimingRepository implements QuranWordTimingRepository {
  const _FakeWordTimingRepository();

  @override
  Future<QuranWordTimingResult> timingsFor({
    required QuranAudioReciter reciter,
    required QuranAudioQueueItem item,
  }) async {
    return QuranWordTimingResult(
      reciterId: reciter.id,
      verseKey: item.verseKey,
      source: QuranWordTimingSource.quranFoundation,
      isExact: true,
      segments: [
        QuranWordTimingSegment(
          verseKey: item.verseKey,
          wordIndex: 1,
          startMs: 0,
          endMs: 1000,
        ),
        QuranWordTimingSegment(
          verseKey: item.verseKey,
          wordIndex: 2,
          startMs: 1000,
          endMs: 2000,
        ),
      ],
    );
  }
}
