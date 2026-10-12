import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/quran_arabic_script.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/content_share_sheet.dart';
import '../../../../core/widgets/note_editor_sheet.dart';
import '../../../../core/widgets/reader_text_size_control.dart';
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
import '../widgets/quran_surah_pull_navigation.dart';
import '../widgets/quran_reader_floating_controls.dart';
import '../widgets/quran_translation_text.dart';
import '../widgets/quran_translation_picker.dart';
import '../widgets/quran_translation_download_sheet.dart';
import '../widgets/quran_share_translation_tile.dart';

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
  final _bookScrollController = QuranBookScrollController();
  final _readerViewportKey = GlobalKey();
  final _floatingControlsKey = GlobalKey();
  int _scrollRequestRevision = 0;
  Timer? _scrollSaveDebounce;
  Timer? _followScrollRetry;
  Timer? _jumpScrollRetry;
  Timer? _programmaticScrollTimer;
  QuranReaderState? _latestState;
  QuranAudioState? _latestAudioState;
  Map<int, List<QuranWord>>? _bookWordPages;
  List<QuranAyah>? _bookWordAyahs;
  QuranArabicScript? _bookWordScript;
  Map<String, List<QuranWord>> _bookWordsByVerse = const {};
  String? _lastFollowScrollSignature;
  int? _lastRenderedSurahNumber;
  QuranAyahTextLayout? _lastRenderedAyahLayout;
  int? _scrubberAyahNumber;
  bool _didInitialScroll = false;
  bool _didResolveInitialAudioFollow = false;
  String? _suppressedInitialAudioFocusVerseKey;
  var _programmaticScroll = false;
  bool _changingSurah = false;
  int? _enterAtBottomSurah;

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

  int? _activeWordIndexForScript(
    QuranReaderState state,
    QuranAudioState audioState,
    QuranArabicScript script,
  ) {
    if (script == QuranArabicScript.uthmani) return audioState.activeWordIndex;
    for (final ayah in state.ayahs) {
      if (ayah.verseKey == audioState.activeWordVerseKey) {
        return ayah.wordIndexForScript(script, audioState.activeWordIndex);
      }
    }
    return null;
  }

  void _scheduleFollowAudioScroll({
    required QuranReaderState state,
    required QuranAudioState audioState,
    required QuranThemeState themeState,
  }) {
    if (!state.followAudio) {
      _lastFollowScrollSignature = null;
      return;
    }
    final verseKey = _activeAudioVerseKey(state, audioState);
    if (verseKey == null) {
      return;
    }
    final signature =
        '$verseKey-${state.ayahTextLayout}-${themeState.quranArabicScript}-${themeState.quranArabicFontScale}-${themeState.quranTranslationFontScale}-${state.showTranslation}-${state.selectedTranslation?.id}-${MediaQuery.sizeOf(context).width}-${MediaQuery.textScalerOf(context).scale(1)}';
    if (_lastFollowScrollSignature == signature) {
      return;
    }
    _lastFollowScrollSignature = signature;
    _scrollToAyah(verseKey, state: state, onlyIfOffscreen: true);
  }

  void _scrollToAyah(
    String verseKey, {
    required QuranReaderState state,
    double alignment = 0.18,
    Duration duration = const Duration(milliseconds: 360),
    int attempt = 0,
    int? requestRevision,
    bool onlyIfOffscreen = false,
  }) {
    final revision = requestRevision ?? ++_scrollRequestRevision;
    if (requestRevision == null) _followScrollRetry?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          revision != _scrollRequestRevision ||
          (onlyIfOffscreen && _latestState?.followAudio != true)) {
        return;
      }
      final targetIndex = _readerItemIndexForVerseKey(verseKey, state);
      if (targetIndex == null) return;
      if (onlyIfOffscreen &&
          targetIndex == 0 &&
          _isBookVerseVisible(verseKey)) {
        return;
      }
      final combined =
          state.ayahTextLayout == QuranAyahTextLayout.combined &&
          targetIndex > 0;
      if (combined) {
        final anchor = _bookScrollController.contextForVerse(verseKey);
        if (anchor != null) {
          if (onlyIfOffscreen && _isBookVerseVisible(verseKey)) return;
          _markProgrammaticScroll();
          await Scrollable.ensureVisible(
            anchor,
            alignment: alignment,
            duration: duration,
            curve: Curves.easeOutCubic,
          );
          return;
        }
      }
      if (_itemScrollController.isAttached) {
        _markProgrammaticScroll();
        await _itemScrollController.scrollTo(
          index: targetIndex,
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: targetIndex == 0 ? 0 : alignment,
        );
        if (!combined) return;
      }
      if (mounted && revision == _scrollRequestRevision && attempt < 8) {
        _followScrollRetry?.cancel();
        _followScrollRetry = Timer(
          const Duration(milliseconds: 100),
          () => _scrollToAyah(
            verseKey,
            state: state,
            alignment: alignment,
            duration: duration,
            attempt: attempt + 1,
            requestRevision: revision,
            onlyIfOffscreen: onlyIfOffscreen,
          ),
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _isBookVerseVisible(String verseKey) {
    if (verseKey == '1:1' && _latestState?.surah?.number == 1) {
      return _itemPositionsListener.itemPositions.value.any(
        (position) =>
            position.index == 0 &&
            position.itemLeadingEdge >= 0 &&
            position.itemTrailingEdge <= 1,
      );
    }
    final anchor = _bookScrollController
        .contextForVerse(verseKey)
        ?.findRenderObject();
    final viewport = _readerViewportKey.currentContext?.findRenderObject();
    if (anchor is! RenderBox ||
        !anchor.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      return false;
    }
    final top = viewport.localToGlobal(Offset.zero).dy;
    var bottom = top + viewport.size.height;
    final controls = _floatingControlsKey.currentContext?.findRenderObject();
    if (controls is RenderBox && controls.hasSize) {
      bottom = controls.localToGlobal(Offset.zero).dy - 12;
    }
    final y = anchor.localToGlobal(Offset.zero).dy;
    return y >= top + 24 && y <= bottom - 24;
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
    if (verseKey == '1:1' && state.surah?.number == 1) return 0;
    final ayahIndex = state.bodyAyahs.indexWhere(
      (ayah) => ayah.verseKey == verseKey,
    );
    if (ayahIndex == -1) {
      return null;
    }
    if (state.ayahTextLayout == QuranAyahTextLayout.combined) {
      return 1 +
          _ayahBookChunks(state.bodyAyahs).indexWhere(
            (chunk) => chunk.any((ayah) => ayah.verseKey == verseKey),
          );
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

  void _saveMostVisibleAyah({bool restoreFollowAudio = true}) {
    final state = _latestState;
    if (!mounted ||
        state == null ||
        _changingSurah ||
        state.status != QuranReaderStatus.success ||
        state.ayahs.isEmpty ||
        _programmaticScroll) {
      return;
    }

    final visibleVerseKey = _mostVisibleVerseKey();
    if (restoreFollowAudio) _restoreFollowAudioIfActiveVisible(visibleVerseKey);
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
    if (itemIndex == null) {
      return null;
    }
    if (itemIndex == 0) return state.surah?.number == 1 ? '1:1' : null;
    if (state.ayahTextLayout == QuranAyahTextLayout.combined) {
      final chunks = _ayahBookChunks(state.bodyAyahs);
      final chunkIndex = itemIndex - 1;
      return chunkIndex < chunks.length
          ? chunks[chunkIndex].first.verseKey
          : null;
    }
    final ayahIndex = itemIndex - 1;
    final bodyAyahs = state.bodyAyahs;
    if (ayahIndex < 0 || ayahIndex >= bodyAyahs.length) {
      return null;
    }
    return bodyAyahs[ayahIndex].verseKey;
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
    if (activeVerseKey == null ||
        (state.ayahTextLayout == QuranAyahTextLayout.combined
            ? !_isBookVerseVisible(activeVerseKey)
            : activeVerseKey != visibleVerseKey)) {
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
    _jumpScrollRetry?.cancel();
    _scrollSaveDebounce?.cancel();
    _scrollRequestRevision++;
    _lastFollowScrollSignature = null;
    _scrubberAyahNumber = null;
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

  void _pauseAudioFollowForDrag() {
    _followScrollRetry?.cancel();
    _jumpScrollRetry?.cancel();
    _scrollRequestRevision++;
    _lastFollowScrollSignature = null;
    _programmaticScroll = false;
    if (_latestState?.followAudio == true) {
      context.read<QuranReaderBloc>().add(
        const QuranReaderFollowAudioChanged(false),
      );
    }
  }

  Future<void> _goToAdjacentSurah(
    QuranReaderState state, {
    bool previous = false,
  }) async {
    final current = state.surah?.number;
    if (_changingSurah || current == null) return;
    final target = current + (previous ? -1 : 1);
    if (target < 1 || target > 114) return;
    _changingSurah = true;
    _pauseAudioFollowForDrag();
    _scrollSaveDebounce?.cancel();
    final bloc = context.read<QuranReaderBloc>();
    try {
      final surah = await getIt<QuranRepository>().getSurah(target);
      if (!mounted) return;
      _enterAtBottomSurah = previous ? target : null;
      // Subscribe before dispatch so even a fully cached transition is observed.
      final changed = bloc.stream.firstWhere(
        (next) => next.surah?.number == target || next.errorMessage != null,
      );
      bloc.add(
        QuranReaderSurahChanged(
          target,
          initialAyahNumber: previous ? surah.ayahCount : 1,
        ),
      );
      final next = await changed;
      if (next.errorMessage != null) throw StateError(next.errorMessage!);
    } catch (_) {
      _enterAtBottomSurah = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open surah. Please try again.'),
          ),
        );
      }
    } finally {
      _changingSurah = false;
    }
  }

  Widget _buildFollowAudioChip(String activeVerseKey) {
    return ActionChip(
      elevation: 4,
      pressElevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      backgroundColor: QuranTheme.surface(context),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsetsDirectional.only(start: 4, end: 2),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -1),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      avatarBoxConstraints: const BoxConstraints.tightFor(
        width: 16,
        height: 16,
      ),
      avatar: const AppIcon(Icons.graphic_eq_rounded, size: 16),
      label: const Text('Follow audio'),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontSize: 12, height: 1.2),
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

  Future<void> _showReaderSettings() {
    final readerBloc = context.read<QuranReaderBloc>();
    final themeCubit = context.read<QuranThemeCubit>();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/reader-settings'),
        builder: (pageContext) => MultiBlocProvider(
          providers: [
            BlocProvider<QuranReaderBloc>.value(value: readerBloc),
            BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          ],
          child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
            builder: (context, readerState) =>
                BlocBuilder<QuranThemeCubit, QuranThemeState>(
                  builder: (context, liveThemeState) => _ReaderSettingsPage(
                    state: readerState,
                    themeState: liveThemeState,
                    onAyahLayoutChanged: (layout) => _changeAyahLayout(
                      settingsContext: context,
                      readerState: readerState,
                      layout: layout,
                    ),
                    onTranslationTap: () => _showTranslationPicker(
                      readerBloc: readerBloc,
                      readerState: readerState,
                    ),
                    onTranslationSwitchChanged: (enabled) {
                      if (enabled && readerState.selectedTranslation == null) {
                        _showTranslationPicker(
                          readerBloc: readerBloc,
                          readerState: readerState,
                        );
                      } else if (readerState.showTranslation != enabled) {
                        readerBloc.add(const QuranReaderTranslationToggled());
                      }
                    },
                    onFollowAudioChanged: (enabled) => readerBloc.add(
                      QuranReaderFollowAudioChanged(
                        enabled,
                        verseKey:
                            _latestAudioState?.currentItem?.verseKey ??
                            readerState.activeAudioVerseKey,
                      ),
                    ),
                    onClose: () => Navigator.of(pageContext).pop(),
                    onFontScaleChanged: themeCubit.setQuranArabicFontScale,
                    onTranslationFontScaleChanged:
                        themeCubit.setQuranTranslationFontScale,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTranslationPicker({
    required QuranReaderBloc readerBloc,
    required QuranReaderState readerState,
  }) async {
    final repository = getIt<QuranTranslationRepository>();
    final selected = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuranTranslationPicker(
        repository: repository,
        currentResource: readerState.selectedTranslation,
      ),
    );
    if (!mounted) {
      return;
    }
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
        builder: (context) => QuranTranslationDownloadSheet(
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppSheet(
        title: 'Tafsir ${ayah.verseKey}',
        child: FutureBuilder<_TafsirDisplayData>(
          future: tafsirFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _TafsirLoadingView(languageLabel: tafsirLanguageLabel);
            }
            final data = snapshot.data;
            if (data == null || data.text.trim().isEmpty) {
              return _TafsirUnavailableView(languageLabel: tafsirLanguageLabel);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TafsirSourcePill(data: data),
                const SizedBox(height: 12),
                Text(
                  data.text,
                  textDirection: data.textDirection,
                  textAlign: data.textAlign,
                  style: QuranTheme.translationStyle(
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.8),
                    data.resource?.languageName,
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
          onSettingsTap: _showReaderSettings,
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
              padding: EdgeInsets.fromLTRB(
                18,
                _ReaderTopBar.height(context),
                18,
                MediaQuery.viewInsetsOf(dialogContext).bottom + 12,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _SurahSwitcherDialog(
                    surahs: surahs,
                    currentSurah: currentSurah,
                    onSurahSelected: (surahNumber, {ayahNumber}) {
                      _enterAtBottomSurah = null;
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
    final activeVerseKey = _activeAudioVerseKey(state, audioState);
    final bodyAyahs = state.bodyAyahs;
    final itemCount = bodyAyahs.length + 3;
    return Stack(
      children: [
        ScrollablePositionedList.builder(
          key: ValueKey('ayah-separated-${state.surah?.number}'),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          initialScrollIndex: _enterAtBottomSurah == surah?.number
              ? itemCount - 1
              : 0,
          initialAlignment: _enterAtBottomSurah == surah?.number ? 1 : 0,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // A final zero-height anchor opens the previous surah at its end,
            // regardless of Arabic size, translation height, or layout.
            if (index == itemCount - 1) return const SizedBox.shrink();
            if (index == 0) {
              return _buildSurahHeader(state, themeState, audioState);
            }
            final ayahIndex = index - 1;
            if (ayahIndex >= bodyAyahs.length) {
              return _buildSurahFooter(state, insets);
            }
            final ayah = bodyAyahs[ayahIndex];
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
                    _StructureMarkers(
                      ayahs: [
                        if (ayahIndex == 0 && state.surah?.number == 1)
                          state.ayahs.first,
                        ayah,
                      ],
                      startsPage:
                          ayahIndex == 0 ||
                          ayah.page != bodyAyahs[ayahIndex - 1].page,
                    ),
                    _AyahCard(
                      ayah: ayah,
                      arabicScript: themeState.quranArabicScript,
                      translation: selectedTranslation ?? ayah.translation,
                      translationResource: selectedTranslation == null
                          ? null
                          : state.selectedTranslation,
                      additionalTranslations: [
                        for (final resource in state.selectedTranslations.skip(
                          1,
                        ))
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
                      isCurrentLastRead: state.currentVerseKey == ayah.verseKey,
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
    final activeVerseKey = _activeAudioVerseKey(state, audioState);
    final activeAudioVerseKey = audioState.status == QuranAudioStatus.completed
        ? null
        : activeVerseKey;
    final bookChunks = _ayahBookChunks(state.bodyAyahs);
    final script = themeState.quranArabicScript;
    final bookWordsByVerse = _surahBookWordsByVerse(state, script);
    final itemCount = bookChunks.length + 3;
    return Stack(
      children: [
        ScrollablePositionedList.builder(
          key: ValueKey('ayah-combined-${state.surah?.number}'),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          initialScrollIndex: _enterAtBottomSurah == surah?.number
              ? itemCount - 1
              : 0,
          initialAlignment: _enterAtBottomSurah == surah?.number ? 1 : 0,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(4, 0, 18, 0),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == itemCount - 1) return const SizedBox.shrink();
            if (index == 0) {
              return _buildSurahHeader(state, themeState, audioState);
            }
            final chunkIndex = index - 1;
            if (chunkIndex >= bookChunks.length) {
              return _buildSurahFooter(state, insets);
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
                  state.selectedVerseKey != null || activeAudioVerseKey != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StructureMarkers(
                    ayahs: [
                      if (chunkIndex == 0 && state.surah?.number == 1)
                        state.ayahs.first,
                      ...chunkAyahs,
                    ],
                    startsPage:
                        chunkIndex == 0 ||
                        chunkAyahs.first.page !=
                            bookChunks[chunkIndex - 1].last.page,
                  ),
                  CombinedPageText(
                    scrollController: _bookScrollController,
                    ayahs: chunkAyahs
                        .map((ayah) => ayah.forScript(script))
                        .toList(growable: false),
                    arabicScript: script,
                    pageWords: chunkWords,
                    selectedVerseKey: state.selectedVerseKey,
                    activeAudioVerseKey: activeAudioVerseKey,
                    activeWordVerseKey: audioState.activeWordVerseKey,
                    activeWordIndex: _activeWordIndexForScript(
                      state,
                      audioState,
                      script,
                    ),
                    currentVerseKey: state.currentVerseKey,
                    arabicFontScale: themeState.quranArabicFontScale,
                    translationFontScale: themeState.quranTranslationFontScale,
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
    );
  }

  List<List<QuranAyah>> _ayahBookChunks(List<QuranAyah> ayahs) {
    final chunks = <List<QuranAyah>>[];
    for (final ayah in ayahs) {
      if (chunks.isEmpty ||
          chunks.last.length == _ayahBookChunkSize ||
          chunks.last.last.page != ayah.page) {
        chunks.add([]);
      }
      chunks.last.add(ayah);
    }
    return chunks;
  }

  Widget _buildSurahHeader(
    QuranReaderState state,
    QuranThemeState themeState,
    QuranAudioState audioState,
  ) {
    final surah = state.surah;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          if (surah != null && surah.number > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: const SurahNavigationCapsule(previous: true),
            ),
          _ReaderHeader(
            arabicName: surah?.arabicName ?? '',
            verseCount: surah?.ayahCount ?? state.ayahs.length,
            arabicScript: themeState.quranArabicScript,
            bismillah: surah == null || surah.number == 9
                ? null
                : _buildBismillah(state, themeState, audioState),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillah(
    QuranReaderState state,
    QuranThemeState themeState,
    QuranAudioState audioState,
  ) {
    final ayah = state.bismillahAyah;
    final numbered = state.surah?.number == 1;
    final item = audioState.currentItem;
    final active =
        item?.surahNumber == state.surah?.number &&
        audioState.status != QuranAudioStatus.completed &&
        (item?.isBismillah == true || (numbered && item?.verseKey == '1:1'));
    final translation = state.selectedTranslation == null
        ? ayah?.translation ?? ''
        : state.translationsByVerse['1:1'] ?? '';
    final translations = <(String, QuranTranslationResource?)>[
      if (translation.trim().isNotEmpty)
        (translation, state.selectedTranslation),
      for (final resource in state.selectedTranslations.skip(1))
        if (state.translationsByResource[resource.id]?['1:1']
                ?.trim()
                .isNotEmpty ==
            true)
          (state.translationsByResource[resource.id]!['1:1']!, resource),
    ];
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoldOrnament(compact: true),
                SizedBox(width: 6),
                AppIcon(
                  Icons.auto_awesome_rounded,
                  size: 8,
                  color: Color(0xFFD6A657),
                ),
                SizedBox(width: 6),
                _GoldOrnament(compact: true, flip: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          QuranReaderArabicText(
            text:
                ayah?.textForScript(themeState.quranArabicScript) ??
                themeState.quranArabicScript.bismillah,
            arabicScript: themeState.quranArabicScript,
            arabicFontScale: themeState.quranArabicFontScale,
            textAlign: TextAlign.center,
            selected: numbered && state.selectedVerseKey == '1:1',
            highlighterActive: active,
            activeWordIndex: active
                ? ayah?.wordIndexForScript(
                    themeState.quranArabicScript,
                    audioState.activeWordIndex,
                  )
                : null,
          ),
          if (state.showTranslation)
            for (final (text, resource) in translations) ...[
              const SizedBox(height: 6),
              QuranTranslationText(
                text: text
                    .replaceFirst(RegExp(r'\s*-?\s*﴾\d+﴿\s*$'), '')
                    .trim(),
                resource: resource,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.78),
                  fontSize: 14.5 * themeState.quranTranslationFontScale,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
        ],
      ),
    );
    return numbered
        ? InkWell(
            key: const ValueKey('bismillah-1:1'),
            borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
            onTap: () => context.read<QuranReaderBloc>().add(
              const QuranReaderAyahSelected(surahNumber: 1, ayahNumber: 1),
            ),
            child: content,
          )
        : content;
  }

  Widget _buildSurahFooter(
    QuranReaderState state,
    QuranReaderBottomInsets insets,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: 28, bottom: insets.contentBottom),
      child: hasNextSurah(state.surah)
          ? const SurahNavigationCapsule()
          : const SizedBox.shrink(),
    );
  }

  Map<String, List<QuranWord>> _surahBookWordsByVerse(
    QuranReaderState state,
    QuranArabicScript script,
  ) {
    if (identical(_bookWordPages, state.pageWordsByPage) &&
        identical(_bookWordAyahs, state.ayahs) &&
        _bookWordScript == script) {
      return _bookWordsByVerse;
    }
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
    for (final ayah in state.ayahs) {
      final original = wordsByVerse[ayah.verseKey];
      if (original != null) {
        wordsByVerse[ayah.verseKey] = QuranWord.forAyahText(
          ayah,
          original,
          script,
        );
      }
    }
    _bookWordPages = state.pageWordsByPage;
    _bookWordAyahs = state.ayahs;
    _bookWordScript = script;
    return _bookWordsByVerse = wordsByVerse;
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
        key: _floatingControlsKey,
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
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(
        title: 'Note for ayah ${ayah.verseKey}',
        initialText: existing?.text ?? '',
      ),
    );
    if (text == null || text.trim().isEmpty) {
      return;
    }
    await store.saveNote(
      id: existing?.id,
      text: text.trim(),
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
  ) {
    final translation = readerState.translationsByVerse[ayah.verseKey];
    final script = context.read<QuranThemeCubit>().state.quranArabicScript;
    return showContentShareSheet(
      context,
      ContentShareSheet(
        title: 'Share verse',
        heading: 'HOLY QURAN',
        arabicText: ayah.textForScript(script),
        script: script,
        translation: translation ?? ayah.translation,
        translationResource: translation == null
            ? null
            : readerState.selectedTranslation,
        referenceTitle: readerState.surah?.englishName ?? 'Quran',
        referenceSubtitle: 'Surah ${ayah.surahNumber}  /  Ayah ${ayah.number}',
        referenceLabel: 'Surah and ayah reference',
        fileName: 'quran_${ayah.surahNumber}_${ayah.number}.png',
        translationPickerBuilder:
            (resource, _, enabled, onChanged, onLoading) =>
                QuranShareTranslationTile(
                  repository: getIt<QuranTranslationRepository>(),
                  verseKey: ayah.verseKey,
                  surahNumber: ayah.surahNumber,
                  resource: resource,
                  enabled: enabled,
                  onLoadingChanged: onLoading,
                  onChanged: (resource, text) =>
                      onChanged(resource, text, resource.resolvedLanguageCode),
                ),
      ),
    );
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
          body: PopScope<void>(
            onPopInvokedWithResult: (didPop, _) {
              if (didPop && _scrollSaveDebounce?.isActive == true) {
                _scrollSaveDebounce?.cancel();
                _saveMostVisibleAyah(restoreFollowAudio: false);
              }
            },
            child: Stack(
              children: [
                SafeArea(
                  top: true,
                  bottom: false,
                  child: switch (state.status) {
                    QuranReaderStatus.initial || QuranReaderStatus.loading =>
                      AppLoadingView(label: l10n.loadingQuran),
                    QuranReaderStatus.failure => AppErrorView(
                      title: l10n.quranLoadFailedTitle,
                      message:
                          state.errorMessage ?? l10n.quranLoadFailedMessage,
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
                          final audioVerseKey =
                              audioState.currentItem?.verseKey;
                          final suppressInitialAudioFocus =
                              _shouldSuppressInitialAudioFocus(
                                state,
                                audioState,
                              );
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
                                    title:
                                        surah?.englishName ??
                                        l10n.quranReaderTitle,
                                    subtitle: _surahSubtitle(
                                      surah?.number,
                                      surah?.revelationType,
                                    ),
                                  ),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) => Stack(
                                        children: [
                                          Positioned.fill(
                                            child: KeyedSubtree(
                                              key: _readerViewportKey,
                                              child: QuranSurahPullNavigation(
                                                key: ValueKey(
                                                  'surah-pull-${surah?.number}-${state.ayahTextLayout}',
                                                ),
                                                hasPrevious:
                                                    (surah?.number ?? 1) > 1,
                                                hasNext: hasNextSurah(surah),
                                                bottomInset:
                                                    insets.contentBottom,
                                                onNavigate: (previous) =>
                                                    _goToAdjacentSurah(
                                                      state,
                                                      previous: previous,
                                                    ),
                                                onDragStart:
                                                    _pauseAudioFollowForDrag,
                                                child: reader,
                                              ),
                                            ),
                                          ),
                                          _AyahScrollbar(
                                            viewportHeight:
                                                constraints.maxHeight,
                                            topInset:
                                                MediaQuery.paddingOf(
                                                  this.context,
                                                ).top +
                                                _ReaderTopBar.height(context),
                                            ayahCount: state.ayahs.length,
                                            currentAyahNumber:
                                                _scrollbarAyahNumber(state),
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
          ),
        );
      },
    );
  }
}

class _AyahScrollbar extends StatefulWidget {
  const _AyahScrollbar({
    required this.viewportHeight,
    required this.topInset,
    required this.ayahCount,
    required this.currentAyahNumber,
    required this.onAyahNumberChanged,
    required this.onAyahNumberSettled,
  });

  final double viewportHeight;
  final double topInset;
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
    const scrollbarHeightFactor = 0.44;
    final scrollbarHeight = (screenHeight * scrollbarHeightFactor).clamp(
      0.0,
      widget.viewportHeight,
    );
    final topOffset = ((screenHeight - scrollbarHeight) / 2 - widget.topInset)
        .clamp(0.0, widget.viewportHeight - scrollbarHeight);
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
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                                fontWeight: FontWeight.w600,
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
          AppIcon(Icons.menu_book_rounded, color: primary, size: 20),
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

  static double height(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return (scaler.scale(20) * 1.05 + scaler.scale(12) * 1.15 + 22).clamp(
      66.0,
      double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height(context),
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
                                fontWeight: FontWeight.w600,
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
                                  color: QuranTheme.subText(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
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
      constraints: const BoxConstraints.tightFor(width: 44, height: 52),
      icon: AppIcon(icon),
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
        radius: QuranTheme.radiusCard,
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
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${surah.number}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w500,
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
                          fontWeight: FontWeight.w500,
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
                          fontWeight: FontWeight.w500,
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
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 72,
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
          IconButton.filled(
            key: const ValueKey('surah-switcher-jump-button'),
            tooltip: 'Jump to selected ayah',
            onPressed: onJump,
            icon: const AppIcon(Icons.arrow_forward_rounded, size: 20),
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
          child: AppIcon(icon, color: primary, size: 28),
        ),
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
    setState(() => _error = null);
    try {
      await for (final progress in widget.repository.downloadFullCache(
        language: widget.languageCode,
      )) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
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
    return AppSheet(
      title: 'Preparing line translation',
      subtitle: '${widget.languageLabel} word-by-word',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress?.percent),
          const SizedBox(height: 10),
          Text(
            progress == null
                ? 'Starting download...'
                : '${progress.completedPages}/${progress.totalPages} pages',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _download,
              icon: const AppIcon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ReaderSettingsPage extends StatefulWidget {
  const _ReaderSettingsPage({
    required this.state,
    required this.themeState,
    required this.onAyahLayoutChanged,
    required this.onTranslationTap,
    required this.onTranslationSwitchChanged,
    required this.onFollowAudioChanged,
    required this.onClose,
    required this.onFontScaleChanged,
    required this.onTranslationFontScaleChanged,
  });

  final QuranReaderState state;
  final QuranThemeState themeState;
  final ValueChanged<QuranAyahTextLayout> onAyahLayoutChanged;
  final VoidCallback onTranslationTap;
  final ValueChanged<bool> onTranslationSwitchChanged;
  final ValueChanged<bool> onFollowAudioChanged;
  final VoidCallback onClose;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<double> onTranslationFontScaleChanged;

  @override
  State<_ReaderSettingsPage> createState() => _ReaderSettingsPageState();
}

class _ReaderSettingsPageState extends State<_ReaderSettingsPage> {
  final _settingsScrollController = ScrollController();
  final _previewScrollController = ScrollController();
  late double _arabicScale = widget.themeState.quranArabicFontScale;
  late double _translationScale = widget.themeState.quranTranslationFontScale;

  @override
  void dispose() {
    _settingsScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReaderSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeState.quranArabicFontScale !=
        widget.themeState.quranArabicFontScale) {
      _arabicScale = widget.themeState.quranArabicFontScale;
    }
    if (oldWidget.themeState.quranTranslationFontScale !=
        widget.themeState.quranTranslationFontScale) {
      _translationScale = widget.themeState.quranTranslationFontScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader settings'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onClose,
          icon: const AppIcon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              SizedBox(
                key: const ValueKey('reader-settings-preview'),
                height: (constraints.maxHeight * 0.4).clamp(0, 320),
                child: _preview(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: Scrollbar(
                  key: const ValueKey('reader-settings-controls'),
                  controller: _settingsScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 3,
                  radius: const Radius.circular(3),
                  child: ListView(
                    controller: _settingsScrollController,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      Text(
                        'Layout',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<QuranAyahTextLayout>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: QuranAyahTextLayout.combined,
                            icon: AppIcon(Icons.view_headline_rounded),
                            label: Text('Combined'),
                          ),
                          ButtonSegment(
                            value: QuranAyahTextLayout.separated,
                            icon: AppIcon(Icons.view_agenda_outlined),
                            label: Text('Separated'),
                          ),
                        ],
                        selected: {state.ayahTextLayout},
                        onSelectionChanged: (value) =>
                            widget.onAyahLayoutChanged(value.first),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Arabic script',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<QuranArabicScript>(
                        segments: [
                          for (final script in QuranArabicScript.values)
                            ButtonSegment(
                              value: script,
                              label: Text(script.label),
                            ),
                        ],
                        selected: {widget.themeState.quranArabicScript},
                        onSelectionChanged: (values) => context
                            .read<QuranThemeCubit>()
                            .setQuranArabicScript(values.first),
                      ),
                      const SizedBox(height: 12),
                      ReaderTextSizeControl(
                        title: 'Arabic size',
                        value: _arabicScale,
                        onPreviewChanged: (value) =>
                            setState(() => _arabicScale = value),
                        onChanged: (value) {
                          setState(() => _arabicScale = value);
                          widget.onFontScaleChanged(value);
                        },
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _arabicScale = 1.0;
                              _translationScale = 1.0;
                            });
                            context
                                .read<QuranThemeCubit>()
                                .resetReaderFontSizes();
                          },
                          icon: const AppIcon(
                            Icons.restart_alt_rounded,
                            size: 18,
                          ),
                          label: const Text('Reset font sizes'),
                        ),
                      ),
                      const Divider(height: 24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Translation'),
                        value: state.showTranslation,
                        onChanged: widget.onTranslationSwitchChanged,
                      ),
                      AnimatedExpansion(
                        expanded: state.showTranslation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const AppIcon(Icons.translate_rounded),
                              title: Text(
                                state.selectedTranslation?.displayEndonym ??
                                    'Select language',
                              ),
                              subtitle: state.selectedTranslation == null
                                  ? null
                                  : Text(
                                      state.selectedTranslation!.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              trailing: const AppIcon(
                                Icons.chevron_right_rounded,
                              ),
                              onTap: widget.onTranslationTap,
                            ),
                            ReaderTextSizeControl(
                              title: 'Translation size',
                              value: _translationScale,
                              onPreviewChanged: (value) =>
                                  setState(() => _translationScale = value),
                              onChanged: (value) {
                                setState(() => _translationScale = value);
                                widget.onTranslationFontScaleChanged(value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto follow audio'),
                        value: state.followAudio,
                        onChanged: widget.onFollowAudioChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final state = widget.state;
    final ayahs = state.ayahs.take(3).toList(growable: false);
    final wordsByVerse = <String, List<QuranWord>>{};
    for (final word in state.pageWordsByPage.values.expand((words) => words)) {
      wordsByVerse.putIfAbsent(word.verseKey, () => []).add(word);
    }
    final script = widget.themeState.quranArabicScript;
    return ColoredBox(
      color: QuranTheme.surfaceVariant(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Row(
              children: [
                Text('Preview', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.surah?.englishName ?? '',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _previewScrollController,
              thumbVisibility: true,
              thickness: 3,
              radius: const Radius.circular(3),
              child: ListView(
                controller: _previewScrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  IgnorePointer(
                    child: state.ayahTextLayout == QuranAyahTextLayout.combined
                        ? ColoredBox(
                            color: QuranTheme.surface(context),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CombinedPageText(
                                ayahs: ayahs
                                    .map((ayah) => ayah.forScript(script))
                                    .toList(),
                                pageWords: [
                                  for (final ayah in ayahs)
                                    ...QuranWord.forAyahText(
                                      ayah,
                                      wordsByVerse[ayah.verseKey] ?? const [],
                                      script,
                                    ),
                                ],
                                selectedVerseKey: null,
                                activeAudioVerseKey: null,
                                activeWordVerseKey: null,
                                activeWordIndex: null,
                                currentVerseKey: null,
                                arabicFontScale: _arabicScale,
                                translationFontScale: _translationScale,
                                arabicScript: script,
                                showTranslation: state.showTranslation,
                                translationsByVerse: state.translationsByVerse,
                                selectedTranslation: state.selectedTranslation,
                                selectionEnabled: false,
                                onAyahTap: (_) {},
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final ayah in ayahs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _AyahCard(
                                    ayah: ayah,
                                    translation:
                                        state.selectedTranslation == null
                                        ? ayah.translation
                                        : state.translationsByVerse[ayah
                                                  .verseKey] ??
                                              '',
                                    translationResource:
                                        state.selectedTranslation,
                                    additionalTranslations: [
                                      for (final resource
                                          in state.selectedTranslations)
                                        if (resource.id !=
                                            state.selectedTranslation?.id)
                                          _DisplayedTranslation(
                                            resource: resource,
                                            text:
                                                state
                                                    .translationsByResource[resource
                                                    .id]?[ayah.verseKey] ??
                                                '',
                                          ),
                                    ],
                                    arabicFontScale: _arabicScale,
                                    translationFontScale: _translationScale,
                                    arabicScript: script,
                                    showTranslation: state.showTranslation,
                                    activeWordIndex: null,
                                    isAudioActive: false,
                                    isSelected: false,
                                    isCurrentLastRead: false,
                                    isBookmarked: false,
                                    onSelect: null,
                                    onBookmarkToggle: () {},
                                    bookmarkTooltip: 'Save',
                                    removeBookmarkTooltip: 'Unsave',
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  const _ReaderHeader({
    required this.arabicName,
    required this.verseCount,
    required this.arabicScript,
    this.bismillah,
  });

  final String arabicName;
  final int verseCount;
  final QuranArabicScript arabicScript;
  final Widget? bismillah;

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
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  arabicName,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontFamily: arabicScript.fontFamily,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
          if (bismillah != null) ...[const SizedBox(height: 16), bismillah!],
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
  const _GoldOrnament({this.flip = false, this.compact = false});

  final bool flip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD6A657);
    return ExcludeSemantics(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
        child: SizedBox(
          width: compact ? 38 : 52,
          height: compact ? 14 : 30,
          child: Row(
            children: [
              AppIcon(
                Icons.auto_awesome_rounded,
                color: gold,
                size: compact ? 5 : 8,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(height: 1, color: gold.withValues(alpha: 0.6)),
                    const SizedBox(height: 3),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: Container(
                        height: 1,
                        color: gold.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              AppIcon(
                Icons.auto_awesome_rounded,
                color: gold,
                size: compact ? 10 : 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StructureMarkers extends StatelessWidget {
  const _StructureMarkers({required this.ayahs, required this.startsPage});

  final List<QuranAyah> ayahs;
  final bool startsPage;

  @override
  Widget build(BuildContext context) {
    final markers = <String>{};
    for (final ayah in ayahs) {
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
    if (markers.isEmpty && !startsPage) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: QuranTheme.subText(context, 0.66),
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.4,
    );
    return Padding(
      padding: EdgeInsets.only(top: startsPage ? 10 : 0, bottom: 8),
      child: Column(
        children: [
          if (startsPage)
            Row(
              children: [
                Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: QuranTheme.outline(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Page ${ayahs.first.page}', style: style),
                ),
                Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: QuranTheme.outline(context),
                  ),
                ),
              ],
            ),
          if (markers.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: startsPage ? 4 : 0),
              child: Text(
                markers.join(' · '),
                textAlign: TextAlign.center,
                style: style,
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
    this.arabicScript = QuranArabicScript.uthmani,
  });

  final QuranAyah ayah;
  final QuranArabicScript arabicScript;
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
    final arabicText = _cleanArabic(ayah.textForScript(arabicScript));
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
                      arabicScript: arabicScript,
                      activeWordIndex: ayah.wordIndexForScript(
                        arabicScript,
                        activeWordIndex,
                      ),
                      selected: isAudioActive || isSelected,
                      highlighterActive: isAudioActive,
                      lineHeight: 1.74,
                    ),
                  ),
                ],
              ),
              AnimatedExpansion(
                expanded: showTranslation && visibleTranslation.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 2),
                  ],
                ),
              ),
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
    return QuranArabicScript.cleanUthmaniText(value);
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
              AppIcon(Icons.brightness_6_rounded, color: iconColor, size: 40),
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
      icon: AppIcon(
        icon,
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.black.withValues(alpha: 0.82),
      ),
    );
  }
}
