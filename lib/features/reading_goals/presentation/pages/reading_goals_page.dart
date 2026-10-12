import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../cubit/reading_goals_cubit.dart';
import '../cubit/reading_goals_state.dart';

class ReadingGoalsPage extends StatelessWidget {
  const ReadingGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReadingGoalsCubit(
        repository: getIt<ReadingProgressRepository>(),
        quranRepository: getIt<QuranRepository>(),
      )..load(),
      child: const _ReadingGoalsView(),
    );
  }
}

class _ReadingGoalsView extends StatelessWidget {
  const _ReadingGoalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).readingJourneyTitle),
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          if (dashboard == null && state.status == ReadingGoalsStatus.loading) {
            return const AppLoadingView(label: 'Loading reading progress');
          }
          if (dashboard == null) {
            return AppErrorView(
              title: 'Progress unavailable',
              message: state.errorMessage ?? 'Could not load reading progress.',
              onRetry: context.read<ReadingGoalsCubit>().load,
            );
          }
          return RefreshIndicator(
            onRefresh: context.read<ReadingGoalsCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                _DailyGoalCard(dashboard: dashboard),
                const Divider(height: 32),
                _StreakCard(dashboard: dashboard),
                const Divider(height: 32),
                _KhatmaCard(dashboard: dashboard),
                const Divider(height: 32),
                _PlansCard(dashboard: dashboard),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => context.push(AppRoutes.hifzPath()),
                  leading: const AppIcon(Icons.psychology_alt_outlined),
                  title: const Text('Hifz review'),
                  subtitle: const Text('Collections and due reviews'),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.dashboard});

  final ReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final goal = dashboard.goal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppIcon(Icons.track_changes_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit daily goal',
                onPressed: () => _editGoal(context, goal),
                icon: const AppIcon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: dashboard.goalProgress,
            minHeight: 4,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            '${dashboard.todayValue} of ${goal.dailyTarget} ${_metricLabel(goal.metric)} today',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, ReadingGoal goal) async {
    var metric = goal.metric;
    var target = goal.dailyTarget;
    var grace = goal.allowOneGraceDay;
    final next = await showModalBottomSheet<ReadingGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppSheet(
          title: 'Daily reading goal',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ReadingGoalMetric>(
                initialValue: metric,
                decoration: const InputDecoration(labelText: 'Measure'),
                items: const [
                  DropdownMenuItem(
                    value: ReadingGoalMetric.pages,
                    child: Text('Pages'),
                  ),
                  DropdownMenuItem(
                    value: ReadingGoalMetric.verses,
                    child: Text('Verses'),
                  ),
                  DropdownMenuItem(
                    value: ReadingGoalMetric.minutes,
                    child: Text('Minutes'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => metric = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease target',
                    onPressed: target > 1
                        ? () => setDialogState(() => target--)
                        : null,
                    icon: const AppIcon(Icons.remove_circle_outline_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$target ${_metricLabel(metric)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase target',
                    onPressed: () => setDialogState(() => target++),
                    icon: const AppIcon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: grace,
                onChanged: (value) => setDialogState(() => grace = value),
                title: const Text('One grace day per streak'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  ReadingGoal(
                    metric: metric,
                    dailyTarget: target,
                    allowOneGraceDay: grace,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (next != null && context.mounted) {
      await context.read<ReadingGoalsCubit>().saveGoal(next);
    }
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.dashboard});

  final ReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppIcon(
            Icons.local_fire_department_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dashboard.currentStreak} day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Best ${dashboard.bestStreak} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.68),
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

class _KhatmaCard extends StatelessWidget {
  const _KhatmaCard({required this.dashboard});

  final ReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final khatma = dashboard.khatma;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Khatma pacing',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (khatma == null) ...[
            FilledButton.tonalIcon(
              onPressed: () => _startKhatma(context),
              icon: const AppIcon(Icons.auto_stories_rounded),
              label: const Text('Start Khatma plan'),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: khatma.progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              'Page ${khatma.currentPage} • ${khatma.dailyPagesRequired(DateTime.now())} pages per day now',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<ReadingGoalsCubit>()
                        .setKhatmaPaused(!khatma.paused),
                    icon: AppIcon(
                      khatma.paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(khatma.paused ? 'Resume' : 'Pause'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove Khatma plan',
                  onPressed: context.read<ReadingGoalsCubit>().clearKhatma,
                  icon: const AppIcon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startKhatma(BuildContext context) async {
    final days = await _daysDialog(context, title: 'Khatma target');
    if (days != null && context.mounted) {
      await context.read<ReadingGoalsCubit>().startKhatma(days);
    }
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.dashboard});

  final ReadingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reading plans',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Add reading plan',
                onSelected: (value) {
                  if (value == '30') {
                    context.read<ReadingGoalsCubit>().startFullQuranPlan();
                  } else {
                    _startCustomPlan(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: '30', child: Text('30-day Quran')),
                  PopupMenuItem(value: 'custom', child: Text('Custom pages')),
                ],
                icon: const AppIcon(Icons.add_rounded),
              ),
            ],
          ),
          if (dashboard.plans.isEmpty)
            const Text('No structured reading plan yet.'),
          for (final plan in dashboard.plans) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: QuranTheme.outline(context)),
                borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: plan.progress),
                  const SizedBox(height: 6),
                  Text(
                    'Page ${plan.currentPage} of ${plan.endPage} • ${plan.dailyPagesRequired(DateTime.now())} per day',
                  ),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openPage(context, plan.currentPage),
                        icon: const AppIcon(Icons.menu_book_rounded),
                        label: const Text('Continue'),
                      ),
                      IconButton(
                        tooltip: plan.paused ? 'Resume plan' : 'Pause plan',
                        onPressed: () => context
                            .read<ReadingGoalsCubit>()
                            .setPlanPaused(plan.id, !plan.paused),
                        icon: AppIcon(
                          plan.paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove plan',
                        onPressed: () => context
                            .read<ReadingGoalsCubit>()
                            .removePlan(plan.id),
                        icon: const AppIcon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startCustomPlan(BuildContext context) async {
    var title = 'My reading plan';
    var start = '1';
    var end = '604';
    var days = '30';
    final result =
        await showModalBottomSheet<
          ({String title, int start, int end, int days})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AppSheet(
            title: 'Custom reading plan',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  initialValue: title,
                  onChanged: (value) => title = value,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: start,
                  onChanged: (value) => start = value,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Start page'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: end,
                  onChanged: (value) => end = value,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'End page'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: days,
                  onChanged: (value) => days = value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Days'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    title: title,
                    start: int.tryParse(start) ?? 1,
                    end: int.tryParse(end) ?? 604,
                    days: int.tryParse(days) ?? 30,
                  )),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
    if (result != null && context.mounted) {
      await context.read<ReadingGoalsCubit>().startCustomPlan(
        title: result.title,
        startPage: result.start,
        endPage: result.end,
        days: result.days,
      );
    }
  }

  Future<void> _openPage(BuildContext context, int page) async {
    final ayahs = await getIt<QuranRepository>().getPageAyahs(page);
    if (ayahs.isEmpty || !context.mounted) {
      return;
    }
    final first = ayahs.first;
    await context.push(
      AppRoutes.quranReaderPath(first.surahNumber, ayahNumber: first.number),
    );
  }
}

Future<int?> _daysDialog(BuildContext context, {required String title}) {
  var days = '30';
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: days,
            onChanged: (value) => days = value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Complete in days'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop((int.tryParse(days) ?? 30).clamp(1, 3650)),
            child: const Text('Start'),
          ),
        ],
      ),
    ),
  );
}

String _metricLabel(ReadingGoalMetric metric) {
  return switch (metric) {
    ReadingGoalMetric.pages => 'pages',
    ReadingGoalMetric.verses => 'verses',
    ReadingGoalMetric.minutes => 'minutes',
  };
}
