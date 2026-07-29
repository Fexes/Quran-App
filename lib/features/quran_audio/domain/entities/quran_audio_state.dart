import 'package:equatable/equatable.dart';

import 'quran_audio_queue_item.dart';

enum QuranAudioStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  failure,
}

enum QuranAudioPlaybackMode { singleAyah, surah }

enum QuranAudioRepeatMode { off, ayah, queue }

enum QuranAudioRepeatAfterAction { stop, continuePlayback }

enum QuranAudioPlaybackScope { ayah, surah, page, range }

enum QuranAudioWordTimingStatus { unavailable, loading, ready }

class QuranAudioState extends Equatable {
  const QuranAudioState({
    required this.status,
    required this.queue,
    required this.position,
    required this.bufferedPosition,
    required this.speed,
    required this.repeatMode,
    required this.repeatCount,
    required this.repeatAfterAction,
    required this.playTranslationAudio,
    required this.playbackScope,
    required this.scopeLabel,
    required this.wordTimingStatus,
    this.rangeStartAyah,
    this.rangeEndAyah,
    this.rangeStartVerseKey,
    this.rangeEndVerseKey,
    this.activeWordVerseKey,
    this.activeWordIndex,
    this.translationReciterId,
    this.translationReciterName,
    this.currentItem,
    this.duration,
    this.currentIndex,
    this.errorMessage,
  });

  const QuranAudioState.initial()
    : status = QuranAudioStatus.idle,
      queue = const [],
      currentItem = null,
      currentIndex = null,
      position = Duration.zero,
      bufferedPosition = Duration.zero,
      duration = null,
      speed = 1,
      repeatMode = QuranAudioRepeatMode.off,
      repeatCount = 1,
      repeatAfterAction = QuranAudioRepeatAfterAction.stop,
      playTranslationAudio = false,
      playbackScope = QuranAudioPlaybackScope.ayah,
      scopeLabel = '',
      wordTimingStatus = QuranAudioWordTimingStatus.unavailable,
      rangeStartAyah = null,
      rangeEndAyah = null,
      rangeStartVerseKey = null,
      rangeEndVerseKey = null,
      activeWordVerseKey = null,
      activeWordIndex = null,
      translationReciterId = null,
      translationReciterName = null,
      errorMessage = null;

  final QuranAudioStatus status;
  final List<QuranAudioQueueItem> queue;
  final QuranAudioQueueItem? currentItem;
  final int? currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final double speed;
  final QuranAudioRepeatMode repeatMode;
  final int repeatCount;
  final QuranAudioRepeatAfterAction repeatAfterAction;
  final bool playTranslationAudio;
  final QuranAudioPlaybackScope playbackScope;
  final String scopeLabel;
  final QuranAudioWordTimingStatus wordTimingStatus;
  final int? rangeStartAyah;
  final int? rangeEndAyah;
  final String? rangeStartVerseKey;
  final String? rangeEndVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? translationReciterId;
  final String? translationReciterName;
  final String? errorMessage;

  bool get hasItem => currentItem != null;
  bool get isPlaying => status == QuranAudioStatus.playing;
  bool get isLoading =>
      status == QuranAudioStatus.loading ||
      status == QuranAudioStatus.buffering;
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;
  bool get hasNext => currentIndex != null && currentIndex! < queue.length - 1;
  bool get canPause => hasItem && (isPlaying || isLoading);
  bool get canStop => hasItem || status != QuranAudioStatus.idle;
  bool get canSeek => hasItem && duration != null;

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    List<QuranAudioQueueItem>? queue,
    QuranAudioQueueItem? currentItem,
    int? currentIndex,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    double? speed,
    QuranAudioRepeatMode? repeatMode,
    int? repeatCount,
    QuranAudioRepeatAfterAction? repeatAfterAction,
    bool? playTranslationAudio,
    QuranAudioPlaybackScope? playbackScope,
    String? scopeLabel,
    QuranAudioWordTimingStatus? wordTimingStatus,
    int? rangeStartAyah,
    int? rangeEndAyah,
    String? rangeStartVerseKey,
    String? rangeEndVerseKey,
    String? activeWordVerseKey,
    int? activeWordIndex,
    String? translationReciterId,
    String? translationReciterName,
    String? errorMessage,
    bool clearItem = false,
    bool clearDuration = false,
    bool clearError = false,
    bool clearRange = false,
    bool clearActiveWord = false,
    bool clearTranslationReciter = false,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      currentItem: clearItem ? null : currentItem ?? this.currentItem,
      currentIndex: clearItem ? null : currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: clearDuration ? null : duration ?? this.duration,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatAfterAction: repeatAfterAction ?? this.repeatAfterAction,
      playTranslationAudio: playTranslationAudio ?? this.playTranslationAudio,
      playbackScope: playbackScope ?? this.playbackScope,
      scopeLabel: scopeLabel ?? this.scopeLabel,
      wordTimingStatus: wordTimingStatus ?? this.wordTimingStatus,
      rangeStartAyah: clearRange ? null : rangeStartAyah ?? this.rangeStartAyah,
      rangeEndAyah: clearRange ? null : rangeEndAyah ?? this.rangeEndAyah,
      rangeStartVerseKey: clearRange
          ? null
          : rangeStartVerseKey ?? this.rangeStartVerseKey,
      rangeEndVerseKey: clearRange
          ? null
          : rangeEndVerseKey ?? this.rangeEndVerseKey,
      activeWordVerseKey: clearActiveWord
          ? null
          : activeWordVerseKey ?? this.activeWordVerseKey,
      activeWordIndex: clearActiveWord
          ? null
          : activeWordIndex ?? this.activeWordIndex,
      translationReciterId: clearTranslationReciter
          ? null
          : translationReciterId ?? this.translationReciterId,
      translationReciterName: clearTranslationReciter
          ? null
          : translationReciterName ?? this.translationReciterName,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    queue,
    currentItem,
    currentIndex,
    position,
    bufferedPosition,
    duration,
    speed,
    repeatMode,
    repeatCount,
    repeatAfterAction,
    playTranslationAudio,
    playbackScope,
    scopeLabel,
    wordTimingStatus,
    rangeStartAyah,
    rangeEndAyah,
    rangeStartVerseKey,
    rangeEndVerseKey,
    activeWordVerseKey,
    activeWordIndex,
    translationReciterId,
    translationReciterName,
    errorMessage,
  ];
}
