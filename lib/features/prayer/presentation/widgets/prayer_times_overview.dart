import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_banner_phase.dart';
import '../../../prayer_times/domain/entities/prayer_day_progress.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/presentation/widgets/animated_prayer_arc.dart';
import '../../domain/entities/prayer_alert_settings.dart';

class PrayerTimesOverview extends StatelessWidget {
  const PrayerTimesOverview({
    super.key,
    required this.dailyTimes,
    required this.alertSettings,
    required this.alertsLoading,
    required this.onLocationTap,
    required this.onCalendarTap,
    required this.onAlertsTap,
    required this.onTogglePrayerAlert,
  });

  final DailyPrayerTimes dailyTimes;
  final PrayerAlertSettings alertSettings;
  final bool alertsLoading;
  final VoidCallback onLocationTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onAlertsTap;
  final Future<void> Function(PrayerTimeName name, bool enabled)
  onTogglePrayerAlert;

  @override
  Widget build(BuildContext context) {
    return PrayerNowTicker(
      builder: (context, now) {
        final progress = PrayerDayProgress.calculate(
          entries: dailyTimes.entries,
          nextDayFajr: dailyTimes.nextDayFajr,
          now: now,
        );
        final currentName = DateUtils.isSameDay(dailyTimes.date, now)
            ? progress.currentPrayer?.name
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrayerHero(
              dailyTimes: dailyTimes,
              progress: progress,
              bannerPhase: PrayerBannerPhase.at(
                entries: dailyTimes.entries,
                now: now,
              ),
              onLocationTap: onLocationTap,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DaylightTimes(entries: dailyTimes.entries),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prayer times',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton.icon(
                            onPressed: onCalendarTap,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: QuranTheme.subText(context),
                              alignment: AlignmentDirectional.centerStart,
                            ),
                            icon: const AppIcon(
                              Icons.calendar_today_outlined,
                              size: 14,
                            ),
                            label: Text(
                              DateFormat('EEE, d MMM').format(dailyTimes.date),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: alertsLoading ? null : onAlertsTap,
                        icon: const AppIcon(
                          Icons.notifications_none_rounded,
                          size: 20,
                        ),
                        label: Text(
                          alertSettings.schedulesAnything
                              ? 'Alerts (${alertSettings.activePrayerCount})'
                              : 'Alerts',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final entry in dailyTimes.entries)
                    _PrayerScheduleRow(
                      entry: entry,
                      isCurrent: entry.name == currentName,
                      isNext: entry.name == progress.nextPrayer.name,
                      alertEnabled: alertSettings.isEnabledFor(entry.name),
                      onToggleAlert: alertsLoading
                          ? null
                          : () => onTogglePrayerAlert(
                              entry.name,
                              !alertSettings.isEnabledFor(entry.name),
                            ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrayerHero extends StatelessWidget {
  const _PrayerHero({
    required this.dailyTimes,
    required this.progress,
    required this.bannerPhase,
    required this.onLocationTap,
  });

  final DailyPrayerTimes dailyTimes;
  final PrayerDayProgress progress;
  final PrayerBannerPhase bannerPhase;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendarConfig.fromGregorian(dailyTimes.date);
    final prayers = dailyTimes.entries
        .where((entry) => entry.name != PrayerTimeName.sunrise)
        .toList(growable: false);
    return Stack(
      children: [
        Positioned.fill(
          child: ArchitecturalBackdrop(
            prominent: true,
            imageAsset: bannerPhase.assetPath,
            overlayColor: const Color(0xA3000000),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                onPressed: onLocationTap,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const AppIcon(Icons.location_on_outlined, size: 18),
                label: Text(
                  dailyTimes.location.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                iconAlignment: IconAlignment.start,
              ),
              const SizedBox(height: 14),
              Text(
                '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Text(
                'Next prayer / ${progress.nextPrayer.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat.jm().format(progress.nextPrayer.time),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.15,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                progress.remainingLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ExcludeSemantics(
                child: SizedBox(
                  height: 52,
                  child: CustomPaint(
                    painter: PrayerArcPainter(
                      progress: progress.arcProgress,
                      color: const Color(0xFFE9D6AD),
                      outlineColor: Colors.white54,
                      strokeWidth: 1,
                      showGlow: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      ((constraints.maxWidth + 8) /
                              (MediaQuery.textScalerOf(context).scale(48) + 8))
                          .floor()
                          .clamp(1, prayers.length);
                  final itemWidth =
                      (constraints.maxWidth - (columns - 1) * 8) / columns;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 16,
                    children: [
                      for (final entry in prayers)
                        SizedBox(
                          width: itemWidth,
                          child: Semantics(
                            label:
                                '${entry.displayName}, ${entry.name == progress.nextPrayer.name ? 'next prayer at ' : ''}${DateFormat.jm().format(entry.time)}',
                            excludeSemantics: true,
                            child: Column(
                              children: [
                                Text(
                                  entry.displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        entry.name == progress.nextPrayer.name
                                        ? const Color(0xFFE9D6AD)
                                        : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat.jm().format(entry.time),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
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
      ],
    );
  }
}

class _DaylightTimes extends StatelessWidget {
  const _DaylightTimes({required this.entries});

  final List<PrayerTimeEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: QuranTheme.outline(context))),
      ),
      child: Row(
        children: [
          for (final name in [PrayerTimeName.sunrise, PrayerTimeName.maghrib])
            Expanded(
              child: Column(
                children: [
                  AppIcon(
                    name == PrayerTimeName.sunrise
                        ? Icons.wb_twilight_outlined
                        : Icons.wb_twilight_rounded,
                    color: QuranTheme.subText(context),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name == PrayerTimeName.sunrise ? 'Sunrise' : 'Sunset',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeFor(name),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _timeFor(PrayerTimeName name) {
    for (final entry in entries) {
      if (entry.name == name) return DateFormat.jm().format(entry.time);
    }
    return '--';
  }
}

class _PrayerScheduleRow extends StatelessWidget {
  const _PrayerScheduleRow({
    required this.entry,
    required this.isCurrent,
    required this.isNext,
    required this.alertEnabled,
    required this.onToggleAlert,
  });

  final PrayerTimeEntry entry;
  final bool isCurrent;
  final bool isNext;
  final bool alertEnabled;
  final VoidCallback? onToggleAlert;

  @override
  Widget build(BuildContext context) {
    final accent = QuranTheme.isDark(context)
        ? const Color(0xFFB9D7C9)
        : const Color(0xFF326953);
    final foreground = isCurrent ? accent : QuranTheme.text(context);
    final time = Text(
      DateFormat.jm().format(entry.time),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Semantics(
      selected: isCurrent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? accent.withValues(alpha: 0.07) : null,
          borderRadius: isCurrent
              ? BorderRadius.circular(QuranTheme.radiusCard)
              : null,
          border: Border(
            bottom: BorderSide(color: QuranTheme.outline(context)),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            return Row(
              children: [
                AppIcon(
                  switch (entry.name) {
                    PrayerTimeName.fajr => Icons.brightness_4_outlined,
                    PrayerTimeName.sunrise => Icons.wb_twilight_outlined,
                    PrayerTimeName.dhuhr => Icons.wb_sunny_outlined,
                    PrayerTimeName.asr => Icons.light_mode_outlined,
                    PrayerTimeName.maghrib => Icons.wb_twilight_rounded,
                    PrayerTimeName.isha => Icons.nightlight_outlined,
                  },
                  size: 23,
                  color: isCurrent ? accent : QuranTheme.subText(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isCurrent || isNext || entry.isFridayDhuhr) ...[
                        const SizedBox(height: 3),
                        Text(
                          isCurrent
                              ? 'Current prayer'
                              : isNext
                              ? 'Up next'
                              : 'Friday prayer',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isCurrent
                                    ? accent
                                    : QuranTheme.subText(context),
                              ),
                        ),
                      ],
                      if (stacked) ...[const SizedBox(height: 4), time],
                    ],
                  ),
                ),
                if (!stacked) ...[const SizedBox(width: 8), time],
                const SizedBox(width: 4),
                IconButton(
                  tooltip: alertEnabled
                      ? 'Disable ${entry.displayName} alert'
                      : 'Enable ${entry.displayName} alert',
                  onPressed: onToggleAlert,
                  icon: AppIcon(
                    alertEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_rounded,
                    size: 21,
                  ),
                  color: alertEnabled
                      ? foreground
                      : QuranTheme.subText(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
