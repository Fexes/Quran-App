import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
              children: [
                PremiumSurface(
                  onTap: () => context.push(AppRoutes.hifzPath()),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.psychology_alt_rounded),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hifz review',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text('Due reviews, recall tools, and weak Surahs'),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DailyGoalCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _StreakCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _KhatmaCard(dashboard: dashboard),
                const SizedBox(height: 14),
                _PlansCard(dashboard: dashboard),
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
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit daily goal',
                onPressed: () => _editGoal(context, goal),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: dashboard.goalProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            '${dashboard.todayValue} of ${goal.dailyTarget} ${_metricLabel(goal.metric)} today',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Only unique verses and pages reached through real reader movement count.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.68),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, ReadingGoal goal) async {
    var metric = goal.metric;
    var target = goal.dailyTarget;
    var grace = goal.allowOneGraceDay;
    final next = await showDialog<ReadingGoal>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Daily reading goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                    onPressed: target > 1
                        ? () => setDialogState(() => target--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$target ${_metricLabel(metric)}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setDialogState(() => target++),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: grace,
                onChanged: (value) => setDialogState(() => grace = value),
                title: const Text('One grace day per streak'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
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
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Best ${dashboard.bestStreak} days • local calendar days',
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
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Khatma pacing',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (khatma == null) ...[
            const Text(
              'Create a completion target. Missed days automatically recalculate the remaining daily pages.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _startKhatma(context),
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Start Khatma plan'),
            ),
          ] else ...[
            LinearProgressIndicator(
              value: khatma.progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Text(
              'Page ${khatma.currentPage} • ${khatma.dailyPagesRequired(DateTime.now())} pages per day now',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<ReadingGoalsCubit>()
                        .setKhatmaPaused(!khatma.paused),
                    icon: Icon(
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
                  icon: const Icon(Icons.delete_outline_rounded),
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
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reading plans',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
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
                icon: const Icon(Icons.add_rounded),
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: plan.progress),
                  const SizedBox(height: 6),
                  Text(
                    'Page ${plan.currentPage} of ${plan.endPage} • ${plan.dailyPagesRequired(DateTime.now())} per day',
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _openPage(context, plan.currentPage),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Continue'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: plan.paused ? 'Resume plan' : 'Pause plan',
                        onPressed: () => context
                            .read<ReadingGoalsCubit>()
                            .setPlanPaused(plan.id, !plan.paused),
                        icon: Icon(
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
                        icon: const Icon(Icons.delete_outline_rounded),
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
    final title = TextEditingController(text: 'My reading plan');
    final start = TextEditingController(text: '1');
    final end = TextEditingController(text: '604');
    final days = TextEditingController(text: '30');
    final result =
        await showDialog<({String title, int start, int end, int days})>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Custom reading plan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: start,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Start page'),
                ),
                TextField(
                  controller: end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'End page'),
                ),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Days'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop((
                  title: title.text,
                  start: int.tryParse(start.text) ?? 1,
                  end: int.tryParse(end.text) ?? 604,
                  days: int.tryParse(days.text) ?? 30,
                )),
                child: const Text('Create'),
              ),
            ],
          ),
        );
    title.dispose();
    start.dispose();
    end.dispose();
    days.dispose();
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
  final controller = TextEditingController(text: '30');
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Complete in days'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((int.tryParse(controller.text) ?? 30).clamp(1, 3650)),
          child: const Text('Start'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

String _metricLabel(ReadingGoalMetric metric) {
  return switch (metric) {
    ReadingGoalMetric.pages => 'pages',
    ReadingGoalMetric.verses => 'verses',
    ReadingGoalMetric.minutes => 'minutes',
  };
}
