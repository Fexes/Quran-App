import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_banner_phase.dart';
import '../../../prayer_times/domain/entities/prayer_day_progress.dart';
import '../../../prayer_times/presentation/widgets/animated_prayer_arc.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/data/stores/quran_user_data_store.dart';
import '../../../quran/domain/entities/surah_image_catalog.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../../shell/presentation/bloc/shell_state.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_dashboard_tiles.dart';

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
        lastReadChanges: getIt.isRegistered<QuranUserDataStore>()
            ? getIt<QuranUserDataStore>().lastReadChanges
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
        style: PremiumSurfaceShadowStyle.none,
        child: AdaptiveInsetArea(
          top: true,
          bottom: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: ShellScreenHeader(
                  icon: Icons.home_rounded,
                  title: 'Assalamu alaikum',
                  subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  actions: [
                    ShellHeaderAction(
                      icon: Icons.search_rounded,
                      tooltip: 'Search Quran',
                      onTap: () => context.push(AppRoutes.quranSearchPath()),
                    ),
                    ShellHeaderAction(
                      icon: Icons.tune_rounded,
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
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      QuranFloatingAudioPlayer.scrollInset(context),
                    ),
                    children: [
                      BlocBuilder<HomeCubit, HomeState>(
                        buildWhen: (previous, next) =>
                            previous.dailyPrayerTimes !=
                                next.dailyPrayerTimes ||
                            previous.prayerErrorMessage !=
                                next.prayerErrorMessage,
                        builder: (context, state) {
                          return _NextPrayerCard(
                            dailyPrayerTimes: state.dailyPrayerTimes,
                            title: l10n.nextPrayerTitle,
                            errorMessage: state.prayerErrorMessage,
                            onRetry: context.read<HomeCubit>().load,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
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
                                final title =
                                    surah?.englishName ?? 'Al-Fatihah';
                                final progress =
                                    lastRead == null || surah == null
                                    ? 0.0
                                    : (lastRead.ayahNumber / surah.ayahCount)
                                          .clamp(0.0, 1.0);
                                final targetSurah = lastRead?.surahNumber ?? 1;
                                return _ContinueReadingCard(
                                  surahNumber: targetSurah,
                                  title: title,
                                  subtitle: subtitle,
                                  progress: progress,
                                  progressLabel:
                                      lastRead == null || surah == null
                                      ? ''
                                      : '${lastRead.ayahNumber} / ${surah.ayahCount}',
                                  buttonLabel: state.hasLastRead
                                      ? 'Resume'
                                      : 'Start',
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
                            const _HomeDestinations(),
                            const SizedBox(height: 26),
                          ],
                        ),
                      ),
                      BlocBuilder<HomeCubit, HomeState>(
                        buildWhen: (previous, next) =>
                            previous.dailyPrayerTimes !=
                                next.dailyPrayerTimes ||
                            previous.dailyAyah != next.dailyAyah ||
                            previous.readingDashboard != next.readingDashboard,
                        builder: (context, state) => HomeDashboardTiles(
                          settingsStore: getIt<SettingsStore>(),
                          prayerTimes: state.dailyPrayerTimes,
                          onRefreshTimes: context.read<HomeCubit>().load,
                          readingDashboard: state.readingDashboard,
                          dailyAyah: state.dailyAyah,
                          loading: state.status == HomeStatus.loading,
                          dailyAyahErrorMessage: state.dailyAyahErrorMessage,
                        ),
                      ),
                      const SizedBox(height: 22),
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
        showBorder: false,
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
              child: AppIcon(
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    error ?? 'Calculating prayer times',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      fontWeight: FontWeight.w500,
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
                icon: const AppIcon(Icons.refresh_rounded),
              ),
          ],
        ),
      );
    }

    return PrayerNowTicker(
      builder: (context, now) {
        final dayProgress = PrayerDayProgress.calculate(
          entries: dailyPrayerTimes!.entries,
          now: now,
        );
        final nextPrayer = dayProgress.nextPrayer;
        return Stack(
          children: [
            Positioned.fill(
              child: ArchitecturalBackdrop(
                prominent: true,
                imageAsset: PrayerBannerPhase.at(
                  entries: dailyPrayerTimes!.entries,
                  now: now,
                ).assetPath,
                overlayColor: const Color(0xA3000000),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dailyPrayerTimes!.location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => context
                              .read<ShellCubit>()
                              .setDestination(ShellDestination.prayer),
                          iconAlignment: IconAlignment.end,
                          icon: const AppIcon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: const Text('Prayer times'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextPrayer.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              DateFormat.jm().format(nextPrayer.time),
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.15,
                                fontWeight: FontWeight.w500,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayProgress.remainingLabel,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.surahNumber,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.buttonLabel,
    required this.onTap,
  });

  final int surahNumber;
  final String title;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      borderColor: QuranTheme.outline(context).withValues(alpha: 0.75),
      borderWidth: 0.6,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  SurahImageCatalog.fallbackAssetPathFor(surahNumber),
                  width: 68,
                  height: 84,
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 68,
                    height: 84,
                    child: AppIcon(Icons.menu_book_outlined, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Reading',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: QuranTheme.outline(context),
          ),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                progressLabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconAlignment: IconAlignment.end,
                label: Text(buttonLabel),
                icon: const AppIcon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeDestinationCard extends StatelessWidget {
  const _HomeDestinationCard({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.image,
    required this.imageAlignment,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final String image;
  final Alignment imageAlignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      borderColor: QuranTheme.outline(context).withValues(alpha: 0.75),
      borderWidth: 0.6,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Image.asset(
              image,
              opacity: const AlwaysStoppedAnimation(0.86),
              fit: BoxFit.cover,
              alignment: imageAlignment,
              cacheWidth: 600,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => ColoredBox(
                color: QuranTheme.surfaceVariant(context),
                child: const AppIcon(Icons.auto_stories_outlined, size: 36),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(icon, size: 18, strokeWidth: 1.1),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const AppIcon(Icons.arrow_outward_rounded, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDestinations extends StatelessWidget {
  const _HomeDestinations();

  @override
  Widget build(BuildContext context) {
    final shell = context.read<ShellCubit>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _HomeDestinationCard(
            title: 'Holy Quran',
            icon: Icons.menu_book_outlined,
            subtitle: 'Read and reflect',
            image: 'assets/images/companions/holy-quran.jpg',
            imageAlignment: Alignment.center,
            onTap: () => shell.setDestination(ShellDestination.quran),
          ),
          _HomeDestinationCard(
            title: 'Worship',
            icon: Icons.mosque_outlined,
            subtitle: 'Prayer and Qibla',
            image: ArchitecturalBackdrop.assetPath,
            imageAlignment: Alignment.centerRight,
            onTap: () => shell.setDestination(ShellDestination.prayer),
          ),
        ];
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return Column(
            children: [cards.first, const SizedBox(height: 12), cards.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: 12),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}
