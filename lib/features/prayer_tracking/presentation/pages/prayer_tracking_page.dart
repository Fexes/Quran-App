import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';
import '../cubit/prayer_tracking_cubit.dart';
import '../cubit/prayer_tracking_state.dart';

class PrayerTrackingPage extends StatelessWidget {
  const PrayerTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).prayerJournalTitle),
      ),
      body: BlocBuilder<PrayerTrackingCubit, PrayerTrackingState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          if (dashboard == null &&
              state.status == PrayerTrackingStatus.loading) {
            return const AppLoadingView(label: 'Loading private journal');
          }
          if (dashboard == null) {
            return AppErrorView(
              title: 'Journal unavailable',
              message: state.errorMessage ?? 'Could not load your journal.',
              onRetry: context.read<PrayerTrackingCubit>().load,
            );
          }
          final selected = state.selectedDate ?? DateTime.now();
          return RefreshIndicator(
            onRefresh: context.read<PrayerTrackingCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                _DateNavigator(date: selected),
                if (dashboard.activePause != null) ...[
                  const SizedBox(height: 12),
                  _PauseBanner(range: dashboard.activePause!),
                ],
                const SizedBox(height: 14),
                _PrayerJournalCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _QadaCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _CyclePauseCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _FastingCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _ReflectionCard(dashboard: dashboard),
                const SizedBox(height: 14),
                Text(
                  'This is a private reflection tool, not a religious ruling. '
                  'Journal data has no sharing or analytics path.',
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
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = worshipDateKey(date) == worshipDateKey(DateTime.now());
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous day',
            onPressed: () => context.read<PrayerTrackingCubit>().changeDay(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selected != null && context.mounted) {
                  await context.read<PrayerTrackingCubit>().load(selected);
                }
              },
              child: Column(
                children: [
                  Text(
                    isToday ? 'Today' : DateFormat.EEEE().format(date),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(DateFormat.yMMMd().format(date)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next day',
            onPressed: () => context.read<PrayerTrackingCubit>().changeDay(1),
            icon: const Icon(Icons.chevron_right_rounded),
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
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              range.exemptTracking
                  ? 'Private pause active. Prayers are exempt from missed totals.'
                  : 'Private pause active for this date.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerJournalCard extends StatelessWidget {
  const _PrayerJournalCard({required this.dashboard});

  final PrayerTrackingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final paused = dashboard.activePause?.exemptTracking == true;
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily prayers',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text('Record only what is useful for your own reflection.'),
          const SizedBox(height: 10),
          for (final prayer in TrackedPrayer.values)
            _PrayerRecordRow(
              prayer: prayer,
              record: dashboard.dayRecords[prayer],
              disabled: paused,
            ),
        ],
      ),
    );
  }
}

class _PrayerRecordRow extends StatelessWidget {
  const _PrayerRecordRow({
    required this.prayer,
    required this.record,
    required this.disabled,
  });

  final TrackedPrayer prayer;
  final PrayerTrackingRecord? record;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final status = record?.status ?? PrayerCompletion.unrecorded;
    final canCongregate =
        !disabled &&
        status != PrayerCompletion.unrecorded &&
        status != PrayerCompletion.missed &&
        status != PrayerCompletion.exempt;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              _prayerLabel(prayer),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<PrayerCompletion>(
              initialValue: status,
              isDense: true,
              decoration: const InputDecoration(),
              items: [
                for (final item in PrayerCompletion.values)
                  DropdownMenuItem(
                    value: item,
                    child: Text(_completionLabel(item)),
                  ),
              ],
              onChanged: disabled
                  ? null
                  : (next) {
                      if (next == null) {
                        return;
                      }
                      context.read<PrayerTrackingCubit>().savePrayer(
                        prayer: prayer,
                        status: next,
                        congregation: record?.congregation ?? false,
                      );
                    },
            ),
          ),
          const SizedBox(width: 5),
          Tooltip(
            message: 'Congregation',
            child: IconButton(
              onPressed: canCongregate
                  ? () => context.read<PrayerTrackingCubit>().savePrayer(
                      prayer: prayer,
                      status: status,
                      congregation: !(record?.congregation ?? false),
                    )
                  : null,
              icon: Icon(
                record?.congregation == true
                    ? Icons.groups_rounded
                    : Icons.group_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QadaCard extends StatelessWidget {
  const _QadaCard({required this.dashboard});

  final PrayerTrackingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.update_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qada plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('${dashboard.qadaDue} currently recorded as due'),
                if (dashboard.qadaPlan.enabled)
                  Text('${dashboard.qadaPlan.dailyTarget} planned per day'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _editQadaPlan(context, dashboard),
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}

class _CyclePauseCard extends StatelessWidget {
  const _CyclePauseCard({required this.dashboard});

  final PrayerTrackingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
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
                      'Private cycle pause',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('Optional exemption and reminder suppression.'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Add private pause',
                onPressed: () => _addPause(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          for (final range in dashboard.pauseRanges.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${range.startDateKey} to ${range.endDateKey}'),
              subtitle: Text(
                [
                  if (range.exemptTracking) 'exempt tracking',
                  if (range.suppressReminders) 'reminders paused',
                ].join(' • '),
              ),
              trailing: IconButton(
                tooltip: 'Delete private pause',
                onPressed: () async {
                  await context.read<PrayerTrackingCubit>().removePauseRange(
                    range.id,
                  );
                  await getIt<PrayerAlertNotificationService>()
                      .syncUpcomingAlerts();
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          if (dashboard.pauseRanges.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('No private pause dates saved.'),
            ),
        ],
      ),
    );
  }
}

class _FastingCard extends StatelessWidget {
  const _FastingCard({required this.dashboard});

  final PrayerTrackingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final fast = dashboard.fast;
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
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
                      'Fasting log',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      fast == null
                          ? 'No fast logged for this date'
                          : '${_fastTypeLabel(fast.type)} • ${_fastStatusLabel(fast.status)}',
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _editFast(context, fast),
                child: Text(fast == null ? 'Log' : 'Edit'),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '${dashboard.missedRamadanFasts} Ramadan fasts recorded missed • '
            '${dashboard.makeupFasts} make-up fasts completed',
          ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({required this.dashboard});

  final PrayerTrackingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reflection summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Last 7 days', summary: dashboard.week),
          const Divider(height: 24),
          _SummaryRow(label: 'Last 30 days', summary: dashboard.month),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.summary});

  final String label;
  final WorshipPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          '${summary.prayersCompleted} prayers completed • '
          '${summary.prayersMissed} missed • ${summary.prayersExempt} exempt',
        ),
        Text(
          '${summary.congregational} in congregation • '
          '${summary.fastsCompleted} fasts completed • '
          '${summary.fastsMissed} fasts missed',
        ),
      ],
    );
  }
}

Future<void> _editQadaPlan(
  BuildContext context,
  PrayerTrackingDashboard dashboard,
) async {
  final balance = TextEditingController(text: '${dashboard.qadaDue}');
  final target = TextEditingController(
    text: '${dashboard.qadaPlan.dailyTarget}',
  );
  var enabled = dashboard.qadaPlan.enabled;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Adjust Qada plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set the balance that is meaningful for you. The app does not '
              'determine religious obligations.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balance,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Current balance'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily target'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use daily plan'),
              value: enabled,
              onChanged: (value) => setDialogState(() => enabled = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    await context.read<PrayerTrackingCubit>().setQadaPlan(
      currentBalance: int.tryParse(balance.text) ?? dashboard.qadaDue,
      dailyTarget: int.tryParse(target.text) ?? 1,
      enabled: enabled,
    );
  }
  balance.dispose();
  target.dispose();
}

Future<void> _addPause(BuildContext context) async {
  var start = DateTime.now();
  var end = DateTime.now();
  var suppressReminders = true;
  var exemptTracking = true;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add private pause'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start'),
              trailing: Text(DateFormat.yMMMd().format(start)),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selected != null) {
                  setDialogState(() {
                    start = selected;
                    if (end.isBefore(start)) {
                      end = start;
                    }
                  });
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End'),
              trailing: Text(DateFormat.yMMMd().format(end)),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: end.isBefore(start) ? start : end,
                  firstDate: start,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selected != null) {
                  setDialogState(() => end = selected);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark prayers exempt'),
              value: exemptTracking,
              onChanged: (value) =>
                  setDialogState(() => exemptTracking = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pause prayer reminders'),
              value: suppressReminders,
              onChanged: (value) =>
                  setDialogState(() => suppressReminders = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save privately'),
          ),
        ],
      ),
    ),
  );
  if (saved == true && context.mounted) {
    await context.read<PrayerTrackingCubit>().addPauseRange(
      start: start,
      end: end,
      suppressReminders: suppressReminders,
      exemptTracking: exemptTracking,
    );
    await getIt<PrayerAlertNotificationService>().syncUpcomingAlerts();
  }
}

Future<void> _editFast(BuildContext context, FastingRecord? initial) async {
  var type = initial?.type ?? FastType.ramadan;
  var status = initial?.status ?? FastStatus.completed;
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Fasting log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<FastType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Fast type'),
              items: [
                for (final item in FastType.values)
                  DropdownMenuItem(
                    value: item,
                    child: Text(_fastTypeLabel(item)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => type = value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<FastStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final item in FastStatus.values)
                  DropdownMenuItem(
                    value: item,
                    child: Text(_fastStatusLabel(item)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() => status = value);
                }
              },
            ),
          ],
        ),
        actions: [
          if (initial != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) {
    return;
  }
  if (action == 'save') {
    await context.read<PrayerTrackingCubit>().saveFast(type, status);
  } else if (action == 'delete') {
    await context.read<PrayerTrackingCubit>().removeFast();
  }
}

String _prayerLabel(TrackedPrayer prayer) {
  return switch (prayer) {
    TrackedPrayer.fajr => 'Fajr',
    TrackedPrayer.dhuhr => 'Dhuhr',
    TrackedPrayer.asr => 'Asr',
    TrackedPrayer.maghrib => 'Maghrib',
    TrackedPrayer.isha => 'Isha',
  };
}

String _completionLabel(PrayerCompletion status) {
  return switch (status) {
    PrayerCompletion.unrecorded => 'Not recorded',
    PrayerCompletion.onTime => 'On time',
    PrayerCompletion.late => 'Late',
    PrayerCompletion.missed => 'Missed',
    PrayerCompletion.qada => 'Qada completed',
    PrayerCompletion.exempt => 'Exempt',
  };
}

String _fastTypeLabel(FastType type) {
  return switch (type) {
    FastType.ramadan => 'Ramadan',
    FastType.voluntary => 'Voluntary',
    FastType.makeup => 'Make-up',
  };
}

String _fastStatusLabel(FastStatus status) {
  return switch (status) {
    FastStatus.completed => 'Completed',
    FastStatus.missed => 'Missed',
    FastStatus.exempt => 'Exempt',
  };
}
