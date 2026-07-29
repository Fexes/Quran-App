import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../data/repositories/quran_audio_download_repository.dart';
import '../../data/services/quran_audio_download_service.dart';
import '../../domain/entities/quran_audio_download_item.dart';
import '../../domain/services/quran_translation_audio_selector.dart';
import 'quran_audio_downloads_state.dart';

class QuranAudioDownloadsCubit extends Cubit<QuranAudioDownloadsState> {
  QuranAudioDownloadsCubit({
    required QuranRepository quranRepository,
    required QuranAudioDownloadRepository downloadRepository,
    required QuranAudioDownloadServicePort downloadService,
    required SettingsStore settingsStore,
    QuranTranslationRepository? translationRepository,
    QuranAudioDownloadAudioType initialAudioType =
        QuranAudioDownloadAudioType.arabic,
  }) : _quranRepository = quranRepository,
       _translationRepository = translationRepository,
       _downloadRepository = downloadRepository,
       _downloadService = downloadService,
       _settingsStore = settingsStore,
       super(QuranAudioDownloadsState.initial(audioType: initialAudioType)) {
    _downloadSubscription = _downloadService.updates.listen((_) {
      _scheduleRefresh();
    });
  }

  final QuranRepository _quranRepository;
  final QuranTranslationRepository? _translationRepository;
  final QuranAudioDownloadRepository _downloadRepository;
  final QuranAudioDownloadServicePort _downloadService;
  final SettingsStore _settingsStore;
  late final StreamSubscription<void> _downloadSubscription;
  Timer? _refreshDebounce;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: QuranAudioDownloadsStatus.loading,
        clearError: true,
        wifiOnlyLargeDownloads: _settingsStore.audioWifiOnlyLargeDownloads,
      ),
    );
    try {
      final allReciters = await _quranRepository.getAudioReciters();
      final selectedId = await _quranRepository.getSelectedAudioReciterId();
      final selectedTranslation = await _translationRepository
          ?.selectedTranslation();
      final arabicReciters = _arabicReciters(allReciters);
      final translationReciters = quranTranslationAudioRecitersFor(
        reciters: allReciters,
        selectedTranslation: selectedTranslation,
        preferredLanguageCode: _settingsStore.audioMeaningLanguageCodeOrNull,
      );
      final selectedArabic = _selectedReciter(arabicReciters, selectedId);
      final savedTranslationId = _settingsStore.audioTranslationReciterId;
      final selectedTranslationReciter = _selectedReciter(
        translationReciters,
        savedTranslationId,
      );
      final visibleReciters = _recitersForAudioType(
        state.audioType,
        arabicReciters: arabicReciters,
        translationReciters: translationReciters,
      );
      final selected = _selectedForAudioType(
        state.audioType,
        selectedArabic: selectedArabic,
        selectedTranslation: selectedTranslationReciter,
      );
      emit(
        state.copyWith(
          status: QuranAudioDownloadsStatus.success,
          reciters: visibleReciters,
          selectedReciter: selected,
          selectedArabicReciter: selectedArabic,
          selectedTranslationReciter: selectedTranslationReciter,
          selectedTranslation: selectedTranslation,
          clearSelectedReciter: selected == null,
          clearSelectedArabicReciter: selectedArabic == null,
          clearSelectedTranslationReciter: selectedTranslationReciter == null,
          clearSelectedTranslation: selectedTranslation == null,
          wifiOnlyLargeDownloads: _settingsStore.audioWifiOnlyLargeDownloads,
          clearError: true,
        ),
      );
      await _refresh();
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranAudioDownloadsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> selectReciter(QuranAudioReciter reciter) async {
    if (state.audioType == QuranAudioDownloadAudioType.translation) {
      await _settingsStore.setAudioTranslationReciterId(reciter.id);
      await _settingsStore.setAudioMeaningLanguageCode(reciter.languageCode);
      emit(
        state.copyWith(
          selectedReciter: reciter,
          selectedTranslationReciter: reciter,
        ),
      );
    } else {
      await _quranRepository.saveSelectedAudioReciterId(reciter.id);
      emit(
        state.copyWith(
          selectedReciter: reciter,
          selectedArabicReciter: reciter,
        ),
      );
    }
    await _refresh();
  }

  Future<void> setAudioType(QuranAudioDownloadAudioType audioType) async {
    final allReciters = await _quranRepository.getAudioReciters();
    final selectedTranslation =
        state.selectedTranslation ??
        await _translationRepository?.selectedTranslation();
    final arabicReciters = _arabicReciters(allReciters);
    final translationReciters = quranTranslationAudioRecitersFor(
      reciters: allReciters,
      selectedTranslation: selectedTranslation,
      preferredLanguageCode: _settingsStore.audioMeaningLanguageCodeOrNull,
    );
    final selectedArabic =
        state.selectedArabicReciter ??
        _selectedReciter(
          arabicReciters,
          await _quranRepository.getSelectedAudioReciterId(),
        );
    final selectedTranslationReciter =
        state.selectedTranslationReciter ??
        _selectedReciter(
          translationReciters,
          _settingsStore.audioTranslationReciterId,
        );
    final visibleReciters = _recitersForAudioType(
      audioType,
      arabicReciters: arabicReciters,
      translationReciters: translationReciters,
    );
    final selected = _selectedForAudioType(
      audioType,
      selectedArabic: selectedArabic,
      selectedTranslation: selectedTranslationReciter,
    );
    emit(
      state.copyWith(
        audioType: audioType,
        reciters: visibleReciters,
        selectedReciter: selected,
        selectedArabicReciter: selectedArabic,
        selectedTranslationReciter: selectedTranslationReciter,
        selectedTranslation: selectedTranslation,
        surahGroups: selected == null ? const [] : null,
        clearSelectedReciter: selected == null,
        clearSelectedArabicReciter: selectedArabic == null,
        clearSelectedTranslationReciter: selectedTranslationReciter == null,
        clearSelectedTranslation: selectedTranslation == null,
        clearError: true,
      ),
    );
    await _refresh();
  }

  Future<void> selectTranslation(int resourceId) async {
    final repository = _translationRepository;
    if (repository == null) {
      return;
    }
    await repository.setSelectedTranslation(resourceId);
    final selectedTranslation = await repository.selectedTranslation();
    final allReciters = await _quranRepository.getAudioReciters();
    final arabicReciters = _arabicReciters(allReciters);
    final translationReciters = quranTranslationAudioRecitersFor(
      reciters: allReciters,
      selectedTranslation: selectedTranslation,
      preferredLanguageCode: _settingsStore.audioMeaningLanguageCodeOrNull,
    );
    final selectedArabic =
        state.selectedArabicReciter ??
        _selectedReciter(
          arabicReciters,
          await _quranRepository.getSelectedAudioReciterId(),
        );
    final selectedTranslationReciter = _selectedReciter(
      translationReciters,
      _settingsStore.audioTranslationReciterId,
    );
    emit(
      state.copyWith(
        audioType: QuranAudioDownloadAudioType.translation,
        reciters: translationReciters,
        selectedReciter: selectedTranslationReciter,
        selectedArabicReciter: selectedArabic,
        selectedTranslationReciter: selectedTranslationReciter,
        selectedTranslation: selectedTranslation,
        surahGroups: selectedTranslationReciter == null ? const [] : null,
        clearSelectedReciter: selectedTranslationReciter == null,
        clearSelectedTranslationReciter: selectedTranslationReciter == null,
        clearSelectedTranslation: selectedTranslation == null,
        clearError: true,
      ),
    );
    await _refresh();
  }

  void setFilter(QuranAudioDownloadsFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> setWifiOnlyLargeDownloads(bool value) async {
    await _settingsStore.setAudioWifiOnlyLargeDownloads(value);
    emit(state.copyWith(wifiOnlyLargeDownloads: value));
  }

  Future<void> downloadSurah(int surahNumber) async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final items = await _downloadRepository.itemsForSurah(
      reciter: reciter,
      surahNumber: surahNumber,
    );
    await _downloadService.enqueueItems(items);
    await _refresh();
  }

  Future<void> downloadFullReciter() async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final items = await _downloadRepository.itemsForReciter(reciter);
    await _downloadService.enqueueItems(
      items,
      requiresWiFi: state.wifiOnlyLargeDownloads,
    );
    await _refresh();
  }

  Future<void> downloadCompleteOffline() async {
    final items = <QuranAudioDownloadItem>[];
    final arabicReciter = state.selectedArabicReciter;
    if (arabicReciter != null) {
      items.addAll(await _downloadRepository.itemsForReciter(arabicReciter));
    }
    final translationReciter = state.selectedTranslationReciter;
    if (translationReciter != null) {
      items.addAll(
        await _downloadRepository.itemsForReciter(translationReciter),
      );
    }
    if (items.isEmpty) {
      return;
    }
    await _downloadService.enqueueItems(
      items,
      requiresWiFi: state.wifiOnlyLargeDownloads,
    );
    await _refresh();
  }

  Future<void> pauseGroup(QuranAudioDownloadGroup group) async {
    await _downloadService.pauseItems(group.items);
    await _refresh();
  }

  Future<void> resumeGroup(QuranAudioDownloadGroup group) async {
    await _downloadService.resumeItems(
      group.items,
      requiresWiFi:
          state.wifiOnlyLargeDownloads &&
          group.scope == QuranAudioDownloadScope.reciter,
    );
    await _refresh();
  }

  Future<void> retryGroup(QuranAudioDownloadGroup group) async {
    await _downloadService.retryItems(group.items);
    await _refresh();
  }

  Future<void> deleteGroup(QuranAudioDownloadGroup group) async {
    await _downloadService.cancelItems(group.items);
    await _downloadRepository.deleteItems(group.items);
    await _refresh();
  }

  Future<void> deleteSurah(int surahNumber) async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final items = _downloadRepository.store.itemsForSurah(
      reciterId: reciter.id,
      surahNumber: surahNumber,
    );
    await _downloadService.cancelItems(items);
    await _downloadRepository.deleteItems(items);
    await _refresh();
  }

  Future<void> deleteSelectedAudio() async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final items = _downloadRepository.store.itemsForReciter(reciter.id);
    await _downloadService.cancelItems(items);
    await _downloadRepository.deleteItems(items);
    await _refresh();
  }

  Future<void> deleteAllAudio() async {
    await _downloadService.cancelItems(_downloadRepository.store.allItems);
    await _downloadRepository.deleteAll();
    await _refresh();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    final reciter = state.selectedReciter;
    if (isClosed) {
      return;
    }
    final surahGroups = reciter == null
        ? const <QuranAudioDownloadGroup>[]
        : await _downloadRepository.surahGroups(reciter: reciter);
    final activeGroups = _downloadRepository.activeGroups();
    final downloadedGroups = _downloadRepository.downloadedGroups();
    final storageUsedBytes = await _downloadRepository.storageUsedBytes();
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        status: QuranAudioDownloadsStatus.success,
        surahGroups: surahGroups,
        activeGroups: activeGroups,
        downloadedGroups: downloadedGroups,
        storageUsedBytes: storageUsedBytes,
        wifiOnlyLargeDownloads: _settingsStore.audioWifiOnlyLargeDownloads,
        clearError: true,
      ),
    );
  }

  QuranAudioReciter? _selectedReciter(
    List<QuranAudioReciter> reciters,
    String? selectedId,
  ) {
    for (final reciter in reciters) {
      if (reciter.id == selectedId) {
        return reciter;
      }
    }
    return reciters.isEmpty ? null : reciters.first;
  }

  List<QuranAudioReciter> _arabicReciters(List<QuranAudioReciter> reciters) {
    return reciters
        .where((reciter) => !reciter.isTranslation)
        .toList(growable: false);
  }

  List<QuranAudioReciter> _recitersForAudioType(
    QuranAudioDownloadAudioType audioType, {
    required List<QuranAudioReciter> arabicReciters,
    required List<QuranAudioReciter> translationReciters,
  }) {
    return audioType == QuranAudioDownloadAudioType.translation
        ? translationReciters
        : arabicReciters;
  }

  QuranAudioReciter? _selectedForAudioType(
    QuranAudioDownloadAudioType audioType, {
    required QuranAudioReciter? selectedArabic,
    required QuranAudioReciter? selectedTranslation,
  }) {
    return audioType == QuranAudioDownloadAudioType.translation
        ? selectedTranslation
        : selectedArabic;
  }

  @override
  Future<void> close() async {
    _refreshDebounce?.cancel();
    await _downloadSubscription.cancel();
    return super.close();
  }
}
