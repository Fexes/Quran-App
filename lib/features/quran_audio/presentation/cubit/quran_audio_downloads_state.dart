import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../domain/entities/quran_audio_download_item.dart';

enum QuranAudioDownloadsStatus { initial, loading, success, failure }

enum QuranAudioDownloadsFilter { surahs, active, downloaded }

enum QuranAudioDownloadAudioType { arabic, translation }

class QuranAudioDownloadsState extends Equatable {
  const QuranAudioDownloadsState({
    required this.status,
    required this.audioType,
    required this.reciters,
    required this.surahGroups,
    required this.activeGroups,
    required this.downloadedGroups,
    required this.filter,
    required this.storageUsedBytes,
    required this.wifiOnlyLargeDownloads,
    this.selectedReciter,
    this.selectedArabicReciter,
    this.selectedTranslationReciter,
    this.selectedTranslation,
    this.errorMessage,
  });

  const QuranAudioDownloadsState.initial({
    this.audioType = QuranAudioDownloadAudioType.arabic,
  }) : status = QuranAudioDownloadsStatus.initial,
       reciters = const [],
       selectedReciter = null,
       selectedArabicReciter = null,
       selectedTranslationReciter = null,
       selectedTranslation = null,
       surahGroups = const [],
       activeGroups = const [],
       downloadedGroups = const [],
       filter = QuranAudioDownloadsFilter.surahs,
       storageUsedBytes = 0,
       wifiOnlyLargeDownloads = true,
       errorMessage = null;

  final QuranAudioDownloadsStatus status;
  final QuranAudioDownloadAudioType audioType;
  final List<QuranAudioReciter> reciters;
  final QuranAudioReciter? selectedReciter;
  final QuranAudioReciter? selectedArabicReciter;
  final QuranAudioReciter? selectedTranslationReciter;
  final QuranTranslationResource? selectedTranslation;
  final List<QuranAudioDownloadGroup> surahGroups;
  final List<QuranAudioDownloadGroup> activeGroups;
  final List<QuranAudioDownloadGroup> downloadedGroups;
  final QuranAudioDownloadsFilter filter;
  final int storageUsedBytes;
  final bool wifiOnlyLargeDownloads;
  final String? errorMessage;

  int get activeDownloadCount =>
      activeGroups.fold(0, (sum, group) => sum + group.items.length);

  String get audioTypeLabel {
    return audioType == QuranAudioDownloadAudioType.translation
        ? 'Translation'
        : 'Arabic';
  }

  QuranAudioDownloadsState copyWith({
    QuranAudioDownloadsStatus? status,
    QuranAudioDownloadAudioType? audioType,
    List<QuranAudioReciter>? reciters,
    QuranAudioReciter? selectedReciter,
    QuranAudioReciter? selectedArabicReciter,
    QuranAudioReciter? selectedTranslationReciter,
    QuranTranslationResource? selectedTranslation,
    List<QuranAudioDownloadGroup>? surahGroups,
    List<QuranAudioDownloadGroup>? activeGroups,
    List<QuranAudioDownloadGroup>? downloadedGroups,
    QuranAudioDownloadsFilter? filter,
    int? storageUsedBytes,
    bool? wifiOnlyLargeDownloads,
    String? errorMessage,
    bool clearError = false,
    bool clearSelectedReciter = false,
    bool clearSelectedArabicReciter = false,
    bool clearSelectedTranslationReciter = false,
    bool clearSelectedTranslation = false,
  }) {
    return QuranAudioDownloadsState(
      status: status ?? this.status,
      audioType: audioType ?? this.audioType,
      reciters: reciters ?? this.reciters,
      selectedReciter: clearSelectedReciter
          ? null
          : selectedReciter ?? this.selectedReciter,
      selectedArabicReciter: clearSelectedArabicReciter
          ? null
          : selectedArabicReciter ?? this.selectedArabicReciter,
      selectedTranslationReciter: clearSelectedTranslationReciter
          ? null
          : selectedTranslationReciter ?? this.selectedTranslationReciter,
      selectedTranslation: clearSelectedTranslation
          ? null
          : selectedTranslation ?? this.selectedTranslation,
      surahGroups: surahGroups ?? this.surahGroups,
      activeGroups: activeGroups ?? this.activeGroups,
      downloadedGroups: downloadedGroups ?? this.downloadedGroups,
      filter: filter ?? this.filter,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      wifiOnlyLargeDownloads:
          wifiOnlyLargeDownloads ?? this.wifiOnlyLargeDownloads,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    audioType,
    reciters,
    selectedReciter,
    selectedArabicReciter,
    selectedTranslationReciter,
    selectedTranslation,
    surahGroups,
    activeGroups,
    downloadedGroups,
    filter,
    storageUsedBytes,
    wifiOnlyLargeDownloads,
    errorMessage,
  ];
}
