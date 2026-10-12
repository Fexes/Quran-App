import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../domain/entities/home_tile.dart';
import 'home_tile_image.dart';

class HomeReadingGoalTile extends StatelessWidget {
  const HomeReadingGoalTile({
    super.key,
    required this.dashboard,
    required this.loading,
    required this.onTap,
    required this.onRetry,
  });

  final ReadingDashboard? dashboard;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = dashboard;
    final unit = switch (data?.goal.metric) {
      ReadingGoalMetric.pages => 'pages',
      ReadingGoalMetric.verses => 'verses',
      ReadingGoalMetric.minutes => 'minutes',
      null => '',
    };
    return PremiumSurface(
      borderColor: QuranTheme.outline(context).withValues(alpha: 0.75),
      borderWidth: 0.6,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HomeTileImage(
                tile: HomeTile.todayReadingGoal,
                width: 72,
                height: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          Icons.auto_stories_outlined,
                          size: 18,
                          strokeWidth: 1.1,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Today's reading goal",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (data != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${data.todayValue} of ${data.goal.dailyTarget} $unit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          if (data == null) ...[
            if (loading)
              const LinearProgressIndicator(minHeight: 4)
            else
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Reading progress unavailable'),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
          ] else ...[
            LinearProgressIndicator(
              value: data.goalProgress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
            ),
            const SizedBox(height: 10),
            Text(
              '${data.currentStreak} day streak',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
            if (data.khatma != null) ...[
              const SizedBox(height: 4),
              Text(
                'Khatma pace: ${data.khatma!.dailyPagesRequired(DateTime.now())} pages today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
