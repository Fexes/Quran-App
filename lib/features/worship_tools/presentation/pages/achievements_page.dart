import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../hifz/domain/entities/hifz_models.dart';
import '../../../hifz/domain/repositories/hifz_repository.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../prayer_tracking/domain/entities/prayer_tracking_models.dart';
import '../../../prayer_tracking/domain/repositories/prayer_tracking_repository.dart';
import '../../../quran/domain/entities/quran_bookmark.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../reading_goals/domain/entities/reading_progress.dart';
import '../../../reading_goals/domain/repositories/reading_progress_repository.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late final LibraryUserDataStore _userData;
  late Future<_AchievementStats> _future;

  @override
  void initState() {
    super.initState();
    _userData = getIt<LibraryUserDataStore>();
    _future = _load();
  }

  Future<_AchievementStats> _load() async {
    final values = await Future.wait<Object>([
      getIt<HifzRepository>().dashboard(),
      getIt<ReadingProgressRepository>().dashboard(),
      getIt<PrayerTrackingRepository>().dashboard(DateTime.now()),
      getIt<QuranRepository>().getBookmarks(),
    ]);
    final hifz = values[0] as HifzDashboard;
    final reading = values[1] as ReadingDashboard;
    final prayer = values[2] as PrayerTrackingDashboard;
    final bookmarks = values[3] as List<QuranBookmark>;
    final namesLearned = [
      for (var index = 1; index <= 99; index++)
        if (_userData.isBookmarked('divine-name:$index')) index,
    ].length;
    return _AchievementStats(
      memorized: hifz.masteredCount,
      surahsStarted: hifz.cards.values
          .map((item) => item.surahNumber)
          .where((item) => item > 0)
          .toSet()
          .length,
      prayerStreak: prayer.prayerStreak,
      bestStreak: reading.bestStreak,
      namesLearned: namesLearned,
      savedVerses: bookmarks.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).achievementsTitle),
      ),
      body: FutureBuilder<_AchievementStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final stats = snapshot.data;
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = [for (final badge in _badges) badge.evaluate(stats)];
          final unlocked = progress.where((item) => item.unlocked).length;
          final enabled = _userData.achievementsEnabled;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              PremiumSurface(
                padding: const EdgeInsets.all(18),
                prominent: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      enabled
                          ? '$unlocked of ${_badges.length} unlocked'
                          : 'Achievements are disabled',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      enabled
                          ? 'Derived only from progress already stored on this device.'
                          : 'Your underlying reading and worship data remains unchanged.',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable private achievements'),
                      subtitle: const Text(
                        'No leaderboard, account, or sharing',
                      ),
                      value: enabled,
                      onChanged: (value) async {
                        await _userData.setAchievementsEnabled(value);
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (enabled)
                for (final item in progress)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumSurface(
                      padding: const EdgeInsets.all(14),
                      prominent: item.unlocked,
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              item.badge.glyph,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.badge.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(item.badge.description),
                                const SizedBox(height: 7),
                                LinearProgressIndicator(
                                  value: item.progress,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.value} of ${item.badge.target}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            item.unlocked
                                ? Icons.check_circle_rounded
                                : Icons.lock_outline_rounded,
                            color: item.unlocked
                                ? Theme.of(context).colorScheme.primary
                                : QuranTheme.subText(context, 0.38),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              Text(
                'Achievements never penalize exempt prayer dates and have no '
                'competitive scoring. Disable them at any time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.62),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _AchievementMetric {
  memorized,
  surahsStarted,
  prayerStreak,
  bestStreak,
  namesLearned,
  savedVerses,
}

class _AchievementStats {
  const _AchievementStats({
    required this.memorized,
    required this.surahsStarted,
    required this.prayerStreak,
    required this.bestStreak,
    required this.namesLearned,
    required this.savedVerses,
  });

  final int memorized;
  final int surahsStarted;
  final int prayerStreak;
  final int bestStreak;
  final int namesLearned;
  final int savedVerses;

  int value(_AchievementMetric metric) {
    return switch (metric) {
      _AchievementMetric.memorized => memorized,
      _AchievementMetric.surahsStarted => surahsStarted,
      _AchievementMetric.prayerStreak => prayerStreak,
      _AchievementMetric.bestStreak => bestStreak,
      _AchievementMetric.namesLearned => namesLearned,
      _AchievementMetric.savedVerses => savedVerses,
    };
  }
}

class _Badge {
  const _Badge({
    required this.glyph,
    required this.name,
    required this.description,
    required this.metric,
    required this.target,
  });

  final String glyph;
  final String name;
  final String description;
  final _AchievementMetric metric;
  final int target;

  _BadgeProgress evaluate(_AchievementStats stats) {
    final current = stats.value(metric).clamp(0, 1000000);
    return _BadgeProgress(
      badge: this,
      value: current,
      unlocked: current >= target,
      progress: (current / target).clamp(0.0, 1.0).toDouble(),
    );
  }
}

class _BadgeProgress {
  const _BadgeProgress({
    required this.badge,
    required this.value,
    required this.unlocked,
    required this.progress,
  });

  final _Badge badge;
  final int value;
  final bool unlocked;
  final double progress;
}

const _badges = [
  _Badge(
    glyph: '✦',
    name: 'First ayah',
    description: 'Master your first Hifz ayah',
    metric: _AchievementMetric.memorized,
    target: 1,
  ),
  _Badge(
    glyph: '📖',
    name: 'Ten mastered',
    description: 'Master 10 Hifz ayahs',
    metric: _AchievementMetric.memorized,
    target: 10,
  ),
  _Badge(
    glyph: '📚',
    name: 'Fifty mastered',
    description: 'Master 50 Hifz ayahs',
    metric: _AchievementMetric.memorized,
    target: 50,
  ),
  _Badge(
    glyph: '📗',
    name: 'Surah starter',
    description: 'Begin memorizing a Surah',
    metric: _AchievementMetric.surahsStarted,
    target: 1,
  ),
  _Badge(
    glyph: '📕',
    name: 'Five Surahs',
    description: 'Begin memorizing five Surahs',
    metric: _AchievementMetric.surahsStarted,
    target: 5,
  ),
  _Badge(
    glyph: '🔥',
    name: '7-day reading streak',
    description: 'Keep your reading journey for 7 days',
    metric: _AchievementMetric.bestStreak,
    target: 7,
  ),
  _Badge(
    glyph: '🌙',
    name: '30-day reading streak',
    description: 'Keep your reading journey for 30 days',
    metric: _AchievementMetric.bestStreak,
    target: 30,
  ),
  _Badge(
    glyph: '🕌',
    name: 'Steadfast',
    description: 'Record a 7-day complete prayer streak',
    metric: _AchievementMetric.prayerStreak,
    target: 7,
  ),
  _Badge(
    glyph: '✨',
    name: 'Ten Names',
    description: 'Learn 10 of the 99 Names',
    metric: _AchievementMetric.namesLearned,
    target: 10,
  ),
  _Badge(
    glyph: '🌟',
    name: 'All 99 Names',
    description: 'Learn all 99 Names',
    metric: _AchievementMetric.namesLearned,
    target: 99,
  ),
  _Badge(
    glyph: '🔖',
    name: 'Collector',
    description: 'Save 5 ayahs',
    metric: _AchievementMetric.savedVerses,
    target: 5,
  ),
  _Badge(
    glyph: '🗂️',
    name: 'Curator',
    description: 'Save 25 ayahs',
    metric: _AchievementMetric.savedVerses,
    target: 25,
  ),
];
