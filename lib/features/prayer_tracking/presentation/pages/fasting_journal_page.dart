import '../../../../core/widgets/app_page_app_bar.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/stores/prayer_tracking_store.dart';
import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../widgets/fasting_log_sheet.dart';

class FastingJournalPage extends StatefulWidget {
  const FastingJournalPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<FastingJournalPage> createState() => _FastingJournalPageState();
}

class _FastingJournalPageState extends State<FastingJournalPage> {
  final _repository = getIt<PrayerTrackingRepository>();
  final _store = getIt<PrayerTrackingStore>();
  final _scrollController = ScrollController();
  DateTime _selectedDate = _day(DateTime.now());
  PrayerTrackingDashboard? _dashboard;
  PrayerTrackingDashboard? _todayDashboard;
  List<FastingRecord> _records = const [];
  bool _loading = true;
  bool _editing = false;
  int _historyLimit = 10;
  String? _error;
  int _generation = 0;

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime get _today => _day(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (widget.initialDate case final date? when date.year >= 1950) {
      _selectedDate = _day(date);
    }
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load([DateTime? date]) async {
    final selected = _day(date ?? _selectedDate);
    final generation = ++_generation;
    setState(() {
      _selectedDate = selected;
      _loading = true;
      _error = null;
    });
    try {
      final today = _today;
      final selectedDashboard = await _repository.dashboard(selected);
      final todayDashboard = selected == today
          ? selectedDashboard
          : await _repository.dashboard(today);
      final records = [..._store.fastingRecords]
        ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
      if (!mounted || generation != _generation) return;
      setState(() {
        _dashboard = selectedDashboard;
        _todayDashboard = todayDashboard;
        _records = records;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Your fasting journal could not be loaded.';
      });
    }
  }

  bool _canLog(DateTime date) =>
      !date.isAfter(_today) && !date.isBefore(DateTime(1950));

  Future<void> _chooseDate() async {
    final today = _today;
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today)
          ? today
          : _selectedDate.isBefore(DateTime(1950))
          ? DateTime(1950)
          : _selectedDate,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Choose a day to log',
    );
    if (selected != null && mounted) await _load(selected);
  }

  Future<void> _editFast() async {
    if (_loading || _editing || !_canLog(_selectedDate)) return;
    setState(() => _editing = true);
    try {
      final saved = await showFastingLogSheet(
        context,
        date: _selectedDate,
        initial: _dashboard?.fast,
      );
      if (saved && mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your fasting log.')),
        );
      }
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _openPlan() async {
    await context.push(AppRoutes.fastingPlanPath());
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageAppBar(
        title: Text(AppLocalizations.of(context).fastingJournalTitle),
        flexibleSpace: const HeaderPatternBackdrop(),
      ),
      body: SafeArea(
        top: false,
        child: _dashboard == null && _loading
            ? const AppLoadingView(label: 'Loading fasting journal')
            : _error != null
            ? AppErrorView(
                title: 'Journal unavailable',
                message: _error!,
                onRetry: _load,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Text(
                      'One day at a time',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep a simple record of your fasts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _dateNavigator(),
                    const SizedBox(height: 12),
                    _weekStrip(),
                    const SizedBox(height: 16),
                    _selectedDayCard(),
                    const SizedBox(height: 28),
                    _summary(),
                    const SizedBox(height: 20),
                    _planCard(),
                    const SizedBox(height: 28),
                    _history(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _dateNavigator() {
    final isToday = _selectedDate == _today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: _editing || !_selectedDate.isAfter(DateTime(1950))
                  ? null
                  : () => _load(
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day - 1,
                      ),
                    ),
              icon: const AppIcon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: TextButton(
                onPressed: _editing ? null : _chooseDate,
                child: Column(
                  children: [
                    Text(
                      isToday
                          ? 'Today'
                          : DateFormat.EEEE().format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: _editing || !_selectedDate.isBefore(_today)
                  ? null
                  : () => _load(
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day + 1,
                      ),
                    ),
              icon: const AppIcon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _editing ? null : _chooseDate,
              icon: const AppIcon(Icons.calendar_today_outlined, size: 16),
              label: const Text('Choose date'),
            ),
            if (!isToday)
              TextButton(
                onPressed: _editing ? null : () => _load(_today),
                child: const Text('Back to today'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _weekStrip() {
    final weekStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day - (_selectedDate.weekday - 1),
    );
    final recordsByDate = {
      for (final record in _records) record.dateKey: record,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
        final width = math.max(46.0 * scale, (constraints.maxWidth - 30) / 7);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                _dayTile(
                  DateTime(weekStart.year, weekStart.month, weekStart.day + i),
                  recordsByDate,
                  width,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dayTile(
    DateTime date,
    Map<String, FastingRecord> records,
    double width,
  ) {
    final selected = date == _selectedDate;
    final record = records[worshipDateKey(date)];
    final enabled = !_editing && (_canLog(date) || record != null);
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.onPrimary
        : QuranTheme.text(context).withValues(alpha: enabled ? 1 : 0.35);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? () => _load(date) : null,
      label:
          '${DateFormat.yMMMMEEEEd().format(date)}, '
          '${record == null ? 'not logged' : _statusLabel(record.status)}',
      excludeSemantics: true,
      child: PremiumSurface(
        width: width,
        radius: QuranTheme.radiusControl,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        color: selected ? scheme.primary : QuranTheme.surface(context),
        borderColor: selected ? scheme.primary : QuranTheme.outline(context),
        borderWidth: 0.8,
        onTap: enabled ? () => _load(date) : null,
        child: Column(
          children: [
            Text(
              DateFormat.E().format(date),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 7),
            Text(
              '${date.day}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            AppIcon(
              record == null
                  ? Icons.circle_outlined
                  : _statusIcon(record.status),
              size: 13,
              color: color.withValues(alpha: record == null ? 0.35 : 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedDayCard() {
    final record = _dashboard?.fast;
    final title = record == null
        ? 'No fast logged'
        : _statusLabel(record.status);
    final subtitle = record == null
        ? 'Add a record when you know how the day went. '
              'Unlogged days are not counted as missed.'
        : switch (record.status) {
            FastStatus.completed =>
              'You recorded a completed fast for this day.',
            FastStatus.missed => 'You recorded that this fast was missed.',
            FastStatus.exempt =>
              'You recorded an exempt day. '
                  'It is not counted as completed or missed.',
          };
    return PremiumSurface(
      borderColor: QuranTheme.outline(context),
      borderWidth: 0.8,
      padding: const EdgeInsets.all(20),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: QuranTheme.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(
                          QuranTheme.radiusControl,
                        ),
                      ),
                      child: AppIcon(
                        record == null
                            ? Icons.edit_note_rounded
                            : _statusIcon(record.status),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (record != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              _typeLabel(record.type),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: QuranTheme.subText(context),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (_canLog(_selectedDate))
                  FilledButton.icon(
                    onPressed: _editing ? null : _editFast,
                    icon: AppIcon(
                      record == null ? Icons.add_rounded : Icons.edit_outlined,
                      size: 18,
                    ),
                    label: Text(record == null ? 'Log fast' : 'Edit fast'),
                  )
                else
                  Text(
                    'This saved record is available to view. '
                    'Choose today or an earlier day to log a fast.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _summary() {
    final dashboard = _todayDashboard!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your progress', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        PremiumSurface(
          borderColor: QuranTheme.outline(context),
          borderWidth: 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Last 30 days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '${dashboard.month.fastsCompleted}',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Fasts completed'),
              const Divider(height: 32),
              Text(
                'All-time records',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 28,
                runSpacing: 16,
                children: [
                  _total(
                    '${dashboard.missedRamadanFasts}',
                    'Ramadan fasts missed',
                  ),
                  _total('${dashboard.makeupFasts}', 'Makeup fasts completed'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _total(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _planCard() => PremiumSurface(
    borderColor: QuranTheme.outline(context),
    borderWidth: 0.8,
    onTap: _editing ? null : _openPlan,
    child: Row(
      children: [
        const AppIcon(Icons.calendar_month_outlined, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).ramadanTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'See Suhoor and Iftar times and prepare for your day.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const AppIcon(Icons.chevron_right_rounded, size: 20),
      ],
    ),
  );

  Widget _history() {
    final records = _records
        .where((record) => DateTime.tryParse(record.dateKey) != null)
        .toList();
    final shown = records.take(_historyLimit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Recent entries', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Tap an entry to view or update it.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          PremiumSurface(
            borderColor: QuranTheme.outline(context),
            borderWidth: 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your journal starts here',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log your first fast above. Your saved entries will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          PremiumSurface(
            borderColor: QuranTheme.outline(context),
            borderWidth: 0.8,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _historyRow(shown[i]),
                ],
              ],
            ),
          ),
        if (records.length > _historyLimit) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _historyLimit += 20),
            child: const Text('Show more entries'),
          ),
        ],
      ],
    );
  }

  Widget _historyRow(FastingRecord record) {
    final date = worshipDateFromKey(record.dateKey);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      onTap: _editing
          ? null
          : () async {
              await _load(date);
              if (mounted && _scrollController.hasClients) {
                await _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
      leading: AppIcon(_statusIcon(record.status), size: 22),
      title: Text(DateFormat.yMMMd().format(date)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${_typeLabel(record.type)} · ${_statusLabel(record.status)}',
        ),
      ),
      trailing: const AppIcon(Icons.chevron_right_rounded, size: 18),
    );
  }

  static String _typeLabel(FastType type) => '${fastingTypeLabel(type)} fast';

  static String _statusLabel(FastStatus status) => fastingStatusLabel(status);

  static IconData _statusIcon(FastStatus status) => switch (status) {
    FastStatus.completed => Icons.check_circle_outline_rounded,
    FastStatus.missed => Icons.remove_circle_outline_rounded,
    FastStatus.exempt => Icons.pause_circle_outline_rounded,
  };
}
