import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_day_progress.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/presentation/widgets/animated_prayer_arc.dart';
import '../../../prayer_times/presentation/widgets/prayer_time_image.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../../shell/presentation/bloc/shell_state.dart';
import '../../domain/entities/daily_ayah.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(
        quranRepository: getIt<QuranRepository>(),
        prayerTimesRepository: getIt<PrayerTimesRepository>(),
        translationRepository: getIt<QuranTranslationRepository>(),
        readingProgressRepository:
            getIt.isRegistered<ReadingProgressRepository>()
            ? getIt<ReadingProgressRepository>()
            : null,
      )..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<ShellCubit, ShellState>(
      listenWhen: (previous, current) =>
          previous.destination != current.destination &&
          current.destination == ShellDestination.home,
      listener: (context, state) => context.read<HomeCubit>().load(),
      child: PremiumSurfaceShadowScope(
        style: PremiumSurfaceShadowStyle.subtle,
        child: AdaptiveInsetArea(
          top: true,
          bottom: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: ShellScreenHeader(
                  icon: Icons.menu_book_rounded,
                  title: 'Quran',
                  subtitle: 'Guidance for the heart',
                  actions: [
                    ShellHeaderAction(
                      icon: Icons.search_rounded,
                      tooltip: 'Search Quran',
                      onTap: () => context.push(AppRoutes.quranSearchPath()),
                    ),
                    ShellHeaderAction(
                      icon: Icons.settings_rounded,
                      tooltip: 'Settings',
                      onTap: () => context.read<ShellCubit>().setDestination(
                        ShellDestination.settings,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: context.read<HomeCubit>().load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 160),
                    children: [
                      BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          return _NextPrayerCard(
                            dailyPrayerTimes: state.dailyPrayerTimes,
                            title: l10n.nextPrayerTitle,
                            errorMessage: state.prayerErrorMessage,
                            onRetry: context.read<HomeCubit>().load,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          final lastRead = state.lastRead;
                          final surah = state.lastReadSurah;
                          final loading =
                              state.status == HomeStatus.loading &&
                              lastRead == null;
                          final subtitle =
                              state.readingErrorMessage ??
                              (loading
                                  ? 'Loading your reading position'
                                  : state.hasLastRead
                                  ? '${surah!.englishName} • ${l10n.ayahLabel} '
                                        '${lastRead!.ayahNumber}'
                                        '${lastRead.page == null ? '' : ' • Page ${lastRead.page}'}'
                                  : l10n.continueReadingEmptySubtitle);
                          final title = surah?.englishName ?? 'Al-Fatihah';
                          final progress = lastRead == null || surah == null
                              ? 0.0
                              : (lastRead.ayahNumber / surah.ayahCount).clamp(
                                  0.0,
                                  1.0,
                                );
                          final targetSurah = lastRead?.surahNumber ?? 1;
                          return _ContinueReadingCard(
                            title: title,
                            subtitle: subtitle,
                            progress: progress,
                            progressLabel: lastRead == null || surah == null
                                ? ''
                                : '${lastRead.ayahNumber} / ${surah.ayahCount}',
                            buttonLabel: state.hasLastRead ? 'Resume' : 'Start',
                            onTap: () => context.push(
                              AppRoutes.quranReaderPath(
                                targetSurah,
                                ayahNumber: lastRead?.ayahNumber,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          final dashboard = state.readingDashboard;
                          if (dashboard == null) {
                            return const SizedBox.shrink();
                          }
                          return _ReadingJourneyCard(
                            dashboard: dashboard,
                            onTap: () =>
                                context.push(AppRoutes.readingGoalsPath()),
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) => _DailyAyahCard(
                          dailyAyah: state.dailyAyah,
                          loading: state.status == HomeStatus.loading,
                          errorMessage: state.dailyAyahErrorMessage,
                          onRetry: context.read<HomeCubit>().load,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _QuickActionsRow(),
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
}

class _ReadingJourneyCard extends StatelessWidget {
  const _ReadingJourneyCard({required this.dashboard, required this.onTap});

  final ReadingDashboard dashboard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goal = dashboard.goal;
    final unit = switch (goal.metric) {
      ReadingGoalMetric.pages => 'pages',
      ReadingGoalMetric.verses => 'verses',
      ReadingGoalMetric.minutes => 'minutes',
    };
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s reading goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${dashboard.currentStreak} day streak',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: dashboard.goalProgress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            '${dashboard.todayValue} of ${goal.dailyTarget} $unit',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (dashboard.khatma != null) ...[
            const SizedBox(height: 4),
            Text(
              'Khatma pace: ${dashboard.khatma!.dailyPagesRequired(DateTime.now())} pages today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.68),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.dailyPrayerTimes,
    required this.title,
    required this.errorMessage,
    required this.onRetry,
  });

  final DailyPrayerTimes? dailyPrayerTimes;
  final String title;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (dailyPrayerTimes == null) {
      final error = errorMessage;
      return PremiumSurface(
        prominent: true,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: QuranTheme.softFill(
                  context,
                  Theme.of(context).colorScheme.primary,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                error == null
                    ? Icons.schedule_rounded
                    : Icons.location_off_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    error ?? 'Calculating prayer times',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (error == null)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              IconButton(
                tooltip: 'Retry prayer times',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      );
    }

    return PrayerNowTicker(
      builder: (context, now) {
        final formatter = DateFormat.jm();
        final dayProgress = PrayerDayProgress.calculate(
          entries: dailyPrayerTimes!.entries,
          now: now,
        );
        final nextPrayer = dayProgress.nextPrayer;
        final prayerName = nextPrayer.displayName;
        final time = formatter.format(nextPrayer.time);
        final phaseColor = prayerPhaseColor(dayProgress.phasePrayer?.name);
        return PremiumSurface(
          prominent: true,
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$title • ${dailyPrayerTimes!.location.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        prayerName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontFamily: 'Georgia',
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayProgress.remainingLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.64),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => context
                              .read<ShellCubit>()
                              .setDestination(ShellDestination.prayer),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          icon: const Icon(
                            Icons.notifications_rounded,
                            size: 16,
                          ),
                          label: const Text('View All Prayers'),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(color: QuranTheme.outline(context), width: 18),
                Expanded(
                  child: _PrayerTimeline(
                    dailyPrayerTimes: dailyPrayerTimes!,
                    activeName: dayProgress.currentPrayer?.name,
                    progress: dayProgress.arcProgress,
                    phaseColor: phaseColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrayerTimeline extends StatelessWidget {
  const _PrayerTimeline({
    required this.dailyPrayerTimes,
    required this.activeName,
    required this.progress,
    required this.phaseColor,
  });

  final DailyPrayerTimes dailyPrayerTimes;
  final PrayerTimeName? activeName;
  final double progress;
  final Color phaseColor;

  @override
  Widget build(BuildContext context) {
    final entries = dailyPrayerTimes.entries
        .where((entry) => entry.name != PrayerTimeName.sunrise)
        .toList();
    final visible = [
      for (final entry in entries)
        _PrayerSlot(
          entry.displayName,
          DateFormat('h:mm').format(entry.time),
          entry.name,
          active: entry.name == activeName,
        ),
    ];
    return Column(
      children: [
        Icon(Icons.wb_sunny_rounded, color: phaseColor, size: 24),
        AnimatedPrayerArc(
          progress: progress,
          color: phaseColor,
          height: 42,
          strokeWidth: 1.2,
          showGlow: false,
        ),
        Row(
          children: [
            for (final slot in visible)
              Expanded(
                child: _PrayerTimelineItem(slot: slot, activeColor: phaseColor),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrayerSlot {
  const _PrayerSlot(this.label, this.time, this.name, {this.active = false});

  final String label;
  final String time;
  final PrayerTimeName name;
  final bool active;
}

class _PrayerTimelineItem extends StatelessWidget {
  const _PrayerTimelineItem({required this.slot, required this.activeColor});

  final _PrayerSlot slot;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = slot.active ? activeColor : QuranTheme.subText(context, 0.60);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrayerTimeImage(
          name: slot.name,
          size: 20,
          monochrome: !slot.active,
          fallbackColor: color,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            slot.label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: slot.active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            slot.time,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: QuranTheme.text(context),
              fontSize: 9.5,
              fontWeight: slot.active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: slot.active ? 32 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
          ),
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Reading',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QuranTheme.subText(context, 0.68),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QuranTheme.subText(context, 0.70),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: QuranTheme.softFill(
                    context,
                    Theme.of(context).colorScheme.primary,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 29,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: QuranTheme.outline(context),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (progressLabel.isNotEmpty) ...[
                const SizedBox(width: 18),
                Text(
                  progressLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(108, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(buttonLabel),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final actions = [
      _QuickAction(
        Icons.bookmark_border_rounded,
        'Bookmarks',
        'Saved verses\nfor later',
        primary,
        onTap: () => context.push(AppRoutes.quranBookmarksPath()),
      ),
      _QuickAction(
        Icons.translate_rounded,
        'Translations',
        'Choose text and\noffline language',
        primary,
        onTap: () =>
            context.push(AppRoutes.quranDownloadsPath(showTranslations: true)),
      ),
      _QuickAction(
        Icons.trip_origin_rounded,
        'Tasbieh',
        'Swipe beads\nto count',
        primary,
        onTap: () => context.push(AppRoutes.tasbiehPath()),
      ),
      _QuickAction(
        Icons.file_download_rounded,
        'Downloads',
        'Offline Quran\nand audio',
        primary,
        onTap: () => context.push(AppRoutes.quranDownloadsPath()),
      ),
      _QuickAction(
        Icons.edit_rounded,
        'Notes',
        'Reflections and\nstudy points',
        primary,
        onTap: () => context.push(AppRoutes.quranNotesPath()),
      ),
      _QuickAction(
        Icons.mosque_rounded,
        'Qibla Finder',
        'Direction to\nthe Kaaba',
        primary,
        onTap: context.read<ShellCubit>().openQiblaFinder,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) => _QuickActionTile(action: actions[index]),
    );
  }
}

class _QuickAction {
  const _QuickAction(
    this.icon,
    this.label,
    this.subtitle,
    this.color, {
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: action.onTap,
      padding: const EdgeInsets.all(16),
      radius: 24,
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, action.color),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const Spacer(),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: QuranTheme.text(context),
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QuranTheme.subText(context, 0.62),
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAyahCard extends StatelessWidget {
  const _DailyAyahCard({
    required this.dailyAyah,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final DailyAyah? dailyAyah;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final item = dailyAyah;
    return PremiumSurface(
      onTap: item == null
          ? null
          : () => context.push(
              AppRoutes.quranReaderPath(
                item.surah.number,
                ayahNumber: item.ayah.number,
              ),
            ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Verse of the Day',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFD19A16),
                size: 26,
              ),
            ],
          ),
          if (item == null) ...[
            const SizedBox(height: 22),
            _DailyAyahStatus(
              loading: loading,
              errorMessage: errorMessage,
              onRetry: onRetry,
            ),
          ] else ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QuranTheme.outline(context)),
                  ),
                  child: Text(
                    item.ayah.number.toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    item.ayah.text,
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.rtl,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.translation,
              textAlign: TextAlign.center,
              textDirection:
                  item.translationResource?.textDirection ??
                  ui.TextDirection.ltr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: QuranTheme.subText(context, 0.72),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.reference,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.translationResource case final resource?) ...[
              const SizedBox(height: 4),
              Text(
                [
                  resource.name,
                  if (resource.authorName.trim().isNotEmpty)
                    resource.authorName,
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: QuranTheme.subText(context, 0.54),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _copyDailyAyah(context, item),
                  icon: const Icon(Icons.share_rounded, size: 19),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    foregroundColor: QuranTheme.subText(context, 0.72),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.quranReaderPath(
                      item.surah.number,
                      ayahNumber: item.ayah.number,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('View Surah'),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyAyahStatus extends StatelessWidget {
  const _DailyAyahStatus({
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          if (loading && message == null)
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            )
          else
            Icon(
              Icons.menu_book_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: 10),
          Text(
            message ?? 'Selecting today\'s ayah',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _copyDailyAyah(BuildContext context, DailyAyah dailyAyah) async {
  await Clipboard.setData(ClipboardData(text: dailyAyah.shareText));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Verse copied to share')));
}
