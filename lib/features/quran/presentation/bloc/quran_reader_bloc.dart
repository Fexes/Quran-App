import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_reading_mode.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_word.dart';
import '../../domain/repositories/quran_interlinear_repository.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import 'quran_reader_event.dart';
import 'quran_reader_state.dart';

class QuranReaderBloc extends Bloc<QuranReaderEvent, QuranReaderState> {
  QuranReaderBloc({
    required QuranRepository repository,
    QuranInterlinearRepository? interlinearRepository,
    QuranTranslationRepository? translationRepository,
    ReadingProgressRepository? readingProgressRepository,
    SettingsStore? settingsStore,
    DateTime Function()? now,
  }) : _repository = repository,
       _interlinearRepository = interlinearRepository,
       _translationRepository = translationRepository,
       _readingProgressRepository = readingProgressRepository,
       _settingsStore = settingsStore,
       _now = now ?? DateTime.now,
       super(const QuranReaderState.initial()) {
    on<QuranReaderStarted>(_onStarted);
    on<QuranReaderSurahChanged>(_onSurahChanged);
    on<QuranReaderTranslationToggled>(_onTranslationToggled);
    on<QuranReaderTranslationSelected>(_onTranslationSelected);
    on<QuranReaderInterlinearCacheCompleted>(_onInterlinearCacheCompleted);
    on<QuranReaderAudioReciterSelected>(_onAudioReciterSelected);
    on<QuranReaderAyahTextLayoutChanged>(_onAyahTextLayoutChanged);
    on<QuranReaderAyahSelected>(_onAyahSelected);
    on<QuranReaderSelectionCleared>(_onSelectionCleared);
    on<QuranReaderAudioVerseFocused>(_onAudioVerseFocused);
    on<QuranReaderFollowAudioChanged>(_onFollowAudioChanged);
    on<QuranReaderBookmarkToggled>(_onBookmarkToggled);
    on<QuranReaderLastReadSaved>(_onLastReadSaved);
  }

  final QuranRepository _repository;
  final QuranInterlinearRepository? _interlinearRepository;
  final QuranTranslationRepository? _translationRepository;
  final ReadingProgressRepository? _readingProgressRepository;
  final SettingsStore? _settingsStore;
  final DateTime Function() _now;
  DateTime? _readingSessionStartedAt;

  Future<_LoadedSurahReaderData> _loadSurahReaderData({
    required int surahNumber,
    int? initialAyahNumber,
    required QuranAyahTextLayout ayahTextLayout,
    required bool showTranslation,
    required bool interlinearCacheComplete,
    required String? interlinearLanguageCode,
    Map<int, List<QuranWord>> existingWords = const {},
  }) async {
    final surah = await _repository.getSurah(surahNumber);
    final ayahs = await _repository.getAyahs(surahNumber);
    final startingAyah = _startingAyah(ayahs, initialAyahNumber);
    final pageWordCache =
        _shouldLoadWords(
          ayahTextLayout: ayahTextLayout,
          showTranslation: showTranslation,
          interlinearCacheComplete: interlinearCacheComplete,
          interlinearLanguageCode: interlinearLanguageCode,
        )
        ? await _surahPageWordCache(
            ayahs,
            existing: existingWords,
            languageCode: interlinearLanguageCode,
          )
        : existingWords;
    if (startingAyah != null) {
      await _repository.saveLastRead(
        surahNumber: startingAyah.surahNumber,
        ayahNumber: startingAyah.number,
      );
    }
    return _LoadedSurahReaderData(
      surah: surah,
      ayahs: ayahs,
      startingAyah: startingAyah,
      pageWordCache: pageWordCache,
    );
  }

  Future<void> _onStarted(
    QuranReaderStarted event,
    Emitter<QuranReaderState> emit,
  ) async {
    emit(state.copyWith(status: QuranReaderStatus.loading));
    try {
      final bookmarks = await _repository.getBookmarks();
      final contentSources = await _repository.getContentSources();
      final audioReciters = await _repository.getAudioReciters();
      final selectedAudioReciterId = await _repository
          .getSelectedAudioReciterId();
      final ayahTextLayout = await _repository.getAyahTextLayout();
      final storedTranslationPreference = await _translationRepository
          ?.selectedTranslation();
      final initialTranslation = await _translationResourceForId(
        event.initialTranslationResourceId,
        event.surahNumber,
      );
      final selectedTranslationPreference =
          initialTranslation ?? storedTranslationPreference;
      final selectedTranslation = selectedTranslationPreference;
      final selectedTranslations = await _selectedTranslationResources(
        selectedTranslation,
      );
      final showTranslation =
          initialTranslation != null ||
          (_settingsStore?.quranTranslationVisible ??
              selectedTranslation != null);
      final interlinearLanguageCode = _interlinearLanguageCode(
        selectedTranslation,
      );
      final interlinearCacheComplete = await _hasFullInterlinearCache(
        interlinearLanguageCode,
      );
      final selectedAudioReciter = _selectedAudioReciter(
        audioReciters,
        selectedAudioReciterId,
      );
      final loaded = await _loadSurahReaderData(
        surahNumber: event.surahNumber,
        initialAyahNumber: event.initialAyahNumber,
        ayahTextLayout: ayahTextLayout,
        showTranslation: showTranslation,
        interlinearCacheComplete: interlinearCacheComplete,
        interlinearLanguageCode: interlinearLanguageCode,
      );
      final translationsByResource = await _translationMapsForSurah(
        selectedTranslations,
        loaded.surah.number,
      );
      final openingAyahs = loaded.surah.number == 1
          ? loaded.ayahs
          : await _repository.getAyahs(1);
      final bismillahAyah = openingAyahs.isEmpty ? null : openingAyahs.first;
      assert(bismillahAyah == null || bismillahAyah.verseKey == '1:1');
      final translationsByVerse = selectedTranslation == null
          ? const <String, String>{}
          : translationsByResource[selectedTranslation.id] ?? const {};
      emit(
        state.copyWith(
          status: QuranReaderStatus.success,
          surah: loaded.surah,
          ayahs: loaded.ayahs,
          bismillahAyah: bismillahAyah,
          bookmarkedVerseKeys: bookmarks
              .map((bookmark) => bookmark.verseKey)
              .toSet(),
          contentSources: contentSources,
          audioReciters: audioReciters,
          selectedAudioReciter: selectedAudioReciter,
          ayahTextLayout: ayahTextLayout,
          showTranslation: showTranslation,
          selectedTranslation: selectedTranslation,
          selectedTranslations: selectedTranslations,
          translationsByResource: translationsByResource,
          interlinearLanguageCode: interlinearLanguageCode,
          translationsByVerse: translationsByVerse,
          interlinearCacheComplete: interlinearCacheComplete,
          pageWordsByPage: loaded.pageWordCache,
          pageWordDataAvailable: _availableWordPages(loaded.pageWordCache),
          currentVerseKey: loaded.startingAyah?.verseKey,
          selectedVerseKey: loaded.startingAyah?.verseKey,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranReaderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSurahChanged(
    QuranReaderSurahChanged event,
    Emitter<QuranReaderState> emit,
  ) async {
    if (state.errorMessage != null) emit(state.copyWith());
    try {
      final loaded = await _loadSurahReaderData(
        surahNumber: event.surahNumber.clamp(1, 114).toInt(),
        initialAyahNumber: event.initialAyahNumber,
        ayahTextLayout: state.ayahTextLayout,
        showTranslation: state.showTranslation,
        interlinearCacheComplete: state.interlinearCacheComplete,
        interlinearLanguageCode: state.interlinearLanguageCode,
        existingWords: state.pageWordsByPage,
      );
      final translationsByResource = await _translationMapsForSurah(
        state.selectedTranslations,
        loaded.surah.number,
      );
      final translationsByVerse = state.selectedTranslation == null
          ? const <String, String>{}
          : translationsByResource[state.selectedTranslation!.id] ?? const {};
      emit(
        state.copyWith(
          surah: loaded.surah,
          ayahs: loaded.ayahs,
          pageWordsByPage: loaded.pageWordCache,
          translationsByVerse: translationsByVerse,
          translationsByResource: translationsByResource,
          pageWordDataAvailable: {
            ...state.pageWordDataAvailable,
            ..._availableWordPages(loaded.pageWordCache),
          },
          currentVerseKey: loaded.startingAyah?.verseKey,
          selectedVerseKey: loaded.startingAyah?.verseKey,
        ),
      );
    } catch (_) {
      // Keep the current reader visible and allow a failed pull to be retried.
      emit(
        state.copyWith(errorMessage: 'Could not open surah. Please try again.'),
      );
    }
  }

  Future<void> _onTranslationToggled(
    QuranReaderTranslationToggled event,
    Emitter<QuranReaderState> emit,
  ) async {
    final showTranslation = !state.showTranslation;
    await _settingsStore?.setQuranTranslationVisible(showTranslation);
    final pageWords =
        _shouldLoadWords(
          ayahTextLayout: state.ayahTextLayout,
          showTranslation: showTranslation,
          interlinearCacheComplete: state.interlinearCacheComplete,
          interlinearLanguageCode: state.interlinearLanguageCode,
        )
        ? await _surahPageWordCache(
            state.ayahs,
            existing: state.pageWordsByPage,
            languageCode: state.interlinearLanguageCode,
          )
        : state.pageWordsByPage;
    emit(
      state.copyWith(
        showTranslation: showTranslation,
        pageWordsByPage: pageWords,
        pageWordDataAvailable: {
          ...state.pageWordDataAvailable,
          ..._availableWordPages(pageWords),
        },
      ),
    );
  }

  Future<void> _onTranslationSelected(
    QuranReaderTranslationSelected event,
    Emitter<QuranReaderState> emit,
  ) async {
    final repository = _translationRepository;
    final surah = state.surah;
    if (repository == null || surah == null) {
      return;
    }
    final cachedForSurah = await repository.cachedTranslationsForSurah(
      event.resourceId,
      surah.number,
    );
    if (cachedForSurah.isEmpty &&
        !await repository.hasFullTranslation(event.resourceId)) {
      return;
    }
    await repository.setSelectedTranslation(event.resourceId);
    await _settingsStore?.setQuranTranslationVisible(true);
    final selected = await repository.selectedTranslation();
    final selectedTranslations = await _selectedTranslationResources(selected);
    final interlinearLanguageCode = _interlinearLanguageCode(selected);
    final interlinearCacheComplete = await _hasFullInterlinearCache(
      interlinearLanguageCode,
    );
    final translationsByResource = await _translationMapsForSurah(
      selectedTranslations,
      surah.number,
    );
    final translationsByVerse = selected == null
        ? const <String, String>{}
        : translationsByResource[selected.id] ?? const {};
    final languageChanged =
        interlinearLanguageCode != state.interlinearLanguageCode;
    final existingWords = languageChanged
        ? const <int, List<QuranWord>>{}
        : state.pageWordsByPage;
    final pageWords =
        _shouldLoadWords(
          ayahTextLayout: state.ayahTextLayout,
          showTranslation: selected != null,
          interlinearCacheComplete: interlinearCacheComplete,
          interlinearLanguageCode: interlinearLanguageCode,
        )
        ? await _surahPageWordCache(
            state.ayahs,
            existing: existingWords,
            languageCode: interlinearLanguageCode,
          )
        : existingWords;
    emit(
      state.copyWith(
        showTranslation: selected != null,
        selectedTranslation: selected,
        selectedTranslations: selectedTranslations,
        translationsByResource: translationsByResource,
        translationsByVerse: translationsByVerse,
        interlinearCacheComplete: interlinearCacheComplete,
        interlinearLanguageCode: interlinearLanguageCode,
        clearInterlinearLanguageCode: interlinearLanguageCode == null,
        pageWordsByPage: pageWords,
        pageWordDataAvailable: _availableWordPages(pageWords),
      ),
    );
  }

  Future<void> _onInterlinearCacheCompleted(
    QuranReaderInterlinearCacheCompleted event,
    Emitter<QuranReaderState> emit,
  ) async {
    if (state.interlinearLanguageCode != event.languageCode) {
      return;
    }
    final pageWords =
        _shouldLoadWords(
          ayahTextLayout: state.ayahTextLayout,
          showTranslation: state.showTranslation,
          interlinearCacheComplete: true,
          interlinearLanguageCode: event.languageCode,
        )
        ? await _surahPageWordCache(
            state.ayahs,
            existing: state.pageWordsByPage,
            languageCode: event.languageCode,
          )
        : state.pageWordsByPage;
    emit(
      state.copyWith(
        interlinearCacheComplete: true,
        interlinearLanguageCode: event.languageCode,
        pageWordsByPage: pageWords,
        pageWordDataAvailable: {
          ...state.pageWordDataAvailable,
          ..._availableWordPages(pageWords),
        },
      ),
    );
  }

  Future<void> _onAudioReciterSelected(
    QuranReaderAudioReciterSelected event,
    Emitter<QuranReaderState> emit,
  ) async {
    for (final reciter in state.audioReciters) {
      if (reciter.id == event.reciterId) {
        await _repository.saveSelectedAudioReciterId(reciter.id);
        emit(state.copyWith(selectedAudioReciter: reciter));
        return;
      }
    }
  }

  Future<void> _onAyahTextLayoutChanged(
    QuranReaderAyahTextLayoutChanged event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _repository.saveAyahTextLayout(event.layout);
    final pageWords =
        _shouldLoadWords(
          ayahTextLayout: event.layout,
          showTranslation: state.showTranslation,
          interlinearCacheComplete: state.interlinearCacheComplete,
          interlinearLanguageCode: state.interlinearLanguageCode,
        )
        ? await _surahPageWordCache(
            state.ayahs,
            existing: state.pageWordsByPage,
            languageCode: state.interlinearLanguageCode,
          )
        : state.pageWordsByPage;
    emit(
      state.copyWith(
        ayahTextLayout: event.layout,
        pageWordsByPage: pageWords,
        pageWordDataAvailable: {
          ...state.pageWordDataAvailable,
          ..._availableWordPages(pageWords),
        },
      ),
    );
  }

  Future<void> _onAyahSelected(
    QuranReaderAyahSelected event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _selectAyah(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
      emit: emit,
    );
  }

  void _onSelectionCleared(
    QuranReaderSelectionCleared event,
    Emitter<QuranReaderState> emit,
  ) {
    emit(state.copyWith(clearSelectedVerseKey: true));
  }

  Future<void> _onAudioVerseFocused(
    QuranReaderAudioVerseFocused event,
    Emitter<QuranReaderState> emit,
  ) async {
    final selected = _parseVerseKey(event.verseKey);
    if (selected == null) {
      return;
    }
    await _repository.saveLastRead(
      surahNumber: selected.surahNumber,
      ayahNumber: selected.ayahNumber,
    );
    if (state.followAudio && selected.surahNumber != state.surah?.number) {
      final loaded = await _loadSurahReaderData(
        surahNumber: selected.surahNumber,
        initialAyahNumber: selected.ayahNumber,
        ayahTextLayout: state.ayahTextLayout,
        showTranslation: state.showTranslation,
        interlinearCacheComplete: state.interlinearCacheComplete,
        interlinearLanguageCode: state.interlinearLanguageCode,
        existingWords: state.pageWordsByPage,
      );
      final translationsByResource = await _translationMapsForSurah(
        state.selectedTranslations,
        loaded.surah.number,
      );
      final translationsByVerse = state.selectedTranslation == null
          ? const <String, String>{}
          : translationsByResource[state.selectedTranslation!.id] ?? const {};
      emit(
        state.copyWith(
          surah: loaded.surah,
          ayahs: loaded.ayahs,
          translationsByVerse: translationsByVerse,
          translationsByResource: translationsByResource,
          activeAudioVerseKey: event.verseKey,
          currentVerseKey: event.verseKey,
          selectedVerseKey: event.verseKey,
          pageWordsByPage: loaded.pageWordCache,
          pageWordDataAvailable: {
            ...state.pageWordDataAvailable,
            ..._availableWordPages(loaded.pageWordCache),
          },
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        activeAudioVerseKey: event.verseKey,
        currentVerseKey: event.verseKey,
        selectedVerseKey: event.verseKey,
      ),
    );
  }

  void _onFollowAudioChanged(
    QuranReaderFollowAudioChanged event,
    Emitter<QuranReaderState> emit,
  ) {
    final activeVerseKey = event.verseKey ?? state.activeAudioVerseKey;
    final active = _parseVerseKey(activeVerseKey);
    if (!event.followAudio || active == null) {
      emit(state.copyWith(followAudio: event.followAudio));
      return;
    }
    emit(state.copyWith(followAudio: true));
    add(QuranReaderAudioVerseFocused(activeVerseKey!));
  }

  Future<void> _onBookmarkToggled(
    QuranReaderBookmarkToggled event,
    Emitter<QuranReaderState> emit,
  ) async {
    final isNowBookmarked = await _repository.toggleBookmark(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    );
    final next = state.bookmarkedVerseKeys.toSet();
    final verseKey = '${event.surahNumber}:${event.ayahNumber}';
    if (isNowBookmarked) {
      next.add(verseKey);
    } else {
      next.remove(verseKey);
    }
    emit(state.copyWith(bookmarkedVerseKeys: next));
  }

  Future<void> _onLastReadSaved(
    QuranReaderLastReadSaved event,
    Emitter<QuranReaderState> emit,
  ) async {
    await _repository.saveLastRead(
      surahNumber: event.surahNumber,
      ayahNumber: event.ayahNumber,
    );
    await _recordReadingProgress(event.surahNumber, event.ayahNumber);
    emit(
      state.copyWith(
        currentVerseKey: '${event.surahNumber}:${event.ayahNumber}',
        selectedVerseKey: event.selectAyah
            ? '${event.surahNumber}:${event.ayahNumber}'
            : state.selectedVerseKey,
      ),
    );
  }

  Future<void> _selectAyah({
    required int surahNumber,
    required int ayahNumber,
    required Emitter<QuranReaderState> emit,
  }) async {
    final verseKey = '$surahNumber:$ayahNumber';
    await _repository.saveLastRead(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    await _recordReadingProgress(surahNumber, ayahNumber);
    if (surahNumber != state.surah?.number) {
      final loaded = await _loadSurahReaderData(
        surahNumber: surahNumber,
        initialAyahNumber: ayahNumber,
        ayahTextLayout: state.ayahTextLayout,
        showTranslation: state.showTranslation,
        interlinearCacheComplete: state.interlinearCacheComplete,
        interlinearLanguageCode: state.interlinearLanguageCode,
        existingWords: state.pageWordsByPage,
      );
      final translationsByResource = await _translationMapsForSurah(
        state.selectedTranslations,
        loaded.surah.number,
      );
      final translationsByVerse = state.selectedTranslation == null
          ? const <String, String>{}
          : translationsByResource[state.selectedTranslation!.id] ?? const {};
      emit(
        state.copyWith(
          surah: loaded.surah,
          ayahs: loaded.ayahs,
          translationsByVerse: translationsByVerse,
          translationsByResource: translationsByResource,
          pageWordsByPage: loaded.pageWordCache,
          pageWordDataAvailable: {
            ...state.pageWordDataAvailable,
            ..._availableWordPages(loaded.pageWordCache),
          },
          selectedVerseKey: verseKey,
          currentVerseKey: verseKey,
        ),
      );
      return;
    }
    emit(state.copyWith(selectedVerseKey: verseKey, currentVerseKey: verseKey));
  }

  Future<void> _recordReadingProgress(int surahNumber, int ayahNumber) async {
    final repository = _readingProgressRepository;
    if (repository == null) {
      return;
    }
    int? page;
    for (final ayah in state.ayahs) {
      if (ayah.surahNumber == surahNumber && ayah.number == ayahNumber) {
        page = ayah.page;
        break;
      }
    }
    _readingSessionStartedAt ??= _now();
    await repository.recordVerse(
      verseKey: '$surahNumber:$ayahNumber',
      page: page,
      at: _now(),
    );
  }

  @override
  Future<void> close() async {
    final startedAt = _readingSessionStartedAt;
    final repository = _readingProgressRepository;
    if (startedAt != null && repository != null) {
      final seconds = _now().difference(startedAt).inSeconds;
      if (seconds >= 30) {
        await repository.recordMinutes(
          ((seconds + 30) ~/ 60).clamp(1, 120),
          at: _now(),
        );
      }
    }
    return super.close();
  }

  static QuranAyah? _startingAyah(
    List<QuranAyah> ayahs,
    int? initialAyahNumber,
  ) {
    if (ayahs.isEmpty) {
      return null;
    }
    if (initialAyahNumber == null) {
      return ayahs.first;
    }
    for (final ayah in ayahs) {
      if (ayah.number == initialAyahNumber) {
        return ayah;
      }
    }
    return ayahs.first;
  }

  static QuranAudioReciter? _selectedAudioReciter(
    List<QuranAudioReciter> reciters,
    String? selectedAudioReciterId,
  ) {
    if (reciters.isEmpty) {
      return null;
    }
    if (selectedAudioReciterId == null) {
      return reciters.first;
    }
    for (final reciter in reciters) {
      if (reciter.id == selectedAudioReciterId) {
        return reciter;
      }
    }
    return reciters.first;
  }

  String? _interlinearLanguageCode(QuranTranslationResource? resource) {
    return resource?.wordTranslationLanguageCode;
  }

  Future<bool> _hasFullInterlinearCache(String? languageCode) async {
    final repository = _interlinearRepository;
    if (repository == null || languageCode == null) {
      return false;
    }
    return repository.hasFullCache(language: languageCode);
  }

  Future<List<QuranTranslationResource>> _selectedTranslationResources(
    QuranTranslationResource? primary,
  ) async {
    final repository = _translationRepository;
    if (repository is QuranMultiTranslationRepository) {
      final selected = await (repository as QuranMultiTranslationRepository)
          .selectedTranslations();
      if (primary == null) {
        return selected;
      }
      return [
        primary,
        ...selected.where((item) => item.id != primary.id),
      ].take(3).toList(growable: false);
    }
    return primary == null ? const [] : [primary];
  }

  Future<QuranTranslationResource?> _translationResourceForId(
    int? resourceId,
    int surahNumber,
  ) async {
    final repository = _translationRepository;
    if (repository == null || resourceId == null) {
      return null;
    }
    for (final language in await repository.translationLanguages()) {
      for (final resource in language.availableResources) {
        if (resource.id == resourceId) {
          final cached = await repository.cachedTranslationsForSurah(
            resource.id,
            surahNumber,
          );
          if (cached.isNotEmpty ||
              await repository.hasFullTranslation(resource.id)) {
            return resource;
          }
          return null;
        }
      }
    }
    return null;
  }

  Future<Map<int, Map<String, String>>> _translationMapsForSurah(
    List<QuranTranslationResource> resources,
    int surahNumber,
  ) async {
    final repository = _translationRepository;
    if (repository == null || resources.isEmpty) {
      return const {};
    }
    final translations = <int, Map<String, String>>{};
    for (final resource in resources) {
      final verses = await repository.cachedTranslationsForSurah(
        resource.id,
        surahNumber,
      );
      final opening = surahNumber == 1 || surahNumber == 9
          ? null
          : await repository.cachedTranslationForVerse(resource.id, '1:1');
      translations[resource.id] = {
        ...verses,
        if (opening != null && opening.trim().isNotEmpty) '1:1': opening,
      };
    }
    return translations;
  }

  Future<Map<int, List<QuranWord>>> _surahPageWordCache(
    List<QuranAyah> ayahs, {
    Map<int, List<QuranWord>> existing = const {},
    String? languageCode,
  }) async {
    final repository = _interlinearRepository;
    if (repository == null || languageCode == null) {
      return existing;
    }
    final pages = {for (final ayah in ayahs) _clampPage(ayah.page)}.toList()
      ..sort();
    final cache = Map<int, List<QuranWord>>.from(existing);
    for (final pageNumber in pages) {
      cache[pageNumber] ??= await repository.cachedPageWords(
        pageNumber,
        language: languageCode,
      );
    }
    return cache;
  }

  bool _shouldLoadWords({
    required QuranAyahTextLayout ayahTextLayout,
    required bool showTranslation,
    required bool interlinearCacheComplete,
    required String? interlinearLanguageCode,
  }) {
    return ayahTextLayout == QuranAyahTextLayout.combined &&
        showTranslation &&
        interlinearCacheComplete &&
        interlinearLanguageCode != null;
  }

  Set<int> _availableWordPages(Map<int, List<QuranWord>> pages) {
    return {
      for (final entry in pages.entries)
        if (entry.value.isNotEmpty) entry.key,
    };
  }

  static int _clampPage(int page) {
    return page.clamp(1, 604).toInt();
  }

  static _ParsedVerseKey? _parseVerseKey(String? verseKey) {
    if (verseKey == null) {
      return null;
    }
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return null;
    }
    final surahNumber = int.tryParse(parts[0]);
    final ayahNumber = int.tryParse(parts[1]);
    if (surahNumber == null || ayahNumber == null) {
      return null;
    }
    return _ParsedVerseKey(surahNumber, ayahNumber);
  }
}

class _LoadedSurahReaderData {
  const _LoadedSurahReaderData({
    required this.surah,
    required this.ayahs,
    required this.startingAyah,
    required this.pageWordCache,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final QuranAyah? startingAyah;
  final Map<int, List<QuranWord>> pageWordCache;
}

class _ParsedVerseKey {
  const _ParsedVerseKey(this.surahNumber, this.ayahNumber);

  final int surahNumber;
  final int ayahNumber;
}
