import 'package:flutter/material.dart';
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
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_navigation.dart';
import '../../domain/repositories/quran_repository.dart';
import '../bloc/quran_list_bloc.dart';
import '../bloc/quran_list_event.dart';
import '../bloc/quran_list_state.dart';
import '../widgets/surah_tile.dart';

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
  final _structureFutures =
      <QuranStructureKind, Future<List<QuranNavigationPoint>>>{};
  var _scrollProgress = 0.0;
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
    if ((nextProgress - _scrollProgress).abs() < 0.004) {
      return;
    }
    setState(() => _scrollProgress = nextProgress);
  }

  void _onQueryChanged(BuildContext context, String value) {
    context.read<QuranListBloc>().add(QuranListQueryChanged(value));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _selectBrowseKind(QuranStructureKind kind) {
    setState(() => _browseKind = kind);
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

  void _jumpToSurahIndex(int index, int itemCount) {
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
                final visibleSurahs = state.visibleSurahs;
                return Stack(
                  children: [
                    ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 0, 32, 112),
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
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              tooltip: l10n.quranOpenTextSearch,
                              onPressed: () =>
                                  context.push(AppRoutes.quranSearchPath()),
                              icon: const Icon(Icons.manage_search_rounded),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                QuranTheme.radiusControl,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _StructureTabs(
                          selected: _browseKind,
                          onSelected: _selectBrowseKind,
                        ),
                        const SizedBox(height: 14),
                        if (_browseKind == QuranStructureKind.surah)
                          switch (state.status) {
                            QuranListStatus.initial ||
                            QuranListStatus.loading => AppLoadingView(
                              label: l10n.loadingQuran,
                            ),
                            QuranListStatus.failure => AppErrorView(
                              title: l10n.quranLoadFailedTitle,
                              message:
                                  state.errorMessage ??
                                  l10n.quranLoadFailedMessage,
                              onRetry: () => context.read<QuranListBloc>().add(
                                const QuranListStarted(),
                              ),
                            ),
                            QuranListStatus.success => _SurahList(state: state),
                          }
                        else
                          FutureBuilder<List<QuranNavigationPoint>>(
                            future: _navigationPoints(_browseKind),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return AppErrorView(
                                  title: 'Navigation unavailable',
                                  message: snapshot.error.toString(),
                                  onRetry: () {
                                    setState(() {
                                      _structureFutures.remove(_browseKind);
                                    });
                                  },
                                );
                              }
                              final points = snapshot.data;
                              if (points == null) {
                                return const AppLoadingView(
                                  label: 'Loading Quran structure',
                                );
                              }
                              return _StructureList(
                                kind: _browseKind,
                                points: points,
                              );
                            },
                          ),
                      ],
                    ),
                    if (_browseKind == QuranStructureKind.surah &&
                        state.status == QuranListStatus.success)
                      _SurahScrollbar(
                        surahs: visibleSurahs,
                        scrollProgress: _scrollProgress,
                        onSurahIndexChanged: (index) =>
                            _jumpToSurahIndex(index, visibleSurahs.length),
                      ),
                  ],
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
                onSelected: (_) => onSelected(kind),
              ),
            ),
        ],
      ),
    );
  }
}

class _StructureList extends StatelessWidget {
  const _StructureList({required this.kind, required this.points});

  final QuranStructureKind kind;
  final List<QuranNavigationPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No navigation points available.'));
    }
    return Column(
      children: [
        if (kind == QuranStructureKind.page)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PageJumpControl(points: points),
          ),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(child: Text('${point.index}')),
                title: Text(
                  point.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Surah ${point.surahNumber}:${point.ayahNumber} • '
                  'Page ${point.page} • Juz ${point.juz}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openNavigationPoint(context, point),
              ),
            ),
          ),
      ],
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
      decoration: const InputDecoration(
        labelText: 'Jump to Mushaf page',
        hintText: '1 to 604',
        prefixIcon: Icon(Icons.my_library_books_outlined),
      ),
      onSubmitted: (value) {
        final page = int.tryParse(value)?.clamp(1, 604);
        if (page == null) {
          return;
        }
        final point = points[page - 1];
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

class _SurahScrollbar extends StatefulWidget {
  const _SurahScrollbar({
    required this.surahs,
    required this.scrollProgress,
    required this.onSurahIndexChanged,
  });

  final List<QuranSurah> surahs;
  final double scrollProgress;
  final ValueChanged<int> onSurahIndexChanged;

  @override
  State<_SurahScrollbar> createState() => _SurahScrollbarState();
}

class _SurahScrollbarState extends State<_SurahScrollbar> {
  int? _previewIndex;
  var _isInteracting = false;

  int _indexForOffset(double dy, double height) {
    if (widget.surahs.length <= 1 || height <= 0) {
      return 0;
    }
    final progress = (dy / height).clamp(0.0, 1.0);
    return (progress * (widget.surahs.length - 1)).round();
  }

  void _changeIndex(int index) {
    setState(() {
      _isInteracting = true;
      _previewIndex = index;
    });
    widget.onSurahIndexChanged(index);
  }

  void _settleIndex(int index) {
    setState(() {
      _isInteracting = false;
      _previewIndex = index;
    });
    widget.onSurahIndexChanged(index);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_isInteracting) {
        setState(() => _previewIndex = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.surahs.length <= 1) {
      return const SizedBox.shrink();
    }
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    const scrollbarHeightFactor = 0.44;
    const shellHeaderHeight = 96.0;
    final scrollbarHeight = screenHeight * scrollbarHeightFactor;
    final topOffset =
        ((screenHeight - scrollbarHeight) / 2) -
        topSafeArea -
        shellHeaderHeight;
    final currentIndex = (widget.scrollProgress * (widget.surahs.length - 1))
        .round();
    final visibleIndex = (_previewIndex ?? currentIndex).clamp(
      0,
      widget.surahs.length - 1,
    );
    final visibleSurah = widget.surahs[visibleIndex];
    final showDrop = _isInteracting || _previewIndex != null;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = QuranTheme.isDark(context);
    return PositionedDirectional(
      end: 2,
      top: topOffset,
      width: 18,
      height: scrollbarHeight,
      child: Tooltip(
        message: 'Jump to surah',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            const dropHeight = 44.0;
            const trackWidth = 12.0;
            const thumbSize = 9.5;
            const thumbInset = (trackWidth - thumbSize) / 2;
            final progress = widget.scrollProgress.clamp(0.0, 1.0).toDouble();
            final top =
                (visibleIndex / (widget.surahs.length - 1)) *
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
                                    'surah-scrollbar-preview',
                                  ),
                                  child: ClipPath(
                                    clipper: const _SurahTearDropClipper(),
                                    child: Container(
                                      width: 64,
                                      height: dropHeight,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 9,
                                      ),
                                      color: primary,
                                      child: Text(
                                        visibleSurah.number.toString(),
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
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey(
                                    'surah-scrollbar-preview-hidden',
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

class _SurahTearDropClipper extends CustomClipper<Path> {
  const _SurahTearDropClipper();

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

class _SurahList extends StatelessWidget {
  const _SurahList({required this.state});

  final QuranListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.visibleSurahs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Center(
          child: Text(
            l10n.quranNoResults,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final surah in state.visibleSurahs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
          ),
      ],
    );
  }
}
