import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/content/content_source.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_reading_mode.dart';
import '../../domain/entities/quran_note.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_tafsir.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_word.dart';
import '../../data/stores/quran_user_data_store.dart';
import '../../domain/repositories/quran_interlinear_repository.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_tafsir_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import '../../../quran_audio/domain/entities/quran_audio_state.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../../quran_audio/presentation/cubit/quran_audio_cubit.dart';
import '../../../quran_audio/presentation/widgets/quran_playback_settings_sheet.dart';
import '../../../quran_audio/presentation/widgets/quran_reciter_picker.dart';
import '../bloc/quran_reader_bloc.dart';
import '../bloc/quran_reader_event.dart';
import '../bloc/quran_reader_state.dart';
import '../widgets/quran_book_text.dart';
import '../widgets/quran_reader_floating_controls.dart';
import '../widgets/quran_translation_text.dart';

class QuranReaderPage extends StatelessWidget {
  const QuranReaderPage({
    super.key,
    required this.surahNumber,
    this.initialAyahNumber,
    this.initialTranslationResourceId,
  });

  final int surahNumber;
  final int? initialAyahNumber;
  final int? initialTranslationResourceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QuranReaderBloc(
            repository: getIt<QuranRepository>(),
            interlinearRepository: getIt<QuranInterlinearRepository>(),
            translationRepository: getIt<QuranTranslationRepository>(),
            readingProgressRepository:
                getIt.isRegistered<ReadingProgressRepository>()
                ? getIt<ReadingProgressRepository>()
                : null,
            settingsStore: getIt.isRegistered<SettingsStore>()
                ? getIt<SettingsStore>()
                : null,
          )..add(
            QuranReaderStarted(
              surahNumber: surahNumber,
              initialAyahNumber: initialAyahNumber,
              initialTranslationResourceId: initialTranslationResourceId,
            ),
          ),
      child: _QuranReaderView(
        surahNumber: surahNumber,
        initialAyahNumber: initialAyahNumber,
      ),
    );
  }
}

class _QuranReaderView extends StatefulWidget {
  const _QuranReaderView({
    required this.surahNumber,
    required this.initialAyahNumber,
  });

  final int surahNumber;
  final int? initialAyahNumber;

  String? get initialVerseKey =>
      initialAyahNumber == null ? null : '$surahNumber:$initialAyahNumber';

  @override
  State<_QuranReaderView> createState() => _QuranReaderViewState();
}

class _QuranReaderViewState extends State<_QuranReaderView> {
  static const _ayahBookChunkSize = 20;

  var _itemScrollController = ItemScrollController();
  var _itemPositionsListener = ItemPositionsListener.create();
  Timer? _scrollSaveDebounce;
  Timer? _followScrollRetry;
  Timer? _jumpScrollRetry;
  Timer? _programmaticScrollTimer;
  QuranReaderState? _latestState;
  QuranAudioState? _latestAudioState;
  String? _lastFollowScrollSignature;
  int? _lastRenderedSurahNumber;
  QuranAyahTextLayout? _lastRenderedAyahLayout;
  int? _scrubberAyahNumber;
  bool _didInitialScroll = false;
  bool _didResolveInitialAudioFollow = false;
  String? _suppressedInitialAudioFocusVerseKey;
  var _programmaticScroll = false;
  var _nextSurahPullExtent = 0.0;
  var _nextSurahProgress = 0.0;
  var _queuedNextSurahProgress = 0.0;
  var _nextSurahTriggered = false;
  var _nextSurahProgressUpdateScheduled = false;
  var _nextSurahDragStartedAtBottom = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_scheduleVisibleAyahSave);
  }

  @override
  void dispose() {
    _scrollSaveDebounce?.cancel();
    _followScrollRetry?.cancel();
    _jumpScrollRetry?.cancel();
    _programmaticScrollTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _scheduleVisibleAyahSave,
    );
    super.dispose();
  }

  void _scheduleInitialScroll(QuranReaderState state) {
    final initialVerseKey = widget.initialVerseKey;
    if (_didInitialScroll || initialVerseKey == null) {
      return;
    }
    if (!state.ayahs.any((ayah) => ayah.verseKey == initialVerseKey)) {
      return;
    }
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToAyah(
        initialVerseKey,
        state: state,
        alignment: 0.08,
        duration: const Duration(milliseconds: 420),
      );
    });
  }

  String? _activeAudioVerseKey(
    QuranReaderState state,
    QuranAudioState audioState,
  ) {
    return audioState.currentItem?.verseKey ?? state.activeAudioVerseKey;
  }

  void _scheduleFollowAudioScroll({
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranThemeState themeState,
  }) {
    if (!state.followAudio) {
      return;
    }
    final verseKey = _activeAudioVerseKey(state, audioState);
    if (verseKey == null) {
      return;
    }
    final signature =
        '$verseKey-${state.ayahTextLayout}-${themeState.quranArabicFontScale}-${themeState.quranTranslationFontScale}';
    if (_lastFollowScrollSignature == signature) {
      return;
    }
    _lastFollowScrollSignature = signature;
    _scrollToAyah(verseKey, state: state);
  }

  void _scrollToAyah(
    String verseKey, {
    required QuranReaderState state,
    double alignment = 0.18,
    Duration duration = const Duration(milliseconds: 360),
    int attempt = 0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final targetIndex = _readerItemIndexForVerseKey(verseKey, state);
      if (targetIndex != null && _itemScrollController.isAttached) {
        _markProgrammaticScroll();
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: alignment,
        );
      }
      if (attempt < 8) {
        _followScrollRetry?.cancel();
        _followScrollRetry = Timer(
          const Duration(milliseconds: 100),
          () => _scrollToAyah(
            verseKey,
            state: state,
            alignment: alignment,
            duration: duration,
            attempt: attempt + 1,
          ),
        );
      }
    });
  }

  void _scheduleJumpScroll(String verseKey, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final state = _latestState;
      final hasTarget =
          state != null && state.ayahs.any((ayah) => ayah.verseKey == verseKey);
      if (hasTarget) {
        _scrollToAyah(
          verseKey,
          state: state,
          alignment: 0.1,
          duration: const Duration(milliseconds: 420),
        );
        return;
      }
      if (attempt >= 12) {
        return;
      }
      _jumpScrollRetry?.cancel();
      _jumpScrollRetry = Timer(
        const Duration(milliseconds: 80),
        () => _scheduleJumpScroll(verseKey, attempt: attempt + 1),
      );
    });
  }

  void _markProgrammaticScroll() {
    _programmaticScroll = true;
    _programmaticScrollTimer?.cancel();
    _programmaticScrollTimer = Timer(const Duration(milliseconds: 560), () {
      _programmaticScroll = false;
    });
  }

  int? _readerItemIndexForVerseKey(String verseKey, QuranReaderState state) {
    final ayahIndex = state.ayahs.indexWhere(
      (ayah) => ayah.verseKey == verseKey,
    );
    if (ayahIndex == -1) {
      return null;
    }
    if (state.ayahTextLayout == QuranAyahTextLayout.combined) {
      return 1 + (ayahIndex ~/ _ayahBookChunkSize);
    }
    return ayahIndex + 1;
  }

  void _scheduleVisibleAyahSave() {
    _scrollSaveDebounce?.cancel();
    _scrollSaveDebounce = Timer(
      const Duration(milliseconds: 420),
      _saveMostVisibleAyah,
    );
  }

  void _saveMostVisibleAyah() {
    final state = _latestState;
    if (!mounted ||
        state == null ||
        state.status != QuranReaderStatus.success ||
        state.ayahs.isEmpty ||
        _programmaticScroll) {
      return;
    }

    final visibleVerseKey = _mostVisibleVerseKey();
    _restoreFollowAudioIfActiveVisible(visibleVerseKey);
    if (visibleVerseKey == null || visibleVerseKey == state.currentVerseKey) {
      return;
    }

    QuranAyah? visibleAyah;
    for (final ayah in state.ayahs) {
      if (ayah.verseKey == visibleVerseKey) {
        visibleAyah = ayah;
        break;
      }
    }
    if (visibleAyah == null) {
      return;
    }

    context.read<QuranReaderBloc>().add(
      QuranReaderLastReadSaved(
        surahNumber: visibleAyah.surahNumber,
        ayahNumber: visibleAyah.number,
        selectAyah: false,
      ),
    );
  }

  String? _mostVisibleVerseKey() {
    final state = _latestState;
    if (state == null || state.ayahs.isEmpty) {
      return null;
    }
    final positions = _itemPositionsListener.itemPositions.value
        .where((position) => position.itemTrailingEdge > 0)
        .where((position) => position.itemLeadingEdge < 1)
        .toList(growable: false);
    if (positions.isEmpty) {
      return null;
    }
    ItemPosition? bestPosition;
    var bestVisibleExtent = 0.0;
    for (final position in positions) {
      final visibleStart = position.itemLeadingEdge.clamp(0.0, 1.0);
      final visibleEnd = position.itemTrailingEdge.clamp(0.0, 1.0);
      final visibleExtent = visibleEnd - visibleStart;
      if (visibleExtent > bestVisibleExtent) {
        bestVisibleExtent = visibleExtent;
        bestPosition = position;
      }
    }
    final itemIndex = bestPosition?.index;
    if (itemIndex == null || itemIndex <= 0) {
      return null;
    }
    final ayahIndex = state.ayahTextLayout == QuranAyahTextLayout.combined
        ? (itemIndex - 1) * _ayahBookChunkSize
        : itemIndex - 1;
    if (ayahIndex < 0 || ayahIndex >= state.ayahs.length) {
      return null;
    }
    return state.ayahs[ayahIndex].verseKey;
  }

  void _restoreFollowAudioIfActiveVisible(String? visibleVerseKey) {
    final state = _latestState;
    final audioState = _latestAudioState;
    if (!mounted ||
        state == null ||
        audioState == null ||
        state.followAudio ||
        visibleVerseKey == null) {
      return;
    }
    final activeVerseKey = _activeAudioVerseKey(state, audioState);
    if (activeVerseKey == null || activeVerseKey != visibleVerseKey) {
      return;
    }
    context.read<QuranReaderBloc>().add(
      QuranReaderFollowAudioChanged(true, verseKey: activeVerseKey),
    );
  }

  QuranAyah? _selectedAyahFor(QuranReaderState state) {
    return state.selectedAyah;
  }

  bool _isAudioVisible(QuranAudioState audioState) {
    return audioState.hasItem && audioState.status != QuranAudioStatus.idle;
  }

  bool _shouldSuppressInitialAudioFocus(
    QuranReaderState state,
    QuranAudioState audioState,
  ) {
    if (_didResolveInitialAudioFollow) {
      return false;
    }
    final audioVerseKey = audioState.currentItem?.verseKey;
    final readerVerseKey = state.currentVerseKey;
    if (readerVerseKey == null) {
      return false;
    }
    if (audioVerseKey == null) {
      _didResolveInitialAudioFollow = true;
      return false;
    }
    _didResolveInitialAudioFollow = true;
    if (audioVerseKey == readerVerseKey) {
      return false;
    }
    _suppressedInitialAudioFocusVerseKey = audioVerseKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<QuranReaderBloc>().add(
        const QuranReaderFollowAudioChanged(false),
      );
    });
    return true;
  }

  bool _shouldFocusAudioVerse({
    required String audioVerseKey,
    required QuranReaderState state,
    required bool suppressInitialAudioFocus,
  }) {
    if (suppressInitialAudioFocus) {
      return false;
    }
    final suppressedVerseKey = _suppressedInitialAudioFocusVerseKey;
    if (suppressedVerseKey != null) {
      if (audioVerseKey == suppressedVerseKey) {
        return false;
      }
      _suppressedInitialAudioFocusVerseKey = null;
    }
    return audioVerseKey != state.activeAudioVerseKey;
  }

  void _resetNextSurahPull() {
    _nextSurahPullExtent = 0;
    _nextSurahTriggered = false;
    _nextSurahDragStartedAtBottom = false;
    _setNextSurahProgress(0);
  }

  void _handleRenderedSurahChange(QuranReaderState state) {
    final surahNumber = state.surah?.number;
    final ayahLayout = state.ayahTextLayout;
    if (surahNumber == null ||
        (surahNumber == _lastRenderedSurahNumber &&
            ayahLayout == _lastRenderedAyahLayout)) {
      return;
    }
    _lastRenderedSurahNumber = surahNumber;
    _lastRenderedAyahLayout = ayahLayout;
    _itemPositionsListener.itemPositions.removeListener(
      _scheduleVisibleAyahSave,
    );
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create()
      ..itemPositions.addListener(_scheduleVisibleAyahSave);
    _followScrollRetry?.cancel();
    _lastFollowScrollSignature = null;
    _nextSurahPullExtent = 0;
    _nextSurahProgress = 0;
    _queuedNextSurahProgress = 0;
    _nextSurahTriggered = false;
    _nextSurahDragStartedAtBottom = false;
    _programmaticScroll = false;
  }

  int _scrollbarAyahNumber(QuranReaderState state) {
    final scrubberAyahNumber = _scrubberAyahNumber;
    if (scrubberAyahNumber != null) {
      return scrubberAyahNumber.clamp(1, state.ayahs.length).toInt();
    }
    final verseKey = state.currentVerseKey ?? state.selectedVerseKey;
    final ayahNumber = int.tryParse(verseKey?.split(':').last ?? '');
    if (ayahNumber != null) {
      return ayahNumber.clamp(1, state.ayahs.length).toInt();
    }
    return state.ayahs.isEmpty ? 1 : state.ayahs.first.number;
  }

  void _scrollToAyahNumberFromScrubber(
    int ayahNumber,
    QuranReaderState state, {
    bool settle = false,
  }) {
    if (state.ayahs.isEmpty) {
      return;
    }
    final normalized = ayahNumber.clamp(1, state.ayahs.length).toInt();
    setState(() => _scrubberAyahNumber = normalized);
    final ayah = state.ayahs.firstWhere(
      (ayah) => ayah.number == normalized,
      orElse: () => state.ayahs[normalized - 1],
    );
    final targetIndex = _readerItemIndexForVerseKey(ayah.verseKey, state);
    if (targetIndex != null && _itemScrollController.isAttached) {
      _markProgrammaticScroll();
      _itemScrollController.jumpTo(index: targetIndex, alignment: 0.16);
    }
    if (settle) {
      context.read<QuranReaderBloc>().add(
        QuranReaderLastReadSaved(
          surahNumber: ayah.surahNumber,
          ayahNumber: ayah.number,
          selectAyah: false,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _scrubberAyahNumber = null);
        }
      });
    }
  }

  void _updateNextSurahPull(double delta) {
    if (delta == 0) {
      return;
    }
    _nextSurahPullExtent = (_nextSurahPullExtent + delta).clamp(0.0, 140.0);
    final progress = (_nextSurahPullExtent / 88).clamp(0.0, 1.0);
    _setNextSurahProgress(progress);
  }

  void _setNextSurahProgress(double progress) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    if (!mounted) {
      return;
    }
    _queuedNextSurahProgress = normalized;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      if (_nextSurahProgress != normalized) {
        setState(() => _nextSurahProgress = normalized);
      }
      return;
    }
    if (_nextSurahProgressUpdateScheduled) {
      return;
    }
    _nextSurahProgressUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nextSurahProgressUpdateScheduled = false;
      if (!mounted || _nextSurahProgress == _queuedNextSurahProgress) {
        return;
      }
      setState(() => _nextSurahProgress = _queuedNextSurahProgress);
    });
  }

  void _goToNextSurah(QuranReaderState state) {
    final surah = state.surah;
    if (!hasNextSurah(surah)) {
      return;
    }
    _resetNextSurahPull();
    context.read<QuranReaderBloc>().add(
      QuranReaderSurahChanged(nextSurahNumber(surah!)),
    );
  }

  bool _handleAyahNextSurahScrollNotification(
    ScrollNotification notification,
    QuranReaderState state,
    QuranAudioState audioState,
  ) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        state.followAudio &&
        audioState.hasItem &&
        !_programmaticScroll) {
      context.read<QuranReaderBloc>().add(
        const QuranReaderFollowAudioChanged(false),
      );
    }
    if (!hasNextSurah(state.surah)) {
      return false;
    }
    final atBottom = notification.metrics.extentAfter <= 18;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _nextSurahDragStartedAtBottom = atBottom;
      if (!atBottom) {
        _nextSurahPullExtent = 0;
        _setNextSurahProgress(0);
      }
    }
    if (_nextSurahDragStartedAtBottom &&
        notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      final dragDelta = notification.dragDetails?.delta.dy ?? 0;
      if (dragDelta < 0) {
        _updateNextSurahPull(-dragDelta);
      } else if (dragDelta > 0) {
        _updateNextSurahPull(-dragDelta);
      }
    }
    if (_nextSurahDragStartedAtBottom &&
        notification is OverscrollNotification &&
        notification.overscroll > 0) {
      _updateNextSurahPull(notification.overscroll);
    }
    if (notification is ScrollEndNotification) {
      final shouldOpenNextSurah =
          _nextSurahPullExtent >= 88 && !_nextSurahTriggered;
      _nextSurahPullExtent = 0;
      _nextSurahDragStartedAtBottom = false;
      if (shouldOpenNextSurah) {
        _nextSurahTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _goToNextSurah(state);
          }
        });
      } else {
        _nextSurahTriggered = false;
        _setNextSurahProgress(0);
      }
    }
    return false;
  }

  Widget _buildFollowAudioChip(String activeVerseKey) {
    return ActionChip(
      avatar: const Icon(Icons.graphic_eq_rounded, size: 18),
      label: const Text('Follow audio'),
      onPressed: () {
        final state = _latestState;
        if (state == null) {
          return;
        }
        _suppressedInitialAudioFocusVerseKey = null;
        context.read<QuranReaderBloc>().add(
          QuranReaderFollowAudioChanged(true, verseKey: activeVerseKey),
        );
        _scrollToAyah(activeVerseKey, state: state);
      },
    );
  }

  Future<QuranAudioReciter?> _ensureReciter(QuranReaderState state) async {
    final repository = getIt<QuranRepository>();
    final selectedId = await repository.getSelectedAudioReciterId();
    QuranAudioReciter? selected;
    if (selectedId != null) {
      for (final reciter in state.audioReciters) {
        if (reciter.id == selectedId) {
          selected = reciter;
          break;
        }
      }
    }
    selected ??= state.selectedAudioReciter;
    if (selected != null) {
      return selected;
    }
    if (state.audioReciters.isEmpty) {
      return null;
    }
    if (!mounted) {
      return null;
    }
    final picked = await showQuranReciterPickerSheet(
      context,
      reciters: state.audioReciters,
      selectedReciterId: null,
      title: 'Choose reciter',
    );
    if (picked == null || !mounted) {
      return null;
    }
    context.read<QuranReaderBloc>().add(
      QuranReaderAudioReciterSelected(picked.id),
    );
    return picked;
  }

  Future<void> _playSelectedToEnd({
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranAyah ayah,
  }) async {
    final audioCubit = context.read<QuranAudioCubit>();
    final readerBloc = context.read<QuranReaderBloc>();
    final isActive =
        audioState.currentItem?.verseKey == ayah.verseKey &&
        audioState.hasItem &&
        audioState.status != QuranAudioStatus.completed;
    if (isActive) {
      await audioCubit.togglePlayPause();
      if (mounted) {
        readerBloc.add(const QuranReaderSelectionCleared());
      }
      return;
    }
    final reciter = await _ensureReciter(state);
    if (reciter == null || !mounted) {
      return;
    }
    final surah = await getIt<QuranRepository>().getSurah(ayah.surahNumber);
    if (!mounted) {
      return;
    }
    readerBloc.add(
      QuranReaderLastReadSaved(
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.number,
      ),
    );
    await audioCubit.playFromAyahToSurahEnd(
      ayah: ayah,
      surah: surah,
      reciter: reciter,
    );
    if (mounted) {
      readerBloc.add(const QuranReaderSelectionCleared());
      readerBloc.add(const QuranReaderFollowAudioChanged(true));
    }
  }

  Future<void> _showReaderSettings({
    required QuranReaderState state,
    required QuranThemeState themeState,
  }) {
    final readerBloc = context.read<QuranReaderBloc>();
    final themeCubit = context.read<QuranThemeCubit>();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reader settings',
      barrierColor: Colors.black.withValues(alpha: 0.16),
      useRootNavigator: false,
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final size = MediaQuery.sizeOf(dialogContext);
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 66, 12, 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: size.height * 0.70,
                ),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<QuranReaderBloc>.value(value: readerBloc),
                    BlocProvider<QuranThemeCubit>.value(value: themeCubit),
                  ],
                  child: Material(
                    color: Colors.transparent,
                    child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                      builder: (context, readerState) {
                        return BlocBuilder<QuranThemeCubit, QuranThemeState>(
                          builder: (context, liveThemeState) {
                            return PremiumSurface(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                16,
                              ),
                              radius: QuranTheme.radiusSheet,
                              prominent: true,
                              child: _ReaderSettingsSheet(
                                state: readerState,
                                themeState: liveThemeState,
                                tafsirLanguageName:
                                    getIt.isRegistered<SettingsStore>()
                                    ? getIt<SettingsStore>().tafsirLanguageName
                                    : 'english',
                                onAyahLayoutChanged: (layout) {
                                  unawaited(
                                    _changeAyahLayout(
                                      settingsContext: context,
                                      readerState: readerState,
                                      layout: layout,
                                    ),
                                  );
                                },
                                onTranslationTap: () {
                                  _showTranslationPicker(
                                    readerBloc: context.read<QuranReaderBloc>(),
                                    readerState: readerState,
                                  );
                                },
                                onTafsirLanguageTap: () {
                                  unawaited(_showTafsirPicker());
                                },
                                onContentSourcesTap: () {
                                  unawaited(
                                    _showContentSources(
                                      readerState.contentSources,
                                    ),
                                  );
                                },
                                onTranslationSwitchChanged: (enabled) {
                                  if (enabled &&
                                      readerState.selectedTranslation == null) {
                                    _showTranslationPicker(
                                      readerBloc: context
                                          .read<QuranReaderBloc>(),
                                      readerState: readerState,
                                    );
                                    return;
                                  }
                                  if (readerState.showTranslation != enabled) {
                                    context.read<QuranReaderBloc>().add(
                                      const QuranReaderTranslationToggled(),
                                    );
                                  }
                                },
                                onFollowAudioChanged: (enabled) {
                                  context.read<QuranReaderBloc>().add(
                                    QuranReaderFollowAudioChanged(
                                      enabled,
                                      verseKey:
                                          _latestAudioState
                                              ?.currentItem
                                              ?.verseKey ??
                                          readerState.activeAudioVerseKey,
                                    ),
                                  );
                                },
                                onClose: () => Navigator.of(context).pop(),
                                onFontScaleChanged: (value) {
                                  context
                                      .read<QuranThemeCubit>()
                                      .setQuranArabicFontScale(value);
                                },
                                onTranslationFontScaleChanged: (value) {
                                  context
                                      .read<QuranThemeCubit>()
                                      .setQuranTranslationFontScale(value);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContentSources(List<ContentSource> sources) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quran content sources',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Edition, attribution, license status, and offline cache policy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: sources.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    final maxAge = source.cachePolicy.maxAge;
                    final details = <String>[
                      if (source.edition?.trim().isNotEmpty == true)
                        source.edition!,
                      if (source.provider?.trim().isNotEmpty == true)
                        source.provider!,
                      if (source.license?.trim().isNotEmpty == true)
                        source.license!,
                      if (maxAge != null)
                        'Offline cache: up to ${maxAge.inDays} days',
                      source.reviewStatus == ContentReviewStatus.approved
                          ? 'Release review: approved'
                          : 'Release review: required',
                    ];
                    return PremiumSurface(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            details.join('\n'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: QuranTheme.subText(context, 0.72),
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            source.attribution,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTafsirPicker() async {
    if (!getIt.isRegistered<QuranTafsirRepository>() ||
        !getIt.isRegistered<SettingsStore>()) {
      return;
    }
    final resources = await getIt<QuranTafsirRepository>().tafsirResources();
    if (!mounted) {
      return;
    }
    final selected = await showModalBottomSheet<QuranTafsirResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Text(
              'Select tafsir edition',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            for (final resource in resources)
              ListTile(
                title: Text(resource.name),
                subtitle: Text(
                  [
                    resource.displayLanguage,
                    if (resource.authorName.trim().isNotEmpty)
                      resource.authorName,
                  ].join(' • '),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(resource),
              ),
          ],
        ),
      ),
    );
    if (selected == null) {
      return;
    }
    await getIt<SettingsStore>().setTafsirPreference(
      languageName: selected.languageName,
      resourceId: selected.id,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selected.displayLanguage} tafsir selected independently.',
          ),
        ),
      );
    }
  }

  Future<void> _showTranslationPicker({
    required QuranReaderBloc readerBloc,
    required QuranReaderState readerState,
  }) async {
    final repository = getIt<QuranTranslationRepository>();
    final result = await showModalBottomSheet<_TranslationPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TranslationPickerSheet(
        repository: repository,
        currentResource: readerState.selectedTranslation,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    final selected = result.resource;
    if (selected == null) {
      return;
    }
    if (!await repository.hasFullTranslation(selected.id)) {
      if (!mounted) {
        return;
      }
      final downloaded = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        builder: (context) => _TranslationDownloadSheet(
          repository: repository,
          resource: selected,
        ),
      );
      if (!mounted || downloaded != true) {
        return;
      }
    }
    await _ensureBookLineTranslationCache(
      readerState: readerState,
      resource: selected,
    );
    readerBloc.add(QuranReaderTranslationSelected(selected.id));
  }

  Future<void> _changeAyahLayout({
    required BuildContext settingsContext,
    required QuranReaderState readerState,
    required QuranAyahTextLayout layout,
  }) async {
    if (layout == QuranAyahTextLayout.combined &&
        readerState.showTranslation &&
        readerState.selectedTranslation != null) {
      final downloaded = await _ensureBookLineTranslationCache(
        readerState: readerState,
        resource: readerState.selectedTranslation!,
        targetLayout: layout,
      );
      if (downloaded && mounted && settingsContext.mounted) {
        final code =
            readerState.selectedTranslation!.wordTranslationLanguageCode;
        if (code != null) {
          settingsContext.read<QuranReaderBloc>().add(
            QuranReaderInterlinearCacheCompleted(languageCode: code),
          );
        }
      }
    }
    if (!mounted || !settingsContext.mounted) {
      return;
    }
    settingsContext.read<QuranReaderBloc>().add(
      QuranReaderAyahTextLayoutChanged(layout),
    );
  }

  Future<bool> _ensureBookLineTranslationCache({
    required QuranReaderState readerState,
    required QuranTranslationResource resource,
    Object? targetLayout,
  }) async {
    final effectiveLayout = targetLayout ?? readerState.ayahTextLayout;
    if (effectiveLayout != QuranAyahTextLayout.combined) {
      return false;
    }
    final languageCode = resource.wordTranslationLanguageCode;
    if (languageCode == null) {
      return false;
    }
    final repository = getIt<QuranInterlinearRepository>();
    if (await repository.hasFullCache(language: languageCode)) {
      return true;
    }
    if (!mounted) {
      return false;
    }
    final downloaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => _InterlinearWordsDownloadSheet(
        repository: repository,
        languageCode: languageCode,
        languageLabel: resource.displayLanguage,
      ),
    );
    return downloaded == true;
  }

  Future<void> _showPlaybackRangeSheet({
    required QuranReaderState state,
    required QuranAudioState audioState,
  }) {
    final currentRange = audioState.scopeLabel.trim().isEmpty
        ? 'No active range'
        : audioState.scopeLabel;

    return showQuranPlaybackSettingsSheet(
      context: context,
      audioState: audioState,
      reciters: state.audioReciters,
      selectedReciter: state.selectedAudioReciter,
      selectedTranslation: state.selectedTranslation,
      audioMeaningLanguageCode: getIt.isRegistered<SettingsStore>()
          ? getIt<SettingsStore>().audioMeaningLanguageCodeOrNull
          : null,
      currentRangeLabel: currentRange,
      onReciterSelected: (selected) async {
        if (!mounted) {
          return;
        }
        await getIt<QuranRepository>().saveSelectedAudioReciterId(selected.id);
        if (!mounted) {
          return;
        }
        context.read<QuranReaderBloc>().add(
          QuranReaderAudioReciterSelected(selected.id),
        );
        if (audioState.hasItem) {
          await context.read<QuranAudioCubit>().changeReciter(selected.id);
        }
      },
    );
  }

  Future<void> _showTafsirSheet(
    BuildContext context, {
    required QuranAyah ayah,
    required QuranReaderState readerState,
  }) async {
    final tafsirLanguage = getIt.isRegistered<SettingsStore>()
        ? getIt<SettingsStore>().tafsirLanguageName
        : 'english';
    final tafsirLanguageLabel = _displayLanguageName(tafsirLanguage);
    final tafsirFuture = _loadTafsirDisplayData(ayah: ayah);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: PremiumSurface(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            radius: QuranTheme.radiusSheet,
            prominent: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                Text(
                  'Tafsir ${ayah.verseKey}',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                FutureBuilder<_TafsirDisplayData>(
                  future: tafsirFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return _TafsirLoadingView(
                        languageLabel: tafsirLanguageLabel,
                      );
                    }
                    final data = snapshot.data;
                    if (data == null || data.text.trim().isEmpty) {
                      return _TafsirUnavailableView(
                        languageLabel: tafsirLanguageLabel,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TafsirSourcePill(data: data),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.sizeOf(sheetContext).height * 0.54,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              data.text,
                              textDirection: data.textDirection,
                              textAlign: data.textAlign,
                              style: Theme.of(sheetContext).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 1.8,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_TafsirDisplayData> _loadTafsirDisplayData({
    required QuranAyah ayah,
  }) async {
    final preferredLanguage = getIt.isRegistered<SettingsStore>()
        ? getIt<SettingsStore>().tafsirLanguageName
        : 'english';
    final preferredResourceId = getIt.isRegistered<SettingsStore>()
        ? getIt<SettingsStore>().tafsirResourceId
        : null;
    final preferredLanguageLabel = _displayLanguageName(preferredLanguage);
    final preferred = await _remoteTafsirFor(
      verseKey: ayah.verseKey,
      languageName: preferredLanguage,
      requestedLanguageLabel: preferredLanguageLabel,
      resourceId: preferredResourceId,
    );
    if (preferred != null) {
      return preferred;
    }

    final fallbackEnglish = preferredLanguage.toLowerCase() == 'english'
        ? null
        : await _remoteTafsirFor(
            verseKey: ayah.verseKey,
            languageName: 'english',
            requestedLanguageLabel: preferredLanguageLabel,
          );
    if (fallbackEnglish != null) {
      return fallbackEnglish;
    }

    final localTafsir = ayah.tafsir?.trim();
    if (localTafsir != null && localTafsir.isNotEmpty) {
      return _TafsirDisplayData(
        text: localTafsir,
        sourceLabel: 'Offline default tafsir',
        detailLabel: preferredLanguage.toLowerCase() == 'arabic'
            ? 'Showing bundled Arabic tafsir'
            : '$preferredLanguageLabel tafsir is not available yet',
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      );
    }

    return const _TafsirDisplayData.empty();
  }

  String _displayLanguageName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'English';
    }
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  Future<_TafsirDisplayData?> _remoteTafsirFor({
    required String verseKey,
    required String? languageName,
    required String? requestedLanguageLabel,
    int? resourceId,
  }) async {
    if (!getIt.isRegistered<QuranTafsirRepository>()) {
      return null;
    }
    try {
      final repository = getIt<QuranTafsirRepository>();
      final result =
          resourceId != null && repository is QuranTafsirEditionRepository
          ? await (repository as QuranTafsirEditionRepository)
                .tafsirForVerseByResource(
                  verseKey: verseKey,
                  resourceId: resourceId,
                )
          : await repository.tafsirForVerse(
              verseKey: verseKey,
              languageName: languageName,
            );
      if (result == null || result.text.trim().isEmpty) {
        return null;
      }
      final requested = requestedLanguageLabel?.trim();
      final detail =
          requested != null &&
              requested.isNotEmpty &&
              requested.toLowerCase() !=
                  result.resource.displayLanguage.toLowerCase()
          ? '$requested tafsir is not available yet. Showing ${result.resource.displayLanguage}.'
          : '${result.resource.displayLanguage} tafsir';
      return _TafsirDisplayData(
        text: result.text.trim(),
        sourceLabel: result.resource.name,
        detailLabel: detail,
        textDirection: result.resource.textDirection,
        textAlign: result.resource.textAlign,
        resource: result.resource,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildReaderChrome({
    required BuildContext context,
    required QuranReaderState state,
    required QuranThemeState themeState,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        _ReaderTopBar(
          title: title,
          subtitle: subtitle,
          onTitleTap: () =>
              _showSurahSwitcherMenu(context: context, state: state),
          onSettingsTap: () =>
              _showReaderSettings(state: state, themeState: themeState),
        ),
      ],
    );
  }

  Future<void> _showSurahSwitcherMenu({
    required BuildContext context,
    required QuranReaderState state,
  }) async {
    final currentSurah = state.surah;
    if (currentSurah == null) {
      return;
    }
    final surahs = await getIt<QuranRepository>().getSurahs();
    if (!mounted || !context.mounted || surahs.isEmpty) {
      return;
    }
    final readerContext = context;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Surah switcher',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(52, 62, 52, 0),
              child: _SurahSwitcherDialog(
                surahs: surahs,
                currentSurah: currentSurah,
                onSurahSelected: (surahNumber, {ayahNumber}) {
                  _resetNextSurahPull();
                  if (ayahNumber != null) {
                    _scrollSaveDebounce?.cancel();
                    _markProgrammaticScroll();
                  }
                  readerContext.read<QuranReaderBloc>().add(
                    QuranReaderSurahChanged(
                      surahNumber,
                      initialAyahNumber: ayahNumber,
                    ),
                  );
                  if (ayahNumber != null) {
                    _scheduleJumpScroll('$surahNumber:$ayahNumber');
                  }
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildAyahMode({
    required BuildContext context,
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranThemeState themeState,
    required AppLocalizations l10n,
    required QuranSurah? surah,
    required QuranReaderBottomInsets insets,
  }) {
    if (state.ayahTextLayout == QuranAyahTextLayout.combined) {
      return _buildAyahBookMode(
        context: context,
        state: state,
        audioState: audioState,
        themeState: themeState,
        surah: surah,
        insets: insets,
      );
    }
    final showNextCapsule = hasNextSurah(state.surah);
    final activeVerseKey = _activeAudioVerseKey(state, audioState);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleAyahNextSurahScrollNotification(
        notification,
        state,
        audioState,
      ),
      child: Stack(
        children: [
          ScrollablePositionedList.builder(
            key: ValueKey('ayah-separated-${state.surah?.number}'),
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(18, 8, 18, insets.contentBottom),
            itemCount: state.ayahs.length + 1 + (showNextCapsule ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ReaderHeader(
                    arabicName: surah?.arabicName ?? '',
                    verseCount: surah?.ayahCount ?? state.ayahs.length,
                  ),
                );
              }
              final ayahIndex = index - 1;
              if (ayahIndex >= state.ayahs.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: NextSurahCapsule(
                    progress: _nextSurahProgress,
                    onTap: () => _goToNextSurah(state),
                  ),
                );
              }
              final ayah = state.ayahs[ayahIndex];
              final selectedTranslation =
                  state.translationsByVerse[ayah.verseKey];
              final isCurrentAudio =
                  audioState.currentItem?.verseKey == ayah.verseKey &&
                  audioState.status != QuranAudioStatus.completed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: KeyedSubtree(
                  key: ValueKey('ayah-card-${ayah.verseKey}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StructureMarkers(ayahs: [ayah]),
                      _AyahCard(
                        ayah: ayah,
                        translation: selectedTranslation ?? ayah.translation,
                        translationResource: selectedTranslation == null
                            ? null
                            : state.selectedTranslation,
                        additionalTranslations: [
                          for (final resource
                              in state.selectedTranslations.skip(1))
                            if (state
                                    .translationsByResource[resource.id]?[ayah
                                        .verseKey]
                                    ?.trim()
                                    .isNotEmpty ==
                                true)
                              _DisplayedTranslation(
                                text:
                                    state.translationsByResource[resource
                                        .id]![ayah.verseKey]!,
                                resource: resource,
                              ),
                        ],
                        arabicFontScale: themeState.quranArabicFontScale,
                        translationFontScale:
                            themeState.quranTranslationFontScale,
                        showTranslation: state.showTranslation,
                        activeWordIndex:
                            audioState.activeWordVerseKey == ayah.verseKey
                            ? audioState.activeWordIndex
                            : null,
                        isAudioActive: isCurrentAudio,
                        isSelected: state.selectedVerseKey == ayah.verseKey,
                        isCurrentLastRead:
                            state.currentVerseKey == ayah.verseKey,
                        isBookmarked: state.bookmarkedVerseKeys.contains(
                          ayah.verseKey,
                        ),
                        onSelect: () => context.read<QuranReaderBloc>().add(
                          QuranReaderAyahSelected(
                            surahNumber: ayah.surahNumber,
                            ayahNumber: ayah.number,
                          ),
                        ),
                        onBookmarkToggle: () =>
                            context.read<QuranReaderBloc>().add(
                              QuranReaderBookmarkToggled(
                                surahNumber: ayah.surahNumber,
                                ayahNumber: ayah.number,
                              ),
                            ),
                        bookmarkTooltip: l10n.bookmarkAyahTooltip,
                        removeBookmarkTooltip: l10n.removeBookmarkTooltip,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (!state.followAudio && activeVerseKey != null)
            Positioned(
              top: 12,
              right: 18,
              child: _buildFollowAudioChip(activeVerseKey),
            ),
        ],
      ),
    );
  }

  Widget _buildAyahBookMode({
    required BuildContext context,
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranThemeState themeState,
    required QuranSurah? surah,
    required QuranReaderBottomInsets insets,
  }) {
    final showNextCapsule = hasNextSurah(state.surah);
    final activeVerseKey = _activeAudioVerseKey(state, audioState);
    final activeAudioVerseKey = audioState.status == QuranAudioStatus.completed
        ? null
        : activeVerseKey;
    final bookChunks = _ayahBookChunks(state.ayahs);
    final bookWordsByVerse = _surahBookWordsByVerse(state);
    final itemCount = 1 + bookChunks.length + (showNextCapsule ? 1 : 0);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleAyahNextSurahScrollNotification(
        notification,
        state,
        audioState,
      ),
      child: Stack(
        children: [
          ScrollablePositionedList.builder(
            key: ValueKey('ayah-combined-${state.surah?.number}'),
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(4, 0, 18, insets.contentBottom),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ReaderHeader(
                    arabicName: surah?.arabicName ?? '',
                    verseCount: surah?.ayahCount ?? state.ayahs.length,
                  ),
                );
              }
              final chunkIndex = index - 1;
              if (chunkIndex >= bookChunks.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: NextSurahCapsule(
                    progress: _nextSurahProgress,
                    onTap: () => _goToNextSurah(state),
                  ),
                );
              }
              final chunkAyahs = bookChunks[chunkIndex];
              final chunkWords = chunkAyahs
                  .expand((ayah) => bookWordsByVerse[ayah.verseKey] ?? const [])
                  .cast<QuranWord>()
                  .toList(growable: false);
              return _CombinedAyahChunkSurface(
                first: chunkIndex == 0,
                last: chunkIndex == bookChunks.length - 1,
                prominent:
                    state.selectedVerseKey != null ||
                    activeAudioVerseKey != null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StructureMarkers(ayahs: chunkAyahs),
                    CombinedPageText(
                      ayahs: chunkAyahs,
                      pageWords: chunkWords,
                      selectedVerseKey: state.selectedVerseKey,
                      activeAudioVerseKey: activeAudioVerseKey,
                      activeWordVerseKey: audioState.activeWordVerseKey,
                      activeWordIndex: audioState.activeWordIndex,
                      currentVerseKey: state.currentVerseKey,
                      arabicFontScale: themeState.quranArabicFontScale,
                      translationFontScale:
                          themeState.quranTranslationFontScale,
                      showTranslation: state.showTranslation,
                      translationsByVerse: state.translationsByVerse,
                      selectedTranslation: state.selectedTranslation,
                      selectionEnabled: true,
                      onAyahTap: (ayah) {
                        context.read<QuranReaderBloc>().add(
                          QuranReaderAyahSelected(
                            surahNumber: ayah.surahNumber,
                            ayahNumber: ayah.number,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          if (!state.followAudio && activeVerseKey != null)
            Positioned(
              top: 12,
              right: 18,
              child: _buildFollowAudioChip(activeVerseKey),
            ),
        ],
      ),
    );
  }

  List<List<QuranAyah>> _ayahBookChunks(List<QuranAyah> ayahs) {
    if (ayahs.isEmpty) {
      return const [];
    }
    return [
      for (var index = 0; index < ayahs.length; index += _ayahBookChunkSize)
        ayahs.skip(index).take(_ayahBookChunkSize).toList(growable: false),
    ];
  }

  Map<String, List<QuranWord>> _surahBookWordsByVerse(QuranReaderState state) {
    final surahNumber = state.surah?.number;
    if (surahNumber == null) {
      return const {};
    }
    final entries = state.pageWordsByPage.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final wordsByVerse = <String, List<QuranWord>>{};
    for (final word in entries.expand((entry) => entry.value)) {
      if (!word.verseKey.startsWith('$surahNumber:')) {
        continue;
      }
      wordsByVerse.putIfAbsent(word.verseKey, () => []).add(word);
    }
    return wordsByVerse;
  }

  Widget _buildFloatingControls({
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranAyah? selectedAyah,
    required double arabicFontScale,
    required double bottom,
  }) {
    if (selectedAyah == null && !_isAudioVisible(audioState)) {
      return const SizedBox.shrink();
    }
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: 12,
      right: 12,
      bottom: bottom,
      child: QuranReaderFloatingControls(
        selectedAyah: selectedAyah,
        audioState: audioState,
        showTranslation: state.showTranslation,
        isBookmarked:
            selectedAyah != null &&
            state.bookmarkedVerseKeys.contains(selectedAyah.verseKey),
        arabicFontScale: arabicFontScale,
        onPrimaryPlay: selectedAyah == null
            ? () {}
            : () => _playSelectedToEnd(
                state: state,
                audioState: audioState,
                ayah: selectedAyah,
              ),
        onPlaySelected: selectedAyah == null
            ? null
            : () => _playSelectedToEnd(
                state: state,
                audioState: audioState,
                ayah: selectedAyah,
              ),
        onStop: () => context.read<QuranAudioCubit>().stopAndClear(),
        onBookmark: selectedAyah == null
            ? () {}
            : () => context.read<QuranReaderBloc>().add(
                QuranReaderBookmarkToggled(
                  surahNumber: selectedAyah.surahNumber,
                  ayahNumber: selectedAyah.number,
                ),
              ),
        onTafsir: selectedAyah != null
            ? () => _showTafsirSheet(
                context,
                ayah: selectedAyah,
                readerState: state,
              )
            : null,
        onNote: selectedAyah == null
            ? null
            : () => _editAyahNote(selectedAyah, state),
        onShare: selectedAyah == null
            ? null
            : () => _showAyahShareSheet(selectedAyah, state),
        onPlaybackMenu: selectedAyah == null
            ? () {}
            : () =>
                  _showPlaybackRangeSheet(state: state, audioState: audioState),
        onPrevious: context.read<QuranAudioCubit>().skipPrevious,
        onTogglePlayPause: audioState.status == QuranAudioStatus.completed
            ? context.read<QuranAudioCubit>().replayQueue
            : context.read<QuranAudioCubit>().togglePlayPause,
        onNext: context.read<QuranAudioCubit>().skipNext,
        onSeek: context.read<QuranAudioCubit>().seek,
      ),
    );
  }

  Future<void> _editAyahNote(
    QuranAyah ayah,
    QuranReaderState readerState,
  ) async {
    if (!getIt.isRegistered<QuranUserDataStore>()) {
      return;
    }
    final store = getIt<QuranUserDataStore>();
    QuranNote? existing;
    for (final note in store.notes) {
      if (note.verseKey == ayah.verseKey) {
        existing = note;
        break;
      }
    }
    final controller = TextEditingController(text: existing?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for ayah ${ayah.verseKey}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Write a private reflection or study note',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) {
      return;
    }
    await store.saveNote(
      id: existing?.id,
      text: text,
      verseKey: ayah.verseKey,
      translationResourceId: readerState.selectedTranslation?.id,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayah note saved privately.')),
      );
    }
  }

  Future<void> _showAyahShareSheet(
    QuranAyah ayah,
    QuranReaderState readerState,
  ) async {
    final resource = readerState.selectedTranslation;
    final selectedText = readerState.translationsByVerse[ayah.verseKey];
    final translation = selectedText ?? ayah.translation;
    final translationResource = selectedText == null ? null : resource;
    final repaintKey = GlobalKey();
    var includeArabic = true;
    var includeTranslation = translation.trim().isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final shareText = _ayahShareText(
            ayah: ayah,
            surahName: readerState.surah?.englishName ?? 'Quran',
            translation: translation,
            translationResource: translationResource,
            includeArabic: includeArabic,
            includeTranslation: includeTranslation,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share ayah ${ayah.verseKey}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                RepaintBoundary(
                  key: repaintKey,
                  child: _AyahShareCard(
                    ayah: ayah,
                    surahName: readerState.surah?.englishName ?? 'Quran',
                    translation: translation,
                    translationResource: translationResource,
                    includeArabic: includeArabic,
                    includeTranslation: includeTranslation,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: includeArabic,
                  onChanged: (value) {
                    setSheetState(() => includeArabic = value ?? true);
                  },
                  title: const Text('Include Arabic'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: includeTranslation,
                  onChanged: translation.trim().isEmpty
                      ? null
                      : (value) {
                          setSheetState(
                            () => includeTranslation = value ?? false,
                          );
                        },
                  title: const Text('Include translation'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: shareText.trim().isEmpty
                      ? null
                      : () => _shareAyahText(sheetContext, shareText, ayah),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share text'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: shareText.trim().isEmpty
                      ? null
                      : () => _shareAyahCard(
                          sheetContext,
                          repaintKey,
                          shareText,
                          ayah,
                        ),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Share card'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _ayahShareText({
    required QuranAyah ayah,
    required String surahName,
    required String translation,
    required QuranTranslationResource? translationResource,
    required bool includeArabic,
    required bool includeTranslation,
  }) {
    final parts = <String>[
      if (includeArabic) ayah.text.trim(),
      if (includeTranslation && translation.trim().isNotEmpty)
        translation.trim(),
      '$surahName ${ayah.verseKey}',
      if (includeTranslation && translationResource != null)
        'Translation: ${translationResource.name}${translationResource.authorName.trim().isEmpty ? '' : ' by ${translationResource.authorName}'}',
    ];
    return parts.where((part) => part.isNotEmpty).join('\n\n');
  }

  Future<void> _shareAyahText(
    BuildContext shareContext,
    String text,
    QuranAyah ayah,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: 'Quran ${ayah.verseKey}',
        sharePositionOrigin: _shareOrigin(shareContext),
      ),
    );
  }

  Future<void> _shareAyahCard(
    BuildContext shareContext,
    GlobalKey repaintKey,
    String text,
    QuranAyah ayah,
  ) async {
    final shareOrigin = _shareOrigin(shareContext);
    final boundary = repaintKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return;
    }
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/quran_${ayah.surahNumber}_${ayah.number}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        title: 'Quran ${ayah.verseKey}',
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  Rect? _shareOrigin(BuildContext context) {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) {
      return null;
    }
    return renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<QuranReaderBloc, QuranReaderState>(
      builder: (context, state) {
        _latestState = state;
        _handleRenderedSurahChange(state);
        final surah = state.surah;
        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                top: true,
                bottom: false,
                child: switch (state.status) {
                  QuranReaderStatus.initial || QuranReaderStatus.loading =>
                    AppLoadingView(label: l10n.loadingQuran),
                  QuranReaderStatus.failure => AppErrorView(
                    title: l10n.quranLoadFailedTitle,
                    message: state.errorMessage ?? l10n.quranLoadFailedMessage,
                    onRetry: () => context.read<QuranReaderBloc>().add(
                      QuranReaderStarted(
                        surahNumber: widget.surahNumber,
                        initialAyahNumber: widget.initialAyahNumber,
                      ),
                    ),
                  ),
                  QuranReaderStatus.success =>
                    BlocBuilder<QuranAudioCubit, QuranAudioState>(
                      buildWhen: (previous, next) {
                        return previous.currentItem?.verseKey !=
                                next.currentItem?.verseKey ||
                            previous.status != next.status ||
                            previous.queue.length != next.queue.length ||
                            previous.currentIndex != next.currentIndex ||
                            previous.position != next.position ||
                            previous.bufferedPosition !=
                                next.bufferedPosition ||
                            previous.duration != next.duration ||
                            previous.activeWordVerseKey !=
                                next.activeWordVerseKey ||
                            previous.activeWordIndex != next.activeWordIndex;
                      },
                      builder: (context, audioState) {
                        _latestAudioState = audioState;
                        final audioVerseKey = audioState.currentItem?.verseKey;
                        final suppressInitialAudioFocus =
                            _shouldSuppressInitialAudioFocus(state, audioState);
                        if (audioVerseKey != null &&
                            _shouldFocusAudioVerse(
                              audioVerseKey: audioVerseKey,
                              state: state,
                              suppressInitialAudioFocus:
                                  suppressInitialAudioFocus,
                            )) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) {
                              return;
                            }
                            context.read<QuranReaderBloc>().add(
                              QuranReaderAudioVerseFocused(audioVerseKey),
                            );
                          });
                        }
                        return BlocBuilder<QuranThemeCubit, QuranThemeState>(
                          builder: (context, themeState) {
                            final selectedAyah = _selectedAyahFor(state);
                            final insets = QuranReaderBottomInsets.resolve(
                              context,
                              audioVisible: _isAudioVisible(audioState),
                              hasSelection: selectedAyah != null,
                            );
                            if (!suppressInitialAudioFocus) {
                              _scheduleFollowAudioScroll(
                                state: state,
                                audioState: audioState,
                                themeState: themeState,
                              );
                            }
                            _scheduleInitialScroll(state);
                            final reader = _buildAyahMode(
                              context: context,
                              state: state,
                              audioState: audioState,
                              themeState: themeState,
                              l10n: l10n,
                              surah: surah,
                              insets: insets,
                            );
                            return Column(
                              children: [
                                _buildReaderChrome(
                                  context: context,
                                  state: state,
                                  themeState: themeState,
                                  title:
                                      surah?.englishName ??
                                      l10n.quranReaderTitle,
                                  subtitle: _surahSubtitle(
                                    surah?.number,
                                    surah?.revelationType,
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(child: reader),
                                      _AyahScrollbar(
                                        ayahCount: state.ayahs.length,
                                        currentAyahNumber: _scrollbarAyahNumber(
                                          state,
                                        ),
                                        onAyahNumberChanged: (ayahNumber) =>
                                            _scrollToAyahNumberFromScrubber(
                                              ayahNumber,
                                              state,
                                            ),
                                        onAyahNumberSettled: (ayahNumber) =>
                                            _scrollToAyahNumberFromScrubber(
                                              ayahNumber,
                                              state,
                                              settle: true,
                                            ),
                                      ),
                                      _buildFloatingControls(
                                        state: state,
                                        audioState: audioState,
                                        selectedAyah: selectedAyah,
                                        arabicFontScale:
                                            themeState.quranArabicFontScale,
                                        bottom: insets.actionBarBottom,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AyahShareCard extends StatelessWidget {
  const _AyahShareCard({
    required this.ayah,
    required this.surahName,
    required this.translation,
    required this.translationResource,
    required this.includeArabic,
    required this.includeTranslation,
  });

  final QuranAyah ayah;
  final String surahName;
  final String translation;
  final QuranTranslationResource? translationResource;
  final bool includeArabic;
  final bool includeTranslation;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuranTheme.softFill(context, primary),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$surahName • ${ayah.verseKey}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (includeArabic) ...[
            const SizedBox(height: 18),
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                height: 1.9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (includeTranslation && translation.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              translation.trim(),
              textDirection: translationResource?.textDirection,
              textAlign: translationResource?.textAlign,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              translationResource == null
                  ? 'Bundled English translation'
                  : '${translationResource!.name}${translationResource!.authorName.trim().isEmpty ? '' : ' • ${translationResource!.authorName}'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Quran',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahScrollbar extends StatefulWidget {
  const _AyahScrollbar({
    required this.ayahCount,
    required this.currentAyahNumber,
    required this.onAyahNumberChanged,
    required this.onAyahNumberSettled,
  });

  final int ayahCount;
  final int currentAyahNumber;
  final ValueChanged<int> onAyahNumberChanged;
  final ValueChanged<int> onAyahNumberSettled;

  @override
  State<_AyahScrollbar> createState() => _AyahScrollbarState();
}

class _AyahScrollbarState extends State<_AyahScrollbar> {
  Timer? _previewTimer;
  int? _previewAyahNumber;
  var _isInteracting = false;

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  int _ayahForOffset(double dy, double height) {
    if (widget.ayahCount <= 1 || height <= 0) {
      return 1;
    }
    final progress = (dy / height).clamp(0.0, 1.0);
    return 1 + (progress * (widget.ayahCount - 1)).round();
  }

  void _showPreview(int ayahNumber, {bool interacting = true}) {
    _previewTimer?.cancel();
    setState(() {
      _isInteracting = interacting;
      _previewAyahNumber = ayahNumber;
    });
  }

  void _hidePreviewSoon() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 760), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInteracting = false;
        _previewAyahNumber = null;
      });
    });
  }

  void _changeAyah(int ayahNumber) {
    _showPreview(ayahNumber);
    widget.onAyahNumberChanged(ayahNumber);
  }

  void _settleAyah(int ayahNumber) {
    _showPreview(ayahNumber, interacting: false);
    widget.onAyahNumberSettled(ayahNumber);
    _hidePreviewSoon();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ayahCount <= 1) {
      return const SizedBox.shrink();
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    const scrollbarHeightFactor = 0.44;
    const readerAppBarHeight = 66.0;
    final scrollbarHeight = screenHeight * scrollbarHeightFactor;
    final screenCenteredTop = (screenHeight - scrollbarHeight) / 2;
    final topOffset = screenCenteredTop - topSafeArea - readerAppBarHeight;
    return PositionedDirectional(
      end: 2,
      top: topOffset,
      width: 14,
      height: scrollbarHeight,
      child: Tooltip(
        message: 'Jump to ayah',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            const dropHeight = 44.0;
            const trackWidth = 9.0;
            const thumbSize = 7.0;
            const thumbInset = (trackWidth - thumbSize) / 2;
            final visibleAyah = _previewAyahNumber ?? widget.currentAyahNumber;
            final progress =
                ((widget.currentAyahNumber - 1) / (widget.ayahCount - 1))
                    .clamp(0.0, 1.0)
                    .toDouble();
            final top =
                ((visibleAyah - 1) / (widget.ayahCount - 1)) *
                (height - dropHeight).clamp(0.0, double.infinity);
            final thumbTop =
                progress * (height - thumbSize).clamp(0.0, double.infinity);
            final showDrop = _isInteracting || _previewAyahNumber != null;
            final primary = Theme.of(context).colorScheme.primary;
            final isDark = QuranTheme.isDark(context);
            return Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: height,
                width: 14,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    final ayahNumber = _ayahForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _settleAyah(ayahNumber);
                  },
                  onVerticalDragStart: (details) {
                    final ayahNumber = _ayahForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _changeAyah(ayahNumber);
                  },
                  onVerticalDragUpdate: (details) {
                    final ayahNumber = _ayahForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _changeAyah(ayahNumber);
                  },
                  onVerticalDragEnd: (_) => _settleAyah(visibleAyah),
                  onVerticalDragCancel: _hidePreviewSoon,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: trackWidth,
                          decoration: BoxDecoration(
                            color: isDark
                                ? QuranTheme.surfaceVariant(
                                    context,
                                  ).withValues(alpha: 0.96)
                                : primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              width: 0.8,
                              color: primary.withValues(
                                alpha: isDark ? 0.62 : 0.34,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.18 : 0.07,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: progress,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primary.withValues(
                                      alpha: isDark ? 0.62 : 0.46,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: thumbTop,
                        end: thumbInset,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          scale: showDrop ? 1.04 : 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.86),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.44),
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const SizedBox(
                              width: thumbSize,
                              height: thumbSize,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: top,
                        end: 0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 130),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: showDrop
                              ? IgnorePointer(
                                  key: const ValueKey('ayah-scrollbar-preview'),
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutBack,
                                    scale: 1,
                                    child: ClipPath(
                                      clipper: const _AyahTearDropClipper(),
                                      child: Container(
                                        width: 64,
                                        height: dropHeight,
                                        alignment: Alignment.center,
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              end: 9,
                                            ),
                                        decoration: BoxDecoration(
                                          color: primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary.withValues(
                                                alpha: 0.30,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          visibleAyah.toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey(
                                    'ayah-scrollbar-preview-hidden',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AyahTearDropClipper extends CustomClipper<Path> {
  const _AyahTearDropClipper();

  @override
  Path getClip(Size size) {
    final r = size.height / 2;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - 12, 0)
      ..quadraticBezierTo(size.width - 2, 0, size.width - 2, r - 6)
      ..lineTo(size.width, r)
      ..lineTo(size.width - 2, r + 6)
      ..quadraticBezierTo(
        size.width - 2,
        size.height,
        size.width - 12,
        size.height,
      )
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class QuranReaderBottomInsets {
  const QuranReaderBottomInsets({
    required this.contentBottom,
    required this.actionBarBottom,
  });

  static const double selectedActionHeight = 184;
  static const double edgeGap = 12;

  final double contentBottom;
  final double actionBarBottom;

  static QuranReaderBottomInsets resolve(
    BuildContext context, {
    required bool audioVisible,
    required bool hasSelection,
  }) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final actionSpace = (audioVisible || hasSelection)
        ? selectedActionHeight + edgeGap
        : 0.0;
    return QuranReaderBottomInsets(
      actionBarBottom: safeBottom + edgeGap,
      contentBottom: safeBottom + 28 + actionSpace,
    );
  }
}

class _TafsirDisplayData {
  const _TafsirDisplayData({
    required this.text,
    required this.sourceLabel,
    required this.detailLabel,
    required this.textDirection,
    required this.textAlign,
    this.resource,
  });

  const _TafsirDisplayData.empty()
    : text = '',
      sourceLabel = '',
      detailLabel = '',
      textDirection = TextDirection.ltr,
      textAlign = TextAlign.left,
      resource = null;

  final String text;
  final String sourceLabel;
  final String detailLabel;
  final TextDirection textDirection;
  final TextAlign textAlign;
  final QuranTafsirResource? resource;
}

class _TafsirLoadingView extends StatelessWidget {
  const _TafsirLoadingView({required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, primary),
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading $languageLabel tafsir',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.text(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TafsirUnavailableView extends StatelessWidget {
  const _TafsirUnavailableView({required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
        border: Border.all(color: QuranTheme.outline(context)),
      ),
      child: Text(
        '$languageLabel tafsir is not available for this ayah yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: QuranTheme.subText(context, 0.72),
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TafsirSourcePill extends StatelessWidget {
  const _TafsirSourcePill({required this.data});

  final _TafsirDisplayData data;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, primary),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.sourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (data.detailLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.detailLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context, 0.68),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: QuranTheme.outline(context),
          borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({
    required this.title,
    required this.subtitle,
    required this.onTitleTap,
    required this.onSettingsTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTitleTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 6),
        child: Row(
          children: [
            _TopBarIcon(
              tooltip: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: 'Switch surah',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTitleTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                height: 1.05,
                              ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBarIcon(
                  tooltip: 'Search',
                  icon: Icons.search_rounded,
                  onTap: () => context.push(AppRoutes.quranSearchPath()),
                ),
                _TopBarIcon(
                  tooltip: 'Reader settings',
                  icon: Icons.tune_rounded,
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarIcon extends StatelessWidget {
  const _TopBarIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 24,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 42, height: 52),
      icon: Icon(icon),
    );
  }
}

typedef _SurahSelectedCallback =
    void Function(int surahNumber, {int? ayahNumber});

class _SurahSwitcherDialog extends StatefulWidget {
  const _SurahSwitcherDialog({
    required this.surahs,
    required this.currentSurah,
    required this.onSurahSelected,
  });

  final List<QuranSurah> surahs;
  final QuranSurah currentSurah;
  final _SurahSelectedCallback onSurahSelected;

  @override
  State<_SurahSwitcherDialog> createState() => _SurahSwitcherDialogState();
}

class _SurahSwitcherDialogState extends State<_SurahSwitcherDialog> {
  late int _selectedIndex;
  late final TextEditingController _ayahController;

  QuranSurah get _selectedSurah => widget.surahs[_selectedIndex];

  @override
  void initState() {
    super.initState();
    final index = widget.surahs.indexWhere(
      (surah) => surah.number == widget.currentSurah.number,
    );
    _selectedIndex = index < 0 ? 0 : index;
    _ayahController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _ayahController.dispose();
    super.dispose();
  }

  void _cycle(int delta) {
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta + widget.surahs.length) %
          widget.surahs.length;
      _ayahController.text = '1';
    });
    widget.onSurahSelected(_selectedSurah.number);
  }

  void _jumpToAyah() {
    final ayahNumber = (int.tryParse(_ayahController.text.trim()) ?? 1)
        .clamp(1, _selectedSurah.ayahCount)
        .toInt();
    _ayahController.text = ayahNumber.toString();
    widget.onSurahSelected(_selectedSurah.number, ayahNumber: ayahNumber);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SurahSwitcherMenu(
      surah: _selectedSurah,
      ayahController: _ayahController,
      onPrevious: () => _cycle(-1),
      onNext: () => _cycle(1),
      onJump: _jumpToAyah,
    );
  }
}

class _SurahSwitcherMenu extends StatelessWidget {
  const _SurahSwitcherMenu({
    required this.surah,
    required this.ayahController,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
  });

  final QuranSurah surah;
  final TextEditingController ayahController;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: PremiumSurface(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        radius: 22,
        prominent: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SurahCycleButton(
                  tooltip: 'Previous surah',
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrevious,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 150,
                    maxWidth: 230,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: QuranTheme.softFill(context, primary),
                          borderRadius: BorderRadius.circular(
                            QuranTheme.radiusPill,
                          ),
                        ),
                        child: Text(
                          '${surah.number}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        surah.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${surah.revelationType} • ${surah.ayahCount} ayahs',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _SurahCycleButton(
                  tooltip: 'Next surah',
                  icon: Icons.chevron_right_rounded,
                  onTap: onNext,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SurahAyahJumpRow(
              controller: ayahController,
              ayahCount: surah.ayahCount,
              onJump: onJump,
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahAyahJumpRow extends StatelessWidget {
  const _SurahAyahJumpRow({
    required this.controller,
    required this.ayahCount,
    required this.onJump,
  });

  final TextEditingController controller;
  final int ayahCount;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 316),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Jump to ayah',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(
            width: 72,
            height: 60,
            child: TextField(
              key: const ValueKey('surah-switcher-ayah-input'),
              controller: controller,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: '1',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
                ),
              ),
              onSubmitted: (_) => onJump(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const ValueKey('surah-switcher-jump-button'),
            behavior: HitTestBehavior.opaque,
            onTap: onJump,
            child: Tooltip(
              message: 'Jump to selected ayah',
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahCycleButton extends StatelessWidget {
  const _SurahCycleButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QuranTheme.softFill(context, primary),
            border: Border.all(color: QuranTheme.outline(context)),
          ),
          child: Icon(icon, color: primary, size: 28),
        ),
      ),
    );
  }
}

class _TranslationPickerResult {
  const _TranslationPickerResult.resource(this.resource);

  final QuranTranslationResource? resource;
}

class _TranslationPickerSheet extends StatefulWidget {
  const _TranslationPickerSheet({
    required this.repository,
    required this.currentResource,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource? currentResource;

  @override
  State<_TranslationPickerSheet> createState() =>
      _TranslationPickerSheetState();
}

class _TranslationPickerSheetState extends State<_TranslationPickerSheet> {
  final _queryController = TextEditingController();
  late final Future<List<QuranTranslationLanguage>> _languagesFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _languagesFuture = widget.repository.translationLanguages();
    _queryController.addListener(() {
      setState(() => _query = _queryController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.92,
      minChildSize: 0.58,
      builder: (context, scrollController) {
        return PremiumSurface(
          margin: const EdgeInsets.all(12),
          radius: QuranTheme.radiusSheet,
          prominent: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select translation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Search language or translator',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<QuranTranslationLanguage>>(
                  future: _languagesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = [
                      for (final language in snapshot.data!)
                        (
                          language: language,
                          resources: _matchingResources(language),
                        ),
                    ].where((group) => group.resources.isNotEmpty).toList();
                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          'No translations match your search.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.66),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      children: [
                        for (final group in groups) ...[
                          if (group.resources.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                              child: Text(
                                '${group.language.displayName} • ${group.resources.length} editions',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: QuranTheme.subText(context, 0.72),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          for (final resource in group.resources) ...[
                            FutureBuilder<bool>(
                              future: widget.repository.hasFullTranslation(
                                resource.id,
                              ),
                              builder: (context, cacheSnapshot) {
                                final downloaded = cacheSnapshot.data ?? false;
                                return _TranslationLanguageTile(
                                  title: group.resources.length == 1
                                      ? group.language.displayName
                                      : resource.name,
                                  subtitle:
                                      [
                                            resource.displayEndonym,
                                            resource.name,
                                            resource.translator,
                                            resource.isRtl ? 'RTL' : 'LTR',
                                            Uri.tryParse(
                                                  resource.sourceUrl,
                                                )?.host ??
                                                resource.sourceUrl,
                                            resource.license,
                                          ]
                                          .where((item) => item.isNotEmpty)
                                          .join(' • '),
                                  selected:
                                      widget.currentResource?.id == resource.id,
                                  downloaded: downloaded,
                                  onTap: () => Navigator.of(context).pop(
                                    _TranslationPickerResult.resource(resource),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<QuranTranslationResource> _matchingResources(
    QuranTranslationLanguage language,
  ) {
    if (_query.isEmpty) {
      return language.availableResources;
    }
    return language.availableResources
        .where((resource) {
          final haystack =
              '${language.displayName} ${resource.displayEndonym} ${resource.languageName} ${resource.name} ${resource.translator} ${resource.publisher} ${resource.license}'
                  .toLowerCase();
          return haystack.contains(_query);
        })
        .toList(growable: false);
  }
}

class _TranslationLanguageTile extends StatelessWidget {
  const _TranslationLanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.downloaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      borderColor: selected ? primary.withValues(alpha: 0.42) : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? QuranTheme.softFill(context, primary)
                  : QuranTheme.surfaceVariant(context).withValues(alpha: 0.55),
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.translate_rounded,
              size: 20,
              color: selected ? primary : QuranTheme.subText(context, 0.72),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.66),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            downloaded ? Icons.download_done_rounded : Icons.download_rounded,
            color: downloaded ? primary : QuranTheme.subText(context, 0.58),
          ),
        ],
      ),
    );
  }
}

class _InterlinearWordsDownloadSheet extends StatefulWidget {
  const _InterlinearWordsDownloadSheet({
    required this.repository,
    required this.languageCode,
    required this.languageLabel,
  });

  final QuranInterlinearRepository repository;
  final String languageCode;
  final String languageLabel;

  @override
  State<_InterlinearWordsDownloadSheet> createState() =>
      _InterlinearWordsDownloadSheetState();
}

class _InterlinearWordsDownloadSheetState
    extends State<_InterlinearWordsDownloadSheet> {
  QuranInterlinearDownloadProgress? _progress;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _download();
  }

  Future<void> _download() async {
    try {
      await for (final progress in widget.repository.downloadFullCache(
        language: widget.languageCode,
      )) {
        if (!mounted) {
          return;
        }
        setState(() => _progress = progress);
        if (progress.isComplete) {
          Navigator.of(context).pop(true);
          return;
        }
      }
      if (mounted) {
        setState(() => _error = 'Some pages failed to download.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PremiumSurface(
        radius: QuranTheme.radiusSheet,
        prominent: true,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 12),
            Text(
              'Preparing line translation',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.languageLabel} word-by-word cache',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: progress?.percent),
            const SizedBox(height: 10),
            Text(
              progress == null
                  ? 'Starting download...'
                  : '${progress.completedPages}/${progress.totalPages} pages',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationDownloadSheet extends StatefulWidget {
  const _TranslationDownloadSheet({
    required this.repository,
    required this.resource,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource resource;

  @override
  State<_TranslationDownloadSheet> createState() =>
      _TranslationDownloadSheetState();
}

class _TranslationDownloadSheetState extends State<_TranslationDownloadSheet> {
  QuranTranslationDownloadProgress? _progress;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _download();
  }

  Future<void> _download() async {
    try {
      await for (final progress in widget.repository.downloadFullTranslation(
        widget.resource.id,
      )) {
        if (!mounted) {
          return;
        }
        setState(() => _progress = progress);
        if (progress.isComplete) {
          await widget.repository.setSelectedTranslation(widget.resource.id);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _error = 'Some chapters failed to download.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PremiumSurface(
        radius: QuranTheme.radiusSheet,
        prominent: true,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 12),
            Text(
              'Preparing ${widget.resource.displayLanguage}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              widget.resource.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: progress?.percent),
            const SizedBox(height: 10),
            Text(
              progress == null
                  ? 'Starting download...'
                  : '${progress.completedChapters}/${progress.totalChapters} chapters • ${progress.completedVerses}/${progress.totalVerses} verses',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderSettingsSheet extends StatefulWidget {
  const _ReaderSettingsSheet({
    required this.state,
    required this.themeState,
    required this.tafsirLanguageName,
    required this.onAyahLayoutChanged,
    required this.onTranslationTap,
    required this.onTafsirLanguageTap,
    required this.onContentSourcesTap,
    required this.onTranslationSwitchChanged,
    required this.onFollowAudioChanged,
    required this.onClose,
    required this.onFontScaleChanged,
    required this.onTranslationFontScaleChanged,
  });

  final QuranReaderState state;
  final QuranThemeState themeState;
  final String tafsirLanguageName;
  final ValueChanged<QuranAyahTextLayout> onAyahLayoutChanged;
  final VoidCallback onTranslationTap;
  final VoidCallback onTafsirLanguageTap;
  final VoidCallback onContentSourcesTap;
  final ValueChanged<bool> onTranslationSwitchChanged;
  final ValueChanged<bool> onFollowAudioChanged;
  final VoidCallback onClose;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<double> onTranslationFontScaleChanged;

  @override
  State<_ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<_ReaderSettingsSheet> {
  late double _arabicFontScale;
  late double _translationFontScale;
  var _draggingArabicScale = false;
  var _draggingTranslationScale = false;

  @override
  void initState() {
    super.initState();
    _arabicFontScale = widget.themeState.quranArabicFontScale;
    _translationFontScale = widget.themeState.quranTranslationFontScale;
  }

  @override
  void didUpdateWidget(covariant _ReaderSettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_draggingArabicScale &&
        oldWidget.themeState.quranArabicFontScale !=
            widget.themeState.quranArabicFontScale) {
      _arabicFontScale = widget.themeState.quranArabicFontScale;
    }
    if (!_draggingTranslationScale &&
        oldWidget.themeState.quranTranslationFontScale !=
            widget.themeState.quranTranslationFontScale) {
      _translationFontScale = widget.themeState.quranTranslationFontScale;
    }
  }

  double _clampReaderScale(double value) => value.clamp(0.82, 1.42).toDouble();

  void _previewArabicFontScale(double value) {
    setState(() => _arabicFontScale = _clampReaderScale(value));
  }

  void _commitArabicFontScale(double value) {
    final next = _clampReaderScale(value);
    setState(() => _arabicFontScale = next);
    widget.onFontScaleChanged(next);
  }

  void _previewTranslationFontScale(double value) {
    setState(() => _translationFontScale = _clampReaderScale(value));
  }

  void _commitTranslationFontScale(double value) {
    final next = _clampReaderScale(value);
    setState(() => _translationFontScale = next);
    widget.onTranslationFontScaleChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final readerState = widget.state;
    final arabicScale = _clampReaderScale(_arabicFontScale);
    final translationScale = _clampReaderScale(_translationFontScale);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reader settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Close reader settings',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ayah layout',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SegmentedButton<QuranAyahTextLayout>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: QuranAyahTextLayout.combined,
                label: Text('Combined'),
                icon: Icon(Icons.notes_rounded),
              ),
              ButtonSegment(
                value: QuranAyahTextLayout.separated,
                label: Text('Separated'),
                icon: Icon(Icons.view_agenda_rounded),
              ),
            ],
            selected: {readerState.ayahTextLayout},
            onSelectionChanged: (value) =>
                widget.onAyahLayoutChanged(value.first),
          ),
          const SizedBox(height: 16),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            onTap: widget.onTranslationTap,
            child: Row(
              children: [
                const Icon(Icons.translate_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Translation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readerState.showTranslation
                            ? '${readerState.selectedTranslation?.displayEndonym ?? 'Selected'} • '
                                  '${readerState.selectedTranslation?.name ?? ''}'
                                  '${readerState.selectedTranslations.length > 1 ? ' +${readerState.selectedTranslations.length - 1}' : ''}'
                            : 'Off',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: readerState.showTranslation,
                  onChanged: widget.onTranslationSwitchChanged,
                ),
              ],
            ),
          ),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size_rounded, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arabic size',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SizeStepButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _commitArabicFontScale(arabicScale - 0.05),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${(arabicScale * 100).round()}%',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: QuranTheme.subText(context, 0.68),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SizeStepButton(
                      icon: Icons.add_rounded,
                      onTap: () => _commitArabicFontScale(arabicScale + 0.05),
                    ),
                  ],
                ),
                Slider(
                  min: 0.82,
                  max: 1.42,
                  divisions: 12,
                  value: arabicScale,
                  onChangeStart: (_) => _draggingArabicScale = true,
                  onChanged: _previewArabicFontScale,
                  onChangeEnd: (value) {
                    _draggingArabicScale = false;
                    _commitArabicFontScale(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.subtitles_rounded, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Translation size',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SizeStepButton(
                      icon: Icons.remove_rounded,
                      onTap: () =>
                          _commitTranslationFontScale(translationScale - 0.05),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${(translationScale * 100).round()}%',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: QuranTheme.subText(context, 0.68),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SizeStepButton(
                      icon: Icons.add_rounded,
                      onTap: () =>
                          _commitTranslationFontScale(translationScale + 0.05),
                    ),
                  ],
                ),
                Slider(
                  min: 0.82,
                  max: 1.42,
                  divisions: 12,
                  value: translationScale,
                  onChangeStart: (_) => _draggingTranslationScale = true,
                  onChanged: _previewTranslationFontScale,
                  onChangeEnd: (value) {
                    _draggingTranslationScale = false;
                    _commitTranslationFontScale(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            onTap: widget.onTafsirLanguageTap,
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tafsir language',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.tafsirLanguageName} • independent of Quran translation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto follow audio',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scroll to the playing ayah as audio changes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: readerState.followAudio,
                  onChanged: widget.onFollowAudioChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumSurface(
            radius: 22,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            onTap: widget.onContentSourcesTap,
            child: Row(
              children: [
                const Icon(Icons.verified_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content sources',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Editions, attribution, licenses, and cache policy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeStepButton extends StatelessWidget {
  const _SizeStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: QuranTheme.outline(context)),
          color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.55),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

String _surahSubtitle(int? number, String? revelationType) {
  if (number == 1) {
    return 'The Opening';
  }
  return revelationType ?? '';
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({required this.arabicName, required this.verseCount});

  final String arabicName;
  final int verseCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GoldOrnament(),
              const SizedBox(width: 18),
              Flexible(
                child: Text(
                  arabicName,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              const _GoldOrnament(flip: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$verseCount Verses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: QuranTheme.subText(context, 0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CombinedAyahChunkSurface extends StatelessWidget {
  const _CombinedAyahChunkSurface({
    required this.first,
    required this.last,
    required this.prominent,
    required this.child,
  });

  final bool first;
  final bool last;
  final bool prominent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _GoldOrnament extends StatelessWidget {
  const _GoldOrnament({this.flip = false});

  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: const Color(0xFFD6A657),
        size: 30,
      ),
    );
  }
}

class _StructureMarkers extends StatelessWidget {
  const _StructureMarkers({required this.ayahs});

  final List<QuranAyah> ayahs;

  @override
  Widget build(BuildContext context) {
    final markers = <String>{};
    for (final ayah in ayahs) {
      if (ayah.isPageStart) {
        markers.add('Page ${ayah.page}');
      }
      if (ayah.isJuzStart) {
        markers.add('Juz ${ayah.juz}');
      }
      if (ayah.isHizbBoundary) {
        markers.add('Hizb ${ayah.hizb}');
      } else if (ayah.rubIndex != null) {
        markers.add('Rub ${ayah.rubIndex}');
      }
      if (ayah.manzil != null) {
        markers.add('Manzil ${ayah.manzil}');
      }
      if (ayah.isSajda) {
        markers.add('Sajdah • ${ayah.surahNumber}:${ayah.number}');
      }
    }
    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        children: [
          for (final marker in markers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: QuranTheme.softFill(context, primary),
                borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
                border: Border.all(color: primary.withValues(alpha: 0.22)),
              ),
              child: Text(
                marker,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    required this.ayah,
    required this.translation,
    required this.translationResource,
    this.additionalTranslations = const [],
    required this.arabicFontScale,
    required this.translationFontScale,
    required this.showTranslation,
    required this.activeWordIndex,
    required this.isAudioActive,
    required this.isSelected,
    required this.isCurrentLastRead,
    required this.isBookmarked,
    required this.onSelect,
    required this.onBookmarkToggle,
    required this.bookmarkTooltip,
    required this.removeBookmarkTooltip,
  });

  final QuranAyah ayah;
  final String translation;
  final QuranTranslationResource? translationResource;
  final List<_DisplayedTranslation> additionalTranslations;
  final double arabicFontScale;
  final double translationFontScale;
  final bool showTranslation;
  final int? activeWordIndex;
  final bool isAudioActive;
  final bool isSelected;
  final bool isCurrentLastRead;
  final bool isBookmarked;
  final VoidCallback? onSelect;
  final VoidCallback onBookmarkToggle;
  final String bookmarkTooltip;
  final String removeBookmarkTooltip;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wordHighlight = QuranTheme.wordHighlight(context);
    final arabicText = _cleanArabic(ayah.text);
    final visibleTranslation = _cleanTranslation(translation);
    final highlighted = isAudioActive || isSelected;
    return Stack(
      children: [
        PremiumSurface(
          color: QuranTheme.surface(context),
          onTap: onSelect,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          borderColor: isAudioActive
              ? wordHighlight.withValues(alpha: 0.55)
              : isSelected
              ? primary.withValues(alpha: 0.32)
              : isCurrentLastRead
              ? primary.withValues(alpha: 0.22)
              : QuranTheme.outline(context),
          prominent: highlighted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VerseBadge(
                    number: ayah.number,
                    active: highlighted,
                    audioActive: isAudioActive,
                    tooltip: isAudioActive
                        ? 'Currently reciting'
                        : 'Selected ayah',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuranReaderArabicText(
                      text: arabicText,
                      arabicFontScale: arabicFontScale,
                      activeWordIndex: activeWordIndex,
                      selected: isAudioActive || isSelected,
                      highlighterActive: isAudioActive,
                      lineHeight: 1.74,
                    ),
                  ),
                ],
              ),
              if (showTranslation && visibleTranslation.isNotEmpty) ...[
                const SizedBox(height: 6),
                QuranTranslationText(
                  text: visibleTranslation,
                  resource: translationResource,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.78),
                    fontSize: 14.5 * translationFontScale,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                for (final additional in additionalTranslations) ...[
                  const SizedBox(height: 8),
                  Divider(color: QuranTheme.outline(context)),
                  const SizedBox(height: 4),
                  QuranTranslationText(
                    text: _cleanTranslation(additional.text),
                    resource: additional.resource,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.78),
                      fontSize: 14.5 * translationFontScale,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  _PlainAction(
                    tooltip: isBookmarked
                        ? removeBookmarkTooltip
                        : bookmarkTooltip,
                    icon: isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    active: isBookmarked,
                    onTap: onBookmarkToggle,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (highlighted || isCurrentLastRead)
          PositionedDirectional(
            start: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: isAudioActive
                    ? QuranTheme.wordHighlight(context)
                    : primary.withValues(alpha: isSelected ? 0.72 : 0.38),
                borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
              ),
            ),
          ),
      ],
    );
  }

  String _cleanArabic(String value) {
    return value.replaceAll(RegExp(r'[\uFC00-\uFCFF]'), '').trim();
  }

  String _cleanTranslation(String value) {
    return value.replaceFirst(RegExp(r'\s*-?\s*﴾\d+﴿\s*$'), '').trim();
  }
}

class _DisplayedTranslation {
  const _DisplayedTranslation({required this.text, required this.resource});

  final String text;
  final QuranTranslationResource resource;
}

class _VerseBadge extends StatelessWidget {
  const _VerseBadge({
    required this.number,
    required this.active,
    required this.audioActive,
    required this.tooltip,
  });

  final int number;
  final bool active;
  final bool audioActive;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wordHighlight = QuranTheme.wordHighlight(context);
    final badgeColor = audioActive ? wordHighlight : primary;
    final iconColor = active
        ? badgeColor
        : QuranTheme.outline(context).withValues(alpha: 0.86);
    final textColor = active
        ? badgeColor
        : QuranTheme.subText(context, QuranTheme.isDark(context) ? 0.78 : 0.66);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.brightness_6_rounded, color: iconColor, size: 40),
              if (active)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QuranTheme.surface(context).withValues(alpha: 0.92),
                  ),
                ),
              Text(
                number.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainAction extends StatelessWidget {
  const _PlainAction({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Icon(
        icon,
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.black.withValues(alpha: 0.82),
      ),
    );
  }
}
