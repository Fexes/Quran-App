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
import '../../domain/entities/hifz_models.dart';
import '../../domain/repositories/hifz_repository.dart';
import '../cubit/hifz_dashboard_cubit.dart';
import '../cubit/hifz_dashboard_state.dart';

class HifzDashboardPage extends StatelessWidget {
  const HifzDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HifzDashboardCubit(
        repository: getIt<HifzRepository>(),
        quranRepository: getIt<QuranRepository>(),
      )..load(),
      child: const _HifzDashboardView(),
    );
  }
}

class _HifzDashboardView extends StatelessWidget {
  const _HifzDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).hifzDashboardTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCollection(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Collection'),
      ),
      body: BlocBuilder<HifzDashboardCubit, HifzDashboardState>(
        builder: (context, state) {
          final dashboard = state.dashboard;
          if (dashboard == null &&
              state.status == HifzDashboardStatus.loading) {
            return const AppLoadingView(label: 'Loading Hifz review');
          }
          if (dashboard == null) {
            return AppErrorView(
              title: 'Hifz unavailable',
              message: state.errorMessage ?? 'Could not load Hifz data.',
              onRetry: context.read<HifzDashboardCubit>().load,
            );
          }
          return RefreshIndicator(
            onRefresh: context.read<HifzDashboardCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _HifzSummary(dashboard: dashboard),
                const SizedBox(height: 14),
                if (dashboard.weakSurahs.isNotEmpty)
                  _WeakSurahsCard(weakSurahs: dashboard.weakSurahs),
                if (dashboard.weakSurahs.isNotEmpty) const SizedBox(height: 14),
                if (dashboard.collections.isEmpty)
                  PremiumSurface(
                    padding: const EdgeInsets.all(18),
                    child: const Text(
                      'Create a Surah or ayah-range collection to begin memorization and scheduled review.',
                    ),
                  ),
                for (final collection in dashboard.collections) ...[
                  _CollectionCard(collection: collection, dashboard: dashboard),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createCollection(BuildContext context) async {
    final title = TextEditingController(text: 'My Hifz');
    final surah = TextEditingController(text: '1');
    final start = TextEditingController(text: '1');
    final end = TextEditingController(text: '7');
    final result =
        await showDialog<({String title, int surah, int start, int end})>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('New Hifz collection'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: surah,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Surah number',
                    ),
                  ),
                  TextField(
                    controller: start,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Start ayah'),
                  ),
                  TextField(
                    controller: end,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'End ayah'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop((
                  title: title.text,
                  surah: (int.tryParse(surah.text) ?? 1).clamp(1, 114),
                  start: (int.tryParse(start.text) ?? 1).clamp(1, 286),
                  end: (int.tryParse(end.text) ?? 1).clamp(1, 286),
                )),
                child: const Text('Create'),
              ),
            ],
          ),
        );
    title.dispose();
    surah.dispose();
    start.dispose();
    end.dispose();
    if (result != null && context.mounted) {
      await context.read<HifzDashboardCubit>().createCollection(
        title: result.title,
        surahNumber: result.surah,
        startAyah: result.start,
        endAyah: result.end < result.start ? result.start : result.end,
      );
    }
  }
}

class _HifzSummary extends StatelessWidget {
  const _HifzSummary({required this.dashboard});

  final HifzDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      prominent: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            Icons.psychology_alt_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dashboard.dueCards.length} due now',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${dashboard.masteredCount} mastered • ${dashboard.cards.length} total verses',
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

class _WeakSurahsCard extends StatelessWidget {
  const _WeakSurahsCard({required this.weakSurahs});

  final List<HifzWeakSurah> weakSurahs;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weak Surahs',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in weakSurahs)
                Chip(
                  label: Text(
                    'Surah ${item.surahNumber} • ${item.lapses} retries',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.dashboard});

  final HifzCollection collection;
  final HifzDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final dueCount = collection.verseKeys
        .where((key) => dashboard.cards[key]?.isDue(DateTime.now()) == true)
        .length;
    return PremiumSurface(
      onTap: dueCount == 0
          ? null
          : () => context.push(AppRoutes.hifzReviewPath(collection.id)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.collections_bookmark_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${collection.verseKeys.length} verses • $dueCount due',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.68),
                  ),
                ),
              ],
            ),
          ),
          if (dueCount > 0) const Icon(Icons.chevron_right_rounded),
          IconButton(
            tooltip: 'Delete collection',
            onPressed: () => context
                .read<HifzDashboardCubit>()
                .deleteCollection(collection.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
