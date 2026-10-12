import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_tracking/domain/entities/prayer_tracking_models.dart';
import '../../../prayer_tracking/domain/repositories/prayer_tracking_repository.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';

class RamadanPage extends StatefulWidget {
  const RamadanPage({super.key});

  @override
  State<RamadanPage> createState() => _RamadanPageState();
}

class _RamadanPageState extends State<RamadanPage> {
  late final PrayerTrackingRepository _trackingRepository;
  late final LibraryUserDataStore _userData;
  late Future<_RamadanData> _future;

  @override
  void initState() {
    super.initState();
    _trackingRepository = getIt<PrayerTrackingRepository>();
    _userData = getIt<LibraryUserDataStore>();
    _future = _load();
  }

  Future<_RamadanData> _load() async {
    final now = DateTime.now();
    HijriCalendarConfig.language = 'en';
    final hijri = HijriCalendarConfig.fromGregorian(now);
    final values = await Future.wait<Object>([
      getIt<PrayerTimesRepository>().getDailyPrayerTimes(date: now),
      _trackingRepository.dashboard(now),
      getIt<ReadingProgressRepository>().dashboard(now: now),
    ]);
    return _RamadanData(
      now: now,
      hijri: hijri,
      prayerTimes: values[0] as DailyPrayerTimes,
      worship: values[1] as PrayerTrackingDashboard,
      reading: values[2] as ReadingDashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).ramadanTitle),
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: FutureBuilder<_RamadanData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const AppIcon(Icons.refresh_rounded),
                label: const Text('Retry dashboard'),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final fajr = _time(data.prayerTimes, PrayerTimeName.fajr);
          final maghrib = _time(data.prayerTimes, PrayerTimeName.maghrib);
          final isRamadan = data.hijri.hMonth == 9;
          final day = data.hijri.hDay;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        isRamadan
                            ? 'RAMADAN ${data.hijri.hYear} • DAY $day'
                            : '${data.hijri.getLongMonthName().toUpperCase()} ${data.hijri.hYear}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRamadan
                            ? _countdownLabel(data.now, maghrib)
                            : 'Ramadan plan',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeMetric(
                              label: 'Suhoor ends',
                              value: DateFormat.jm().format(fajr),
                            ),
                          ),
                          Expanded(
                            child: _TimeMetric(
                              label: 'Iftar',
                              value: DateFormat.jm().format(maghrib),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.prayerTimes.location.name} • calculated offline',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                _FastingTodayCard(record: data.worship.fast, onLog: _logFast),
                const Divider(height: 28),
                InkWell(
                  borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
                  onTap: () => context.push(AppRoutes.readingGoalsPath()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const AppIcon(Icons.menu_book_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Quran goal',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const AppIcon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: data.reading.goalProgress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${data.reading.todayValue} of '
                          '${data.reading.goal.dailyTarget} '
                          '${data.reading.goal.metric.name} today',
                        ),
                        if (data.reading.khatma != null)
                          Text(
                            'Khatma pace: ${data.reading.khatma!.dailyPagesRequired(data.now)} pages today',
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 28),
                _LastTenNightsCard(
                  hijriYear: data.hijri.hYear,
                  night: isRamadan ? day : 21,
                  active: isRamadan && day >= 21,
                  userData: _userData,
                  onChanged: () {
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Hijri dates can vary by local sighting. Prayer times use '
                  'your saved location and calculation settings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.62),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _logFast(FastStatus status) async {
    await _trackingRepository.saveFast(
      date: DateTime.now(),
      type: FastType.ramadan,
      status: status,
    );
    await _refresh();
  }

  DateTime _time(DailyPrayerTimes times, PrayerTimeName name) {
    return times.entries.firstWhere((item) => item.name == name).time;
  }

  String _countdownLabel(DateTime now, DateTime iftar) {
    if (!now.isBefore(iftar)) {
      return 'Iftar has begun';
    }
    final remaining = iftar.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '$hours h $minutes min until Iftar';
  }
}

class _RamadanData {
  const _RamadanData({
    required this.now,
    required this.hijri,
    required this.prayerTimes,
    required this.worship,
    required this.reading,
  });

  final DateTime now;
  final HijriCalendarConfig hijri;
  final DailyPrayerTimes prayerTimes;
  final PrayerTrackingDashboard worship;
  final ReadingDashboard reading;
}

class _TimeMetric extends StatelessWidget {
  const _TimeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FastingTodayCard extends StatelessWidget {
  const _FastingTodayCard({required this.record, required this.onLog});

  final FastingRecord? record;
  final ValueChanged<FastStatus> onLog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Today’s fast',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            record == null
                ? 'Not recorded yet'
                : '${record!.type.name} • ${record!.status.name}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                selected: record?.status == FastStatus.completed,
                label: const Text('Completed'),
                onSelected: (_) => onLog(FastStatus.completed),
              ),
              ChoiceChip(
                selected: record?.status == FastStatus.missed,
                label: const Text('Missed'),
                onSelected: (_) => onLog(FastStatus.missed),
              ),
              ChoiceChip(
                selected: record?.status == FastStatus.exempt,
                label: const Text('Exempt'),
                onSelected: (_) => onLog(FastStatus.exempt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastTenNightsCard extends StatelessWidget {
  const _LastTenNightsCard({
    required this.hijriYear,
    required this.night,
    required this.active,
    required this.userData,
    required this.onChanged,
  });

  final int hijriYear;
  final int night;
  final bool active;
  final LibraryUserDataStore userData;
  final VoidCallback onChanged;

  static const _actions = {
    'night-prayer': 'Night prayer',
    'quran': 'Quran reading',
    'dua': 'Focused Dua',
    'charity': 'Charity or service',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Last ten nights plan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            active
                ? 'Night $night • private checklist'
                : 'Prepare a simple private checklist before night 21.',
          ),
          const SizedBox(height: 8),
          for (final entry in _actions.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.value),
              value: userData.isBookmarked(_key(entry.key)),
              onChanged: (_) async {
                await userData.toggleBookmark(_key(entry.key));
                onChanged();
              },
            ),
        ],
      ),
    );
  }

  String _key(String action) {
    return 'ramadan-plan:$hijriYear:${night.clamp(21, 30)}:$action';
  }
}
