import '../../../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/utils/parse_localized_int.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../cubit/prayer_tracking_cubit.dart';
import '../cubit/prayer_tracking_state.dart';
import '../widgets/fasting_log_sheet.dart';
import 'fasting_journal_page.dart';

class PrayerTrackingPage extends StatelessWidget {
  const PrayerTrackingPage({super.key, this.fastingOnly = false});

  final bool fastingOnly;

  @override
  Widget build(BuildContext context) {
    if (fastingOnly) return const FastingJournalPage();
    return BlocProvider(
      create: (_) =>
          PrayerTrackingCubit(repository: getIt<PrayerTrackingRepository>())
            ..load(),
      child: const _PrayerTrackingView(),
    );
  }
}

class _PrayerTrackingView extends StatelessWidget {
  const _PrayerTrackingView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: Text(AppLocalizations.of(context).prayerJournalTitle),
      flexibleSpace: const HeaderPatternBackdrop(),
    ),
    body: SafeArea(
      top: false,
      child: BlocBuilder<PrayerTrackingCubit, PrayerTrackingState>(
        builder: (context, state) {
          final cubit = context.read<PrayerTrackingCubit>();
          final dashboard = state.dashboard;
          if (dashboard == null &&
              state.status != PrayerTrackingStatus.failure) {
            return const AppLoadingView(label: 'Loading your journal');
          }
          if (dashboard == null) {
            return AppErrorView(
              title: 'Journal unavailable',
              message: state.errorMessage ?? 'Could not load your journal.',
              onRetry: cubit.load,
            );
          }
          final date = worshipDateFromKey(dashboard.dateKey);
          final requestedDate = state.selectedDate ?? date;
          final busy = state.status == PrayerTrackingStatus.loading;
          final sameDate = worshipDateKey(requestedDate) == dashboard.dateKey;
          final enabled = !busy && sameDate;
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: () => cubit.load(requestedDate),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text(
                  'Your daily journal',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'A simple space for your prayers and fasts.',
                  style: _subText(context),
                ),
                const SizedBox(height: 24),
                _DateNavigator(date: date, busy: busy),
                if (busy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                  if (!sameDate) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Opening ${DateFormat.yMMMd().format(requestedDate)}…',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
                if (state.status == PrayerTrackingStatus.failure) ...[
                  const SizedBox(height: 12),
                  _JournalSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sameDate
                              ? state.errorMessage ??
                                    'Could not update your journal.'
                              : 'Could not open ${DateFormat.yMMMd().format(requestedDate)}. '
                                    'Your entries below are for ${DateFormat.yMMMd().format(date)}.',
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => cubit.load(requestedDate),
                          icon: const AppIcon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (dashboard.activePause != null) ...[
                  const SizedBox(height: 16),
                  _PauseBanner(range: dashboard.activePause!),
                ],
                const SizedBox(height: 20),
                _PrayerJournalCard(dashboard: dashboard, enabled: enabled),
                const SizedBox(height: 16),
                _FastingCard(dashboard: dashboard, enabled: enabled),
                const SizedBox(height: 28),
                Text('Your recent rhythm', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Totals up to ${DateFormat.yMMMd().format(date)}.',
                  style: _subText(context, small: true),
                ),
                const SizedBox(height: 16),
                _JournalSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryRow(
                        label: 'Last 7 days',
                        summary: dashboard.week,
                      ),
                      const Divider(height: 36),
                      _SummaryRow(
                        label: 'Last 30 days',
                        summary: dashboard.month,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text('Your preferences', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                _QadaCard(dashboard: dashboard, enabled: enabled),
                const SizedBox(height: 16),
                _CyclePauseCard(dashboard: dashboard, enabled: enabled),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _JournalSurface extends StatelessWidget {
  const _JournalSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => PremiumSurface(
    padding: padding,
    borderColor: QuranTheme.outline(context),
    borderWidth: 0.8,
    radius: 12,
    child: child,
  );
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.date, required this.busy});

  final DateTime date;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PrayerTrackingCubit>();
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = DateTime(1950);
    final lastDate = today.add(const Duration(days: 365));
    final day = DateUtils.dateOnly(date);
    final isToday = day == today;
    return _JournalSurface(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: busy || !day.isAfter(firstDate)
                    ? null
                    : () => cubit.load(
                        DateTime(day.year, day.month, day.day - 1),
                      ),
                icon: const AppIcon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: day.isBefore(firstDate)
                                ? firstDate
                                : day.isAfter(lastDate)
                                ? lastDate
                                : day,
                            firstDate: firstDate,
                            lastDate: lastDate,
                            helpText: 'Choose a journal day',
                          );
                          if (selected != null && context.mounted) {
                            await cubit.load(selected);
                          }
                        },
                  child: Column(
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat.EEEE().format(day),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat.yMMMd().format(day),
                        textAlign: TextAlign.center,
                        style: _subText(context, small: true),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: busy || !day.isBefore(lastDate)
                    ? null
                    : () => cubit.load(
                        DateTime(day.year, day.month, day.day + 1),
                      ),
                icon: const AppIcon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          if (!isToday)
            Center(
              child: TextButton(
                onPressed: busy ? null : () => cubit.load(today),
                child: const Text('Back to today'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PauseBanner extends StatelessWidget {
  const _PauseBanner({required this.range});

  final CyclePauseRange range;

  @override
  Widget build(BuildContext context) => _JournalSurface(
    child: Row(
      children: [
        const AppIcon(Icons.pause_circle_outline, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A private pause is active',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                range.exemptTracking
                    ? 'Prayers on this day are marked exempt.'
                    : 'Your saved pause includes this day.',
                style: _subText(context, small: true),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrayerJournalCard extends StatelessWidget {
  const _PrayerJournalCard({required this.dashboard, required this.enabled});

  final PrayerTrackingDashboard dashboard;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final paused = dashboard.activePause?.exemptTracking == true;
    final recorded = dashboard.dayRecords.values
        .where((record) => record.status != PrayerCompletion.unrecorded)
        .length;
    final completed = dashboard.dayRecords.values
        .where((record) => _canCongregate(record.status))
        .length;
    return _JournalSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily prayers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  paused
                      ? 'Your private pause covers this day.'
                      : 'Tap a prayer to record how it went.',
                  style: _subText(context),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _JournalTag(label: '$recorded of 5 recorded'),
                    if (completed > 0)
                      _JournalTag(label: '$completed completed'),
                  ],
                ),
              ],
            ),
          ),
          for (final prayer in TrackedPrayer.values) ...[
            const Divider(height: 1),
            _PrayerRecordRow(
              prayer: prayer,
              record: dashboard.dayRecords[prayer],
              date: worshipDateFromKey(dashboard.dateKey),
              enabled: enabled && !paused,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
            child: Text(
              'Unrecorded prayers stay unrecorded.',
              style: _subText(context, small: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalTag extends StatelessWidget {
  const _JournalTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: QuranTheme.surfaceVariant(context),
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelMedium),
  );
}

class _PrayerRecordRow extends StatelessWidget {
  const _PrayerRecordRow({
    required this.prayer,
    required this.record,
    required this.date,
    required this.enabled,
  });

  final TrackedPrayer prayer;
  final PrayerTrackingRecord? record;
  final DateTime date;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final status = record?.status ?? PrayerCompletion.unrecorded;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${_prayerLabel(prayer)}, ${_completionLabel(status)}',
      child: InkWell(
        onTap: enabled
            ? () => _editPrayer(context, prayer, record, date)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              AppIcon(_completionIcon(status), size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _prayerLabel(prayer),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _completionLabel(status),
                        if (record?.congregation == true &&
                            _canCongregate(status))
                          'In congregation',
                      ].join(' · '),
                      style: _subText(context, small: true),
                    ),
                  ],
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                const AppIcon(Icons.chevron_right_rounded, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FastingCard extends StatelessWidget {
  const _FastingCard({required this.dashboard, required this.enabled});

  final PrayerTrackingDashboard dashboard;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fast = dashboard.fast;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      child: PremiumSurface(
        borderColor: QuranTheme.outline(context),
        borderWidth: 0.8,
        radius: 12,
        padding: const EdgeInsets.all(18),
        onTap: enabled
            ? () async {
                final date = worshipDateFromKey(dashboard.dateKey);
                final cubit = context.read<PrayerTrackingCubit>();
                try {
                  await context.push(AppRoutes.fastingJournalPath(date: date));
                  if (context.mounted) await cubit.load(date);
                } catch (_) {
                  if (context.mounted) {
                    _showError(context, 'Could not open your fasting journal.');
                  }
                }
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(Icons.wb_twilight_outlined, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fasting journal',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                const AppIcon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              fast == null
                  ? 'No fast logged for this day'
                  : '${fastingTypeLabel(fast.type)} · ${fastingStatusLabel(fast.status)}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              fast == null
                  ? 'Log this day and view your fasting history.'
                  : 'Edit this day or explore your fasting history.',
              style: _subText(context),
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _JournalTag(
                  label:
                      '${dashboard.missedRamadanFasts} Ramadan fasts not completed',
                ),
                _JournalTag(
                  label: '${dashboard.makeupFasts} make-up fasts completed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.summary});

  final String label;
  final WorshipPeriodSummary summary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 280
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;
          final metrics = <(int, String)>[
            (summary.prayersCompleted, 'Prayers completed'),
            (summary.prayersMissed, 'Prayers missed'),
            (summary.prayersExempt, 'Prayers exempt'),
            (summary.congregational, 'In congregation'),
            (summary.fastsCompleted, 'Fasts completed'),
            (summary.fastsMissed, 'Fasts not completed'),
          ];
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final (count, label) in metrics)
                SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(label, style: _subText(context, small: true)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _QadaCard extends StatelessWidget {
  const _QadaCard({required this.dashboard, required this.enabled});

  final PrayerTrackingDashboard dashboard;
  final bool enabled;

  @override
  Widget build(BuildContext context) => _JournalSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Make-up prayers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Your Qada plan', style: _subText(context)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _JournalTag(label: '${dashboard.qadaDue} in your recorded balance'),
            _JournalTag(
              label: dashboard.qadaPlan.enabled
                  ? '${dashboard.qadaPlan.dailyTarget} planned per day'
                  : 'Daily plan off',
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: enabled ? () => _editQadaPlan(context, dashboard) : null,
          icon: const AppIcon(Icons.tune_rounded, size: 18),
          label: const Text('Adjust plan'),
        ),
      ],
    ),
  );
}

class _CyclePauseCard extends StatelessWidget {
  const _CyclePauseCard({required this.dashboard, required this.enabled});

  final PrayerTrackingDashboard dashboard;
  final bool enabled;

  @override
  Widget build(BuildContext context) => _JournalSurface(
    padding: EdgeInsets.zero,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(
          'Private cycle pause',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Manage exempt days and prayer reminders.',
            style: _subText(context, small: true),
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: enabled
                    ? () => _addPause(
                        context,
                        worshipDateFromKey(dashboard.dateKey),
                      )
                    : null,
                icon: const AppIcon(Icons.add_rounded, size: 18),
                label: const Text('Add pause dates'),
              ),
              if (dashboard.pauseRanges.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'No pause dates saved.',
                  style: _subText(context, small: true),
                ),
              ],
              for (final range in dashboard.pauseRanges) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat.yMMMd().format(worshipDateFromKey(range.startDateKey))} '
                            'to ${DateFormat.yMMMd().format(worshipDateFromKey(range.endDateKey))}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (range.exemptTracking) 'Prayers exempt',
                              if (range.suppressReminders) 'Reminders paused',
                              if (!range.exemptTracking &&
                                  !range.suppressReminders)
                                'Dates saved',
                            ].join(' · '),
                            style: _subText(context, small: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remove pause dates',
                      onPressed: enabled
                          ? () => _removePause(context, range)
                          : null,
                      icon: const AppIcon(
                        Icons.delete_outline_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _editPrayer(
  BuildContext context,
  TrackedPrayer prayer,
  PrayerTrackingRecord? record,
  DateTime date,
) async {
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrayerLogSheet(
        cubit: context.read<PrayerTrackingCubit>(),
        prayer: prayer,
        record: record,
        date: date,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Could not open this prayer entry.');
    }
  }
}

class _PrayerLogSheet extends StatefulWidget {
  const _PrayerLogSheet({
    required this.cubit,
    required this.prayer,
    required this.record,
    required this.date,
  });

  final PrayerTrackingCubit cubit;
  final TrackedPrayer prayer;
  final PrayerTrackingRecord? record;
  final DateTime date;

  @override
  State<_PrayerLogSheet> createState() => _PrayerLogSheetState();
}

class _PrayerLogSheetState extends State<_PrayerLogSheet> {
  late PrayerCompletion _status =
      widget.record?.status ?? PrayerCompletion.unrecorded;
  late bool _congregation = widget.record?.congregation ?? false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.cubit.savePrayer(
        prayer: widget.prayer,
        status: _status,
        congregation: _canCongregate(_status) && _congregation,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your prayer could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppSheet(
      title: _prayerLabel(widget.prayer),
      subtitle: DateFormat.yMMMMEEEEd().format(widget.date),
      onClose: () {
        if (!_saving) Navigator.of(context).pop();
      },
      footer: _SaveFooter(
        saving: _saving,
        error: _error,
        label: 'Save prayer',
        onSave: _save,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'How did it go?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final status in [
            PrayerCompletion.onTime,
            PrayerCompletion.late,
            PrayerCompletion.missed,
            PrayerCompletion.qada,
            PrayerCompletion.exempt,
            PrayerCompletion.unrecorded,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                button: true,
                selected: _status == status,
                enabled: !_saving,
                child: PremiumSurface(
                  onTap: _saving
                      ? null
                      : () => setState(() => _status = status),
                  radius: QuranTheme.radiusControl,
                  padding: const EdgeInsets.all(14),
                  borderColor: _status == status
                      ? Theme.of(context).colorScheme.primary
                      : QuranTheme.outline(context),
                  borderWidth: _status == status ? 1.3 : 0.8,
                  child: Row(
                    children: [
                      AppIcon(_completionIcon(status), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _completionLabel(status),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (_status == status) ...[
                        const SizedBox(width: 8),
                        const AppIcon(Icons.check_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (_canCongregate(_status))
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prayed in congregation'),
              value: _congregation,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _congregation = value),
            ),
        ],
      ),
    ),
  );
}

class _SaveFooter extends StatelessWidget {
  const _SaveFooter({
    required this.saving,
    required this.error,
    required this.label,
    required this.onSave,
  });

  final bool saving;
  final String? error;
  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (error != null) ...[
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 12),
      ],
      FilledButton.icon(
        onPressed: saving ? null : onSave,
        icon: saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const AppIcon(Icons.check_rounded, size: 18),
        label: Text(saving ? 'Saving…' : label),
      ),
    ],
  );
}

Future<void> _editQadaPlan(
  BuildContext context,
  PrayerTrackingDashboard dashboard,
) async {
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _QadaPlanSheet(
        cubit: context.read<PrayerTrackingCubit>(),
        dashboard: dashboard,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Could not open your make-up prayer plan.');
    }
  }
}

class _QadaPlanSheet extends StatefulWidget {
  const _QadaPlanSheet({required this.cubit, required this.dashboard});

  final PrayerTrackingCubit cubit;
  final PrayerTrackingDashboard dashboard;

  @override
  State<_QadaPlanSheet> createState() => _QadaPlanSheetState();
}

class _QadaPlanSheetState extends State<_QadaPlanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _balance = TextEditingController(
    text: '${widget.dashboard.qadaDue}',
  );
  late final _target = TextEditingController(
    text: '${widget.dashboard.qadaPlan.dailyTarget}',
  );
  late bool _enabled = widget.dashboard.qadaPlan.enabled;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _balance.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.cubit.setQadaPlan(
        currentBalance: parseLocalizedInt(_balance.text)!,
        dailyTarget: parseLocalizedInt(_target.text)!,
        enabled: _enabled,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your plan could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppSheet(
      title: 'Your make-up prayer plan',
      subtitle: 'Set a balance and a manageable daily target.',
      onClose: () {
        if (!_saving) Navigator.of(context).pop();
      },
      footer: _SaveFooter(
        saving: _saving,
        error: _error,
        label: 'Save plan',
        onSave: _save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextFormField(
              controller: _balance,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Current recorded balance',
                helperText: 'Number of make-up prayers you want to track.',
                helperMaxLines: 3,
              ),
              validator: (value) {
                final number = parseLocalizedInt(value);
                return number == null || number < 0 || number > 1000000
                    ? 'Enter a number from 0 to 1,000,000.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _target,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Daily target',
                helperText: 'Make-up prayers you plan to complete each day.',
                helperMaxLines: 3,
              ),
              validator: (value) {
                final number = parseLocalizedInt(value);
                return number == null || number < 1 || number > 100
                    ? 'Enter a number from 1 to 100.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use a daily plan'),
              subtitle: const Text('Show your target in the journal.'),
              value: _enabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _addPause(BuildContext context, DateTime date) async {
  try {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PauseSheet(cubit: context.read<PrayerTrackingCubit>(), date: date),
    );
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Could not open your private pause.');
    }
  }
}

class _PauseSheet extends StatefulWidget {
  const _PauseSheet({required this.cubit, required this.date});

  final PrayerTrackingCubit cubit;
  final DateTime date;

  @override
  State<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<_PauseSheet> {
  late DateTimeRange _range = DateTimeRange(
    start: DateUtils.dateOnly(widget.date),
    end: DateUtils.dateOnly(widget.date),
  );
  bool _suppressReminders = true;
  bool _exemptTracking = true;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    final notificationContext = context;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.cubit.addPauseRange(
        start: _range.start,
        end: _range.end,
        suppressReminders: _suppressReminders,
        exemptTracking: _exemptTracking,
      );
      await _syncAlerts(
        notificationContext.mounted ? notificationContext : null,
        'Pause saved. Prayer reminders could not be updated yet.',
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your pause could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppSheet(
      title: 'Add private pause dates',
      subtitle: 'Choose the dates and options that suit you.',
      onClose: () {
        if (!_saving) Navigator.of(context).pop(false);
      },
      footer: _SaveFooter(
        saving: _saving,
        error: _error,
        label: 'Save pause',
        onSave: _save,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          PremiumSurface(
            borderColor: QuranTheme.outline(context),
            borderWidth: 0.8,
            onTap: _saving
                ? null
                : () async {
                    final first = DateTime(1950);
                    final last = DateUtils.dateOnly(
                      DateTime.now(),
                    ).add(const Duration(days: 365));
                    final initial =
                        _range.start.isBefore(first) || _range.end.isAfter(last)
                        ? null
                        : _range;
                    final selected = await showDateRangePicker(
                      context: context,
                      firstDate: first,
                      lastDate: last,
                      initialDateRange: initial,
                      helpText: 'Choose your pause dates',
                    );
                    if (selected != null && mounted) {
                      setState(() => _range = selected);
                    }
                  },
            child: Row(
              children: [
                const AppIcon(Icons.calendar_today_outlined, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date range',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.yMMMd().format(_range.start)} to ${DateFormat.yMMMd().format(_range.end)}',
                        style: _subText(context, small: true),
                      ),
                    ],
                  ),
                ),
                const AppIcon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark prayers exempt'),
            subtitle: const Text(
              'Exclude these days from missed-prayer totals.',
            ),
            value: _exemptTracking,
            onChanged: _saving
                ? null
                : (value) => setState(() => _exemptTracking = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pause prayer reminders'),
            subtitle: const Text('Silence prayer alerts during these dates.'),
            value: _suppressReminders,
            onChanged: _saving
                ? null
                : (value) => setState(() => _suppressReminders = value),
          ),
        ],
      ),
    ),
  );
}

Future<void> _removePause(BuildContext context, CyclePauseRange range) async {
  final cubit = context.read<PrayerTrackingCubit>();
  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove these pause dates?'),
        content: const Text(
          'The journal and prayer reminders will use your usual settings for these days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep pause'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await cubit.removePauseRange(range.id);
  } catch (_) {
    if (context.mounted) {
      _showError(
        context,
        'These pause dates could not be removed. Please try again.',
      );
    }
    return;
  }
  await _syncAlerts(
    context.mounted ? context : null,
    'Pause removed. Prayer reminders could not be updated yet.',
  );
}

Future<void> _syncAlerts(BuildContext? context, String failureMessage) async {
  try {
    await getIt<PrayerAlertNotificationService>().syncUpcomingAlerts();
  } catch (_) {
    if (context != null && context.mounted) {
      _showError(context, failureMessage);
    }
  }
}

void _showError(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

TextStyle? _subText(BuildContext context, {bool small = false}) =>
    (small
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(color: QuranTheme.subText(context));

bool _canCongregate(PrayerCompletion status) =>
    status == PrayerCompletion.onTime ||
    status == PrayerCompletion.late ||
    status == PrayerCompletion.qada;

String _prayerLabel(TrackedPrayer prayer) => switch (prayer) {
  TrackedPrayer.fajr => 'Fajr',
  TrackedPrayer.dhuhr => 'Dhuhr',
  TrackedPrayer.asr => 'Asr',
  TrackedPrayer.maghrib => 'Maghrib',
  TrackedPrayer.isha => 'Isha',
};

String _completionLabel(PrayerCompletion status) => switch (status) {
  PrayerCompletion.unrecorded => 'Not recorded',
  PrayerCompletion.onTime => 'On time',
  PrayerCompletion.late => 'Late',
  PrayerCompletion.missed => 'Missed',
  PrayerCompletion.qada => 'Qada completed',
  PrayerCompletion.exempt => 'Exempt',
};

IconData _completionIcon(PrayerCompletion status) => switch (status) {
  PrayerCompletion.unrecorded => Icons.radio_button_unchecked,
  PrayerCompletion.onTime => Icons.check_circle_outline,
  PrayerCompletion.late => Icons.schedule_rounded,
  PrayerCompletion.missed => Icons.remove_circle_outline,
  PrayerCompletion.qada => Icons.update_rounded,
  PrayerCompletion.exempt => Icons.pause_circle_outline,
};
