import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../domain/entities/quran_navigation.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../bloc/quran_list_bloc.dart';
import '../bloc/quran_list_event.dart';
import '../bloc/quran_list_state.dart';
import '../widgets/surah_tile.dart';
import '../widgets/quran_browse_tile.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = getIt<QuranRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              QuranListBloc(repository: repository)
                ..add(const QuranListStarted()),
        ),
      ],
      child: const _QuranView(),
    );
  }
}

class _QuranView extends StatefulWidget {
  const _QuranView();

  @override
  State<_QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<_QuranView> {
  final _scrollController = ScrollController();
  final _scrollProgress = ValueNotifier<double>(0);
  final _structureFutures =
      <QuranStructureKind, Future<List<QuranNavigationPoint>>>{};
  var _browseKind = QuranStructureKind.surah;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollProgress)
      ..dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxExtent = _scrollController.position.maxScrollExtent;
    final nextProgress = maxExtent <= 0
        ? 0.0
        : (_scrollController.offset / maxExtent).clamp(0.0, 1.0).toDouble();
    if ((nextProgress - _scrollProgress.value).abs() < 0.004) {
      return;
    }
    _scrollProgress.value = nextProgress;
  }

  void _onQueryChanged(BuildContext context, String value) {
    context.read<QuranListBloc>().add(QuranListQueryChanged(value));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _selectBrowseKind(QuranStructureKind kind) {
    setState(() => _browseKind = kind);
    _scrollProgress.value = 0;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<List<QuranNavigationPoint>> _navigationPoints(
    QuranStructureKind kind,
  ) {
    return _structureFutures.putIfAbsent(kind, () {
      final repository = getIt<QuranRepository>();
      if (repository is! QuranStructureRepository) {
        return Future.value(const []);
      }
      return (repository as QuranStructureRepository).getNavigationPoints(kind);
    });
  }

  void _jumpToItemIndex(int index, int itemCount) {
    if (!_scrollController.hasClients || itemCount <= 1) {
      return;
    }
    final targetProgress = (index / (itemCount - 1)).clamp(0.0, 1.0);
    final targetOffset =
        targetProgress * _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(
      targetOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      ),
    );
  }

  Widget _browseStack(
    QuranListState state, {
    List<QuranNavigationPoint>? points,
    Object? structureError,
  }) {
    final isSurah = _browseKind == QuranStructureKind.surah;
    final visibleSurahs = state.visibleSurahs;
    final itemCount = isSurah ? visibleSurahs.length : points?.length ?? 0;
    final canShowScrollbar =
        itemCount > 1 &&
        structureError == null &&
        (isSurah ? state.status == QuranListStatus.success : points != null);

    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: Color.alphaBlend(
          QuranTheme.surfaceVariant(context).withValues(alpha: 0.7),
          QuranTheme.surface(context),
        ),
        child: Stack(
          children: [
            _browseScrollView(
              context,
              state,
              points: points,
              structureError: structureError,
            ),
            if (canShowScrollbar)
              ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, child) => _QuranSectionScrollbar(
                  key: ValueKey(_browseKind),
                  viewportHeight: constraints.maxHeight,
                  topInset:
                      MediaQuery.paddingOf(this.context).top +
                      34 +
                      ShellScreenHeader.height(context),
                  itemCount: itemCount,
                  sectionLabel: _structureKindLabel(_browseKind),
                  previewLabel: (index) => isSurah
                      ? visibleSurahs[index].number.toString()
                      : points![index].index.toString(),
                  scrollProgress: progress,
                  onIndexChanged: (index) => _jumpToItemIndex(index, itemCount),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _browseScrollView(
    BuildContext context,
    QuranListState state, {
    List<QuranNavigationPoint>? points,
    Object? structureError,
  }) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 32, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => _onQueryChanged(context, value),
                  onSubmitted: (value) {
                    final query = value.trim();
                    if (query.isNotEmpty) {
                      context.push(AppRoutes.quranSearchPath(query));
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.quranSearchHint,
                    prefixIcon: const AppIcon(Icons.search_rounded),
                    filled: true,
                    fillColor: QuranTheme.surface(context),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: QuranTheme.outline(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _StructureTabs(
                  selected: _browseKind,
                  onSelected: _selectBrowseKind,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _browseKind == QuranStructureKind.surah
                            ? 'Surahs'
                            : _structureKindLabel(_browseKind),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if ((_browseKind == QuranStructureKind.surah &&
                            state.status == QuranListStatus.success) ||
                        points != null)
                      Text(
                        '${_browseKind == QuranStructureKind.surah ? state.visibleSurahs.length : points!.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_browseKind == QuranStructureKind.surah)
          switch (state.status) {
            QuranListStatus.initial ||
            QuranListStatus.loading => _QuranBrowseStatusSliver(
              child: AppLoadingView(label: l10n.loadingQuran),
            ),
            QuranListStatus.failure => _QuranBrowseStatusSliver(
              child: AppErrorView(
                title: l10n.quranLoadFailedTitle,
                message: state.errorMessage ?? l10n.quranLoadFailedMessage,
                onRetry: () =>
                    context.read<QuranListBloc>().add(const QuranListStarted()),
              ),
            ),
            QuranListStatus.success => _SurahSliverList(state: state),
          }
        else if (structureError != null)
          _QuranBrowseStatusSliver(
            child: AppErrorView(
              title: 'Navigation unavailable',
              message: structureError.toString(),
              onRetry: () {
                setState(() {
                  _structureFutures.remove(_browseKind);
                });
              },
            ),
          )
        else if (points == null)
          const _QuranBrowseStatusSliver(
            child: AppLoadingView(label: 'Loading Quran structure'),
          )
        else
          _StructureSliverList(
            kind: _browseKind,
            points: points,
            surahs: {for (final surah in state.surahs) surah.number: surah},
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdaptiveInsetArea(
      top: true,
      bottom: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: ShellScreenHeader(
              icon: Icons.menu_book_rounded,
              title: l10n.quranTitle,
              subtitle: l10n.quranSubtitle,
              actions: [
                ShellHeaderAction(
                  icon: Icons.search_rounded,
                  tooltip: l10n.quranOpenTextSearch,
                  onTap: () => context.push(AppRoutes.quranSearchPath()),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<QuranListBloc, QuranListState>(
              builder: (context, state) {
                if (_browseKind == QuranStructureKind.surah) {
                  return _browseStack(state);
                }
                return FutureBuilder<List<QuranNavigationPoint>>(
                  key: ValueKey(_browseKind),
                  future: _navigationPoints(_browseKind),
                  builder: (context, snapshot) => _browseStack(
                    state,
                    points: snapshot.data,
                    structureError: snapshot.error,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureTabs extends StatelessWidget {
  const _StructureTabs({required this.selected, required this.onSelected});

  final QuranStructureKind selected;
  final ValueChanged<QuranStructureKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final kind in QuranStructureKind.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: selected == kind,
                label: Text(_structureKindLabel(kind)),
                showCheckmark: false,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                selectedColor: QuranTheme.text(context),
                backgroundColor: QuranTheme.surface(context),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected == kind
                      ? QuranTheme.surface(context)
                      : QuranTheme.subText(context, 0.85),
                  fontWeight: selected == kind
                      ? FontWeight.w500
                      : FontWeight.w400,
                  letterSpacing: 0,
                ),
                onSelected: (_) => onSelected(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuranBrowseStatusSliver extends StatelessWidget {
  const _QuranBrowseStatusSliver({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(height: 260, child: Center(child: child)),
    );
  }
}

class _StructureSliverList extends StatelessWidget {
  const _StructureSliverList({
    required this.kind,
    required this.points,
    required this.surahs,
  });

  final QuranStructureKind kind;
  final List<QuranNavigationPoint> points;
  final Map<int, QuranSurah> surahs;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _QuranBrowseStatusSliver(
        child: Text('No navigation points available.'),
      );
    }
    final hasPageJump = kind == QuranStructureKind.page;
    return SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(
        18,
        0,
        32,
        QuranFloatingAudioPlayer.scrollInset(context),
      ),
      sliver: SliverList.builder(
        itemCount: points.length + (hasPageJump ? 1 : 0),
        itemBuilder: (context, index) {
          if (hasPageJump && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PageJumpControl(points: points),
            );
          }
          final point = points[index - (hasPageJump ? 1 : 0)];
          final surah = surahs[point.surahNumber];
          return Padding(
            key: ValueKey('${kind.name}-${point.index}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: QuranBrowseTile(
              number: point.index,
              title: point.label,
              arabicTitle: surah?.arabicName,
              details: [
                '${surah?.englishName ?? 'Surah ${point.surahNumber}'} ${point.verseKey}',
                if (kind != QuranStructureKind.page) 'Page ${point.page}',
                if (kind != QuranStructureKind.juz) 'Juz ${point.juz}',
              ],
              onTap: () => _openNavigationPoint(context, point),
            ),
          );
        },
      ),
    );
  }
}

class _PageJumpControl extends StatelessWidget {
  const _PageJumpControl({required this.points});

  final List<QuranNavigationPoint> points;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.go,
      decoration: InputDecoration(
        labelText: 'Jump to page',
        hintText: '1 to 604',
        prefixIcon: const AppIcon(Icons.my_library_books_outlined),
        filled: true,
        fillColor: QuranTheme.surface(context),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: QuranTheme.outline(context)),
        ),
      ),
      onSubmitted: (value) {
        final page = int.tryParse(value)?.clamp(1, 604);
        if (page == null) {
          return;
        }
        final point = points.where((point) => point.index == page).firstOrNull;
        if (point == null) return;
        _openNavigationPoint(context, point);
      },
    );
  }
}

Future<void> _openNavigationPoint(
  BuildContext context,
  QuranNavigationPoint point,
) async {
  final repository = getIt<QuranRepository>();
  if (repository is QuranStructureRepository) {
    await (repository as QuranStructureRepository).saveNavigationContext(
      kind: point.kind,
      index: point.index,
      page: point.page,
    );
  }
  if (context.mounted) {
    await context.push(
      AppRoutes.quranReaderPath(
        point.surahNumber,
        ayahNumber: point.ayahNumber,
      ),
    );
  }
}

String _structureKindLabel(QuranStructureKind kind) {
  return switch (kind) {
    QuranStructureKind.surah => 'Surah',
    QuranStructureKind.juz => 'Juz',
    QuranStructureKind.hizb => 'Hizb',
    QuranStructureKind.rub => 'Rub',
    QuranStructureKind.page => 'Page',
    QuranStructureKind.sajdah => 'Sajdah',
    QuranStructureKind.manzil => 'Manzil',
  };
}

class _QuranSectionScrollbar extends StatefulWidget {
  const _QuranSectionScrollbar({
    super.key,
    required this.viewportHeight,
    required this.topInset,
    required this.itemCount,
    required this.sectionLabel,
    required this.previewLabel,
    required this.scrollProgress,
    required this.onIndexChanged,
  });

  final double viewportHeight;
  final double topInset;
  final int itemCount;
  final String sectionLabel;
  final String Function(int index) previewLabel;
  final double scrollProgress;
  final ValueChanged<int> onIndexChanged;

  @override
  State<_QuranSectionScrollbar> createState() => _QuranSectionScrollbarState();
}

class _QuranSectionScrollbarState extends State<_QuranSectionScrollbar> {
  int? _previewIndex;
  var _isInteracting = false;

  int _indexForOffset(double dy, double height) {
    if (widget.itemCount <= 1 || height <= 0) {
      return 0;
    }
    final progress = (dy / height).clamp(0.0, 1.0);
    return (progress * (widget.itemCount - 1)).round();
  }

  void _changeIndex(int index) {
    setState(() {
      _isInteracting = true;
      _previewIndex = index;
    });
    widget.onIndexChanged(index);
  }

  void _settleIndex(int index) {
    setState(() {
      _isInteracting = false;
      _previewIndex = index;
    });
    widget.onIndexChanged(index);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_isInteracting) {
        setState(() => _previewIndex = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount <= 1) {
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
    final currentIndex = (widget.scrollProgress * (widget.itemCount - 1))
        .round();
    final visibleIndex = (_previewIndex ?? currentIndex).clamp(
      0,
      widget.itemCount - 1,
    );
    final showDrop = _isInteracting || _previewIndex != null;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = QuranTheme.isDark(context);
    return PositionedDirectional(
      end: 2,
      top: topOffset,
      width: 18,
      height: scrollbarHeight,
      child: Tooltip(
        message: 'Jump to ${widget.sectionLabel}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            const dropHeight = 44.0;
            const trackWidth = 12.0;
            const thumbSize = 9.5;
            const thumbInset = (trackWidth - thumbSize) / 2;
            final progress = widget.scrollProgress.clamp(0.0, 1.0).toDouble();
            final top =
                (visibleIndex / (widget.itemCount - 1)) *
                (height - dropHeight).clamp(0.0, double.infinity);
            final thumbTop =
                progress * (height - thumbSize).clamp(0.0, double.infinity);
            return Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: height,
                width: 18,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final index = _indexForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _settleIndex(index);
                  },
                  onVerticalDragStart: (details) {
                    final index = _indexForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _changeIndex(index);
                  },
                  onVerticalDragUpdate: (details) {
                    final index = _indexForOffset(
                      details.localPosition.dy,
                      height,
                    );
                    _changeIndex(index);
                  },
                  onVerticalDragEnd: (_) => _settleIndex(visibleIndex),
                  onVerticalDragCancel: () => setState(() {
                    _isInteracting = false;
                    _previewIndex = null;
                  }),
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.86),
                              width: 0.8,
                            ),
                          ),
                          child: const SizedBox(
                            width: thumbSize,
                            height: thumbSize,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: top,
                        end: 0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 130),
                          child: showDrop
                              ? IgnorePointer(
                                  key: const ValueKey(
                                    'quran-section-scrollbar-preview',
                                  ),
                                  child: ClipPath(
                                    clipper: const _QuranIndexTearDropClipper(),
                                    child: Container(
                                      width: 64,
                                      height: dropHeight,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 9,
                                      ),
                                      color: primary,
                                      child: Text(
                                        widget.previewLabel(visibleIndex),
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
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey(
                                    'quran-section-scrollbar-preview-hidden',
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

class _QuranIndexTearDropClipper extends CustomClipper<Path> {
  const _QuranIndexTearDropClipper();

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

class _SurahSliverList extends StatelessWidget {
  const _SurahSliverList({required this.state});

  final QuranListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.visibleSurahs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Text(
            l10n.quranNoResults,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsetsDirectional.fromSTEB(
        18,
        0,
        32,
        QuranFloatingAudioPlayer.scrollInset(context),
      ),
      sliver: SliverList.builder(
        itemCount: state.visibleSurahs.length,
        itemBuilder: (context, index) {
          final surah = state.visibleSurahs[index];
          return Padding(
            key: ValueKey(surah.number),
            padding: const EdgeInsets.only(bottom: 12),
            child: SurahTile(
              surah: surah,
              onTap: () async {
                final repository = getIt<QuranRepository>();
                if (repository is QuranStructureRepository) {
                  final page = await repository.getPageNumberForAyah(
                    surahNumber: surah.number,
                    ayahNumber: 1,
                  );
                  await (repository as QuranStructureRepository)
                      .saveNavigationContext(
                        kind: QuranStructureKind.surah,
                        index: surah.number,
                        page: page,
                      );
                }
                if (context.mounted) {
                  await context.push(AppRoutes.quranReaderPath(surah.number));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
