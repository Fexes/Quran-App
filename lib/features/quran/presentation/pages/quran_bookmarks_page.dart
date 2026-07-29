import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import '../bloc/quran_bookmarks_cubit.dart';
import '../bloc/quran_bookmarks_state.dart';
import '../widgets/quran_translation_text.dart';

class QuranBookmarksPage extends StatelessWidget {
  const QuranBookmarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranBookmarksCubit(
        repository: getIt<QuranRepository>(),
        translationRepository: getIt<QuranTranslationRepository>(),
      )..load(),
      child: const _QuranBookmarksView(),
    );
  }
}

class _QuranBookmarksView extends StatelessWidget {
  const _QuranBookmarksView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<QuranBookmarksCubit>().load(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<QuranBookmarksCubit, QuranBookmarksState>(
          builder: (context, state) {
            return switch (state.status) {
              QuranBookmarksStatus.initial || QuranBookmarksStatus.loading =>
                const AppLoadingView(label: 'Loading bookmarks'),
              QuranBookmarksStatus.failure => AppErrorView(
                title: 'Bookmarks could not be loaded',
                message: state.errorMessage ?? 'Please try again.',
                onRetry: () => context.read<QuranBookmarksCubit>().load(),
              ),
              QuranBookmarksStatus.success => Column(
                children: [
                  _CollectionBar(state: state),
                  Expanded(
                    child: state.bookmarks.isEmpty
                        ? const _BookmarksEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                            itemCount: state.bookmarks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _BookmarkListTile(
                                bookmark: state.bookmarks[index],
                                collections: state.collections,
                              );
                            },
                          ),
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

class _CollectionBar extends StatelessWidget {
  const _CollectionBar({required this.state});

  final QuranBookmarksState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.selectedCollectionId == null,
            onSelected: (_) =>
                context.read<QuranBookmarksCubit>().selectCollection(null),
          ),
          const SizedBox(width: 8),
          for (final collection in state.collections) ...[
            InputChip(
              label: Text(collection.name),
              selected: state.selectedCollectionId == collection.id,
              onPressed: () => context
                  .read<QuranBookmarksCubit>()
                  .selectCollection(collection.id),
              onDeleted: collection.id == 'default'
                  ? null
                  : () => context.read<QuranBookmarksCubit>().deleteCollection(
                      collection.id,
                    ),
            ),
            const SizedBox(width: 8),
          ],
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
            onPressed: () => _newCollection(context),
          ),
        ],
      ),
    );
  }

  Future<void> _newCollection(BuildContext context) async {
    final controller = TextEditingController();
    final description = TextEditingController();
    var colorValue = 0xFF2E7D5B;
    var iconCodePoint = Icons.bookmark_rounded.codePoint;
    final result =
        await showDialog<
          ({String name, String description, int colorValue, int iconCodePoint})
        >(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('New bookmark collection'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final value in const [
                          0xFF2E7D5B,
                          0xFF1565C0,
                          0xFF6A1B9A,
                          0xFFEF6C00,
                        ])
                          ChoiceChip(
                            label: CircleAvatar(
                              radius: 9,
                              backgroundColor: Color(value),
                            ),
                            selected: colorValue == value,
                            onSelected: (_) =>
                                setDialogState(() => colorValue = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: Icons.bookmark_rounded.codePoint,
                          icon: const Icon(Icons.bookmark_rounded),
                        ),
                        ButtonSegment(
                          value: Icons.favorite_rounded.codePoint,
                          icon: const Icon(Icons.favorite_rounded),
                        ),
                        ButtonSegment(
                          value: Icons.school_rounded.codePoint,
                          icon: const Icon(Icons.school_rounded),
                        ),
                      ],
                      selected: {iconCodePoint},
                      onSelectionChanged: (values) =>
                          setDialogState(() => iconCodePoint = values.first),
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
                    name: controller.text.trim(),
                    description: description.text.trim(),
                    colorValue: colorValue,
                    iconCodePoint: iconCodePoint,
                  )),
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
    controller.dispose();
    description.dispose();
    if (result != null && result.name.isNotEmpty && context.mounted) {
      await context.read<QuranBookmarksCubit>().createCollection(
        result.name,
        description: result.description,
        colorValue: result.colorValue,
        iconCodePoint: result.iconCodePoint,
      );
    }
  }
}

class _BookmarksEmptyState extends StatelessWidget {
  const _BookmarksEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No bookmarks yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark ayahs while reading and they will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkListTile extends StatelessWidget {
  const _BookmarkListTile({required this.bookmark, required this.collections});

  final QuranBookmarkSummary bookmark;
  final List<QuranBookmarkCollection> collections;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      onTap: () => context.push(
        AppRoutes.quranReaderPath(
          bookmark.surah.number,
          ayahNumber: bookmark.ayah.number,
        ),
      ),
      padding: const EdgeInsets.all(16),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: QuranTheme.softFill(context, primary),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bookmark_rounded, color: primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.surah.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ayah ${bookmark.ayah.number}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: QuranTheme.subText(context, 0.64),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Move bookmark',
                onSelected: (collectionId) => context
                    .read<QuranBookmarksCubit>()
                    .moveBookmark(bookmark.ayah.verseKey, collectionId),
                itemBuilder: (context) => [
                  for (final collection in collections)
                    PopupMenuItem(
                      value: collection.id,
                      child: Row(
                        children: [
                          if (bookmark.collectionId == collection.id)
                            const Icon(Icons.check_rounded, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(collection.name),
                        ],
                      ),
                    ),
                ],
                icon: const Icon(Icons.folder_open_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bookmark.ayah.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.65,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          QuranTranslationText(
            text: bookmark.translation,
            resource: bookmark.translationResource,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.70),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
