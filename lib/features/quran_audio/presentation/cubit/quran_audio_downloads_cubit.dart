import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/domain/services/quran_translation_audio_pairings.dart';
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
  int _refreshVersion = 0;
  List<QuranAudioReciter> _allReciters = const [];

  Future<void> load() async {
    if (isClosed) return;
    _refreshVersion += 1;
    emit(
      state.copyWith(
        status: QuranAudioDownloadsStatus.loading,
        clearError: true,
        wifiOnlyLargeDownloads: _settingsStore.audioWifiOnlyLargeDownloads,
      ),
    );
    try {
      final allReciters = await _quranRepository.getAudioReciters();
      _allReciters = allReciters;
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
      final selectedTranslationReciter = _preferredTranslationReciter(
        translationReciters,
        selectedTranslation,
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
      if (isClosed) return;
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
      if (isClosed) return;
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
      final pair = quranTranslationPairForVoice(reciter.id);
      final repository = _translationRepository;
      if (pair == null ||
          repository == null ||
          !await repository.hasFullTranslation(pair.resource.id)) {
        throw StateError('Prepare the matching text translation first.');
      }
      await _settingsStore.setAudioMeaningLanguageCode(reciter.languageCode);
      await _settingsStore.setAudioTranslationReciterId(
        reciter.id,
        languageCode: reciter.languageCode,
      );
      await repository.setSelectedTranslation(pair.resource.id);
      emit(
        state.copyWith(
          selectedReciter: reciter,
          selectedTranslationReciter: reciter,
          selectedTranslation: pair.resource,
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
    final selectedTranslation = await _translationRepository
        ?.selectedTranslation();
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
    final selectedTranslationReciter = _preferredTranslationReciter(
      translationReciters,
      selectedTranslation,
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
    await _settingsStore.setAudioMeaningLanguageCode(
      selectedTranslation?.resolvedLanguageCode ?? '',
    );
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
    final selectedTranslationReciter = _preferredTranslationReciter(
      translationReciters,
      selectedTranslation,
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

  QuranAudioReciter? _preferredTranslationReciter(
    List<QuranAudioReciter> reciters,
    QuranTranslationResource? selectedTranslation,
  ) => preferredQuranTranslationVoice(
    quranCompatibleTranslationAudioReciters(
      reciters: reciters,
      selectedTranslation: selectedTranslation,
    ),
    preferredId: _settingsStore.translationVoiceForLanguage(
      reciters.firstOrNull?.languageCode ?? '',
    ),
    legacyId: _settingsStore.audioTranslationReciterId,
  );

  Future<void> setWifiOnlyLargeDownloads(bool value) async {
    await _settingsStore.setAudioWifiOnlyLargeDownloads(value);
    emit(state.copyWith(wifiOnlyLargeDownloads: value));
  }

  Future<void> downloadSurah(int surahNumber, {String? reciterId}) async {
    final reciter = reciterId == null
        ? state.selectedReciter
        : _allReciters.where((item) => item.id == reciterId).firstOrNull;
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
          (group.scope == QuranAudioDownloadScope.reciter ||
              group.items.any((item) => item.isBulkDownload)),
    );
    await _refresh();
  }

  Future<void> retryGroup(QuranAudioDownloadGroup group) async {
    await _downloadService.retryItems(
      group.items,
      requiresWiFi:
          state.wifiOnlyLargeDownloads &&
          (group.scope == QuranAudioDownloadScope.reciter ||
              group.items.any((item) => item.isBulkDownload)),
    );
    await _refresh();
  }

  Future<void> deleteGroup(QuranAudioDownloadGroup group) async {
    final items = group.surahNumber == null
        ? group.items
        : group.items
              .where((item) => item.surahNumber == group.surahNumber)
              .toList(growable: false);
    await _downloadService.cancelItems(items);
    await _downloadRepository.deleteItems(items);
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
    if (isClosed || state.status != QuranAudioDownloadsStatus.success) {
      return;
    }
    final version = ++_refreshVersion;
    final reciter = state.selectedReciter;
    final surahGroups = reciter == null
        ? const <QuranAudioDownloadGroup>[]
        : await _downloadRepository.surahGroups(reciter: reciter);
    final activeGroups = _downloadRepository.activeGroups();
    final downloadedGroups = _downloadRepository.downloadedGroups();
    final pendingItems = _downloadRepository.store.allItems
        .where(
          (item) =>
              item.isActive ||
              item.status == QuranAudioDownloadStatus.paused ||
              item.status == QuranAudioDownloadStatus.failed,
        )
        .toList(growable: false);
    final pendingGroupIds = {
      for (final item in pendingItems)
        '${item.reciterId}_${item.downloadSurahNumber}',
    };
    final allGroupsById = {for (final group in surahGroups) group.id: group};
    final otherReciterIds = {
      for (final group in [...activeGroups, ...downloadedGroups])
        if (group.reciterId != reciter?.id) group.reciterId,
      for (final item in pendingItems)
        if (item.reciterId != reciter?.id) item.reciterId,
    };
    final otherGroups = await Future.wait([
      for (final otherReciter in _allReciters)
        if (otherReciterIds.contains(otherReciter.id))
          _downloadRepository.surahGroups(reciter: otherReciter),
    ]);
    for (final groups in otherGroups) {
      for (final group in groups) {
        allGroupsById[group.id] = group;
      }
    }
    for (final group in activeGroups) {
      allGroupsById.putIfAbsent(group.id, () => group);
    }
    final pendingGroups = [
      for (final group in allGroupsById.values)
        if (pendingGroupIds.contains(group.id)) group,
    ]..sort((a, b) => (a.surahNumber ?? 0).compareTo(b.surahNumber ?? 0));
    final storageUsedBytes = await _downloadRepository.storageUsedBytes();
    if (isClosed || version != _refreshVersion) {
      return;
    }
    emit(
      state.copyWith(
        status: QuranAudioDownloadsStatus.success,
        surahGroups: surahGroups,
        activeGroups: pendingGroups,
        downloadedGroups: [
          for (final group in downloadedGroups)
            allGroupsById[group.id] ?? group,
        ],
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
