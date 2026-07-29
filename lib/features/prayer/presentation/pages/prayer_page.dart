import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/datasources/offline_prayer_city_data_source.dart';
import '../../data/services/prayer_alert_notification_service.dart';
import '../../domain/entities/prayer_alert_settings.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/entities/prayer_day_progress.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../prayer_times/presentation/bloc/prayer_times_state.dart';
import '../../../prayer_times/presentation/widgets/animated_prayer_arc.dart';
import '../../../prayer_times/presentation/widgets/prayer_time_image.dart';
import '../../../qibla/domain/entities/qibla_direction.dart';
import '../../../qibla/domain/repositories/qibla_repository.dart';
import '../../../qibla/presentation/bloc/qibla_cubit.dart';
import '../../../qibla/presentation/bloc/qibla_state.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../../shell/presentation/bloc/shell_state.dart';

const _prayerGold = Color(0xFFD19A16);
const _qiblaHeadingEvents = EventChannel('quran/qibla_heading');

class PrayerPage extends StatelessWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              PrayerTimesCubit(repository: getIt<PrayerTimesRepository>())
                ..load(),
        ),
        BlocProvider(
          create: (_) =>
              QiblaCubit(repository: getIt<QiblaRepository>())..load(),
        ),
      ],
      child: const _PrayerView(),
    );
  }
}

class _PrayerView extends StatelessWidget {
  const _PrayerView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<ShellCubit, ShellState>(
      listenWhen: (previous, current) =>
          previous.qiblaOpenRequestId != current.qiblaOpenRequestId &&
          current.qiblaOpenRequestId > 0,
      listener: (context, state) {
        _openQiblaFromShortcut(context);
      },
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
                  icon: Icons.mosque_rounded,
                  title: l10n.prayerTitle,
                  subtitle: l10n.prayerSubtitle,
                  actions: [
                    ShellHeaderAction(
                      icon: Icons.refresh_rounded,
                      tooltip: l10n.commonRefresh,
                      onTap: context.read<PrayerTimesCubit>().load,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 150),
                  children: [
                    const _PrayerTimesSection(),
                    const SizedBox(height: 22),
                    Text(
                      'Worship Tools',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PrayerToolsGrid(calendarTitle: l10n.calendarTitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openQiblaFromShortcut(BuildContext context) async {
  final cubit = context.read<QiblaCubit>();
  if (cubit.state.status != QiblaStatus.success ||
      cubit.state.direction == null) {
    await cubit.load();
  }
  if (!context.mounted) {
    return;
  }
  await _showQiblaDirectionSheet(context, cubit.state);
}

class _QiblaCard extends StatelessWidget {
  const _QiblaCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QiblaCubit, QiblaState>(
      builder: (context, state) {
        final direction = state.direction;
        final subtitle = switch (state.status) {
          QiblaStatus.initial || QiblaStatus.loading => 'Calculating direction',
          QiblaStatus.failure => 'Direction unavailable',
          QiblaStatus.success =>
            direction == null
                ? 'Direction unavailable'
                : '${direction.bearingDegrees.toStringAsFixed(0)}° ${direction.cardinalDirection} from ${direction.location.name}',
        };
        return _PrayerToolTile(
          icon: Icons.navigation_rounded,
          iconOverride: _RoundedQiblaIcon(
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          title: 'Qibla Direction',
          subtitle: subtitle,
          onTap: () async {
            final cubit = context.read<QiblaCubit>();
            if (state.status != QiblaStatus.success || direction == null) {
              await cubit.load();
            }
            if (!context.mounted) {
              return;
            }
            _showQiblaDirectionSheet(context, cubit.state);
          },
        );
      },
    );
  }
}

class _PrayerToolsGrid extends StatelessWidget {
  const _PrayerToolsGrid({required this.calendarTitle});

  final String calendarTitle;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      children: [
        const _QiblaCard(),
        _PrayerToolTile(
          icon: Icons.calendar_month_rounded,
          title: calendarTitle,
          subtitle: 'Hijri month view',
          onTap: () => _showIslamicCalendarSheet(context),
        ),
        _PrayerToolTile(
          icon: Icons.fact_check_outlined,
          title: 'Prayer Journal',
          subtitle: 'Prayer, Qada & fasting',
          onTap: () => context.push(AppRoutes.prayerTrackingPath()),
        ),
        const _PrayerAlertsToolTile(),
      ],
    );
  }
}

class _PrayerAlertsToolTile extends StatelessWidget {
  const _PrayerAlertsToolTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        final dailyTimes = state.dailyTimes;
        final alertSettings = getIt<PrayerAlertNotificationService>()
            .loadSettings();
        return _PrayerToolTile(
          icon: Icons.notifications_rounded,
          title: 'Prayer Alerts',
          subtitle: alertSettings.schedulesAnything
              ? '${alertSettings.activePrayerCount} active'
              : 'Set reminders',
          onTap: dailyTimes == null
              ? context.read<PrayerTimesCubit>().load
              : () => _openPrayerAlertsFromTools(context, dailyTimes),
        );
      },
    );
  }
}

class _PrayerToolTile extends StatelessWidget {
  const _PrayerToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconOverride,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? iconOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      radius: 22,
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, primary),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: iconOverride ?? Icon(icon, color: primary, size: 26),
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimesSection extends StatelessWidget {
  const _PrayerTimesSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
      builder: (context, state) {
        return switch (state.status) {
          PrayerTimesStatus.initial || PrayerTimesStatus.loading =>
            const AppLoadingView(label: 'Loading prayer times'),
          PrayerTimesStatus.failure => AppErrorView(
            title: 'Prayer times could not be loaded',
            message: state.errorMessage ?? 'Please try again.',
            onRetry: context.read<PrayerTimesCubit>().load,
          ),
          PrayerTimesStatus.success => _PrayerTimesCard(state: state),
        };
      },
    );
  }
}

class _PrayerTimesCard extends StatefulWidget {
  const _PrayerTimesCard({required this.state});

  final PrayerTimesState state;

  @override
  State<_PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<_PrayerTimesCard> {
  late final PrayerAlertNotificationService _alertService;
  PrayerAlertSettings _alertSettings = PrayerAlertSettings.disabled();
  var _alertsLoading = true;

  @override
  void initState() {
    super.initState();
    _alertService = getIt<PrayerAlertNotificationService>();
    _loadAlertSettings();
  }

  @override
  void didUpdateWidget(covariant _PrayerTimesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDailyTimes = oldWidget.state.dailyTimes;
    final nextDailyTimes = widget.state.dailyTimes;
    if (oldDailyTimes != nextDailyTimes && _alertSettings.schedulesAnything) {
      unawaited(_alertService.syncUpcomingAlerts(settings: _alertSettings));
    }
  }

  Future<void> _loadAlertSettings() async {
    final settings = _alertService.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _alertSettings = settings;
      _alertsLoading = false;
    });
  }

  Future<void> _openAlertsSheet(DailyPrayerTimes dailyTimes) async {
    final next = await _showPrayerAlertsSheet(
      context,
      dailyTimes,
      _alertSettings,
    );
    if (next == null) {
      return;
    }
    await _saveAlertSettings(
      next,
      requestPermission:
          !_alertSettings.schedulesAnything && next.schedulesAnything,
    );
  }

  Future<void> _togglePrayerAlert(PrayerTimeName name, bool enabled) async {
    var next = _alertSettings.withPrayer(name, enabled);
    if (enabled && !next.notifyAtPrayerTime && !next.notifyBeforePrayer) {
      next = next.copyWith(notifyAtPrayerTime: true);
    }
    await _saveAlertSettings(
      next,
      requestPermission: enabled && !_alertSettings.schedulesAnything,
      showSnack: false,
    );
  }

  Future<void> _saveAlertSettings(
    PrayerAlertSettings settings, {
    required bool requestPermission,
    bool showSnack = true,
  }) async {
    if (requestPermission) {
      final confirmed = await _showPrayerAlertPermissionDialog(context);
      if (confirmed != true || !mounted) {
        return;
      }
      final allowed = await _alertService.requestPermissions();
      if (!mounted) {
        return;
      }
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is needed for alerts'),
          ),
        );
        return;
      }
    }
    final previous = _alertSettings;
    setState(() => _alertSettings = settings);
    try {
      await _alertService.saveSettings(settings);
      if (!mounted || !showSnack) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.schedulesAnything
                ? 'Prayer alerts updated'
                : 'Prayer alerts turned off',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _alertSettings = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update prayer alerts')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyTimes = widget.state.dailyTimes;
    if (dailyTimes == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrayerQuickControls(
          dailyTimes: dailyTimes,
          alertSettings: _alertSettings,
          alertsLoading: _alertsLoading,
          onAlertsTap: () => _openAlertsSheet(dailyTimes),
        ),
        const SizedBox(height: 10),
        _ExpandedNextPrayerCard(dailyTimes: dailyTimes),
        const SizedBox(height: 10),
        _SunriseSunsetRow(dailyTimes: dailyTimes),
        const SizedBox(height: 14),
        PremiumSurface(
          padding: const EdgeInsets.all(16),
          prominent: true,
          child: _PrayerSettingsControls(dailyTimes: dailyTimes),
        ),
        const SizedBox(height: 14),
        _TodayScheduleCard(
          dailyTimes: dailyTimes,
          alertSettings: _alertSettings,
          onTogglePrayerAlert: _togglePrayerAlert,
        ),
      ],
    );
  }
}

class _PrayerQuickControls extends StatelessWidget {
  const _PrayerQuickControls({
    required this.dailyTimes,
    required this.alertSettings,
    required this.alertsLoading,
    required this.onAlertsTap,
  });

  final DailyPrayerTimes dailyTimes;
  final PrayerAlertSettings alertSettings;
  final bool alertsLoading;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactPrayerControl(
            icon: Icons.location_on_rounded,
            title: dailyTimes.location.name,
            subtitle: _methodLabel(dailyTimes.settings.method),
            onTap: () =>
                _showPrayerLocationDialog(context, dailyTimes.location),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompactPrayerControl(
            icon: Icons.notifications_rounded,
            title: 'Alerts',
            subtitle: alertsLoading
                ? 'Loading'
                : alertSettings.schedulesAnything
                ? '${alertSettings.activePrayerCount} active'
                : 'Off',
            onTap: onAlertsTap,
          ),
        ),
      ],
    );
  }
}

class _CompactPrayerControl extends StatelessWidget {
  const _CompactPrayerControl({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, primary),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w800,
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

class _ExpandedNextPrayerCard extends StatelessWidget {
  const _ExpandedNextPrayerCard({required this.dailyTimes});

  final DailyPrayerTimes dailyTimes;

  @override
  Widget build(BuildContext context) {
    return PrayerNowTicker(
      builder: (context, now) {
        final progress = PrayerDayProgress.calculate(
          entries: dailyTimes.entries,
          now: now,
        );
        final next = progress.nextPrayer;
        final phaseColor = prayerPhaseColor(progress.phasePrayer?.name);
        final formatter = DateFormat.jm();
        return PremiumSurface(
          padding: const EdgeInsets.all(18),
          prominent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Prayer',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.68),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          next.displayName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(next.time),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: phaseColor,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress.remainingLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.64),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: QuranTheme.outline(context)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: PrayerTimeImage(
                        key: ValueKey('${next.name.name}-${next.time}'),
                        name: next.name,
                        size: 74,
                        fallbackColor: phaseColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _PrayerDayArc(
                entries: dailyTimes.entries,
                activeName: progress.currentPrayer?.name,
                progress: progress.arcProgress,
                phaseColor: phaseColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerDayArc extends StatelessWidget {
  const _PrayerDayArc({
    required this.entries,
    required this.activeName,
    required this.progress,
    required this.phaseColor,
  });

  final List<PrayerTimeEntry> entries;
  final PrayerTimeName? activeName;
  final double progress;
  final Color phaseColor;

  @override
  Widget build(BuildContext context) {
    final visible = entries
        .where((entry) => entry.name != PrayerTimeName.sunrise)
        .toList();
    return Column(
      children: [
        AnimatedPrayerArc(progress: progress, color: phaseColor),
        Row(
          children: [
            for (final entry in visible)
              Expanded(
                child: _PrayerArcSlot(
                  entry: entry,
                  active: entry.name == activeName,
                  activeColor: phaseColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrayerArcSlot extends StatelessWidget {
  const _PrayerArcSlot({
    required this.entry,
    required this.active,
    required this.activeColor,
  });

  final PrayerTimeEntry entry;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : QuranTheme.subText(context, 0.56);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrayerTimeImage(
          name: entry.name,
          size: 22,
          monochrome: !active,
          fallbackColor: color,
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            entry.displayName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            DateFormat('h:mm a').format(entry.time),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? activeColor : QuranTheme.subText(context, 0.78),
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SunriseSunsetRow extends StatelessWidget {
  const _SunriseSunsetRow({required this.dailyTimes});

  final DailyPrayerTimes dailyTimes;

  @override
  Widget build(BuildContext context) {
    final sunrise = _entryFor(dailyTimes.entries, PrayerTimeName.sunrise);
    final sunset = _entryFor(dailyTimes.entries, PrayerTimeName.maghrib);
    return Row(
      children: [
        Expanded(
          child: _MiniPrayerMetric(
            name: PrayerTimeName.sunrise,
            title: 'Sunrise',
            value: sunrise == null
                ? '--'
                : DateFormat('h:mm').format(sunrise.time),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniPrayerMetric(
            name: PrayerTimeName.maghrib,
            title: 'Sunset',
            imageVariant: PrayerTimeImageVariant.sunset,
            value: sunset == null
                ? '--'
                : DateFormat('h:mm').format(sunset.time),
          ),
        ),
      ],
    );
  }
}

class _MiniPrayerMetric extends StatelessWidget {
  const _MiniPrayerMetric({
    required this.name,
    required this.title,
    required this.value,
    this.imageVariant = PrayerTimeImageVariant.prayer,
  });

  final PrayerTimeName name;
  final String title;
  final String value;
  final PrayerTimeImageVariant imageVariant;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _prayerGold.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: PrayerTimeImage(
              name: name,
              size: 32,
              fallbackColor: _prayerGold,
              semanticLabel: title,
              variant: imageVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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

class _PrayerSettingsControls extends StatelessWidget {
  const _PrayerSettingsControls({required this.dailyTimes});

  final DailyPrayerTimes dailyTimes;

  @override
  Widget build(BuildContext context) {
    final settings = dailyTimes.settings;
    return SegmentedButton<PrayerAsrMadhab>(
      segments: const [
        ButtonSegment(value: PrayerAsrMadhab.shafi, label: Text('Shafi')),
        ButtonSegment(value: PrayerAsrMadhab.hanafi, label: Text('Hanafi')),
      ],
      selected: {settings.asrMadhab},
      showSelectedIcon: false,
      onSelectionChanged: (selection) async {
        await context.read<PrayerTimesCubit>().updateSettings(
          PrayerCalculationSettings(
            method: settings.method,
            asrMadhab: selection.first,
          ),
        );
        await getIt<PrayerAlertNotificationService>().syncUpcomingAlerts();
      },
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.dailyTimes,
    required this.alertSettings,
    required this.onTogglePrayerAlert,
  });

  final DailyPrayerTimes dailyTimes;
  final PrayerAlertSettings alertSettings;
  final Future<void> Function(PrayerTimeName name, bool enabled)
  onTogglePrayerAlert;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.jm();
    return PrayerNowTicker(
      builder: (context, now) {
        final progress = PrayerDayProgress.calculate(
          entries: dailyTimes.entries,
          now: now,
        );
        final currentName = DateUtils.isSameDay(dailyTimes.date, now)
            ? progress.currentPrayer?.name
            : null;
        return PremiumSurface(
          padding: const EdgeInsets.all(18),
          prominent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _prayerGold.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: QuranTheme.outline(context)),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: _prayerGold,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today Schedule',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dailyTimes.location.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.62),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: QuranTheme.surfaceVariant(
                        context,
                      ).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(
                        QuranTheme.radiusPill,
                      ),
                      border: Border.all(color: QuranTheme.outline(context)),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d').format(dailyTimes.date),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: QuranTheme.subText(context, 0.70),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < dailyTimes.entries.length; index++)
                _PrayerTimeRow(
                  entry: dailyTimes.entries[index],
                  time: formatter.format(dailyTimes.entries[index].time),
                  isCurrent: dailyTimes.entries[index].name == currentName,
                  isLast: index == dailyTimes.entries.length - 1,
                  alertEnabled: alertSettings.isEnabledFor(
                    dailyTimes.entries[index].name,
                  ),
                  onToggleAlert: () => onTogglePrayerAlert(
                    dailyTimes.entries[index].name,
                    !alertSettings.isEnabledFor(dailyTimes.entries[index].name),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showPrayerLocationDialog(
  BuildContext context,
  PrayerLocation location,
) async {
  final cubit = context.read<PrayerTimesCubit>();
  final qiblaCubit = context.read<QiblaCubit>();
  final cityDataSource = getIt<OfflinePrayerCityDataSource>();

  final next = await showModalBottomSheet<PrayerLocation>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: QuranTheme.isDark(context) ? 0.62 : 0.18,
    ),
    builder: (_) {
      return _PrayerLocationSheet(
        currentLocation: location,
        cityDataSource: cityDataSource,
      );
    },
  );

  if (next != null) {
    await cubit.updateLocation(next);
    await qiblaCubit.load();
    await getIt<PrayerAlertNotificationService>().syncUpcomingAlerts();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prayer location set to ${next.name}')),
      );
    }
  }
}

class _PrayerLocationSheet extends StatefulWidget {
  const _PrayerLocationSheet({
    required this.currentLocation,
    required this.cityDataSource,
  });

  final PrayerLocation currentLocation;
  final OfflinePrayerCityDataSource cityDataSource;

  @override
  State<_PrayerLocationSheet> createState() => _PrayerLocationSheetState();
}

class _PrayerLocationSheetState extends State<_PrayerLocationSheet> {
  final _searchController = TextEditingController();
  var _cities = <OfflinePrayerCity>[];
  var _loadingCities = true;
  var _locating = false;
  var _searchRun = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final run = ++_searchRun;
    setState(() {
      _loadingCities = true;
      _message = null;
    });

    final results = await widget.cityDataSource.search(query);
    if (!mounted || run != _searchRun) {
      return;
    }
    setState(() {
      _cities = results;
      _loadingCities = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      final allowed = await _showLocationPermissionRationale(context);
      if (!mounted || !allowed) {
        return;
      }
    }

    setState(() {
      _locating = true;
      _message = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }
        setState(() {
          _locating = false;
          _message = 'Turn on location services to use current location.';
        });
        await _showLocationSettingsDialog(context);
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) {
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locating = false;
          _message = 'Location permission was not granted.';
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _message = 'Location permission is blocked in system settings.';
        });
        await _showLocationSettingsDialog(context, appSettings: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final nearest = await widget.cityDataSource.nearest(
        position.latitude,
        position.longitude,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        nearest?.toPrayerLocation() ??
            PrayerLocation(
              name: 'Current Location',
              latitude: position.latitude,
              longitude: position.longitude,
              timeZone: widget.currentLocation.timeZone,
            ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locating = false;
        _message = 'Could not read your location. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.54,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: _LocationSheetSurface(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LocationSheetHandle(),
                          const _LocationSheetHeader(),
                          const SizedBox(height: 14),
                          _CurrentLocationSummary(
                            location: widget.currentLocation,
                          ),
                          const SizedBox(height: 10),
                          _CurrentGpsLocationTile(
                            loading: _locating,
                            onTap: _locating ? null : _useCurrentLocation,
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 10),
                            _LocationLookupError(message: _message!),
                          ],
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: _runSearch,
                            decoration: const InputDecoration(
                              hintText: 'Search offline city database',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.trim().isEmpty
                                ? 'Suggested cities'
                                : 'Offline city results',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (_loadingCities)
                    const SliverToBoxAdapter(child: _LocationResultsLoading())
                  else if (_cities.isEmpty)
                    SliverToBoxAdapter(
                      child: _LocationSearchEmpty(
                        query: _searchController.text,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final city = _cities[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _cities.length - 1 ? 0 : 8,
                            ),
                            child: _LocationPresetTile(
                              city: city,
                              selected: _isSamePrayerLocation(
                                widget.currentLocation,
                                city,
                              ),
                              onTap: () => Navigator.of(
                                context,
                              ).pop(city.toPrayerLocation()),
                            ),
                          );
                        }, childCount: _cities.length),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LocationSheetHandle extends StatelessWidget {
  const _LocationSheetHandle();

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

class _LocationSheetSurface extends StatelessWidget {
  const _LocationSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.vertical(
      top: Radius.circular(QuranTheme.radiusSheet),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QuranTheme.surface(context),
        borderRadius: borderRadius,
        border: Border.all(color: QuranTheme.outline(context)),
        boxShadow: QuranTheme.premiumShadow(
          context,
          prominent: true,
          compact: true,
        ),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _LocationSheetHeader extends StatelessWidget {
  const _LocationSheetHeader();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: QuranTheme.softFill(context, primary),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.map_rounded, color: primary, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prayer location',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Choose a city for accurate prayer times',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.64),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _CurrentLocationSummary extends StatelessWidget {
  const _CurrentLocationSummary({required this.location});

  final PrayerLocation location;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, primary),
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: QuranTheme.outline(context)),
            ),
            child: Icon(Icons.my_location_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Used for prayer times and Qibla',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
              border: Border.all(color: QuranTheme.outline(context)),
            ),
            child: Text(
              'Current',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPresetTile extends StatelessWidget {
  const _LocationPresetTile({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final OfflinePrayerCity city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tileColor = selected
        ? QuranTheme.softFill(context, primary)
        : QuranTheme.surfaceVariant(context).withValues(alpha: 0.56);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.22)
                : QuranTheme.outline(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: QuranTheme.outline(context)),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.mosque_rounded,
                color: selected ? primary : QuranTheme.subText(context, 0.70),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.62),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? primary : QuranTheme.subText(context, 0.44),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentGpsLocationTile extends StatelessWidget {
  const _CurrentGpsLocationTile({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QuranTheme.softFill(context, primary),
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: QuranTheme.outline(context)),
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    )
                  : Icon(Icons.navigation_rounded, color: primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use current location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GPS finds the nearest offline city',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: QuranTheme.subText(context, 0.54),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchEmpty extends StatelessWidget {
  const _LocationSearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final message = query.trim().isEmpty
        ? 'Start typing to find a city.'
        : 'No offline city match. Try a larger nearby city.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
          border: Border.all(color: QuranTheme.outline(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: QuranTheme.subText(context, 0.56),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.66),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationResultsLoading extends StatelessWidget {
  const _LocationResultsLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
          border: Border.all(color: QuranTheme.outline(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading offline cities',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationLookupError extends StatelessWidget {
  const _LocationLookupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSamePrayerLocation(PrayerLocation location, OfflinePrayerCity city) {
  final sameName = location.name.toLowerCase() == city.name.toLowerCase();
  final sameCoordinates =
      (location.latitude - city.latitude).abs() < 0.05 &&
      (location.longitude - city.longitude).abs() < 0.05;
  return sameName || sameCoordinates;
}

Future<bool> _showLocationPermissionRationale(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        child: PremiumSurface(
          padding: const EdgeInsets.all(20),
          radius: QuranTheme.radiusSheet,
          prominent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: QuranTheme.softFill(
                    context,
                    Theme.of(context).colorScheme.primary,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Use your location',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'We use your location once to find the nearest offline city, calculate accurate prayer times, and set Qibla direction. Your location is not stored beyond your selected prayer city.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.72),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

Future<void> _showLocationSettingsDialog(
  BuildContext context, {
  bool appSettings = false,
}) async {
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(appSettings ? 'Location blocked' : 'Location is off'),
        content: Text(
          appSettings
              ? 'Location permission is blocked. Open app settings and allow location while using the app.'
              : 'Turn on location services to find your nearest prayer city.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open settings'),
          ),
        ],
      );
    },
  );

  if (openSettings == true) {
    if (appSettings) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }
}

Future<void> _openPrayerAlertsFromTools(
  BuildContext context,
  DailyPrayerTimes dailyTimes,
) async {
  final service = getIt<PrayerAlertNotificationService>();
  final initialSettings = service.loadSettings();
  final next = await _showPrayerAlertsSheet(
    context,
    dailyTimes,
    initialSettings,
  );
  if (next == null || !context.mounted) {
    return;
  }
  if (!initialSettings.schedulesAnything && next.schedulesAnything) {
    final confirmed = await _showPrayerAlertPermissionDialog(context);
    if (confirmed != true || !context.mounted) {
      return;
    }
    final allowed = await service.requestPermissions();
    if (!context.mounted) {
      return;
    }
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is needed for alerts'),
        ),
      );
      return;
    }
  }
  try {
    await service.saveSettings(next);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next.schedulesAnything
              ? 'Prayer alerts updated'
              : 'Prayer alerts turned off',
        ),
      ),
    );
    context.read<PrayerTimesCubit>().load();
  } catch (_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update prayer alerts')),
    );
  }
}

Future<PrayerAlertSettings?> _showPrayerAlertsSheet(
  BuildContext context,
  DailyPrayerTimes dailyTimes,
  PrayerAlertSettings initialSettings,
) async {
  var draft = initialSettings;

  return showModalBottomSheet<PrayerAlertSettings>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.28,
        builder: (sheetContext, scrollController) {
          return SafeArea(
            top: false,
            child: PremiumSurface(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              radius: QuranTheme.radiusSheet,
              prominent: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    void update(PrayerAlertSettings next) {
                      setSheetState(() => draft = next);
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: QuranTheme.outline(context),
                              borderRadius: BorderRadius.circular(
                                QuranTheme.radiusPill,
                              ),
                            ),
                          ),
                        ),
                        Row(
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
                                Icons.notifications_active_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prayer alerts',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${dailyTimes.location.name} • ${_methodLabel(dailyTimes.settings.method)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: QuranTheme.subText(
                                            context,
                                            0.66,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AlertSwitchTile(
                          icon: Icons.notifications_rounded,
                          title: 'All prayer alerts',
                          subtitle: draft.schedulesAnything
                              ? '${draft.activePrayerCount} reminders active'
                              : 'No prayer alerts scheduled',
                          value: draft.schedulesAnything,
                          onChanged: (value) {
                            var next = draft.withAllCorePrayers(value);
                            if (value &&
                                !next.notifyAtPrayerTime &&
                                !next.notifyBeforePrayer) {
                              next = next.copyWith(notifyAtPrayerTime: true);
                            }
                            update(next);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Timing',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        _AlertSwitchTile(
                          icon: Icons.access_time_rounded,
                          title: 'At prayer time',
                          subtitle: 'Notify when the prayer begins',
                          value: draft.notifyAtPrayerTime,
                          onChanged: (value) =>
                              update(draft.copyWith(notifyAtPrayerTime: value)),
                        ),
                        const SizedBox(height: 8),
                        _AlertSwitchTile(
                          icon: Icons.timer_rounded,
                          title: 'Before prayer',
                          subtitle:
                              'Notify ${draft.beforeMinutes} minutes before time',
                          value: draft.notifyBeforePrayer,
                          onChanged: (value) =>
                              update(draft.copyWith(notifyBeforePrayer: value)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final minutes in const [5, 10, 15, 30])
                              _AlertMinuteChip(
                                minutes: minutes,
                                selected: draft.beforeMinutes == minutes,
                                onTap: () => update(
                                  draft.copyWith(beforeMinutes: minutes),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _AlertSwitchTile(
                          icon: Icons.wb_twilight_rounded,
                          title: 'Sunrise reminder',
                          subtitle: 'Optional alert for sunrise',
                          value:
                              draft.includeSunrise &&
                              draft.enabledPrayerNames.contains(
                                PrayerTimeName.sunrise,
                              ),
                          onChanged: (value) {
                            final nextNames = {...draft.enabledPrayerNames};
                            if (value) {
                              nextNames.add(PrayerTimeName.sunrise);
                            } else {
                              nextNames.remove(PrayerTimeName.sunrise);
                            }
                            update(
                              draft.copyWith(
                                includeSunrise: value,
                                enabledPrayerNames: nextNames,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Prayers',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        for (final entry in dailyTimes.entries)
                          if (entry.name != PrayerTimeName.sunrise)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _PrayerAlertToggleRow(
                                entry: entry,
                                enabled: draft.isEnabledFor(entry.name),
                                onChanged: (value) {
                                  var next = draft.withPrayer(
                                    entry.name,
                                    value,
                                  );
                                  if (value &&
                                      !next.notifyAtPrayerTime &&
                                      !next.notifyBeforePrayer) {
                                    next = next.copyWith(
                                      notifyAtPrayerTime: true,
                                    );
                                  }
                                  update(next);
                                },
                              ),
                            ),
                        const SizedBox(height: 6),
                        FilledButton.icon(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(draft),
                          icon: const Icon(Icons.notifications_rounded),
                          label: const Text('Save alerts'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<bool> _showPrayerAlertPermissionDialog(BuildContext context) async {
  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final primary = Theme.of(context).colorScheme.primary;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: PremiumSurface(
          padding: const EdgeInsets.all(20),
          radius: QuranTheme.radiusSheet,
          prominent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: QuranTheme.softFill(context, primary),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Allow prayer alerts',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Quran needs notification permission to remind you at prayer times, even when the app is closed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Allow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return allowed ?? false;
}

class _AlertSwitchTile extends StatelessWidget {
  const _AlertSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? QuranTheme.softFill(context, primary)
            : QuranTheme.surfaceVariant(context).withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? primary.withValues(alpha: 0.18)
              : QuranTheme.outline(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: QuranTheme.outline(context)),
            ),
            child: Icon(
              icon,
              color: value ? primary : QuranTheme.subText(context, 0.62),
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context, 0.58),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AlertMinuteChip extends StatelessWidget {
  const _AlertMinuteChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text('$minutes min'),
      onSelected: (_) => onTap(),
      selectedColor: QuranTheme.softFill(context, primary),
      backgroundColor: QuranTheme.surfaceVariant(
        context,
      ).withValues(alpha: 0.48),
      side: BorderSide(
        color: selected
            ? primary.withValues(alpha: 0.30)
            : QuranTheme.outline(context),
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? primary : QuranTheme.subText(context, 0.72),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PrayerAlertToggleRow extends StatelessWidget {
  const _PrayerAlertToggleRow({
    required this.entry,
    required this.enabled,
    required this.onChanged,
  });

  final PrayerTimeEntry entry;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: enabled
          ? primary.withValues(alpha: 0.08)
          : QuranTheme.surfaceVariant(context).withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!enabled),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              PrayerTimeImage(
                name: entry.name,
                size: 28,
                monochrome: !enabled,
                fallbackColor: enabled
                    ? primary
                    : QuranTheme.subText(context, 0.62),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showQiblaDirectionSheet(
  BuildContext context,
  QiblaState state,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: QuranTheme.isDark(context) ? 0.62 : 0.18,
    ),
    builder: (_) {
      return SafeArea(
        top: false,
        child: PremiumSurface(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.zero,
          radius: QuranTheme.radiusSheet,
          prominent: true,
          clipBehavior: Clip.antiAlias,
          child: state.direction == null
              ? _QiblaUnavailableContent(message: state.errorMessage)
              : _QiblaDirectionContent(direction: state.direction!),
        ),
      );
    },
  );
}

class _QiblaUnavailableContent extends StatelessWidget {
  const _QiblaUnavailableContent({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _LocationSheetHandle(),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, primary),
              shape: BoxShape.circle,
            ),
            child: _RoundedQiblaIcon(color: primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'Qibla unavailable',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                'Set a prayer location or use current location to calculate your Qibla bearing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.70),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _QiblaDirectionContent extends StatelessWidget {
  const _QiblaDirectionContent({required this.direction});

  final QiblaDirection direction;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final degrees = direction.bearingDegrees.toStringAsFixed(0);
    return _QiblaAlignmentScope(
      builder: (context, aligned) {
        final activeColor = aligned ? const Color(0xFF12A36D) : primary;
        final titleColor = aligned ? activeColor : QuranTheme.text(context);
        final subtitleColor = aligned
            ? activeColor.withValues(alpha: 0.78)
            : QuranTheme.subText(context, 0.66);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: aligned
                ? activeColor.withValues(
                    alpha: QuranTheme.isDark(context) ? 0.14 : 0.08,
                  )
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const _LocationSheetHandle(),
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: QuranTheme.softFill(context, activeColor),
                  borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: QuranTheme.surface(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: aligned
                              ? activeColor.withValues(alpha: 0.26)
                              : QuranTheme.outline(context),
                        ),
                      ),
                      child: _RoundedQiblaIcon(color: activeColor, size: 32),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aligned ? 'Facing Qibla' : 'Qibla Direction',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${direction.location.name} • Bearing from north',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LiveQiblaCompass(
                      qiblaBearing: direction.bearingDegrees,
                      location: direction.location,
                      color: activeColor,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _QiblaInfoPill(
                            icon: Icons.navigation_rounded,
                            label: 'Bearing',
                            value: '$degrees° ${direction.cardinalDirection}',
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QiblaInfoPill(
                            icon: Icons.navigation_rounded,
                            label: 'Reference',
                            value: 'North',
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hold the phone flat and rotate until the Qibla marker points straight ahead. Move away from metal or magnets if the reading feels unstable.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: aligned
                            ? activeColor.withValues(alpha: 0.74)
                            : QuranTheme.subText(context, 0.66),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QiblaAlignmentScope extends StatefulWidget {
  const _QiblaAlignmentScope({required this.builder});

  final Widget Function(BuildContext context, bool aligned) builder;

  static _QiblaAlignmentScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_QiblaAlignmentScopeState>();
  }

  @override
  State<_QiblaAlignmentScope> createState() => _QiblaAlignmentScopeState();
}

class _QiblaAlignmentScopeState extends State<_QiblaAlignmentScope> {
  var aligned = false;

  void updateAligned(bool value) {
    if (aligned == value || !mounted) {
      return;
    }
    setState(() => aligned = value);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, aligned);
  }
}

class _QiblaInfoPill extends StatelessWidget {
  const _QiblaInfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, color),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context, 0.60),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
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

class _LiveQiblaCompass extends StatefulWidget {
  const _LiveQiblaCompass({
    required this.qiblaBearing,
    required this.location,
    required this.color,
  });

  final double qiblaBearing;
  final PrayerLocation location;
  final Color color;

  @override
  State<_LiveQiblaCompass> createState() => _LiveQiblaCompassState();
}

class _LiveQiblaCompassState extends State<_LiveQiblaCompass> {
  StreamSubscription<dynamic>? _headingSubscription;

  double? _heading;
  String? _source;
  String? _sensorError;
  var _lastHeadingUpdateMs = 0;
  var _lowAccuracySamples = 0;
  var _calibrationHintVisible = false;
  var _calibrationHintVisibleSinceMs = 0;
  var _calibrationHintSuppressedUntilMs = 0;

  static const _lowAccuracySampleThreshold = 12;
  static const _calibrationHintMaxVisibleMs = 7000;
  static const _calibrationHintCooldownMs = 120000;

  @override
  void initState() {
    super.initState();
    _startHeadingStream();
  }

  @override
  void didUpdateWidget(covariant _LiveQiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.latitude != widget.location.latitude ||
        oldWidget.location.longitude != widget.location.longitude) {
      _startHeadingStream(resetState: true);
    }
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    _headingSubscription = null;
    super.dispose();
  }

  void _startHeadingStream({bool resetState = false}) {
    _headingSubscription?.cancel();
    if (resetState && mounted) {
      setState(_resetHeadingState);
    } else {
      _resetHeadingState();
    }

    _headingSubscription = _qiblaHeadingEvents
        .receiveBroadcastStream({
          'latitude': widget.location.latitude,
          'longitude': widget.location.longitude,
          'altitude': 0.0,
        })
        .listen(
          _handleHeadingEvent,
          onError: _handleHeadingError,
          cancelOnError: false,
        );
  }

  void _resetHeadingState() {
    _heading = null;
    _source = null;
    _sensorError = null;
    _lastHeadingUpdateMs = 0;
    _lowAccuracySamples = 0;
    _calibrationHintVisible = false;
    _calibrationHintVisibleSinceMs = 0;
    _calibrationHintSuppressedUntilMs = 0;
  }

  void _handleHeadingEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    final rawHeading = _readDouble(event['heading']);
    if (rawHeading == null || !mounted) {
      return;
    }

    final nextHeading = _normalizeDegrees(rawHeading);
    final previous = _heading;
    final nextAccuracy = _readDouble(event['accuracy']);
    final nextSource = event['source']?.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (previous != null &&
        now - _lastHeadingUpdateMs < 80 &&
        _signedAngle(nextHeading - previous).abs() < 2) {
      return;
    }

    _updateCalibrationHint(
      now: now,
      accuracy: nextAccuracy,
      source: nextSource,
    );

    setState(() {
      _lastHeadingUpdateMs = now;
      _heading = previous == null
          ? nextHeading
          : _smoothDegrees(previous, nextHeading, 0.36);
      _source = nextSource;
      _sensorError = null;
    });
  }

  void _updateCalibrationHint({
    required int now,
    required double? accuracy,
    required String? source,
  }) {
    if (!_hasLowCompassAccuracy(accuracy: accuracy, source: source)) {
      _lowAccuracySamples = 0;
      _calibrationHintVisible = false;
      _calibrationHintVisibleSinceMs = 0;
      return;
    }

    _lowAccuracySamples += 1;
    if (_calibrationHintVisible &&
        now - _calibrationHintVisibleSinceMs >= _calibrationHintMaxVisibleMs) {
      _calibrationHintVisible = false;
      _calibrationHintVisibleSinceMs = 0;
      _calibrationHintSuppressedUntilMs = now + _calibrationHintCooldownMs;
      return;
    }

    if (!_calibrationHintVisible &&
        now >= _calibrationHintSuppressedUntilMs &&
        _lowAccuracySamples >= _lowAccuracySampleThreshold) {
      _calibrationHintVisible = true;
      _calibrationHintVisibleSinceMs = now;
    }
  }

  void _handleHeadingError(Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _sensorError =
          'Compass heading unavailable. Enable location and calibrate compass.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading;
    final relative = heading == null
        ? null
        : _signedAngle(widget.qiblaBearing - heading);
    final alignment = relative?.abs();
    final aligned = alignment != null && alignment <= 6;
    final needsTrueHeading =
        heading != null && _source == 'ios_core_location_magnetic';
    final calibrating = _calibrationHintVisible;
    final turnStatus = relative == null
        ? 'Finding compass'
        : '${relative > 0 ? 'Turn right' : 'Turn left'} ${relative.abs().toStringAsFixed(0)}°';
    final liveStatus = needsTrueHeading
        ? 'Enable location for true north'
        : calibrating
        ? 'Improve compass accuracy'
        : aligned
        ? 'Facing Qibla'
        : turnStatus;
    final status = _sensorError ?? liveStatus;
    _notifyAligned(aligned && _sensorError == null);
    final outline = QuranTheme.outline(context);
    final textColor = QuranTheme.subText(context, 0.68);
    final fillColor = QuranTheme.surfaceVariant(
      context,
    ).withValues(alpha: 0.56);
    final alignmentStrength = alignment == null
        ? 0.0
        : (1 - (alignment / 90).clamp(0.0, 1.0)).toDouble();

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 286,
            height: 286,
            child: CustomPaint(
              painter: _LiveQiblaCompassPainter(
                heading: heading ?? 0,
                qiblaBearing: widget.qiblaBearing,
                hasHeading: heading != null,
                pulse: heading == null ? 0 : 0.55,
                color: widget.color,
                outline: outline,
                textColor: textColor,
                fillColor: fillColor,
                alignmentStrength: aligned ? 1 : alignmentStrength,
                calibrating: calibrating,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: aligned
                ? widget.color.withValues(alpha: 0.14)
                : QuranTheme.softFill(context, widget.color),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: aligned
                  ? widget.color.withValues(alpha: 0.32)
                  : outline.withValues(alpha: 0.86),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aligned ? Icons.check_circle_rounded : Icons.explore_rounded,
                size: 18,
                color: aligned ? widget.color : textColor,
              ),
              const SizedBox(width: 8),
              Text(
                status,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: aligned ? widget.color : QuranTheme.text(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (calibrating) ...[
          const SizedBox(height: 12),
          _QiblaCalibrationProgress(color: widget.color),
        ],
      ],
    );
  }

  bool _hasLowCompassAccuracy({
    required double? accuracy,
    required String? source,
  }) {
    if (_sensorError != null || source == null) {
      return false;
    }
    if (source == 'ios_core_location_magnetic') {
      return false;
    }
    if (source == 'android_rotation_vector' ||
        source == 'android_geomagnetic_rotation_vector') {
      final level = accuracy?.round();
      return level != null && level <= 0;
    }
    return accuracy != null && accuracy >= 0 && accuracy > 45;
  }

  void _notifyAligned(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _QiblaAlignmentScope.maybeOf(context)?.updateAligned(value);
    });
  }
}

class _QiblaCalibrationProgress extends StatefulWidget {
  const _QiblaCalibrationProgress({required this.color});

  final Color color;

  @override
  State<_QiblaCalibrationProgress> createState() =>
      _QiblaCalibrationProgressState();
}

class _QiblaCalibrationProgressState extends State<_QiblaCalibrationProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, widget.color),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: widget.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return SizedBox(
                width: 44,
                height: 34,
                child: CustomPaint(
                  painter: _QiblaCalibrationFigureEightPainter(
                    color: widget.color,
                    progress: _controller.value,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'For a steadier reading, move your phone once in a slow figure-eight away from metal objects.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.72),
                fontWeight: FontWeight.w700,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaCalibrationFigureEightPainter extends CustomPainter {
  const _QiblaCalibrationFigureEightPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final path = Path();
    for (var step = 0; step <= 96; step++) {
      final t = step / 96 * math.pi * 2;
      final point =
          center +
          Offset(
            math.sin(t) * size.width * 0.34,
            math.sin(t * 2) * size.height * 0.30,
          );
      if (step == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.22),
    );

    for (var index = 0; index < 3; index++) {
      final t = ((progress + index / 3) % 1) * math.pi * 2;
      final point =
          center +
          Offset(
            math.sin(t) * size.width * 0.34,
            math.sin(t * 2) * size.height * 0.30,
          );
      canvas.drawCircle(
        point,
        3.8 - index * 0.7,
        Paint()..color = color.withValues(alpha: 0.92 - index * 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _QiblaCalibrationFigureEightPainter oldDelegate,
  ) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _RoundedQiblaIcon extends StatelessWidget {
  const _RoundedQiblaIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RoundedQiblaIconPainter(color: color)),
    );
  }
}

class _RoundedQiblaIconPainter extends CustomPainter {
  const _RoundedQiblaIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final offset = Offset((size.width - side) / 2, (size.height - side) / 2);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(side / 192);

    final iconStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final circleStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final symbolPath = Path()
      ..moveTo(108.09, 140.77)
      ..relativeLineTo(-8.655, -38.483)
      ..relativeLineTo(34.531, 19.039)
      ..relativeLineTo(-17.195, 4.273)
      ..relativeLineTo(-8.681, 15.171)
      ..close()
      ..moveTo(72.263, 90.31)
      ..relativeLineTo(-13.048, -18.858)
      ..relativeLineTo(9.887, -14.531)
      ..relativeLineTo(17.138, -3.518)
      ..relativeLineTo(12.91, 19.187)
      ..relativeLineTo(-10.538, 13.007)
      ..relativeLineTo(-16.349, 4.713)
      ..close();
    final circlePath = Path()
      ..moveTo(96, 170)
      ..cubicTo(136.869, 170, 170, 136.869, 170, 96)
      ..cubicTo(170, 55.13, 136.869, 22, 96, 22)
      ..cubicTo(55.13, 22, 22, 55.13, 22, 96)
      ..cubicTo(22, 136.869, 55.13, 170, 96, 170)
      ..close();
    canvas.drawPath(symbolPath, iconStroke);
    canvas.drawPath(circlePath, circleStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoundedQiblaIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LiveQiblaCompassPainter extends CustomPainter {
  const _LiveQiblaCompassPainter({
    required this.heading,
    required this.qiblaBearing,
    required this.hasHeading,
    required this.pulse,
    required this.color,
    required this.outline,
    required this.textColor,
    required this.fillColor,
    required this.alignmentStrength,
    required this.calibrating,
  });

  final double heading;
  final double qiblaBearing;
  final bool hasHeading;
  final double pulse;
  final Color color;
  final Color outline;
  final Color textColor;
  final Color fillColor;
  final double alignmentStrength;
  final bool calibrating;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 24;
    _drawDepthStage(canvas, size, center, radius);
    _drawAmbientField(canvas, center, radius);
    _drawCompassBody(canvas, center, radius);
    _drawTicks(canvas, center, radius);
    _drawLabels(canvas, center, radius);
    _drawPhoneDirectionMarker(canvas, center, radius);
    _drawQiblaMarker(canvas, center, radius);
    _drawCenter(canvas, center);
  }

  void _drawDepthStage(Canvas canvas, Size size, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.56),
        width: radius * 1.92,
        height: radius * 0.32,
      ),
      shadowPaint,
    );

    final rect = Offset.zero & size;
    final haloPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.62,
        colors: [
          color.withValues(alpha: 0.22 + alignmentStrength * 0.10),
          color.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, haloPaint);

    canvas.drawCircle(
      center,
      radius * 1.16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color.withValues(alpha: 0.08 + alignmentStrength * 0.05),
    );
  }

  void _drawAmbientField(Canvas canvas, Offset center, double radius) {
    final fieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.25
      ..color = color.withValues(alpha: calibrating ? 0.22 : 0.13);
    final qiblaAngle = _bearingToCanvasAngle(qiblaBearing);
    for (var index = 0; index < 14; index++) {
      final t = index / 14;
      final phase = t * math.pi * 2;
      final startAngle = phase + math.sin(phase) * 0.18;
      final endAngle = qiblaAngle + math.sin(phase) * 0.30;
      final start =
          center +
          Offset(math.cos(startAngle), math.sin(startAngle)) *
              (radius * (0.74 + (index % 4) * 0.08));
      final end =
          center +
          Offset(math.cos(endAngle), math.sin(endAngle)) *
              (radius * (0.42 + (index % 3) * 0.11));
      final control =
          center +
          Offset(
                math.cos((startAngle + endAngle) / 2 + math.pi / 2),
                math.sin((startAngle + endAngle) / 2 + math.pi / 2),
              ) *
              radius *
              (0.28 + math.sin(phase) * 0.08);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(
        path,
        fieldPaint
          ..color = color.withValues(
            alpha: (calibrating ? 0.22 : 0.12) * (0.55 + t),
          ),
      );
    }
  }

  void _drawCompassBody(Canvas canvas, Offset center, double radius) {
    final compassRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center.translate(0, 8),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.09),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.30, -0.42),
          radius: 1.06,
          colors: [
            fillColor.withValues(alpha: 0.96),
            fillColor.withValues(alpha: 0.70),
            color.withValues(alpha: 0.08 + alignmentStrength * 0.08),
          ],
        ).createShader(compassRect),
    );

    for (final scale in [1.0, 0.72, 0.44]) {
      canvas.drawCircle(
        center,
        radius * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale == 1.0 ? 2.4 : 1.1
          ..color = (scale == 1.0 ? color : outline).withValues(
            alpha: scale == 1.0 ? 0.28 + alignmentStrength * 0.24 : 0.68,
          ),
      );
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final minorPaint = Paint()
      ..color = outline.withValues(alpha: 0.64)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final majorPaint = Paint()
      ..color = textColor.withValues(alpha: 0.82)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var bearing = 0; bearing < 360; bearing += 10) {
      final isMajor = bearing % 30 == 0;
      final angle = _bearingToCanvasAngle(bearing.toDouble());
      final direction = Offset(math.cos(angle), math.sin(angle));
      final outer = center + direction * radius;
      final inner = center + direction * (radius - (isMajor ? 14 : 7));
      canvas.drawLine(inner, outer, isMajor ? majorPaint : minorPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius) {
    _drawCompassLabel(canvas, 'N', _point(center, radius - 31, 0));
    _drawCompassLabel(canvas, 'E', _point(center, radius - 31, 90));
    _drawCompassLabel(canvas, 'S', _point(center, radius - 31, 180));
    _drawCompassLabel(canvas, 'W', _point(center, radius - 31, 270));
  }

  void _drawPhoneDirectionMarker(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = textColor.withValues(alpha: 0.84)
      ..style = PaintingStyle.fill;
    final qiblaBadgeCenter = Offset(center.dx, center.dy - radius - 14);
    final path = Path()
      ..moveTo(center.dx, center.dy - radius - 1)
      ..lineTo(center.dx - 8, center.dy - radius + 15)
      ..lineTo(center.dx + 8, center.dy - radius + 15)
      ..close();
    canvas.drawPath(path, markerPaint);
    _drawKaabaMarker(canvas, qiblaBadgeCenter, scale: 0.78);
  }

  void _drawQiblaMarker(Canvas canvas, Offset center, double radius) {
    final angle = _bearingToCanvasAngle(qiblaBearing);
    final direction = Offset(math.cos(angle), math.sin(angle));
    final end = center + direction * (radius - 38);

    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, arrowPaint);

    final arrowHead = Path();
    final leftAngle = angle + math.pi * 0.82;
    final rightAngle = angle - math.pi * 0.82;
    arrowHead
      ..moveTo(end.dx + math.cos(angle) * 15, end.dy + math.sin(angle) * 15)
      ..lineTo(
        end.dx + math.cos(leftAngle) * 17,
        end.dy + math.sin(leftAngle) * 17,
      )
      ..lineTo(
        end.dx + math.cos(rightAngle) * 17,
        end.dy + math.sin(rightAngle) * 17,
      )
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = color);
  }

  void _drawCenter(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center.translate(0, 5),
      22,
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      23,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.92), color],
        ).createShader(Rect.fromCircle(center: center, radius: 23)),
    );
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  void _drawKaabaMarker(Canvas canvas, Offset center, {double scale = 1}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-13, -10, 26, 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      body.shift(const Offset(0, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151515), Color(0xFF2A2112)],
        ).createShader(body.outerRect),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-13, -4, 26, 4),
      Paint()..color = const Color(0xFFD7B46A),
    );
    canvas.restore();
  }

  Offset _point(Offset center, double radius, double bearing) {
    final angle = _bearingToCanvasAngle(bearing);
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  double _bearingToCanvasAngle(double bearing) {
    return (_normalizeDegrees(bearing - heading) - 90) * math.pi / 180;
  }

  void _drawCompassLabel(Canvas canvas, String label, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: label == 'N' ? 16 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LiveQiblaCompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.qiblaBearing != qiblaBearing ||
        oldDelegate.hasHeading != hasHeading ||
        oldDelegate.pulse != pulse ||
        oldDelegate.color != color ||
        oldDelegate.outline != outline ||
        oldDelegate.textColor != textColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.alignmentStrength != alignmentStrength ||
        oldDelegate.calibrating != calibrating;
  }
}

double _normalizeDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

double? _readDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

double _signedAngle(double degrees) {
  final normalized = (degrees + 540) % 360;
  return normalized - 180;
}

double _smoothDegrees(double current, double target, double amount) {
  return _normalizeDegrees(current + _signedAngle(target - current) * amount);
}

Future<void> _showIslamicCalendarSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(
      alpha: QuranTheme.isDark(context) ? 0.62 : 0.18,
    ),
    builder: (_) {
      return SafeArea(
        top: false,
        child: PremiumSurface(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          radius: QuranTheme.radiusSheet,
          prominent: true,
          child: const SingleChildScrollView(child: _IslamicCalendarContent()),
        ),
      );
    },
  );
}

class _IslamicCalendarContent extends StatefulWidget {
  const _IslamicCalendarContent();

  @override
  State<_IslamicCalendarContent> createState() =>
      _IslamicCalendarContentState();
}

class _IslamicCalendarContentState extends State<_IslamicCalendarContent> {
  late final DateTime _todayGregorian;
  late final HijriCalendarConfig _todayHijri;
  late int _displayedYear;
  late int _displayedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    HijriCalendarConfig.language = 'en';
    _todayGregorian = DateTime.now();
    _todayHijri = HijriCalendarConfig.fromGregorian(_todayGregorian);
    _displayedYear = _todayHijri.hYear;
    _displayedMonth = _todayHijri.hMonth;
    _selectedDay = _todayHijri.hDay;
  }

  void _changeMonth(int delta) {
    setState(() {
      var nextMonth = _displayedMonth + delta;
      var nextYear = _displayedYear;
      while (nextMonth < 1) {
        nextMonth += 12;
        nextYear--;
      }
      while (nextMonth > 12) {
        nextMonth -= 12;
        nextYear++;
      }
      final maxDay = HijriCalendarConfig().getDaysInMonth(nextYear, nextMonth);
      _displayedYear = nextYear;
      _displayedMonth = nextMonth;
      _selectedDay = math.min(_selectedDay, maxDay);
    });
  }

  void _selectDay(int day) {
    setState(() => _selectedDay = day);
  }

  void _goToToday() {
    setState(() {
      _displayedYear = _todayHijri.hYear;
      _displayedMonth = _todayHijri.hMonth;
      _selectedDay = _todayHijri.hDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthHijri = HijriCalendarConfig.fromHijri(
      _displayedYear,
      _displayedMonth,
      _selectedDay,
    );
    final daysInMonth = monthHijri.getDaysInMonth(
      _displayedYear,
      _displayedMonth,
    );
    final firstGregorian = monthHijri.hijriToGregorian(
      _displayedYear,
      _displayedMonth,
      1,
    );
    final lastGregorian = monthHijri.hijriToGregorian(
      _displayedYear,
      _displayedMonth,
      daysInMonth,
    );
    final selectedGregorian = monthHijri.hijriToGregorian(
      _displayedYear,
      _displayedMonth,
      _selectedDay,
    );
    final leadingBlanks = firstGregorian.weekday % 7;
    final primary = Theme.of(context).colorScheme.primary;
    final showingCurrentMonth =
        _displayedYear == _todayHijri.hYear &&
        _displayedMonth == _todayHijri.hMonth;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LocationSheetHandle(),
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: QuranTheme.softFill(context, primary),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${monthHijri.getLongMonthName()} $_displayedYear',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(firstGregorian)} to ${DateFormat('MMM d, y').format(lastGregorian)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context, 0.64),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _CalendarTodayButton(
              enabled: !showingCurrentMonth || _selectedDay != _todayHijri.hDay,
              onTap: _goToToday,
            ),
            const Spacer(),
            _CalendarIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              quarterTurns: 1,
              onTap: () => _changeMonth(-1),
            ),
            const SizedBox(width: 8),
            _CalendarIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              quarterTurns: 3,
              onTap: () => _changeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SelectedHijriDateCard(
          hijri: monthHijri,
          gregorian: selectedGregorian,
          day: _selectedDay,
        ),
        const SizedBox(height: 16),
        const _HijriWeekdayHeader(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingBlanks + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox.shrink();
            }
            final selected = day == _selectedDay;
            final today = showingCurrentMonth && day == _todayHijri.hDay;
            return _HijriDayCell(
              day: day,
              selected: selected,
              today: today,
              onTap: () => _selectDay(day),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CalendarStatPill(
                label: 'Month length',
                value: '$daysInMonth days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CalendarStatPill(label: 'Calendar', value: 'Umm al-Qura'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarIconButton extends StatelessWidget {
  const _CalendarIconButton({
    required this.icon,
    required this.onTap,
    this.quarterTurns = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.54),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: RotatedBox(
            quarterTurns: quarterTurns,
            child: Icon(icon, color: primary, size: 24),
          ),
        ),
      ),
    );
  }
}

class _CalendarTodayButton extends StatelessWidget {
  const _CalendarTodayButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: const Text('Today'),
      style: TextButton.styleFrom(
        foregroundColor: primary,
        disabledForegroundColor: QuranTheme.subText(context, 0.38),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _SelectedHijriDateCard extends StatelessWidget {
  const _SelectedHijriDateCard({
    required this.hijri,
    required this.gregorian,
    required this.day,
  });

  final HijriCalendarConfig hijri;
  final DateTime gregorian;
  final int day;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: QuranTheme.softFill(context, primary),
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: QuranTheme.outline(context)),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hijri.fullDate(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(gregorian),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w800,
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

class _HijriWeekdayHeader extends StatelessWidget {
  const _HijriWeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: QuranTheme.subText(context, 0.54),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HijriDayCell extends StatelessWidget {
  const _HijriDayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fill = selected
        ? primary
        : today
        ? QuranTheme.softFill(context, primary)
        : QuranTheme.surfaceVariant(context).withValues(alpha: 0.44);
    final border = selected || today ? primary : QuranTheme.outline(context);
    final textColor = selected
        ? Colors.white
        : today
        ? primary
        : QuranTheme.subText(context, 0.78);
    return Material(
      color: fill,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: selected || today
                    ? FontWeight.w700
                    : FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarStatPill extends StatelessWidget {
  const _CalendarStatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: QuranTheme.outline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: QuranTheme.subText(context, 0.58),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.entry,
    required this.time,
    required this.isCurrent,
    required this.isLast,
    required this.alertEnabled,
    required this.onToggleAlert,
  });

  final PrayerTimeEntry entry;
  final String time;
  final bool isCurrent;
  final bool isLast;
  final bool alertEnabled;
  final VoidCallback onToggleAlert;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? primary.withValues(alpha: 0.08)
            : QuranTheme.surfaceVariant(context).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? primary.withValues(alpha: 0.22)
              : QuranTheme.outline(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrent
                  ? primary.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? primary.withValues(alpha: 0.20)
                    : QuranTheme.outline(context),
              ),
            ),
            child: PrayerTimeImage(
              name: entry.name,
              size: 36,
              monochrome: !isCurrent,
              fallbackColor: isCurrent
                  ? primary
                  : QuranTheme.subText(context, 0.72),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent ? 'Current prayer' : _scheduleHint(entry),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? primary
                        : QuranTheme.subText(context, 0.54),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? primary.withValues(alpha: 0.10)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
              border: Border.all(
                color: isCurrent
                    ? primary.withValues(alpha: 0.18)
                    : QuranTheme.outline(context),
              ),
            ),
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isCurrent ? primary : QuranTheme.subText(context, 0.82),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Material(
            color: alertEnabled
                ? primary.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggleAlert,
              child: SizedBox(
                width: 40,
                height: 40,

                child: Icon(
                  alertEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: alertEnabled
                      ? primary
                      : QuranTheme.subText(context, 0.54),
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _scheduleHint(PrayerTimeEntry entry) {
  if (entry.isFridayDhuhr) {
    return 'Friday congregational prayer';
  }

  return switch (entry.name) {
    PrayerTimeName.fajr => 'Before sunrise',
    PrayerTimeName.sunrise => 'Sunrise',
    PrayerTimeName.dhuhr => 'Midday',
    PrayerTimeName.asr => 'Afternoon',
    PrayerTimeName.maghrib => 'Sunset',
    PrayerTimeName.isha => 'Night',
  };
}

PrayerTimeEntry? _entryFor(List<PrayerTimeEntry> entries, PrayerTimeName name) {
  for (final entry in entries) {
    if (entry.name == name) {
      return entry;
    }
  }
  return null;
}

String _methodLabel(PrayerCalculationMethod method) {
  return switch (method) {
    PrayerCalculationMethod.karachi => 'Karachi method',
    PrayerCalculationMethod.muslimWorldLeague => 'MWL method',
    PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
  };
}
