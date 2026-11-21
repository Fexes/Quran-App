import '../../../../core/widgets/app_page_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_tracking/domain/entities/prayer_tracking_models.dart';
import '../../../prayer_tracking/domain/repositories/prayer_tracking_repository.dart';
import '../../../prayer_tracking/presentation/widgets/fasting_log_sheet.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';

class RamadanPage extends StatefulWidget {
  const RamadanPage({super.key});

  @override
  State<RamadanPage> createState() => _RamadanPageState();
}

class _RamadanPageState extends State<RamadanPage> with WidgetsBindingObserver {
  late final _trackingRepository = getIt<PrayerTrackingRepository>();
  late final _prayerRepository = getIt<PrayerTimesRepository>();
  late final _userData = getIt<LibraryUserDataStore>();
  late Future<_FastingPlanData> _future;
  Timer? _clock;
  DateTime? _loadedDate;
  bool _refreshing = false;
  bool _refreshQueued = false;
  bool _openingLog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_prayerRepository case PrayerLocationObservable observable) {
      observable.locationChanges.addListener(_locationChanged);
    }
    _future = _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      if (!DateUtils.isSameDay(_loadedDate, DateTime.now())) {
        unawaited(_refresh());
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_prayerRepository case PrayerLocationObservable observable) {
      observable.locationChanges.removeListener(_locationChanged);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  void _locationChanged() => unawaited(_refresh());

  Future<_FastingPlanData> _load() async {
    final now = DateTime.now();
    final values = await Future.wait<Object>([
      _prayerRepository.getDailyPrayerTimes(date: now),
      _trackingRepository.dashboard(now),
      getIt<ReadingProgressRepository>().dashboard(now: now),
    ]);
    _loadedDate = now;
    return _FastingPlanData(
      date: now,
      hijri: HijriCalendarConfig.fromGregorian(now),
      prayerTimes: values[0] as DailyPrayerTimes,
      worship: values[1] as PrayerTrackingDashboard,
      reading: values[2] as ReadingDashboard,
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        setState(() => _future = _load());
        try {
          await _future;
        } catch (_) {
          // The page presents the failed request with a retry action.
        }
      } while (mounted && _refreshQueued);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _logFast(DateTime date, FastingRecord? record) async {
    if (_openingLog || _refreshing) return;
    if (!DateUtils.isSameDay(date, DateTime.now())) {
      await _refresh();
      return;
    }
    setState(() => _openingLog = true);
    try {
      final changed = await showFastingLogSheet(
        context,
        date: date,
        initial: record,
      );
      if (changed && mounted) await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your fasting log.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingLog = false);
    }
  }

  Future<void> _openJournal() async {
    await context.push(AppRoutes.fastingJournalPath());
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppPageAppBar(
        title: Text(AppLocalizations.of(context).ramadanTitle),
        flexibleSpace: const HeaderPatternBackdrop(),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<_FastingPlanData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Your fasting plan could not be loaded.'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const AppIcon(Icons.refresh_rounded, size: 20),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const AppLoadingView(label: 'Loading your fasting plan…');
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Today', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.yMMMMEEEEd().format(data.date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: QuranTheme.subText(context),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _schedule(data),
                          const SizedBox(height: 16),
                          _todayRecord(data.worship.fast, data.date),
                          const SizedBox(height: 16),
                          PremiumSurface(
                            onTap: _openJournal,
                            borderWidth: 0.8,
                            padding: const EdgeInsets.all(18),
                            child: const _NavigationRow(
                              icon: Icons.calendar_month_outlined,
                              title: 'Fasting journal',
                              subtitle: 'View past fasts or log another day.',
                            ),
                          ),
                          if (data.reading.goal.enabled ||
                              data.reading.khatma != null) ...[
                            const SizedBox(height: 24),
                            _readingGoal(data.reading, data.date),
                          ],
                          if (data.hijri.hMonth == 9) ...[
                            const SizedBox(height: 16),
                            _LastTenNightsCard(
                              key: ValueKey(
                                '${data.hijri.hYear}:${data.hijri.hDay}',
                              ),
                              hijriYear: data.hijri.hYear,
                              night: data.hijri.hDay,
                              userData: _userData,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Times follow your saved prayer location and '
                            'calculation settings. Hijri dates may vary by '
                            'local moon sighting.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: QuranTheme.subText(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _schedule(_FastingPlanData data) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final fajr = data.prayerTimes.entries
        .firstWhere((item) => item.name == PrayerTimeName.fajr)
        .time;
    final maghrib = data.prayerTimes.entries
        .firstWhere((item) => item.name == PrayerTimeName.maghrib)
        .time;
    final beforeFajr = now.isBefore(fajr);
    final beforeIftar = now.isBefore(maghrib);
    final target = beforeFajr ? fajr : maghrib;
    final minutes = (target.difference(now).inSeconds / 60).ceil();
    final countdown = minutes >= 60
        ? '${minutes ~/ 60} h ${minutes % 60} min'
        : '$minutes min';
    return PremiumSurface(
      borderColor: QuranTheme.outline(context),
      borderWidth: 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${data.hijri.hDay} ${data.hijri.getLongMonthName()} '
            '${data.hijri.hYear}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            beforeFajr
                ? 'Suhoor ends in'
                : beforeIftar
                ? 'Iftar in'
                : 'Iftar time has arrived',
            style: theme.textTheme.titleMedium,
          ),
          if (beforeIftar) ...[
            const SizedBox(height: 4),
            Text(countdown, style: theme.textTheme.headlineLarge),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'You can record how today went in your journal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          ],
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth >=
                      300 * MediaQuery.textScalerOf(context).scale(1)
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _TimeMetric(
                    width: width,
                    label: 'Suhoor ends',
                    caption: 'Fajr',
                    time: fajr,
                  ),
                  _TimeMetric(
                    width: width,
                    label: 'Iftar',
                    caption: 'Maghrib',
                    time: maghrib,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AppIcon(
                Icons.location_on_outlined,
                size: 18,
                color: QuranTheme.subText(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.prayerTimes.location.name,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Your saved prayer location',
            style: theme.textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayRecord(FastingRecord? record, DateTime date) {
    final theme = Theme.of(context);
    return PremiumSurface(
      borderColor: QuranTheme.outline(context),
      borderWidth: 0.8,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Today’s fast', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RecordLabel(
                record == null
                    ? 'Not logged yet'
                    : fastingStatusLabel(record.status),
              ),
              if (record != null) _RecordLabel(fastingTypeLabel(record.type)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record == null
                ? 'Keep a simple record when you’re ready.'
                : 'Your entry is saved. You can update it anytime.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openingLog || _refreshing
                ? null
                : () => _logFast(date, record),
            icon: AppIcon(
              record == null ? Icons.add_rounded : Icons.edit_outlined,
              size: 20,
            ),
            label: Text(record == null ? 'Log fast' : 'Edit fast'),
          ),
        ],
      ),
    );
  }

  Widget _readingGoal(ReadingDashboard reading, DateTime date) {
    final theme = Theme.of(context);
    final metric = switch (reading.goal.metric) {
      ReadingGoalMetric.verses => 'verses',
      ReadingGoalMetric.pages => 'pages',
      ReadingGoalMetric.minutes => 'minutes',
    };
    return PremiumSurface(
      onTap: () async {
        await context.push(AppRoutes.readingGoalsPath());
        if (mounted) await _refresh();
      },
      padding: const EdgeInsets.all(18),
      borderWidth: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NavigationRow(
            icon: Icons.menu_book_outlined,
            title: 'Quran reading',
            subtitle: 'A little space for your reading goal.',
          ),
          if (reading.goal.enabled) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: reading.goalProgress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              '${reading.todayValue} of ${reading.goal.dailyTarget} $metric today',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (reading.khatma case final khatma?
              when !khatma.paused && !khatma.completed) ...[
            const SizedBox(height: 6),
            Text(
              'Khatma goal: ${khatma.dailyPagesRequired(date)} pages today',
              style: theme.textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FastingPlanData {
  const _FastingPlanData({
    required this.date,
    required this.hijri,
    required this.prayerTimes,
    required this.worship,
    required this.reading,
  });
  final DateTime date;
  final HijriCalendarConfig hijri;
  final DailyPrayerTimes prayerTimes;
  final PrayerTrackingDashboard worship;
  final ReadingDashboard reading;
}

class _TimeMetric extends StatelessWidget {
  const _TimeMetric({
    required this.width,
    required this.label,
    required this.caption,
    required this.time,
  });
  final double width;
  final String label;
  final String caption;
  final DateTime time;

  @override
  Widget build(BuildContext context) => PremiumSurface(
    width: width,
    color: QuranTheme.surfaceVariant(context),
    showBorder: false,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        Text(
          DateFormat.jm().format(time),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 3),
        Text(
          caption,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
        ),
      ],
    ),
  );
}

class _RecordLabel extends StatelessWidget {
  const _RecordLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: QuranTheme.surfaceVariant(context),
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppIcon(icon, size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
      const SizedBox(width: 10),
      const AppIcon(Icons.chevron_right_rounded, size: 20),
    ],
  );
}

class _LastTenNightsCard extends StatefulWidget {
  const _LastTenNightsCard({
    super.key,
    required this.hijriYear,
    required this.night,
    required this.userData,
  });
  final int hijriYear;
  final int night;
  final LibraryUserDataStore userData;

  @override
  State<_LastTenNightsCard> createState() => _LastTenNightsCardState();
}

class _LastTenNightsCardState extends State<_LastTenNightsCard> {
  static const _actions = {
    'night-prayer': 'Night prayer',
    'quran': 'Quran reading',
    'dua': 'Focused dua',
    'charity': 'Charity or service',
  };
  bool _saving = false;
  String? _error;

  String _key(String action) =>
      'ramadan-plan:${widget.hijriYear}:${widget.night.clamp(21, 30)}:$action';

  Future<void> _toggle(String action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.userData.toggleBookmark(_key(action));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Your checklist could not be saved. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PremiumSurface(
    borderColor: QuranTheme.outline(context),
    borderWidth: 0.8,
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      initiallyExpanded: widget.night >= 21,
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        'Last ten nights',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        widget.night >= 21
            ? 'Night ${widget.night} · Your private checklist'
            : 'Optional checklist for night 21 onwards',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      children: [
        Text(
          'Choose a few things you would like to make time for.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
        ),
        const SizedBox(height: 8),
        for (final entry in _actions.entries)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              entry.value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: widget.userData.isBookmarked(_key(entry.key)),
            onChanged: _saving ? null : (_) => _toggle(entry.key),
          ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );
}
