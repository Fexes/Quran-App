import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../domain/entities/quran_bookmark.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import '../bloc/quran_bookmarks_cubit.dart';
import '../bloc/quran_bookmarks_state.dart';
import '../widgets/quran_bookmark_collection_sheet.dart';
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

class _QuranBookmarksView extends StatefulWidget {
  const _QuranBookmarksView();

  @override
  State<_QuranBookmarksView> createState() => _QuranBookmarksViewState();
}

class _QuranBookmarksViewState extends State<_QuranBookmarksView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _message(String text) {
    final error = context.read<QuranBookmarksCubit>().state.errorMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? text)));
  }

  Future<void> _newCollection() async {
    final cubit = context.read<QuranBookmarksCubit>();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranBookmarkCollectionSheet(
        onCreate: (name, description, color, icon) => cubit.createCollection(
          name,
          description: description,
          colorValue: color,
          iconCodePoint: icon,
        ),
      ),
    );
    if (created == true && mounted) _message('Collection created');
  }

  Future<void> _deleteCollection(QuranBookmarkCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Delete collection?'),
        content: Text(
          'Ayahs in "${collection.name}" will stay bookmarked in Saved ayahs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete collection'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await context.read<QuranBookmarksCubit>().deleteCollection(
      collection.id,
    );
    if (saved && mounted) {
      _message('Collection deleted. Your ayahs are still saved.');
    }
  }

  Future<void> _moveBookmark(QuranBookmarkSummary bookmark) async {
    final cubit = context.read<QuranBookmarksCubit>();
    final collection = await showModalBottomSheet<QuranBookmarkCollection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheet(
        title: 'Move to collection',
        subtitle: '${bookmark.surah.englishName} ${bookmark.ayah.verseKey}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final collection in cubit.state.collections)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(
                  bookmarkCollectionIcon(collection.iconCodePoint),
                  color: bookmarkCollectionColor(context, collection.colorValue),
                ),
                title: Text(collection.name),
                selected: collection.id == bookmark.collectionId,
                trailing: collection.id == bookmark.collectionId
                    ? const AppIcon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, collection),
              ),
          ],
        ),
      ),
    );
    if (collection == null ||
        !mounted ||
        collection.id == bookmark.collectionId) {
      return;
    }
    final saved = await cubit.moveBookmark(
      bookmark.ayah.verseKey,
      collection.id,
    );
    if (saved && mounted) _message('Moved to ${collection.name}');
  }

  Future<void> _removeBookmark(QuranBookmarkSummary bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Remove bookmark?'),
        content: Text(
          '${bookmark.surah.englishName}, ayah ${bookmark.ayah.number} will be removed from your bookmarks. Your notes will not change.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await context.read<QuranBookmarksCubit>().removeBookmark(
      bookmark,
    );
    if (saved && mounted) _message('Bookmark removed');
  }

  Future<void> _openBookmark(QuranBookmarkSummary bookmark) async {
    await context.push(
      AppRoutes.quranReaderPath(
        bookmark.surah.number,
        ayahNumber: bookmark.ayah.number,
      ),
    );
    if (mounted) await context.read<QuranBookmarksCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<QuranBookmarksCubit>();
    return BlocConsumer<QuranBookmarksCubit, QuranBookmarksState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          previous.errorMessage != current.errorMessage,
      listener: (_, state) => _message(state.errorMessage!),
      builder: (context, state) {
        final visible = state.visibleBookmarks;
        final selected = state.collections
            .where((item) => item.id == state.selectedCollectionId)
            .firstOrNull;
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: const Text('Bookmarks'),
            flexibleSpace: const ArchitecturalBackdrop(),
            leading: IconButton(
              tooltip: 'Back',
              icon: const AppIcon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: 'New collection',
                icon: const AppIcon(Icons.create_new_folder_outlined),
                onPressed: state.isUpdating ? null : _newCollection,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: switch (state.status) {
              QuranBookmarksStatus.initial || QuranBookmarksStatus.loading =>
                const AppLoadingView(label: 'Loading bookmarks'),
              QuranBookmarksStatus.failure => AppErrorView(
                title: 'Bookmarks could not be loaded',
                message: state.errorMessage ?? 'Please try again.',
                onRetry: cubit.load,
              ),
              QuranBookmarksStatus.success => RefreshIndicator(
                onRefresh: cubit.load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 2,
                            child: state.isRefreshing || state.isUpdating
                                ? const LinearProgressIndicator(minHeight: 2)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your saved ayahs',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${state.bookmarks.length} saved ayahs  /  ${state.collections.length} collections',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: QuranTheme.subText(context, 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CollectionBar(
                            state: state,
                            onSelect: cubit.selectCollection,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: TextField(
                              controller: _search,
                              textInputAction: TextInputAction.search,
                              onChanged: cubit.search,
                              decoration: InputDecoration(
                                hintText: 'Search saved ayahs',
                                prefixIcon: const AppIcon(Icons.search_rounded),
                                suffixIcon: state.query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const AppIcon(
                                          Icons.close_rounded,
                                        ),
                                        onPressed: () {
                                          _search.clear();
                                          cubit.search('');
                                        },
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${selected?.name ?? 'All bookmarks'} (${visible.length})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<QuranBookmarkSort>(
                                  tooltip: 'Sort bookmarks',
                                  initialValue: state.sort,
                                  icon: const AppIcon(Icons.sort_rounded),
                                  onSelected: cubit.sortBy,
                                  itemBuilder: (_) => [
                                    for (final sort in QuranBookmarkSort.values)
                                      CheckedPopupMenuItem(
                                        value: sort,
                                        checked: state.sort == sort,
                                        child: Text(
                                          sort == QuranBookmarkSort.recent
                                              ? 'Recently saved'
                                              : 'Quran order',
                                        ),
                                      ),
                                  ],
                                ),
                                if (selected != null &&
                                    selected.id !=
                                        QuranBookmarkCollection.defaultId)
                                  PopupMenuButton<String>(
                                    tooltip: 'Collection actions',
                                    enabled: !state.isUpdating,
                                    icon: const AppIcon(
                                      Icons.more_horiz_rounded,
                                    ),
                                    onSelected: (_) =>
                                        _deleteCollection(selected),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete collection'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (selected != null &&
                              selected.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Text(
                                selected.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (visible.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                state.query.trim().isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 44,
                                color: QuranTheme.subText(context, 0.55),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.query.trim().isNotEmpty
                                    ? 'No matching ayahs'
                                    : selected == null
                                    ? 'No bookmarks yet'
                                    : 'No ayahs in this collection',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed:
                                    state.query.isNotEmpty || selected != null
                                    ? () {
                                        _search.clear();
                                        cubit.search('');
                                        cubit.selectCollection(null);
                                      }
                                    : () => context.push(
                                        AppRoutes.quranSearchPath(),
                                      ),
                                child: Text(
                                  state.query.isNotEmpty || selected != null
                                      ? 'Show all bookmarks'
                                      : 'Read Quran',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        sliver: SliverList.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bookmark = visible[index];
                            return _BookmarkCard(
                              key: ValueKey(bookmark.ayah.verseKey),
                              bookmark: bookmark,
                              collection: state.collections
                                  .where(
                                    (item) => item.id == bookmark.collectionId,
                                  )
                                  .firstOrNull,
                              onOpen: () => _openBookmark(bookmark),
                              onMove: state.isUpdating
                                  ? null
                                  : () => _moveBookmark(bookmark),
                              onRemove: state.isUpdating
                                  ? null
                                  : () => _removeBookmark(bookmark),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            },
          ),
        );
      },
    );
  }
}

class _CollectionBar extends StatelessWidget {
  const _CollectionBar({required this.state, required this.onSelect});
  final QuranBookmarksState state;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72 + MediaQuery.textScalerOf(context).scale(14) * 3,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.collections.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final collection = index == 0 ? null : state.collections[index - 1];
          final selected = state.selectedCollectionId == collection?.id;
          final color = collection == null
              ? Theme.of(context).colorScheme.primary
              : bookmarkCollectionColor(context, collection.colorValue);
          final count = collection == null
              ? state.bookmarks.length
              : state.bookmarks
                    .where((item) => item.collectionId == collection.id)
                    .length;
          return Semantics(
            selected: selected,
            button: true,
            onTap: () => onSelect(collection?.id),
            label: '${collection?.name ?? 'All bookmarks'}, $count ayahs',
            child: ExcludeSemantics(
              child: SizedBox(
                width: 150,
                child: Material(
                  color: Color.alphaBlend(
                    color.withValues(alpha: selected ? 0.12 : 0.04),
                    QuranTheme.surface(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: selected ? color : QuranTheme.outline(context),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelect(collection?.id),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppIcon(
                                collection == null
                                    ? Icons.collections_bookmark_outlined
                                    : bookmarkCollectionIcon(
                                        collection.iconCodePoint,
                                      ),
                                color: color,
                                size: 23,
                              ),
                              const Spacer(),
                              Text(
                                '$count',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                collection?.name ?? 'All bookmarks',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    super.key,
    required this.bookmark,
    required this.collection,
    required this.onOpen,
    required this.onMove,
    required this.onRemove,
  });
  final QuranBookmarkSummary bookmark;
  final QuranBookmarkCollection? collection;
  final VoidCallback onOpen;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = collection == null
        ? theme.colorScheme.primary
        : bookmarkCollectionColor(context, collection!.colorValue);
    return PremiumSurface(
      radius: 8,
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(Icons.bookmark_rounded, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.surah.englishName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Ayah ${bookmark.ayah.number} / ${bookmark.ayah.verseKey}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context, 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Bookmark actions',
                enabled: onRemove != null,
                icon: const AppIcon(Icons.more_horiz_rounded),
                onSelected: (action) =>
                    action == 'move' ? onMove?.call() : onRemove?.call(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'move',
                    child: Text('Move to collection'),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      'Remove bookmark',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bookmark.ayah.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              height: 1.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          QuranTranslationText(
            text: bookmark.translation,
            resource: bookmark.translationResource,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: QuranTheme.outline(context)),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    foregroundColor: QuranTheme.subText(context, 0.75),
                  ),
                  onPressed: onMove,
                  icon: AppIcon(
                    bookmarkCollectionIcon(collection?.iconCodePoint ?? 0),
                    size: 16,
                    color: accent,
                  ),
                  label: Text(
                    collection?.name ?? 'Saved ayahs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    'Read ${bookmark.surah.englishName}, ayah ${bookmark.ayah.number}',
                onPressed: onOpen,
                icon: const AppIcon(Icons.arrow_forward_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
