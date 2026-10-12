import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../quran/presentation/widgets/quran_translation_text.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../azkar/domain/entities/azkar_category.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../azkar/presentation/bloc/azkar_library_cubit.dart';
import '../../../azkar/presentation/bloc/azkar_library_state.dart';
import '../../../hadith/domain/entities/hadith_book.dart';
import '../../../hadith/domain/entities/hadith_item.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../hadith/presentation/bloc/hadith_library_cubit.dart';
import '../../../hadith/presentation/bloc/hadith_library_state.dart';
import '../../../hadith/presentation/widgets/hadith_translation_sheet.dart';

enum _LibrarySection { hadith, azkar, tools }

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HadithLibraryCubit(repository: getIt<HadithRepository>())..load(),
        ),
        BlocProvider(
          create: (_) =>
              AzkarLibraryCubit(repository: getIt<AzkarRepository>())..load(),
        ),
      ],
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> {
  _LibrarySection _section = _LibrarySection.hadith;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _LibrarySection.values.length,
      child: AdaptiveInsetArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: ShellScreenHeader(
                icon: Icons.local_library_rounded,
                title: 'Library',
                subtitle: _section == _LibrarySection.tools
                    ? 'Private worship tools and learning utilities.'
                    : 'Hadith collections and daily remembrance.',
                actions: [
                  if (_section == _LibrarySection.hadith)
                    ShellHeaderAction(
                      icon: Icons.translate_rounded,
                      tooltip: 'Hadith translations',
                      onTap: () => _showHadithTranslations(context),
                    ),
                  if (_section != _LibrarySection.tools)
                    ShellHeaderAction(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh library',
                      onTap: () {
                        if (_section == _LibrarySection.hadith) {
                          context.read<HadithLibraryCubit>().load();
                        } else {
                          context.read<AzkarLibraryCubit>().load();
                        }
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  QuranFloatingAudioPlayer.scrollInset(context),
                ),
                children: [
                  TabBar(
                    labelColor: QuranTheme.text(context),
                    unselectedLabelColor: QuranTheme.subText(context),
                    indicatorColor: QuranTheme.text(context),
                    tabs: const [
                      Tab(text: 'Hadith'),
                      Tab(text: 'Azkar'),
                      Tab(text: 'Tools'),
                    ],
                    onTap: (index) {
                      setState(() => _section = _LibrarySection.values[index]);
                    },
                  ),
                  const SizedBox(height: 16),
                  switch (_section) {
                    _LibrarySection.hadith => const _HadithSection(),
                    _LibrarySection.azkar => const _AzkarSection(),
                    _LibrarySection.tools => const _WorshipToolsSection(),
                  },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHadithTranslations(BuildContext context) {
    showHadithTranslationSheet(
      context,
      onHadeethEncTap: () => _showHadeethEncDownloads(context),
    );
  }

  void _showHadeethEncDownloads(BuildContext context) {
    final cubit = context.read<HadithLibraryCubit>()..loadHadeethEncLanguages();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _HadeethEncDownloadSheet(),
      ),
    );
  }
}

class _HadithSection extends StatefulWidget {
  const _HadithSection();

  @override
  State<_HadithSection> createState() => _HadithSectionState();
}

class _HadithSectionState extends State<_HadithSection> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<HadithLibraryCubit>().search(value);
      }
    });
    setState(() {});
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    context.read<HadithLibraryCubit>().load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HadithLibraryCubit, HadithLibraryState>(
      listener: (context, state) {
        if (state.query.isEmpty && _searchController.text.isNotEmpty) {
          _searchController.clear();
          setState(() {});
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                context.read<HadithLibraryCubit>().search(value);
              },
              decoration: InputDecoration(
                hintText: 'Search all hadith',
                prefixIcon: const AppIcon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const AppIcon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            switch (state.status) {
              HadithLibraryStatus.initial ||
              HadithLibraryStatus.loading => AppLoadingView(
                label: state.query.isEmpty
                    ? 'Loading hadith'
                    : 'Searching hadith',
              ),
              HadithLibraryStatus.failure => AppErrorView(
                title: 'Hadith could not be loaded',
                message: state.errorMessage ?? 'Please try again.',
                onRetry: state.query.isEmpty
                    ? context.read<HadithLibraryCubit>().load
                    : () => context.read<HadithLibraryCubit>().search(
                        state.query,
                      ),
              ),
              HadithLibraryStatus.empty => _EmptyState(
                icon: Icons.search_off_rounded,
                message: state.query.isEmpty
                    ? 'No hadith collections found.'
                    : 'No hadith found for “${state.query}”.',
                onRefresh: _clearSearch,
              ),
              HadithLibraryStatus.success => _HadithContent(state: state),
            },
          ],
        );
      },
    );
  }
}

class _HadithContent extends StatelessWidget {
  const _HadithContent({required this.state});

  final HadithLibraryState state;

  @override
  Widget build(BuildContext context) {
    if (state.query.isEmpty && state.selectedBookId == null) {
      return Column(
        children: [
          for (final book in state.books)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HadithBookCard(
                book: book,
                onTap: () => context.push(AppRoutes.hadithBookPath(book.id)),
              ),
            ),
        ],
      );
    }

    if (state.query.isNotEmpty && state.selectedBookId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${state.hadiths.length} result${state.hadiths.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QuranTheme.subText(context, 0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          for (final hadith in state.hadiths)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HadithCard(
                hadith: hadith,
                onTap: () => context.push(
                  AppRoutes.hadithBookPath(
                    hadith.bookId,
                    hadithNumber: hadith.hadithNumber,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _HadeethEncDownloadSheet extends StatelessWidget {
  const _HadeethEncDownloadSheet();

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'HadeethEnc downloads',
      scrollableChild: true,
      child: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
        builder: (context, state) {
          final cubit = context.read<HadithLibraryCubit>();
          if (state.hadeethEncLanguages.isEmpty) {
            return ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                if (state.hadeethEncLoading)
                  const AppLoadingView(label: 'Loading languages')
                else if (state.hadeethEncErrorMessage != null)
                  AppErrorView(
                    title: 'Translations could not be loaded',
                    message: state.hadeethEncErrorMessage!,
                    onRetry: cubit.loadHadeethEncLanguages,
                  )
                else
                  _EmptyState(
                    icon: Icons.translate_rounded,
                    message: 'No translation languages found.',
                    onRefresh: cubit.loadHadeethEncLanguages,
                  ),
              ],
            );
          }

          final selectedCode =
              state.selectedHadeethEncLanguageCode ??
              state.hadeethEncLanguages.first.code;
          final selectedLanguage = state.hadeethEncLanguages.firstWhere(
            (language) => language.code == selectedCode,
            orElse: () => state.hadeethEncLanguages.first,
          );
          final progress = state.hadeethEncDownloadProgress;

          return ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              Text(
                'A separate selection of translated hadiths, not full book translations.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.72),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedLanguage.code,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  prefixIcon: AppIcon(Icons.language_rounded),
                ),
                items: [
                  for (final language in state.hadeethEncLanguages)
                    DropdownMenuItem(
                      value: language.code,
                      child: Text('${language.nativeName} (${language.code})'),
                    ),
                ],
                onChanged: state.hadeethEncLoading
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        cubit.selectHadeethEncLanguage(value);
                      },
              ),
              const SizedBox(height: 14),
              if (state.hadeethEncLoading) ...[
                LinearProgressIndicator(value: progress?.percent),
                const SizedBox(height: 8),
                Text(
                  progress == null || progress.totalItems == 0
                      ? 'Downloading ${selectedLanguage.nativeName} hadith...'
                      : 'Downloaded ${progress.completedItems} of ${progress.totalItems}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context, 0.72),
                  ),
                ),
              ] else if (!state.selectedHadeethEncLanguageDownloaded) ...[
                FilledButton.icon(
                  onPressed: () async {
                    await cubit.downloadSelectedHadeethEncLanguage();
                    if (context.mounted &&
                        ModalRoute.of(context)?.isCurrent == true &&
                        cubit.state.selectedHadeethEncLanguageDownloaded) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const AppIcon(Icons.download_rounded),
                  label: Text('Download ${selectedLanguage.nativeName} hadith'),
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.check_circle_outline_rounded),
                  title: Text('${selectedLanguage.nativeName} downloaded'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
              if (state.hadeethEncErrorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.hadeethEncErrorMessage!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AzkarSection extends StatelessWidget {
  const _AzkarSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AzkarLibraryCubit, AzkarLibraryState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (state.status) {
              AzkarLibraryStatus.initial || AzkarLibraryStatus.loading =>
                const AppLoadingView(label: 'Loading azkar'),
              AzkarLibraryStatus.failure => AppErrorView(
                title: 'Azkar could not be loaded',
                message: state.errorMessage ?? 'Please try again.',
                onRetry: context.read<AzkarLibraryCubit>().load,
              ),
              AzkarLibraryStatus.empty => _EmptyState(
                icon: Icons.favorite_border_rounded,
                message: 'No azkar found.',
                onRefresh: context.read<AzkarLibraryCubit>().load,
              ),
              AzkarLibraryStatus.success => _AzkarContent(state: state),
            },
          ],
        );
      },
    );
  }
}

class _AzkarContent extends StatelessWidget {
  const _AzkarContent({required this.state});

  final AzkarLibraryState state;

  @override
  Widget build(BuildContext context) {
    if (state.query.isEmpty && state.selectedCategoryId == null) {
      return Column(
        children: [
          for (final category in state.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AzkarCategoryCard(
                category: category,
                onTap: () =>
                    context.push(AppRoutes.azkarCategoryPath(category.id)),
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _HadithBookCard extends StatelessWidget {
  const _HadithBookCard({required this.book, required this.onTap});

  final HadithBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      leading: SizedBox.square(
        dimension: 36,
        child: Center(
          child: Text(
            book.sortOrder.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
        ),
      ),
      title: Text(book.englishName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(book.arabicName, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          Text(
            '${book.hadithCount} hadiths · ${book.chapterCount} chapters',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _AzkarCategoryCard extends StatelessWidget {
  const _AzkarCategoryCard({required this.category, required this.onTap});

  final AzkarCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: AppIcon(_azkarIcon(category.iconKey)),
      title: Text(category.englishName),
      subtitle: Text(category.arabicName, textDirection: TextDirection.rtl),
      trailing: Text(
        '${category.itemCount}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: onTap,
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith, required this.onTap});

  final HadithItem hadith;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hadith.reference,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppIcon(
                Icons.chevron_right_rounded,
                color: QuranTheme.subText(context, 0.6),
                size: 20,
              ),
            ],
          ),
          if (hadith.arabic.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hadith.arabic,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                height: 1.7,
                color: QuranTheme.quranTextNormal(context),
              ),
            ),
          ],
          if (hadith.translation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            QuranTranslationText(
              text: hadith.translation,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.82),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _azkarIcon(String key) {
  return switch (key) {
    'sunny' => Icons.wb_sunny_rounded,
    'home' => Icons.home_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'travel' => Icons.flight_takeoff_rounded,
    'prayer' => Icons.mosque_rounded,
    'tasbieh' => Icons.radio_button_checked_rounded,
    'kaaba' => Icons.location_city_rounded,
    'nature' => Icons.park_rounded,
    'health' => Icons.health_and_safety_rounded,
    _ => Icons.favorite_rounded,
  };
}

class _WorshipToolsSection extends StatelessWidget {
  const _WorshipToolsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tools = [
      (
        l10n.duasTitle,
        'Sourced supplications, search & favorites',
        Icons.volunteer_activism_outlined,
        AppRoutes.duas,
      ),
      (
        l10n.divineNamesTitle,
        'Arabic, meanings & learned progress',
        Icons.auto_awesome_outlined,
        AppRoutes.divineNames,
      ),
      (
        l10n.zakatTitle,
        'Offline assumptions-first estimate',
        Icons.calculate_outlined,
        AppRoutes.zakat,
      ),
      (
        l10n.ramadanTitle,
        'Suhoor, Iftar, fasting & Quran goal',
        Icons.nightlight_outlined,
        AppRoutes.ramadan,
      ),
      (
        l10n.achievementsTitle,
        'Optional private journey milestones',
        Icons.workspace_premium_outlined,
        AppRoutes.achievements,
      ),
      (
        l10n.mosquesTitle,
        'OpenStreetMap search & map handoff',
        Icons.location_on_outlined,
        AppRoutes.mosques,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.worshipToolsTitle),
        const SizedBox(height: 10),
        for (final tool in tools)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: AppIcon(
              tool.$3,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(tool.$1),
            subtitle: Text(tool.$2),
            trailing: const AppIcon(Icons.chevron_right_rounded),
            onTap: () => context.push(tool.$4),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIcon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const AppIcon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
