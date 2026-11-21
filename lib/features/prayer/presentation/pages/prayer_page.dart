import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/daily_refresh.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/utils/parse_localized_int.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../home/domain/entities/home_tile.dart';
import '../../../home/presentation/widgets/home_tile_image.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../data/datasources/offline_prayer_city_data_source.dart';
import '../../data/services/prayer_alert_notification_service.dart';
import '../../domain/entities/prayer_alert_settings.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/presentation/bloc/prayer_times_cubit.dart';
import '../../../prayer_times/presentation/bloc/prayer_times_state.dart';
import '../../../qibla/domain/repositories/qibla_repository.dart';
import '../../../qibla/presentation/bloc/qibla_cubit.dart';
import '../../../qibla/presentation/bloc/qibla_state.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../../shell/presentation/bloc/shell_state.dart';
import '../widgets/prayer_times_overview.dart';

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
    return MultiBlocListener(
      listeners: [
        BlocListener<ShellCubit, ShellState>(
          listenWhen: (previous, current) =>
              previous.destination != current.destination &&
              current.destination == ShellDestination.prayer,
          listener: (context, state) => context.read<PrayerTimesCubit>().load(),
        ),
        BlocListener<ShellCubit, ShellState>(
          listenWhen: (previous, current) =>
              previous.qiblaOpenRequestId != current.qiblaOpenRequestId &&
              current.qiblaOpenRequestId > 0,
          listener: (context, state) => _openQiblaFromShortcut(context),
        ),
      ],
      child: DailyRefresh(
        onRefresh: context.read<PrayerTimesCubit>().load,
        timeZone: () => getIt<SettingsStore>().prayerTimeZone,
        builder: (context) => PremiumSurfaceShadowScope(
          style: PremiumSurfaceShadowStyle.none,
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
                        icon: Icons.manage_search_rounded,
                        tooltip: l10n.searchEverythingTitle,
                        onTap: () => context.push(AppRoutes.searchPath()),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: context.read<PrayerTimesCubit>().load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: QuranFloatingAudioPlayer.scrollInset(context),
                      ),
                      children: [
                        const _PrayerTimesSection(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Your worship',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 14),
                              _PrayerToolsGrid(
                                calendarTitle: l10n.calendarTitle,
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
          ),
        ),
      ),
    );
  }
}

Future<void> _openQiblaFromShortcut(BuildContext context) async {
  await context.push(AppRoutes.qiblaPath());
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
        return PremiumSurface(
          padding: EdgeInsets.zero,
          color: const Color(0xFF172A27),
          borderColor: Colors.white12,
          onTap: () => context.push(AppRoutes.qiblaPath()),
          child: _WorshipTileBackground(
            tile: HomeTile.qibla,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AppIcon(
                    Icons.explore_outlined,
                    size: 42,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qibla direction',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppIcon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Colors.white70,
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

class _PrayerToolsGrid extends StatelessWidget {
  const _PrayerToolsGrid({required this.calendarTitle});

  final String calendarTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _QiblaCard(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _PrayerToolTile(
                    tile: HomeTile.islamicCalendar,
                    icon: Icons.calendar_month_outlined,
                    title: calendarTitle,
                    subtitle: 'Hijri calendar',
                    onTap: () => showIslamicCalendarSheet(context),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _PrayerToolTile(
                    tile: HomeTile.prayerJournal,
                    icon: Icons.fact_check_outlined,
                    title: 'Prayer Journal',
                    subtitle: 'Prayer, Qada & fasting',
                    onTap: () => context.push(AppRoutes.prayerTrackingPath()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PrayerToolTile extends StatelessWidget {
  const _PrayerToolTile({
    required this.tile,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final HomeTile tile;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: EdgeInsets.zero,
      color: const Color(0xFF172A27),
      borderColor: Colors.white12,
      onTap: onTap,
      child: _WorshipTileBackground(
        tile: tile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(icon, size: 26, color: Colors.white),
                  const Spacer(),
                  const AppIcon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorshipTileBackground extends StatelessWidget {
  const _WorshipTileBackground({required this.tile, required this.child});

  final HomeTile tile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: ResizeImage(
            AssetImage(HomeTileImage.assetFor(tile)),
            width: 720,
          ),
          opacity: 0.78,
          fit: BoxFit.cover,
          alignment: tile == HomeTile.islamicCalendar
              ? Alignment.center
              : const Alignment(0, 0.4),
          onError: (error, stack) =>
              debugPrint('Worship tile image unavailable: $error'),
        ),
      ),
      child: Ink(
        decoration: const BoxDecoration(color: Color(0xA6000000)),
        child: child,
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
    return PrayerTimesOverview(
      dailyTimes: dailyTimes,
      alertSettings: _alertSettings,
      alertsLoading: _alertsLoading,
      onLocationTap: () =>
          _showPrayerLocationDialog(context, dailyTimes.location),
      onCalendarTap: () => showIslamicCalendarSheet(context),
      onAlertsTap: () => _openAlertsSheet(dailyTimes),
      onTogglePrayerAlert: _togglePrayerAlert,
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
        PrayerLocation(
          name: nearest?.name ?? 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
          timeZone: nearest?.timeZone ?? widget.currentLocation.timeZone,
          usesDeviceLocation: true,
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
    return AppSheet(
      title: 'Prayer location',
      scrollableChild: true,
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentLocationSummary(location: widget.currentLocation),
                _CurrentGpsLocationTile(
                  loading: _locating,
                  onTap: _locating ? null : _useCurrentLocation,
                ),
                if (_message != null) _LocationLookupError(message: _message!),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _runSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search offline city database',
                    prefixIcon: AppIcon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.trim().isEmpty
                      ? 'Suggested cities'
                      : 'Offline city results',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_loadingCities)
            const SliverToBoxAdapter(child: _LocationResultsLoading())
          else if (_cities.isEmpty)
            SliverToBoxAdapter(
              child: _LocationSearchEmpty(query: _searchController.text),
            )
          else
            SliverList.builder(
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                return _LocationPresetTile(
                  city: city,
                  selected: _isSamePrayerLocation(widget.currentLocation, city),
                  onTap: () =>
                      Navigator.of(context).pop(city.toPrayerLocation()),
                );
              },
            ),
        ],
      ),
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
            child: AppIcon(Icons.my_location_rounded, color: primary, size: 20),
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
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Used for prayer times and Qibla',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                    fontWeight: FontWeight.w500,
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
              child: AppIcon(
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.62),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppIcon(
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
                  : AppIcon(Icons.navigation_rounded, color: primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use current location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GPS finds the nearest offline city',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon(
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
            AppIcon(
              Icons.search_rounded,
              color: QuranTheme.subText(context, 0.56),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.66),
                  fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w500,
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
            AppIcon(
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
      return AlertDialog(
        scrollable: true,
        icon: const AppIcon(Icons.my_location_rounded),
        title: const Text('Use your location'),
        content: const Text(
          'We use your location once to find the nearest offline city, calculate accurate prayer times, and set Qibla direction. Your location is not stored beyond your selected prayer city.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
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
        scrollable: true,
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

Future<PrayerAlertSettings?> _showPrayerAlertsSheet(
  BuildContext context,
  DailyPrayerTimes dailyTimes,
  PrayerAlertSettings initialSettings,
) async {
  var draft = initialSettings;
  return showModalBottomSheet<PrayerAlertSettings>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        void update(PrayerAlertSettings next) =>
            setSheetState(() => draft = next);
        return AppSheet(
          title: 'Prayer alerts',
          subtitle:
              '${dailyTimes.location.name} \u00b7 ${_methodLabel(dailyTimes.settings.method)}',
          footer: FilledButton.icon(
            onPressed: () => Navigator.of(sheetContext).pop(draft),
            icon: const AppIcon(Icons.notifications_rounded),
            label: const Text('Save alerts'),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                subtitle: 'Notify ${draft.beforeMinutes} minutes before time',
                value: draft.notifyBeforePrayer,
                onChanged: (value) =>
                    update(draft.copyWith(notifyBeforePrayer: value)),
              ),
              AnimatedExpansion(
                expanded: draft.notifyBeforePrayer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final minutes in const [5, 10, 15, 30])
                          _AlertMinuteChip(
                            minutes: minutes,
                            selected: draft.beforeMinutes == minutes,
                            onTap: () =>
                                update(draft.copyWith(beforeMinutes: minutes)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AlertSwitchTile(
                icon: Icons.wb_twilight_rounded,
                title: 'Sunrise reminder',
                subtitle: 'Optional alert for sunrise',
                value:
                    draft.includeSunrise &&
                    draft.enabledPrayerNames.contains(PrayerTimeName.sunrise),
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                        var next = draft.withPrayer(entry.name, value);
                        if (value &&
                            !next.notifyAtPrayerTime &&
                            !next.notifyBeforePrayer) {
                          next = next.copyWith(notifyAtPrayerTime: true);
                        }
                        update(next);
                      },
                    ),
                  ),
            ],
          ),
        );
      },
    ),
  );
}

Future<bool> _showPrayerAlertPermissionDialog(BuildContext context) async {
  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        scrollable: true,
        icon: const AppIcon(Icons.notifications_active_rounded),
        title: const Text('Allow prayer alerts'),
        content: const Text(
          'Quran needs notification permission to remind you at prayer times, even when the app is closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
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
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: AppIcon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
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
        fontWeight: FontWeight.w600,
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
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.displayName),
      subtitle: Text(DateFormat.jm().format(entry.time)),
      value: enabled,
      onChanged: onChanged,
    );
  }
}

Future<void> showIslamicCalendarSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AppSheet(
      title: 'Islamic calendar',
      subtitle: 'Explore a date, month, or year.',
      child: _IslamicCalendarContent(),
    ),
  );
}

// The installed Umm al-Qura table contains full years 1356 through 1500.
// Derive month lengths from its starts, rather than the package's fixed pattern.
const _calendarFirstYear = 1356;
const _calendarLastYear = 1500;
const _calendarMonthCount = (_calendarLastYear - _calendarFirstYear + 1) * 12;
final _calendarFirstGregorian = HijriCalendarConfig().hijriToGregorian(
  _calendarFirstYear,
  1,
  1,
);
final _calendarLastGregorian = _calendarGregorianForMonthIndex(
  _calendarMonthCount,
  0,
);

DateTime _calendarGregorianForMonthIndex(int index, [int day = 1]) {
  final offset = ummAlquraDateArray[index] - ummAlquraDateArray.first + day - 1;
  return DateTime(
    _calendarFirstGregorian.year,
    _calendarFirstGregorian.month,
    _calendarFirstGregorian.day + offset,
  );
}

int _calendarMonthIndex(int year, int month) =>
    (year - _calendarFirstYear) * 12 + month - 1;

int _calendarDaysInMonth(int year, int month) {
  final index = _calendarMonthIndex(year, month);
  return ummAlquraDateArray[index + 1] - ummAlquraDateArray[index];
}

class _CalendarHijriDate {
  const _CalendarHijriDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;
}

_CalendarHijriDate? _calendarHijriForGregorian(DateTime date) {
  // UTC is used only to count civil days without a daylight-saving offset.
  final offset = DateTime.utc(date.year, date.month, date.day)
      .difference(
        DateTime.utc(
          _calendarFirstGregorian.year,
          _calendarFirstGregorian.month,
          _calendarFirstGregorian.day,
        ),
      )
      .inDays;
  final lunarDay = ummAlquraDateArray.first + offset;
  if (lunarDay < ummAlquraDateArray.first ||
      lunarDay >= ummAlquraDateArray[_calendarMonthCount]) {
    return null;
  }
  var low = 0;
  var high = _calendarMonthCount - 1;
  while (low <= high) {
    final index = (low + high) ~/ 2;
    if (lunarDay < ummAlquraDateArray[index]) {
      high = index - 1;
    } else if (lunarDay >= ummAlquraDateArray[index + 1]) {
      low = index + 1;
    } else {
      return _CalendarHijriDate(
        _calendarFirstYear + index ~/ 12,
        index % 12 + 1,
        lunarDay - ummAlquraDateArray[index] + 1,
      );
    }
  }
  return null;
}

class _IslamicCalendarContent extends StatefulWidget {
  const _IslamicCalendarContent();

  @override
  State<_IslamicCalendarContent> createState() =>
      _IslamicCalendarContentState();
}

class _IslamicCalendarContentState extends State<_IslamicCalendarContent>
    with WidgetsBindingObserver {
  _CalendarHijriDate? _today;
  Timer? _dayRefresh;
  late int _displayedYear;
  late int _displayedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _today = _calendarHijriForGregorian(now);
    final initial =
        _today ??
        (now.isBefore(_calendarFirstGregorian)
            ? const _CalendarHijriDate(_calendarFirstYear, 1, 1)
            : _CalendarHijriDate(
                _calendarLastYear,
                12,
                _calendarDaysInMonth(_calendarLastYear, 12),
              ));
    _displayedYear = initial.year;
    _displayedMonth = initial.month;
    _selectedDay = initial.day;
    _scheduleDayRefresh();
  }

  @override
  void dispose() {
    _dayRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshToday();
    } else if (state == AppLifecycleState.paused) {
      _dayRefresh?.cancel();
    }
  }

  bool get _selectedIsToday =>
      _today?.year == _displayedYear &&
      _today?.month == _displayedMonth &&
      _today?.day == _selectedDay;

  void _scheduleDayRefresh() {
    _dayRefresh?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dayRefresh = Timer(
      tomorrow.difference(now) + const Duration(milliseconds: 100),
      _refreshToday,
    );
  }

  void _refreshToday() {
    if (!mounted) return;
    final followToday = _selectedIsToday;
    setState(() {
      _today = _calendarHijriForGregorian(DateTime.now());
      if (followToday && _today != null) {
        _displayedYear = _today!.year;
        _displayedMonth = _today!.month;
        _selectedDay = _today!.day;
      }
    });
    _scheduleDayRefresh();
  }

  void _showMonth(int year, int month) {
    if (year < _calendarFirstYear ||
        year > _calendarLastYear ||
        month < 1 ||
        month > 12) {
      return;
    }
    setState(() {
      _displayedYear = year;
      _displayedMonth = month;
      _selectedDay = math.min(_selectedDay, _calendarDaysInMonth(year, month));
    });
  }

  void _changeMonth(int delta) {
    final index = _calendarMonthIndex(_displayedYear, _displayedMonth) + delta;
    if (index < 0 || index >= _calendarMonthCount) return;
    _showMonth(_calendarFirstYear + index ~/ 12, index % 12 + 1);
  }

  void _goToToday() {
    final today = _calendarHijriForGregorian(DateTime.now());
    if (today == null) {
      _refreshToday();
      return;
    }
    setState(() {
      _today = today;
      _displayedYear = today.year;
      _displayedMonth = today.month;
      _selectedDay = today.day;
    });
    _scheduleDayRefresh();
  }

  Future<void> _chooseMonth() async {
    final choice = await showModalBottomSheet<_CalendarHijriDate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppSheet(
        title: 'Go to month & year',
        subtitle: 'Enter any Hijri year from 1356 to 1500.',
        child: _CalendarMonthPicker(
          year: _displayedYear,
          month: _displayedMonth,
        ),
      ),
    );
    if (!mounted || choice == null) return;
    _showMonth(choice.year, choice.month);
  }

  Future<void> _chooseGregorianDate() async {
    final index = _calendarMonthIndex(_displayedYear, _displayedMonth);
    final selected = await showDatePicker(
      context: context,
      initialDate: _calendarGregorianForMonthIndex(index, _selectedDay),
      firstDate: _calendarFirstGregorian,
      lastDate: _calendarLastGregorian,
      helpText: 'Go to Gregorian date',
      confirmText: 'Show date',
    );
    if (!mounted || selected == null) return;
    final hijri = _calendarHijriForGregorian(selected);
    if (hijri == null) return;
    setState(() {
      _displayedYear = hijri.year;
      _displayedMonth = hijri.month;
      _selectedDay = hijri.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthIndex = _calendarMonthIndex(_displayedYear, _displayedMonth);
    final daysInMonth = _calendarDaysInMonth(_displayedYear, _displayedMonth);
    final firstGregorian = _calendarGregorianForMonthIndex(monthIndex);
    final lastGregorian = _calendarGregorianForMonthIndex(
      monthIndex,
      daysInMonth,
    );
    final selectedGregorian = _calendarGregorianForMonthIndex(
      monthIndex,
      _selectedDay,
    );
    final monthName = monthNames[_displayedMonth]!;
    final leadingBlanks = firstGregorian.weekday % 7;
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final showingCurrentMonth =
        _today?.year == _displayedYear && _today?.month == _displayedMonth;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _chooseMonth,
              icon: const AppIcon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Month & year'),
            ),
            TextButton.icon(
              onPressed: _chooseGregorianDate,
              icon: const AppIcon(Icons.search_rounded, size: 18),
              label: const Text('Gregorian date'),
            ),
            TextButton.icon(
              onPressed: _today != null && !_selectedIsToday
                  ? _goToToday
                  : null,
              icon: const AppIcon(Icons.calendar_today_rounded, size: 18),
              label: const Text('Today'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PremiumSurface(
          borderColor: QuranTheme.outline(context),
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    icon: const AppIcon(Icons.chevron_left_rounded),
                    onPressed: monthIndex > 0 ? () => _changeMonth(-1) : null,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_displayedYear AH',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: QuranTheme.subText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    icon: const AppIcon(Icons.chevron_right_rounded),
                    onPressed: monthIndex < _calendarMonthCount - 1
                        ? () => _changeMonth(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('d MMM y').format(firstGregorian)} to ${DateFormat('d MMM y').format(lastGregorian)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: _CalendarYearButton(
                      label: 'Previous year',
                      icon: Icons.chevron_left_rounded,
                      onTap: _displayedYear > _calendarFirstYear
                          ? () =>
                                _showMonth(_displayedYear - 1, _displayedMonth)
                          : null,
                    ),
                  ),
                  Expanded(
                    child: _CalendarYearButton(
                      label: 'Next year',
                      icon: Icons.chevron_right_rounded,
                      onTap: _displayedYear < _calendarLastYear
                          ? () =>
                                _showMonth(_displayedYear + 1, _displayedMonth)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Select a day', style: theme.textTheme.titleSmall),
            ),
            Text(
              '$daysInMonth days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HijriWeekdayHeader(),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: cellCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: math.max(
              44,
              MediaQuery.textScalerOf(context).scale(16) + 20,
            ),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final day = index - leadingBlanks + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox.shrink();
            }
            final gregorian = _calendarGregorianForMonthIndex(monthIndex, day);
            return _HijriDayCell(
              day: day,
              selected: day == _selectedDay,
              today: showingCurrentMonth && day == _today?.day,
              semanticLabel:
                  '$day $monthName $_displayedYear AH, '
                  '${DateFormat('EEEE, d MMMM y').format(gregorian)}',
              onTap: () => setState(() => _selectedDay = day),
            );
          },
        ),
        const SizedBox(height: 16),
        _SelectedHijriDateCard(
          hijriLabel: '$_selectedDay $monthName $_displayedYear AH',
          gregorian: selectedGregorian,
          today: _selectedIsToday,
        ),
        const SizedBox(height: 14),
        Text(
          'Umm al-Qura calendar · 1356 to 1500 AH',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: QuranTheme.subText(context),
          ),
        ),
      ],
    );
  }
}

class _CalendarMonthPicker extends StatefulWidget {
  const _CalendarMonthPicker({required this.year, required this.month});

  final int year;
  final int month;

  @override
  State<_CalendarMonthPicker> createState() => _CalendarMonthPickerState();
}

class _CalendarMonthPickerState extends State<_CalendarMonthPicker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;
  late int _month;

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(text: widget.year.toString());
    _month = widget.month;
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      _CalendarHijriDate(parseLocalizedInt(_yearController.text)!, _month, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _month,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            menuMaxHeight: 340,
            decoration: const InputDecoration(labelText: 'Hijri month'),
            items: [
              for (var month = 1; month <= 12; month++)
                DropdownMenuItem(value: month, child: Text(monthNames[month]!)),
            ],
            onChanged: (month) {
              if (month != null) setState(() => _month = month);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Hijri year',
              suffixText: 'AH',
              helperText: '1356 to 1500',
            ),
            validator: (value) {
              final year = parseLocalizedInt(value);
              if (year == null ||
                  year < _calendarFirstYear ||
                  year > _calendarLastYear) {
                return 'Enter a year from 1356 to 1500.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submit,
            icon: const AppIcon(Icons.calendar_month_rounded, size: 20),
            label: const Text('Show month'),
          ),
        ],
      ),
    );
  }
}

class _CalendarYearButton extends StatelessWidget {
  const _CalendarYearButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _SelectedHijriDateCard extends StatelessWidget {
  const _SelectedHijriDateCard({
    required this.hijriLabel,
    required this.gregorian,
    required this.today,
  });

  final String hijriLabel;
  final DateTime gregorian;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumSurface(
      borderColor: QuranTheme.outline(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(Icons.calendar_today_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  today ? 'Selected date · Today' : 'Selected date',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hijriLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM y').format(gregorian),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
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
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const names = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Semantics(
              label: names[index],
              excludeSemantics: true,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: QuranTheme.subText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    required this.semanticLabel,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool today;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      side: today ? BorderSide(color: primary, width: 1.5) : BorderSide.none,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: today ? '$semanticLabel, today' : semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? primary : Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  day.toString(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : today
                        ? primary
                        : null,
                    fontWeight: selected || today
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _methodLabel(PrayerCalculationMethod method) {
  return switch (method) {
    PrayerCalculationMethod.karachi => 'Karachi method',
    PrayerCalculationMethod.muslimWorldLeague => 'MWL method',
    PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
  };
}
