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
        flexibleSpace: const ArchitecturalBackdrop(),
        actions: [
          IconButton(
            tooltip: 'New collection',
            onPressed: () => _createCollection(context),
            icon: const AppIcon(Icons.add_rounded),
          ),
        ],
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _HifzSummary(dashboard: dashboard),
                const Divider(height: 32),
                if (dashboard.weakSurahs.isNotEmpty)
                  _WeakSurahsCard(weakSurahs: dashboard.weakSurahs),
                if (dashboard.weakSurahs.isNotEmpty) const SizedBox(height: 14),
                if (dashboard.collections.isEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AppIcon(Icons.collections_bookmark_outlined),
                    title: const Text('No collections yet'),
                    trailing: const AppIcon(Icons.add_rounded),
                    onTap: () => _createCollection(context),
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
    var title = 'My Hifz';
    var surah = '1';
    var start = '1';
    var end = '7';
    final result =
        await showModalBottomSheet<
          ({String title, int surah, int start, int end})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AppSheet(
            title: 'New Hifz collection',
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
                  initialValue: surah,
                  onChanged: (value) => surah = value,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Surah number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: start,
                  onChanged: (value) => start = value,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Start ayah'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: end,
                  onChanged: (value) => end = value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'End ayah'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    title: title,
                    surah: (int.tryParse(surah) ?? 1).clamp(1, 114),
                    start: (int.tryParse(start) ?? 1).clamp(1, 286),
                    end: (int.tryParse(end) ?? 1).clamp(1, 286),
                  )),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dashboard.dueCards.length} due now',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'For review',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
    return ListTile(
      onTap: dueCount == 0
          ? null
          : () => context.push(AppRoutes.hifzReviewPath(collection.id)),
      contentPadding: EdgeInsets.zero,
      leading: const AppIcon(Icons.collections_bookmark_outlined),
      title: Text(collection.title),
      subtitle: Text('${collection.verseKeys.length} verses • $dueCount due'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dueCount > 0) const AppIcon(Icons.chevron_right_rounded),
          IconButton(
            tooltip: 'Delete collection',
            onPressed: () => context
                .read<HifzDashboardCubit>()
                .deleteCollection(collection.id),
            icon: const AppIcon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
