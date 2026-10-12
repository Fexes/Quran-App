import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/entities/surah_image_catalog.dart';

enum QuranAudioSegmentType { arabic, translation }

class QuranAudioQueueItem extends Equatable {
  const QuranAudioQueueItem({
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseKey,
    required this.page,
    required this.surahName,
    required this.arabicText,
    required this.translation,
    required this.reciterId,
    required this.reciterName,
    required this.remoteAudioUrl,
    required this.playbackUri,
    this.segmentType = QuranAudioSegmentType.arabic,
    this.isBismillah = false,
    this.reciterImageUrl,
    this.surahImageAssetPath,
    this.surahArtworkUri,
    this.timingProvider = QuranAudioTimingProvider.none,
    this.timingRecitationId,
    this.timingChapterReciterId,
    this.localUri,
    this.isDownloaded = false,
  });

  factory QuranAudioQueueItem.fromAyah({
    required QuranAyah ayah,
    required QuranSurah surah,
    required QuranAudioReciter reciter,
    QuranAudioSegmentType segmentType = QuranAudioSegmentType.arabic,
    QuranAyah? bismillah,
  }) {
    assert(bismillah == null || bismillah.verseKey == '1:1');
    final audioAyah = bismillah ?? ayah;
    final effectiveSegmentType = reciter.isTranslation
        ? QuranAudioSegmentType.translation
        : segmentType;
    final hasWordTiming =
        effectiveSegmentType == QuranAudioSegmentType.arabic &&
        bismillah == null;
    return QuranAudioQueueItem(
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.number,
      verseKey: ayah.verseKey,
      page: ayah.page,
      surahName: surah.englishName,
      arabicText: audioAyah.text,
      translation: audioAyah.translation,
      reciterId: reciter.id,
      reciterName: reciter.name,
      segmentType: effectiveSegmentType,
      isBismillah: bismillah != null,
      reciterImageUrl: reciter.effectiveImageUrl,
      surahImageAssetPath: SurahImageCatalog.imageUrlFor(ayah.surahNumber),
      remoteAudioUrl: reciter.audioUrlFor(audioAyah),
      playbackUri: reciter.audioUrlFor(audioAyah),
      timingProvider: hasWordTiming
          ? reciter.timingProvider
          : QuranAudioTimingProvider.none,
      timingRecitationId: hasWordTiming ? reciter.timingRecitationId : null,
      timingChapterReciterId: hasWordTiming
          ? reciter.timingChapterReciterId
          : null,
    );
  }

  final int surahNumber;
  final int ayahNumber;
  final String verseKey;
  final int page;
  final String surahName;
  final String arabicText;
  final String translation;
  final String reciterId;
  final String reciterName;
  final String? reciterImageUrl;
  final String? surahImageAssetPath;
  final String? surahArtworkUri;
  final QuranAudioSegmentType segmentType;
  final bool isBismillah;
  final QuranAudioTimingProvider timingProvider;
  final int? timingRecitationId;
  final int? timingChapterReciterId;
  final String remoteAudioUrl;
  final String playbackUri;
  final String? localUri;
  final bool isDownloaded;

  bool get isTranslationSegment =>
      segmentType == QuranAudioSegmentType.translation;

  // Opening audio reuses Al-Fatihah 1:1 without moving the reader to Al-Fatihah.
  int get audioSurahNumber => isBismillah ? 1 : surahNumber;
  int get audioAyahNumber => isBismillah ? 1 : ayahNumber;

  MediaItem toMediaItem() {
    return MediaItem(
      id: playbackUri,
      title: isBismillah
          ? '$surahName Bismillah${isTranslationSegment ? ' Translation' : ''}'
          : isTranslationSegment
          ? '$surahName $surahNumber:$ayahNumber Translation'
          : '$surahName $surahNumber:$ayahNumber',
      artist: reciterName,
      album: 'Quran',
      artUri: surahArtworkUri == null ? null : Uri.tryParse(surahArtworkUri!),
      extras: {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'verseKey': verseKey,
        'page': page,
        'surahName': surahName,
        'arabicText': arabicText,
        'translation': translation,
        'reciterId': reciterId,
        'reciterName': reciterName,
        'reciterImageUrl': reciterImageUrl,
        'surahImageAssetPath': surahImageAssetPath,
        'surahArtworkUri': surahArtworkUri,
        'segmentType': segmentType.name,
        'isBismillah': isBismillah,
        'timingProvider': timingProvider.name,
        'timingRecitationId': timingRecitationId,
        'timingChapterReciterId': timingChapterReciterId,
        'remoteAudioUrl': remoteAudioUrl,
        'localUri': localUri,
        'isDownloaded': isDownloaded,
      },
    );
  }

  QuranAudioQueueItem copyWithPlayback({
    required String playbackUri,
    String? localUri,
    bool isDownloaded = false,
  }) {
    return QuranAudioQueueItem(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      verseKey: verseKey,
      page: page,
      surahName: surahName,
      arabicText: arabicText,
      translation: translation,
      reciterId: reciterId,
      reciterName: reciterName,
      segmentType: segmentType,
      isBismillah: isBismillah,
      reciterImageUrl: reciterImageUrl,
      surahImageAssetPath: surahImageAssetPath,
      surahArtworkUri: surahArtworkUri,
      timingProvider: timingProvider,
      timingRecitationId: timingRecitationId,
      timingChapterReciterId: timingChapterReciterId,
      remoteAudioUrl: remoteAudioUrl,
      playbackUri: playbackUri,
      localUri: localUri,
      isDownloaded: isDownloaded,
    );
  }

  QuranAudioQueueItem copyWithArtwork({required String? surahArtworkUri}) {
    return QuranAudioQueueItem(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      verseKey: verseKey,
      page: page,
      surahName: surahName,
      arabicText: arabicText,
      translation: translation,
      reciterId: reciterId,
      reciterName: reciterName,
      segmentType: segmentType,
      isBismillah: isBismillah,
      reciterImageUrl: reciterImageUrl,
      surahImageAssetPath: surahImageAssetPath,
      surahArtworkUri: surahArtworkUri,
      timingProvider: timingProvider,
      timingRecitationId: timingRecitationId,
      timingChapterReciterId: timingChapterReciterId,
      remoteAudioUrl: remoteAudioUrl,
      playbackUri: playbackUri,
      localUri: localUri,
      isDownloaded: isDownloaded,
    );
  }

  Map<String, Object?> toCacheMap() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'verseKey': verseKey,
      'page': page,
      'surahName': surahName,
      'arabicText': arabicText,
      'translation': translation,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'reciterImageUrl': reciterImageUrl,
      'surahImageAssetPath': surahImageAssetPath,
      'surahArtworkUri': surahArtworkUri,
      'segmentType': segmentType.name,
      'isBismillah': isBismillah,
      'timingProvider': timingProvider.name,
      'timingRecitationId': timingRecitationId,
      'timingChapterReciterId': timingChapterReciterId,
      'remoteAudioUrl': remoteAudioUrl,
      'playbackUri': playbackUri,
      'localUri': localUri,
      'isDownloaded': isDownloaded,
    };
  }

  static QuranAudioQueueItem? fromCacheMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final surahNumber = _intFrom(value['surahNumber']);
    final ayahNumber = _intFrom(value['ayahNumber']);
    final page = _intFrom(value['page']);
    final reciterId = value['reciterId'];
    final remoteAudioUrl = value['remoteAudioUrl'];
    final playbackUri = value['playbackUri'];
    if (surahNumber == null ||
        ayahNumber == null ||
        page == null ||
        reciterId is! String ||
        remoteAudioUrl is! String ||
        playbackUri is! String) {
      return null;
    }
    return QuranAudioQueueItem(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      verseKey: value['verseKey'] as String? ?? '$surahNumber:$ayahNumber',
      page: page,
      surahName: value['surahName'] as String? ?? '',
      arabicText: value['arabicText'] as String? ?? '',
      translation: value['translation'] as String? ?? '',
      reciterId: reciterId,
      reciterName: value['reciterName'] as String? ?? '',
      reciterImageUrl: value['reciterImageUrl'] as String?,
      surahImageAssetPath:
          value['surahImageAssetPath'] as String? ??
          SurahImageCatalog.imageUrlFor(surahNumber),
      surahArtworkUri: value['surahArtworkUri'] as String?,
      segmentType: QuranAudioSegmentType.values.firstWhere(
        (segmentType) => segmentType.name == value['segmentType'],
        orElse: () => QuranAudioSegmentType.arabic,
      ),
      isBismillah: value['isBismillah'] == true,
      timingProvider: QuranAudioTimingProvider.values.firstWhere(
        (provider) => provider.name == value['timingProvider'],
        orElse: () => QuranAudioTimingProvider.none,
      ),
      timingRecitationId: _intFrom(value['timingRecitationId']),
      timingChapterReciterId: _intFrom(value['timingChapterReciterId']),
      remoteAudioUrl: remoteAudioUrl,
      playbackUri: playbackUri,
      localUri: value['localUri'] as String?,
      isDownloaded: value['isDownloaded'] == true,
    );
  }

  static QuranAudioQueueItem? fromMediaItem(MediaItem? item) {
    final extras = item?.extras;
    if (item == null || extras == null) {
      return null;
    }
    final surahNumber = extras['surahNumber'];
    final ayahNumber = extras['ayahNumber'];
    if (surahNumber is! int || ayahNumber is! int) {
      return null;
    }
    return QuranAudioQueueItem(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      verseKey: extras['verseKey'] as String? ?? '$surahNumber:$ayahNumber',
      page: extras['page'] as int? ?? 0,
      surahName: extras['surahName'] as String? ?? '',
      arabicText: extras['arabicText'] as String? ?? '',
      translation: extras['translation'] as String? ?? '',
      reciterId: extras['reciterId'] as String? ?? '',
      reciterName: extras['reciterName'] as String? ?? item.artist ?? '',
      reciterImageUrl: extras['reciterImageUrl'] as String?,
      surahImageAssetPath:
          extras['surahImageAssetPath'] as String? ??
          SurahImageCatalog.imageUrlFor(surahNumber),
      surahArtworkUri:
          extras['surahArtworkUri'] as String? ?? item.artUri?.toString(),
      segmentType: QuranAudioSegmentType.values.firstWhere(
        (segmentType) => segmentType.name == extras['segmentType'],
        orElse: () => QuranAudioSegmentType.arabic,
      ),
      isBismillah: extras['isBismillah'] == true,
      timingProvider: QuranAudioTimingProvider.values.firstWhere(
        (provider) => provider.name == extras['timingProvider'],
        orElse: () => QuranAudioTimingProvider.none,
      ),
      timingRecitationId: extras['timingRecitationId'] as int?,
      timingChapterReciterId: extras['timingChapterReciterId'] as int?,
      remoteAudioUrl: extras['remoteAudioUrl'] as String? ?? item.id,
      playbackUri: item.id,
      localUri: extras['localUri'] as String?,
      isDownloaded: extras['isDownloaded'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    surahNumber,
    ayahNumber,
    verseKey,
    page,
    surahName,
    arabicText,
    translation,
    reciterId,
    reciterName,
    reciterImageUrl,
    surahImageAssetPath,
    surahArtworkUri,
    segmentType,
    isBismillah,
    timingProvider,
    timingRecitationId,
    timingChapterReciterId,
    remoteAudioUrl,
    playbackUri,
    localUri,
    isDownloaded,
  ];
}

int? _intFrom(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return null;
}
