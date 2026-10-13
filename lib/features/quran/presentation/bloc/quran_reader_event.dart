import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_reading_mode.dart';

sealed class QuranReaderEvent extends Equatable {
  const QuranReaderEvent();

  @override
  List<Object?> get props => [];
}

class QuranReaderStarted extends QuranReaderEvent {
  const QuranReaderStarted({
    required this.surahNumber,
    this.initialAyahNumber,
    this.initialTranslationResourceId,
  });

  final int surahNumber;
  final int? initialAyahNumber;
  final int? initialTranslationResourceId;

  @override
  List<Object?> get props => [
    surahNumber,
    initialAyahNumber,
    initialTranslationResourceId,
  ];
}

class QuranReaderSurahChanged extends QuranReaderEvent {
  const QuranReaderSurahChanged(this.surahNumber, {this.initialAyahNumber});

  final int surahNumber;
  final int? initialAyahNumber;

  @override
  List<Object?> get props => [surahNumber, initialAyahNumber];
}

class QuranReaderTranslationToggled extends QuranReaderEvent {
  const QuranReaderTranslationToggled();
}

class QuranReaderTranslationPreferenceChanged extends QuranReaderEvent {
  const QuranReaderTranslationPreferenceChanged();
}

class QuranReaderTranslationSelected extends QuranReaderEvent {
  const QuranReaderTranslationSelected(this.resourceId);

  final int resourceId;

  @override
  List<Object> get props => [resourceId];
}

class QuranReaderInterlinearCacheCompleted extends QuranReaderEvent {
  const QuranReaderInterlinearCacheCompleted({this.languageCode = 'en'});

  final String languageCode;

  @override
  List<Object> get props => [languageCode];
}

class QuranReaderAudioReciterSelected extends QuranReaderEvent {
  const QuranReaderAudioReciterSelected(this.reciterId);

  final String reciterId;

  @override
  List<Object> get props => [reciterId];
}

class QuranReaderAyahTextLayoutChanged extends QuranReaderEvent {
  const QuranReaderAyahTextLayoutChanged(this.layout);

  final QuranAyahTextLayout layout;

  @override
  List<Object> get props => [layout];
}

class QuranReaderAyahSelected extends QuranReaderEvent {
  const QuranReaderAyahSelected({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  List<Object> get props => [surahNumber, ayahNumber];
}

class QuranReaderSelectionCleared extends QuranReaderEvent {
  const QuranReaderSelectionCleared();
}

class QuranReaderAudioVerseFocused extends QuranReaderEvent {
  const QuranReaderAudioVerseFocused(this.verseKey);

  final String verseKey;

  @override
  List<Object> get props => [verseKey];
}

class QuranReaderFollowAudioChanged extends QuranReaderEvent {
  const QuranReaderFollowAudioChanged(this.followAudio, {this.verseKey});

  final bool followAudio;
  final String? verseKey;

  @override
  List<Object?> get props => [followAudio, verseKey];
}

class QuranReaderBookmarkToggled extends QuranReaderEvent {
  const QuranReaderBookmarkToggled({
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  List<Object> get props => [surahNumber, ayahNumber];
}

class QuranReaderLastReadSaved extends QuranReaderEvent {
  const QuranReaderLastReadSaved({
    required this.surahNumber,
    required this.ayahNumber,
    this.selectAyah = true,
  });

  final int surahNumber;
  final int ayahNumber;
  final bool selectAyah;

  @override
  List<Object> get props => [surahNumber, ayahNumber, selectAyah];
}
