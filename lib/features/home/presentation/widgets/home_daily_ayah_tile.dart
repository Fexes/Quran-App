import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/search/local_search_revision.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../library/presentation/widgets/library_share_sheet.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/quran_translation_text.dart';
import '../../../quran_audio/domain/entities/quran_audio_state.dart';
import '../../../quran_audio/presentation/cubit/quran_audio_cubit.dart';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/services/daily_library_content_service.dart';
import 'daily_ayah_share_sheet.dart';

enum _DailyKind { verse, hadith, dua }

typedef _DailyPassage = ({
  String id,
  String arabic,
  String translation,
  String title,
  String subtitle,
  String route,
  QuranTranslationResource? resource,
  String? languageCode,
  String? unavailableTranslation,
});

class HomeDailyAyahTile extends StatefulWidget {
  const HomeDailyAyahTile({
    super.key,
    required this.settingsStore,
    required this.dailyAyah,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final SettingsStore settingsStore;
  final DailyAyah? dailyAyah;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  State<HomeDailyAyahTile> createState() => _HomeDailyAyahTileState();
}

class _HomeDailyAyahTileState extends State<HomeDailyAyahTile> {
  final _pageController = PageController();
  final _cardHeights = <_DailyKind, double>{};
  _DailyKind _kind = _DailyKind.verse;
  DailyHadith? _hadith;
  bool _hadithUnavailable = false;
  DailyDua? _dua;
  final _loading = <_DailyKind>{};
  final _errors = <_DailyKind, String>{};
  final _saved = <String, bool>{};
  bool _saving = false;
  bool _startingAudio = false;
  final _expanded = <_DailyKind>{};
  int _duaCount = 0;
  int _libraryRevision = 0;
  int _bookmarkRevision = 0;
  Timer? _libraryRefresh;

  DateTime get _date => widget.dailyAyah?.date ?? DateTime.now();

  List<_DailyKind> get _visibleKinds => [
    for (final kind in _DailyKind.values)
      if (kind != _DailyKind.hadith || !_hadithUnavailable) kind,
  ];

  DailyLibraryContentService get _library => DailyLibraryContentService(
    hadithRepository: getIt<HadithRepository>(),
    azkarRepository: getIt<AzkarRepository>(),
    translationRepository: getIt<QuranTranslationRepository>(),
  );

  _DailyPassage? _passageFor(_DailyKind kind) {
    switch (kind) {
      case _DailyKind.verse:
        final value = widget.dailyAyah;
        if (value == null) return null;
        return (
          id: value.ayah.verseKey,
          arabic: value.ayah.textForScript(
            context.read<QuranThemeCubit>().state.quranArabicScript,
          ),
          translation: widget.settingsStore.quranTranslationVisible
              ? value.translation
              : '',
          title: value.surah.englishName,
          subtitle:
              'Surah ${value.surah.number} \u00b7 Ayah ${value.ayah.number}',
          route: AppRoutes.quranReaderPath(
            value.surah.number,
            ayahNumber: value.ayah.number,
          ),
          resource: value.translationResource,
          languageCode: value.translationResource?.resolvedLanguageCode,
          unavailableTranslation: null,
        );
      case _DailyKind.hadith:
        final value = _hadith;
        if (value == null) return null;
        return (
          id: value.item.id,
          arabic: value.item.arabic,
          translation:
              widget.settingsStore.libraryTranslationEnabled &&
                  value.translationAvailable
              ? value.item.translation
              : '',
          title: value.item.collectionName,
          subtitle: 'Hadith ${value.item.hadithNumber}',
          route: AppRoutes.hadithBookPath(
            value.item.bookId,
            hadithNumber: value.item.hadithNumber,
          ),
          resource: value.language.resource,
          languageCode: value.language.hadithCode,
          unavailableTranslation:
              !widget.settingsStore.libraryTranslationEnabled ||
                  value.translationAvailable
              ? null
              : 'Translation unavailable in ${value.language.label}',
        );
      case _DailyKind.dua:
        final value = _dua;
        if (value == null) return null;
        return (
          id: value.item.id,
          arabic: value.item.arabic,
          translation:
              widget.settingsStore.libraryTranslationEnabled &&
                  value.translationAvailable
              ? value.item.translation
              : '',
          title: value.item.title,
          subtitle: value.item.reference,
          route: AppRoutes.azkarCategoryPath(
            value.item.categoryId,
            itemId: value.item.id,
          ),
          resource: value.language.resource,
          languageCode: value.language.azkarCode,
          unavailableTranslation:
              !widget.settingsStore.libraryTranslationEnabled ||
                  value.translationAvailable
              ? null
              : 'Translation unavailable in ${value.language.label}',
        );
    }
  }

  @override
  void initState() {
    super.initState();
    LocalSearchRevision.changes.addListener(_onLocalContentChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshBookmark();
        _loadLibrary(_DailyKind.hadith);
      }
    });
  }

  @override
  void dispose() {
    LocalSearchRevision.changes.removeListener(_onLocalContentChanged);
    _libraryRefresh?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeDailyAyahTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDate = oldWidget.dailyAyah?.date;
    final changedDay = oldDate != null && !DateUtils.isSameDay(oldDate, _date);
    final changedLanguage =
        oldWidget.dailyAyah?.translationResource?.id !=
        widget.dailyAyah?.translationResource?.id;
    final refreshed = oldWidget.loading && !widget.loading;
    if (changedDay || changedLanguage || refreshed) {
      _libraryRevision++;
      _hadith = null;
      _hadithUnavailable = false;
      _syncDailyPage();
      _dua = null;
      _loading.clear();
      _errors.clear();
      _expanded.clear();
      if (changedDay) _duaCount = 0;
    }
    if (changedDay || changedLanguage || refreshed) {
      if (_kind != _DailyKind.verse) _loadLibrary(_kind, refresh: true);
      if (_kind != _DailyKind.hadith) {
        _loadLibrary(_DailyKind.hadith, refresh: true);
      }
      _refreshBookmark();
    } else if (oldWidget.dailyAyah != widget.dailyAyah) {
      _refreshBookmark();
    }
  }

  void _onLocalContentChanged() {
    _libraryRefresh?.cancel();
    _libraryRefresh = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _libraryRevision++;
      _loading.clear();
      _loadLibrary(_DailyKind.hadith, refresh: true);
      if (_kind == _DailyKind.dua) _loadLibrary(_DailyKind.dua, refresh: true);
    });
  }

  void _syncDailyPage() {
    final revision = _libraryRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != _libraryRevision ||
          !_pageController.hasClients) {
        return;
      }
      final index = _visibleKinds.indexOf(_kind);
      if (index >= 0 && _pageController.page?.round() != index) {
        _pageController.jumpToPage(index);
      }
    });
  }

  void _select(_DailyKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
    });
    _loadLibrary(kind);
    _refreshBookmark();
  }

  Future<void> _loadLibrary(_DailyKind kind, {bool refresh = false}) async {
    if (kind == _DailyKind.verse || _loading.contains(kind)) return;
    if (!refresh && _passageFor(kind) != null) return;
    final revision = _libraryRevision;
    final date = _date;
    setState(() {
      _loading.add(kind);
      _errors.remove(kind);
    });
    try {
      if (kind == _DailyKind.hadith) {
        final value = await _library.loadHadith(date);
        if (!mounted || revision != _libraryRevision) return;
        final moveToDua = value == null && _kind == _DailyKind.hadith;
        final changedVisibility = _hadithUnavailable != (value == null);
        setState(() {
          _hadith = value;
          _hadithUnavailable = value == null;
          if (moveToDua) _kind = _DailyKind.dua;
        });
        if (changedVisibility) _syncDailyPage();
        if (moveToDua) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || revision != _libraryRevision) return;
            _loadLibrary(_DailyKind.dua);
          });
        }
      } else {
        final value = await _library.loadDua(date);
        if (!mounted || revision != _libraryRevision) return;
        if (_dua?.item.id != value.item.id) _duaCount = 0;
        setState(() => _dua = value);
      }
      if (_kind == kind) _refreshBookmark();
    } catch (_) {
      if (mounted && revision == _libraryRevision) {
        setState(
          () => _errors[kind] = 'Today\'s ${kind.name} could not be loaded.',
        );
      }
    } finally {
      if (mounted && revision == _libraryRevision) {
        setState(() => _loading.remove(kind));
      }
    }
  }

  Future<void> _refreshBookmark() async {
    final revision = ++_bookmarkRevision;
    final kind = _kind;
    final passage = _passageFor(kind);
    if (passage == null) return;
    try {
      final saved = kind == _DailyKind.verse
          ? await getIt<QuranRepository>().isBookmarked(
              surahNumber: widget.dailyAyah!.surah.number,
              ayahNumber: widget.dailyAyah!.ayah.number,
            )
          : getIt<LibraryUserDataStore>().isBookmarked(passage.id);
      if (mounted &&
          revision == _bookmarkRevision &&
          _passageFor(kind)?.id == passage.id &&
          !_saving) {
        setState(() => _saved[passage.id] = saved);
      }
    } catch (_) {
      // Reading remains available if bookmark storage cannot be opened.
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleBookmark(_DailyKind kind) async {
    final passage = _passageFor(kind);
    if (passage == null || _saving) return;
    _bookmarkRevision++;
    setState(() => _saving = true);
    try {
      final saved = kind == _DailyKind.verse
          ? await getIt<QuranRepository>().toggleBookmark(
              surahNumber: widget.dailyAyah!.surah.number,
              ayahNumber: widget.dailyAyah!.ayah.number,
            )
          : await getIt<LibraryUserDataStore>().toggleBookmark(passage.id);
      if (mounted) setState(() => _saved[passage.id] = saved);
      HapticFeedback.selectionClick();
    } catch (_) {
      _showError('Could not update this bookmark. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share(_DailyKind kind) async {
    try {
      switch (kind) {
        case _DailyKind.verse:
          await showDailyAyahShareSheet(context, widget.dailyAyah!);
        case _DailyKind.hadith:
          final value = _hadith!;
          await showHadithShareSheet(
            context,
            value.item,
            languageCode: value.language.hadithCode,
            translationResource: value.language.resource,
            includeTranslation: widget.settingsStore.libraryTranslationEnabled,
            translationAvailable: value.translationAvailable,
          );
        case _DailyKind.dua:
          final value = _dua!;
          await showDhikrShareSheet(
            context,
            value.item,
            languageCode: value.language.azkarCode,
            translationResource: value.language.resource,
            includeTranslation: widget.settingsStore.libraryTranslationEnabled,
            translationAvailable: value.translationAvailable,
            includeTransliteration: false,
          );
      }
    } catch (_) {
      _showError('Could not open sharing. Try again.');
    }
  }

  Future<void> _playVerse() async {
    final value = widget.dailyAyah;
    if (value == null || _startingAudio) return;
    final audio = context.read<QuranAudioCubit>();
    setState(() => _startingAudio = true);
    try {
      if (audio.state.currentItem?.verseKey == value.ayah.verseKey) {
        await audio.togglePlayPause();
        return;
      }
      final repository = getIt<QuranRepository>();
      final reciters = await repository.getAudioReciters();
      final selectedId = await repository.getSelectedAudioReciterId();
      final reciter =
          reciters.where((item) => item.id == selectedId).firstOrNull ??
          reciters.firstOrNull;
      if (reciter == null) throw StateError('No reciter available.');
      if (!mounted) return;
      await audio.playAyah(
        ayah: value.ayah,
        surah: value.surah,
        reciter: reciter,
      );
    } catch (_) {
      _showError('Could not play this verse. Try again.');
    } finally {
      if (mounted) setState(() => _startingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: duration,
          alignment: Alignment.topCenter,
          curve: Curves.easeInOutCubic,
          child: SizedBox(
            height:
                _cardHeights[_kind] ?? _cardHeights[_DailyKind.verse] ?? 420,
            child: PageView.builder(
              controller: _pageController,
              allowImplicitScrolling: true,
              itemCount: _visibleKinds.length,
              onPageChanged: (index) => _select(_visibleKinds[index]),
              itemBuilder: (context, index) {
                final kind = _visibleKinds[index];
                return OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: _DailyCardSize(
                    onHeightChanged: (height) {
                      if (!mounted || _cardHeights[kind] == height) return;
                      setState(() => _cardHeights[kind] = height);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: _buildCard(context, kind),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final kind in _visibleKinds)
              Semantics(
                selected: kind == _kind,
                child: IconButton(
                  tooltip: _titleFor(kind),
                  onPressed: () {
                    if (duration == Duration.zero) {
                      _pageController.jumpToPage(_visibleKinds.indexOf(kind));
                    } else {
                      _pageController.animateToPage(
                        _visibleKinds.indexOf(kind),
                        duration: duration,
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  icon: AnimatedContainer(
                    duration: duration,
                    width: kind == _kind ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kind == _kind
                          ? QuranTheme.wordHighlight(context)
                          : QuranTheme.outline(context),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _titleFor(_DailyKind kind) => switch (kind) {
    _DailyKind.verse => 'Verse of the Day',
    _DailyKind.hadith => 'Hadith of the Day',
    _DailyKind.dua => 'Dua of the Day',
  };

  Widget _buildCard(BuildContext context, _DailyKind kind) {
    final theme = Theme.of(context);
    final themeState = context.watch<QuranThemeCubit>().state;
    final accent = QuranTheme.wordHighlight(context);
    final passage = _passageFor(kind);
    final expanded = _expanded.contains(kind);
    final saved = passage != null && _saved[passage.id] == true;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: saved ? 'Remove bookmark' : 'Save ${kind.name}',
          onPressed: passage == null || _saving
              ? null
              : () => _toggleBookmark(kind),
          isSelected: saved,
          selectedIcon: AppIcon(
            Icons.bookmark_rounded,
            size: 19,
            color: accent,
          ),
          icon: const AppIcon(
            Icons.bookmark_border_rounded,
            size: 19,
            strokeWidth: 1.1,
          ),
        ),
      ],
    );
    return PremiumSurface(
      borderColor: QuranTheme.outline(context).withValues(alpha: 0.75),
      borderWidth: 0.6,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      color: QuranTheme.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(
                Icons.wb_sunny_outlined,
                color: accent,
                size: 18,
                strokeWidth: 1.1,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _titleFor(kind),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: QuranTheme.subText(context, 0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!largeText) actions,
            ],
          ),
          if (largeText)
            Align(alignment: AlignmentDirectional.centerEnd, child: actions),
          const SizedBox(height: 18),
          if (passage == null)
            _DailyContentStatus(
              loading: kind == _DailyKind.verse
                  ? widget.loading
                  : _loading.contains(kind),
              errorMessage: kind == _DailyKind.verse
                  ? widget.errorMessage
                  : _errors[kind],
              label: kind == _DailyKind.verse
                  ? 'Selecting today\'s verse'
                  : 'Loading today\'s ${kind.name}',
              onRetry: () => kind == _DailyKind.verse
                  ? widget.onRetry()
                  : _loadLibrary(kind, refresh: true),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final script = themeState.quranArabicScript;
                final arabicStyle = theme.textTheme.headlineMedium!.copyWith(
                  fontFamily: script.fontFamily,
                  fontFamilyFallback: const ['NotoSansArabic'],
                  fontSize:
                      (theme.textTheme.headlineMedium?.fontSize ?? 28) *
                      themeState.quranArabicFontScale,
                  height: script.readerLineHeight,
                  fontWeight: FontWeight.w400,
                  color: QuranTheme.quranTextSelected(context),
                  letterSpacing: 0,
                );
                final arabicSpans = <InlineSpan>[];
                var offset = 0;
                if (kind != _DailyKind.verse) {
                  // The Mushaf font uses ornamental glyphs for some punctuation.
                  for (final mark in RegExp(
                    r'[\u060C\u061B\u061F,;:!?()\[\]{}"\u201C\u201D\u00AB\u00BB\u2026.\-]+',
                  ).allMatches(passage.arabic)) {
                    if (mark.start > offset) {
                      arabicSpans.add(
                        TextSpan(
                          text: passage.arabic.substring(offset, mark.start),
                        ),
                      );
                    }
                    arabicSpans.add(
                      TextSpan(
                        text: mark.group(0),
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                    );
                    offset = mark.end;
                  }
                }
                arabicSpans.add(
                  TextSpan(text: passage.arabic.substring(offset)),
                );
                final arabicSpan = TextSpan(
                  style: arabicStyle,
                  children: arabicSpans,
                );
                final translationStyle = theme.textTheme.bodyLarge!.copyWith(
                  fontFamilyFallback: const ['NotoSansArabic'],
                  fontSize:
                      (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                      themeState.quranTranslationFontScale,
                  color: QuranTheme.subText(context, 0.78),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                );
                bool exceeds(
                  InlineSpan text,
                  ui.TextDirection direction,
                  int lines,
                ) {
                  final painter = TextPainter(
                    text: text,
                    textDirection: direction,
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: lines,
                  )..layout(maxWidth: constraints.maxWidth);
                  final exceeds = painter.didExceedMaxLines;
                  painter.dispose();
                  return exceeds;
                }

                final expandable =
                    exceeds(arabicSpan, ui.TextDirection.rtl, 3) ||
                    exceeds(
                      TextSpan(
                        text: passage.translation,
                        style: QuranTheme.translationStyle(
                          translationStyle,
                          passage.languageCode,
                        ),
                      ),
                      passage.resource?.textDirection ?? ui.TextDirection.ltr,
                      4,
                    );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text.rich(
                      arabicSpan,
                      textAlign: TextAlign.center,
                      textDirection: ui.TextDirection.rtl,
                      maxLines: expanded ? null : 3,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                    ),
                    if (passage.translation.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      QuranTranslationText(
                        text: passage.translation,
                        resource: passage.resource,
                        languageCode: passage.languageCode,
                        maxLines: expanded ? null : 4,
                        overflow: expanded ? null : TextOverflow.ellipsis,
                        style: translationStyle,
                      ),
                    ] else if (passage.unavailableTranslation != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        passage.unavailableTranslation!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                    ],
                    if (expandable)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          if (!_expanded.add(kind)) _expanded.remove(kind);
                        }),
                        icon: AppIcon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 18,
                          strokeWidth: 1.1,
                        ),
                        label: Text(expanded ? 'Show less' : 'Read more'),
                      ),
                    const SizedBox(height: 18),
                    Text(
                      passage.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      passage.subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: QuranTheme.subText(context),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _share(kind),
                          icon: const AppIcon(
                            Icons.share_rounded,
                            size: 18,
                            strokeWidth: 1.1,
                          ),
                          label: const Text('Share'),
                          style: TextButton.styleFrom(
                            foregroundColor: QuranTheme.subText(context, 0.72),
                          ),
                        ),
                        if (kind == _DailyKind.verse)
                          BlocBuilder<QuranAudioCubit, QuranAudioState>(
                            buildWhen: (previous, next) =>
                                previous.currentItem?.verseKey !=
                                    next.currentItem?.verseKey ||
                                previous.status != next.status,
                            builder: (context, audio) {
                              final playing =
                                  audio.currentItem?.verseKey == passage.id &&
                                  audio.isPlaying;
                              final busy =
                                  _startingAudio ||
                                  (audio.currentItem?.verseKey == passage.id &&
                                      audio.isLoading);
                              return TextButton.icon(
                                onPressed: busy ? null : _playVerse,
                                icon: busy
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : AppIcon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 18,
                                      ),
                                label: Text(playing ? 'Pause' : 'Listen'),
                              );
                            },
                          ),
                        if (kind == _DailyKind.dua) ...[
                          TextButton.icon(
                            onPressed: _duaCount >= _dua!.item.repeatCount
                                ? null
                                : () {
                                    setState(() => _duaCount++);
                                    HapticFeedback.selectionClick();
                                  },
                            icon: AppIcon(
                              _duaCount >= _dua!.item.repeatCount
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _duaCount >= _dua!.item.repeatCount
                                  ? 'Completed'
                                  : 'Recited $_duaCount / ${_dua!.item.repeatCount}',
                            ),
                          ),
                          if (_duaCount > 0)
                            IconButton(
                              tooltip: 'Reset dua count',
                              onPressed: () => setState(() => _duaCount = 0),
                              icon: const AppIcon(
                                Icons.restart_alt_rounded,
                                size: 18,
                              ),
                            ),
                        ],
                        TextButton.icon(
                          onPressed: () async {
                            if (kind == _DailyKind.hadith &&
                                _hadith?.item.bookId == 'hadeethenc') {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AppSheet(
                                  title: passage.title,
                                  subtitle: passage.subtitle,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        passage.arabic,
                                        textDirection: TextDirection.rtl,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontFamily: themeState
                                                  .quranArabicScript
                                                  .fontFamily,
                                              fontSize:
                                                  25 *
                                                  themeState
                                                      .quranArabicFontScale,
                                              height: themeState
                                                  .quranArabicScript
                                                  .readerLineHeight,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                      if (passage.translation.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        QuranTranslationText(
                                          text: passage.translation,
                                          resource: passage.resource,
                                          languageCode: passage.languageCode,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontSize:
                                                    15 *
                                                    themeState
                                                        .quranTranslationFontScale,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              await context.push(passage.route);
                            }
                            if (mounted) {
                              _loadLibrary(kind, refresh: true);
                              _refreshBookmark();
                            }
                          },
                          iconAlignment: IconAlignment.end,
                          icon: const AppIcon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            strokeWidth: 1.1,
                          ),
                          label: Text(switch (kind) {
                            _DailyKind.verse => 'View Surah',
                            _DailyKind.hadith => 'Read Hadith',
                            _DailyKind.dua => 'View Dua',
                          }),
                          style: TextButton.styleFrom(
                            foregroundColor: QuranTheme.text(context),
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DailyCardSize extends SingleChildRenderObjectWidget {
  const _DailyCardSize({required this.onHeightChanged, required super.child});

  final ValueChanged<double> onHeightChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDailyCardSize(onHeightChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDailyCardSize renderObject,
  ) => renderObject.onHeightChanged = onHeightChanged;
}

class _RenderDailyCardSize extends RenderProxyBox {
  _RenderDailyCardSize(this.onHeightChanged);

  ValueChanged<double> onHeightChanged;
  double? _lastHeight;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _lastHeight) return;
    _lastHeight = height;
    // Report after layout so the carousel can resize without mutating the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeightChanged(height);
    });
  }
}

class _DailyContentStatus extends StatelessWidget {
  const _DailyContentStatus({
    required this.loading,
    required this.errorMessage,
    required this.label,
    required this.onRetry,
  });

  final bool loading;
  final String? errorMessage;
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      children: [
        if (loading)
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          AppIcon(
            Icons.menu_book_outlined,
            size: 28,
            color: QuranTheme.subText(context),
          ),
        const SizedBox(height: 12),
        Text(
          errorMessage ?? label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: QuranTheme.subText(context)),
        ),
        if (errorMessage != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const AppIcon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
      ],
    ),
  );
}
