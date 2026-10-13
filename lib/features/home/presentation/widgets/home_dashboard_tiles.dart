import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../prayer/presentation/pages/prayer_page.dart'
    show showIslamicCalendarSheet;
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/presentation/widgets/animated_prayer_arc.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../domain/entities/daily_ayah.dart';
import '../../domain/entities/home_tile.dart';
import 'home_daily_ayah_tile.dart';
import 'home_image_card.dart';
import 'home_reading_goal_tile.dart';
import 'home_tile_image.dart';

class HomeDashboardTiles extends StatefulWidget {
  const HomeDashboardTiles({
    super.key,
    required this.settingsStore,
    required this.prayerTimes,
    required this.onRefreshTimes,
    this.readingDashboard,
    this.dailyAyah,
    this.loading = false,
    this.dailyAyahErrorMessage,
  });

  final SettingsStore settingsStore;
  final DailyPrayerTimes? prayerTimes;
  final VoidCallback onRefreshTimes;
  final ReadingDashboard? readingDashboard;
  final DailyAyah? dailyAyah;
  final bool loading;
  final String? dailyAyahErrorMessage;

  @override
  State<HomeDashboardTiles> createState() => _HomeDashboardTilesState();
}

class _HomeDashboardTilesState extends State<HomeDashboardTiles> {
  late List<HomeTile> _tiles;

  @override
  void initState() {
    super.initState();
    _tiles = HomeTile.fromIds(widget.settingsStore.homeTileIds);
  }

  Future<void> _customize() async {
    final result = await showModalBottomSheet<List<HomeTile>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _HomeTilesEditor(tiles: _tiles, store: widget.settingsStore),
    );
    if (mounted && result != null) setState(() => _tiles = result);
  }

  void _open(HomeTile tile) {
    if (tile == HomeTile.islamicCalendar) {
      showIslamicCalendarSheet(context);
      return;
    }
    if (tile == HomeTile.qibla) {
      context.read<ShellCubit>().openQiblaFinder();
      return;
    }
    context.push(switch (tile) {
      HomeTile.tasbieh => AppRoutes.tasbiehPath(),
      HomeTile.bookmarks => AppRoutes.quranBookmarksPath(),
      HomeTile.fasting => AppRoutes.ramadanPath(),
      HomeTile.todayReadingGoal => AppRoutes.readingGoalsPath(),
      HomeTile.prayerJournal => AppRoutes.prayerTrackingPath(),
      HomeTile.duas => AppRoutes.duasPath(),
      HomeTile.divineNames => AppRoutes.divineNamesPath(),
      HomeTile.hifz => AppRoutes.hifzPath(),
      HomeTile.notes => AppRoutes.quranNotesPath(),
      HomeTile.mosques => AppRoutes.mosquesPath(),
      HomeTile.qibla ||
      HomeTile.islamicCalendar ||
      HomeTile.dailyAyah => throw StateError('This tile opens without a route'),
    });
  }

  Widget _buildTile(HomeTile tile) => KeyedSubtree(
    key: ValueKey(tile),
    child: switch (tile) {
      HomeTile.fasting => _FastingTile(
        times: widget.prayerTimes,
        onRefresh: widget.onRefreshTimes,
      ),
      HomeTile.todayReadingGoal => HomeReadingGoalTile(
        dashboard: widget.readingDashboard,
        loading: widget.loading,
        onTap: () => _open(tile),
        onRetry: widget.onRefreshTimes,
      ),
      HomeTile.dailyAyah => HomeDailyAyahTile(
        settingsStore: widget.settingsStore,
        dailyAyah: widget.dailyAyah,
        loading: widget.loading,
        errorMessage: widget.dailyAyahErrorMessage,
        onRetry: widget.onRefreshTimes,
      ),
      _ => HomeImageCard(
        title: tile.label,
        icon: tile.icon,
        image: HomeTileImage.assetFor(tile),
        onTap: () => _open(tile),
      ),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your daily companions',
                  style: MediaQuery.textScalerOf(context).scale(1) > 1.3
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _customize,
                tooltip: 'Customize Home',
                icon: const AppIcon(Icons.tune_rounded, size: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_tiles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _customize,
              icon: const AppIcon(Icons.add_rounded),
              label: const Text('Add tiles'),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final single = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final contentWidth = (constraints.maxWidth - 40).clamp(
              0.0,
              constraints.maxWidth,
            );
            final width = (contentWidth * 0.62).clamp(0.0, 260.0);
            final rows = <Widget>[];
            for (var i = 0; i < _tiles.length;) {
              if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
              final tile = _tiles[i];
              if (tile.fullWidth || single) {
                rows.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTile(tile),
                  ),
                );
                i++;
                continue;
              }
              final shortcuts = <HomeTile>[];
              while (i < _tiles.length && !_tiles[i].fullWidth) {
                shortcuts.add(_tiles[i++]);
              }
              rows.add(
                SingleChildScrollView(
                  key: PageStorageKey('home-companions-${tile.name}'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        var index = 0;
                        index < shortcuts.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 12),
                        SizedBox(
                          width: shortcuts.length == 1 ? contentWidth : width,
                          child: _buildTile(shortcuts[index]),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          },
        ),
      ],
    );
  }
}

extension _TilePresentation on HomeTile {
  IconData get icon => switch (this) {
    HomeTile.tasbieh => Icons.trip_origin_rounded,
    HomeTile.qibla => Icons.explore_outlined,
    HomeTile.bookmarks => Icons.bookmark_border_rounded,
    HomeTile.fasting => Icons.restaurant_rounded,
    HomeTile.prayerJournal => Icons.fact_check_outlined,
    HomeTile.duas => Icons.volunteer_activism_outlined,
    HomeTile.divineNames => Icons.auto_awesome_outlined,
    HomeTile.hifz => Icons.school_rounded,
    HomeTile.notes => Icons.edit_note_rounded,
    HomeTile.mosques => Icons.mosque_outlined,
    HomeTile.islamicCalendar => Icons.calendar_month_outlined,
    HomeTile.todayReadingGoal => Icons.auto_stories_outlined,
    HomeTile.dailyAyah => Icons.wb_sunny_outlined,
  };

  bool get fullWidth =>
      this == HomeTile.fasting ||
      this == HomeTile.todayReadingGoal ||
      this == HomeTile.dailyAyah;

  String get label => switch (this) {
    HomeTile.tasbieh => 'Tasbieh',
    HomeTile.qibla => 'Qibla Finder',
    HomeTile.bookmarks => 'Bookmarks',
    HomeTile.fasting => 'Fasting times',
    HomeTile.prayerJournal => 'Prayer journal',
    HomeTile.duas => 'Duas',
    HomeTile.divineNames => 'Names of Allah',
    HomeTile.hifz => 'Memorization',
    HomeTile.notes => 'Notes',
    HomeTile.mosques => 'Nearby mosques',
    HomeTile.islamicCalendar => 'Islamic calendar',
    HomeTile.todayReadingGoal => "Today's reading goal",
    HomeTile.dailyAyah => 'Daily inspiration',
  };
}

class _FastingTile extends StatelessWidget {
  const _FastingTile({required this.times, required this.onRefresh});
  final DailyPrayerTimes? times;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE8DCCA);
    final buttonStyle = TextButton.styleFrom(foregroundColor: Colors.white);
    return PremiumSurface(
      showBorder: false,
      padding: EdgeInsets.zero,
      color: const Color(0xFF172A27),
      child: Ink(
        decoration: BoxDecoration(
          image: DecorationImage(
            opacity: 0.86,
            image: ResizeImage(
              AssetImage(HomeTileImage.assetFor(HomeTile.fasting)),
              width: 720,
            ),
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.3),
            onError: (error, stack) =>
                debugPrint('Fasting card image unavailable: $error'),
          ),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB3172A27),
                Color(0x33172A27),
                Color(0xE6172A27),
                Color(0xFF172A27),
              ],
              stops: [0, 0.3, 0.65, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PrayerNowTicker(
              builder: (context, now) {
                final current =
                    times != null && DateUtils.isSameDay(times!.date, now);
                final byName = {
                  if (current)
                    for (final entry in times!.entries) entry.name: entry.time,
                };
                final fajr = byName[PrayerTimeName.fajr],
                    maghrib = byName[PrayerTimeName.maghrib];
                final ready = fajr != null && maghrib != null;
                final ramadan =
                    HijriCalendarConfig.fromGregorian(now).hMonth == 9;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AppIcon(
                            HomeTile.fasting.icon,
                            size: 20,
                            strokeWidth: 1.1,
                            applyTextScaling: true,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fasting times',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ramadan ? 'Ramadan' : 'Daily fasting',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: accent),
                    ),
                    const SizedBox(height: 72),
                    if (ready) ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact =
                              constraints.maxWidth < 290 ||
                              MediaQuery.textScalerOf(context).scale(1) > 1.3;
                          final metrics = [
                            _FastingTime(
                              label: 'Suhoor ends',
                              time: fajr,
                              icon: Icons.wb_twilight_outlined,
                              accent: accent,
                            ),
                            _FastingTime(
                              label: 'Iftar',
                              time: maghrib,
                              icon: Icons.wb_twilight_rounded,
                              accent: accent,
                            ),
                          ];
                          return compact
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    metrics[0],
                                    const SizedBox(height: 16),
                                    metrics[1],
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: metrics[0]),
                                    const SizedBox(width: 20),
                                    Expanded(child: metrics[1]),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${times!.location.name} · ${DateFormat('d MMM').format(times!.date)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ] else ...[
                      const Text(
                        'Today\'s fasting times are unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          style: buttonStyle,
                          onPressed: onRefresh,
                          icon: const AppIcon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh times'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            style: buttonStyle,
                            onPressed: () =>
                                context.push(AppRoutes.fastingJournalPath()),
                            icon: const AppIcon(
                              Icons.fact_check_outlined,
                              size: 18,
                            ),
                            label: const Text('Fasting journal'),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            width: 12,
                            thickness: 0.6,
                            color: Colors.white24,
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            style: buttonStyle,
                            onPressed: () =>
                                context.push(AppRoutes.ramadanPath()),
                            icon: const AppIcon(
                              Icons.nightlight_outlined,
                              size: 18,
                            ),
                            label: const Text('Fasting Plan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FastingTime extends StatelessWidget {
  const _FastingTime({
    required this.label,
    required this.time,
    required this.icon,
    required this.accent,
  });
  final String label;
  final DateTime time;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          AppIcon(icon, size: 18, color: accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        DateFormat.jm().format(time),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _HomeTilesEditor extends StatefulWidget {
  const _HomeTilesEditor({required this.tiles, required this.store});
  final List<HomeTile> tiles;
  final SettingsStore store;
  @override
  State<_HomeTilesEditor> createState() => _HomeTilesEditorState();
}

class _HomeTilesEditorState extends State<_HomeTilesEditor> {
  late final List<HomeTile> _draft = List.of(widget.tiles);
  bool _saving = false;
  String? _error;

  void _reorder(int oldIndex, int newIndex) {
    if (_saving) return;
    setState(() {
      _draft.insert(newIndex, _draft.removeAt(oldIndex));
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.setHomeTileIds(
        _draft.map((tile) => tile.name).toList(),
      );
      if (mounted) Navigator.of(context).pop(List<HomeTile>.of(_draft));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your Home. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = HomeTile.values
        .where((tile) => !_draft.contains(tile))
        .toList();
    return PopScope(
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: AppSheet(
          title: 'Customize Home',
          scrollableChild: true,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                Expanded(
                  // Keep thumbnail ink on a clipped material inside the viewport.
                  child: Material(
                    color: QuranTheme.surface(context),
                    clipBehavior: Clip.hardEdge,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'On your Home',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                        SliverReorderableList(
                          itemCount: _draft.length,
                          onReorderItem: _reorder,
                          itemBuilder: (context, index) {
                            final tile = _draft[index];
                            return Material(
                              key: ValueKey(tile),
                              color: QuranTheme.surface(context),
                              child: Semantics(
                                customSemanticsActions: _saving
                                    ? null
                                    : {
                                        if (index > 0)
                                          const CustomSemanticsAction(
                                            label: 'Move up',
                                          ): () =>
                                              _reorder(index, index - 1),
                                        if (index < _draft.length - 1)
                                          const CustomSemanticsAction(
                                            label: 'Move down',
                                          ): () =>
                                              _reorder(index, index + 1),
                                      },
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: tile == HomeTile.dailyAyah
                                      ? const AppIcon(
                                          Icons.wb_sunny_rounded,
                                          size: 28,
                                        )
                                      : HomeTileImage(
                                          tile: tile,
                                          width: 44,
                                          height: 44,
                                        ),
                                  title: Text(tile.label),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Remove ${tile.label}',
                                        onPressed: _saving
                                            ? null
                                            : () => setState(
                                                () => _draft.remove(tile),
                                              ),
                                        icon: const AppIcon(
                                          Icons.remove_circle_outline_rounded,
                                          size: 20,
                                        ),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        enabled: !_saving,
                                        child: Tooltip(
                                          message: 'Reorder ${tile.label}',
                                          child: const SizedBox(
                                            width: 44,
                                            height: 48,
                                            child: AppIcon(
                                              Icons.drag_handle_rounded,
                                              size: 22,
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
                        if (_draft.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No tiles selected'),
                            ),
                          ),
                        if (available.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 24,
                                bottom: 12,
                              ),
                              child: Text(
                                'Add tiles',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                          SliverList.builder(
                            itemCount: available.length,
                            itemBuilder: (context, index) {
                              final tile = available[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: tile == HomeTile.dailyAyah
                                    ? const AppIcon(
                                        Icons.wb_sunny_rounded,
                                        size: 28,
                                      )
                                    : HomeTileImage(
                                        tile: tile,
                                        width: 44,
                                        height: 44,
                                      ),
                                title: Text(tile.label),
                                subtitle: tile == HomeTile.fasting
                                    ? const Text('Suhoor and Iftar')
                                    : null,
                                trailing: IconButton(
                                  tooltip: 'Add ${tile.label}',
                                  onPressed: _saving
                                      ? null
                                      : () => setState(() => _draft.add(tile)),
                                  icon: const AppIcon(
                                    Icons.add_rounded,
                                    size: 20,
                                  ),
                                ),
                                onTap: _saving
                                    ? null
                                    : () => setState(() => _draft.add(tile)),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _draft
                                ..clear()
                                ..addAll(HomeTile.defaults);
                            }),
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving...' : 'Save Home'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
