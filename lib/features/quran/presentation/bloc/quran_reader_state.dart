import 'package:equatable/equatable.dart';

import '../../../../core/content/content_source.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_reading_mode.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_word.dart';

enum QuranReaderStatus { initial, loading, success, failure }

class QuranReaderState extends Equatable {
  const QuranReaderState({
    required this.status,
    required this.ayahs,
    required this.showTranslation,
    required this.bookmarkedVerseKeys,
    required this.contentSources,
    required this.audioReciters,
    required this.ayahTextLayout,
    required this.pageWordsByPage,
    required this.pageWordDataAvailable,
    required this.followAudio,
    required this.interlinearCacheComplete,
    this.interlinearLanguageCode,
    required this.translationsByVerse,
    this.selectedTranslations = const [],
    this.translationsByResource = const {},
    this.selectedAudioReciter,
    this.selectedTranslation,
    this.currentVerseKey,
    this.selectedVerseKey,
    this.activeAudioVerseKey,
    this.surah,
    this.errorMessage,
  });

  const QuranReaderState.initial()
    : status = QuranReaderStatus.initial,
      ayahs = const [],
      showTranslation = false,
      bookmarkedVerseKeys = const {},
      contentSources = const [],
      audioReciters = const [],
      ayahTextLayout = QuranAyahTextLayout.separated,
      pageWordsByPage = const {},
      pageWordDataAvailable = const {},
      followAudio = false,
      interlinearCacheComplete = false,
      interlinearLanguageCode = null,
      translationsByVerse = const {},
      selectedTranslations = const [],
      translationsByResource = const {},
      selectedAudioReciter = null,
      selectedTranslation = null,
      currentVerseKey = null,
      selectedVerseKey = null,
      activeAudioVerseKey = null,
      surah = null,
      errorMessage = null;

  final QuranReaderStatus status;
  final QuranSurah? surah;
  final List<QuranAyah> ayahs;
  final bool showTranslation;
  final Set<String> bookmarkedVerseKeys;
  final List<ContentSource> contentSources;
  final List<QuranAudioReciter> audioReciters;
  final QuranAyahTextLayout ayahTextLayout;
  final Map<int, List<QuranWord>> pageWordsByPage;
  final Set<int> pageWordDataAvailable;
  final bool followAudio;
  final bool interlinearCacheComplete;
  final String? interlinearLanguageCode;
  final Map<String, String> translationsByVerse;
  final List<QuranTranslationResource> selectedTranslations;
  final Map<int, Map<String, String>> translationsByResource;
  final QuranAudioReciter? selectedAudioReciter;
  final QuranTranslationResource? selectedTranslation;
  final String? currentVerseKey;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? errorMessage;

  QuranAyah? get selectedAyah {
    final verseKey = selectedVerseKey;
    if (verseKey == null) {
      return null;
    }
    for (final ayah in ayahs) {
      if (ayah.verseKey == verseKey) {
        return ayah;
      }
    }
    return null;
  }

  QuranReaderState copyWith({
    QuranReaderStatus? status,
    QuranSurah? surah,
    List<QuranAyah>? ayahs,
    bool? showTranslation,
    Set<String>? bookmarkedVerseKeys,
    List<ContentSource>? contentSources,
    List<QuranAudioReciter>? audioReciters,
    QuranAyahTextLayout? ayahTextLayout,
    Map<int, List<QuranWord>>? pageWordsByPage,
    Set<int>? pageWordDataAvailable,
    bool? followAudio,
    bool? interlinearCacheComplete,
    String? interlinearLanguageCode,
    bool clearInterlinearLanguageCode = false,
    Map<String, String>? translationsByVerse,
    List<QuranTranslationResource>? selectedTranslations,
    Map<int, Map<String, String>>? translationsByResource,
    QuranAudioReciter? selectedAudioReciter,
    QuranTranslationResource? selectedTranslation,
    bool clearSelectedTranslation = false,
    String? currentVerseKey,
    String? selectedVerseKey,
    bool clearSelectedVerseKey = false,
    String? activeAudioVerseKey,
    String? errorMessage,
  }) {
    return QuranReaderState(
      status: status ?? this.status,
      surah: surah ?? this.surah,
      ayahs: ayahs ?? this.ayahs,
      showTranslation: showTranslation ?? this.showTranslation,
      bookmarkedVerseKeys: bookmarkedVerseKeys ?? this.bookmarkedVerseKeys,
      contentSources: contentSources ?? this.contentSources,
      audioReciters: audioReciters ?? this.audioReciters,
      ayahTextLayout: ayahTextLayout ?? this.ayahTextLayout,
      pageWordsByPage: pageWordsByPage ?? this.pageWordsByPage,
      pageWordDataAvailable:
          pageWordDataAvailable ?? this.pageWordDataAvailable,
      followAudio: followAudio ?? this.followAudio,
      interlinearCacheComplete:
          interlinearCacheComplete ?? this.interlinearCacheComplete,
      interlinearLanguageCode: clearInterlinearLanguageCode
          ? null
          : interlinearLanguageCode ?? this.interlinearLanguageCode,
      translationsByVerse: translationsByVerse ?? this.translationsByVerse,
      selectedTranslations: selectedTranslations ?? this.selectedTranslations,
      translationsByResource:
          translationsByResource ?? this.translationsByResource,
      selectedAudioReciter: selectedAudioReciter ?? this.selectedAudioReciter,
      selectedTranslation: clearSelectedTranslation
          ? null
          : selectedTranslation ?? this.selectedTranslation,
      currentVerseKey: currentVerseKey ?? this.currentVerseKey,
      selectedVerseKey: clearSelectedVerseKey
          ? null
          : selectedVerseKey ?? this.selectedVerseKey,
      activeAudioVerseKey: activeAudioVerseKey ?? this.activeAudioVerseKey,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surah,
    ayahs,
    showTranslation,
    bookmarkedVerseKeys,
    contentSources,
    audioReciters,
    ayahTextLayout,
    pageWordsByPage,
    pageWordDataAvailable,
    followAudio,
    interlinearCacheComplete,
    interlinearLanguageCode,
    translationsByVerse,
    selectedTranslations,
    translationsByResource,
    selectedAudioReciter,
    selectedTranslation,
    currentVerseKey,
    selectedVerseKey,
    activeAudioVerseKey,
    errorMessage,
  ];
}
