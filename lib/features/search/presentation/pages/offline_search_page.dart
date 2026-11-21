import '../../../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../hadith/domain/services/hadith_grading.dart';
import '../../../hadith/presentation/widgets/hadith_grading_panel.dart';
import '../../../quran/presentation/widgets/quran_translation_text.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../shell/presentation/bloc/shell_cubit.dart';
import '../../../shell/presentation/bloc/shell_state.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/repositories/offline_search_repository.dart';
import '../cubit/offline_search_cubit.dart';
import '../widgets/search_result_excerpt.dart';

part '../widgets/search_result_cards.dart';

class OfflineSearchPage extends StatelessWidget {
  const OfflineSearchPage({
    super.key,
    this.initialQuery,
    this.initialFilter = OfflineSearchFilter.all,
    this.repository,
  });

  final String? initialQuery;
  final OfflineSearchFilter initialFilter;
  final OfflineSearchRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = OfflineSearchCubit(
        repository: repository ?? getIt<OfflineSearchRepository>(),
        initialFilter: initialFilter,
      );
      final query = initialQuery?.trim();
      if (query != null && query.isNotEmpty) cubit.submit(query);
      return cubit;
    },
    child: _OfflineSearchView(initialQuery: initialQuery),
  );
}

class _OfflineSearchView extends StatefulWidget {
  const _OfflineSearchView({this.initialQuery});
  final String? initialQuery;

  @override
  State<_OfflineSearchView> createState() => _OfflineSearchViewState();
}

class _OfflineSearchViewState extends State<_OfflineSearchView>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  final _scrollController = ScrollController();
  OfflineSearchFilter? _resultFilter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<OfflineSearchCubit>().refreshSubmittedQuery();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit([String? suggestion]) {
    if (suggestion != null) {
      _controller.text = suggestion;
      _controller.selection = TextSelection.collapsed(
        offset: suggestion.length,
      );
    }
    FocusScope.of(context).unfocus();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    final cubit = context.read<OfflineSearchCubit>();
    final hasPreviousQuery = cubit.state.query.isNotEmpty;
    setState(() => _resultFilter = null);
    cubit.submit(
      _controller.text,
      filter: hasPreviousQuery ? OfflineSearchFilter.all : null,
    );
  }

  void _selectFilter(OfflineSearchFilter filter) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    final cubit = context.read<OfflineSearchCubit>();
    if (cubit.state.query.isEmpty) {
      cubit.selectFilter(filter);
      return;
    }
    setState(() => _resultFilter = filter);
    // A route or pre-query selection may have restricted retrieval itself.
    // All must escape that scope, while ordinary result facets stay local.
    if (filter == OfflineSearchFilter.all &&
        cubit.state.filter != OfflineSearchFilter.all) {
      cubit.selectFilter(OfflineSearchFilter.all);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: const Text('Search'),
      flexibleSpace: const HeaderPatternBackdrop(),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                Icons.offline_bolt_outlined,
                size: 16,
                color: QuranTheme.subText(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    body: BlocConsumer<OfflineSearchCubit, OfflineSearchState>(
      listener: (context, state) {
        final response = state.response;
        if ((state.status == OfflineSearchStatus.success ||
                state.status == OfflineSearchStatus.empty) &&
            response != null &&
            _resultFilter != null &&
            _resultFilter != OfflineSearchFilter.all &&
            (_resultCounts(response)[_resultFilter] ?? 0) == 0) {
          setState(() => _resultFilter = OfflineSearchFilter.all);
        }
      },
      builder: (context, state) {
        final response = state.response;
        final counts = response == null ? null : _resultCounts(response);
        final requestedFilter = _resultFilter ?? state.filter;
        final effectiveFilter =
            requestedFilter == OfflineSearchFilter.all ||
                (counts?[requestedFilter] ?? 0) > 0
            ? requestedFilter
            : OfflineSearchFilter.all;
        // Do not paint All as selected if tapping it still needs to expand
        // the retrieval scope beyond this response.
        final selectedResultFilter =
            effectiveFilter == OfflineSearchFilter.all &&
                state.filter != OfflineSearchFilter.all
            ? null
            : effectiveFilter;
        final visibleResponse = response == null
            ? null
            : _filterResponse(response, effectiveFilter);
        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: _SearchComposer(
                    controller: _controller,
                    loading: state.status == OfflineSearchStatus.loading,
                    onSubmit: _submit,
                    onClear: () {
                      _controller.clear();
                      setState(() => _resultFilter = null);
                      context.read<OfflineSearchCubit>().clear();
                    },
                  ),
                ),
                if (state.query.isEmpty)
                  _SearchFilters(
                    selected: state.filter,
                    onSelected: _selectFilter,
                  )
                else if (counts != null)
                  _SearchFilters(
                    selected: selectedResultFilter,
                    counts: counts,
                    onSelected: _selectFilter,
                  )
                else
                  SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(14) + 28,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          QuranFloatingAudioPlayer.scrollInset(context),
                        ),
                        sliver: SliverMainAxisGroup(
                          slivers: [
                            if (state.response?.warning
                                case final String warning)
                              SliverToBoxAdapter(
                                child: _SearchNotice(
                                  icon: Icons.info_outline_rounded,
                                  text: warning,
                                ),
                              ),
                            if (state.status == OfflineSearchStatus.success)
                              _SearchResults(
                                response: visibleResponse!,
                                query: state.query,
                              )
                            else
                              SliverToBoxAdapter(
                                child: switch (state.status) {
                                  OfflineSearchStatus.initial =>
                                    _SearchDiscovery(onSearch: _submit),
                                  OfflineSearchStatus.loading =>
                                    const _SearchingView(),
                                  OfflineSearchStatus.empty =>
                                    _SearchEmptyState(
                                      filtered:
                                          state.filter !=
                                          OfflineSearchFilter.all,
                                      onReset: () => _selectFilter(
                                        OfflineSearchFilter.all,
                                      ),
                                      onSearch: _submit,
                                    ),
                                  OfflineSearchStatus.failure => AppErrorView(
                                    title: 'Search could not finish',
                                    message:
                                        state.errorMessage ??
                                        'Please try again.',
                                    onRetry: _submit,
                                  ),
                                  OfflineSearchStatus.success =>
                                    const SizedBox.shrink(),
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuranAudioDock(bottomInset: 12),
            ),
          ],
        );
      },
    ),
  );
}

class _SearchComposer extends StatelessWidget {
  const _SearchComposer({
    required this.controller,
    required this.loading,
    required this.onSubmit,
    required this.onClear,
  });
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: const Key('offline-search-input'),
        controller: controller,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 1,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Search words or a reference…',
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 4, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: onClear,
                    icon: AppIcon(
                      Icons.close_rounded,
                      size: 18,
                      color: QuranTheme.subText(context),
                    ),
                  ),
                Tooltip(
                  message: 'Search',
                  excludeFromSemantics: true,
                  child: Semantics(
                    label: loading ? 'Searching' : 'Search',
                    child: FilledButton(
                      key: const Key('offline-search-submit'),
                      onPressed: value.text.trim().isEmpty ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const AppIcon(Icons.search_rounded, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchFilters extends StatelessWidget {
  const _SearchFilters({
    required this.selected,
    required this.onSelected,
    this.counts,
  });
  final OfflineSearchFilter? selected;
  final ValueChanged<OfflineSearchFilter> onSelected;
  final Map<OfflineSearchFilter, int>? counts;

  @override
  Widget build(BuildContext context) {
    final filters = OfflineSearchFilter.values
        .where(
          (filter) =>
              counts == null ||
              filter == OfflineSearchFilter.all ||
              (counts![filter] ?? 0) > 0,
        )
        .toList();
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(14) + 28,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = selected == filter;
          return ChoiceChip(
            showCheckmark: false,
            avatar: AppIcon(
              _kindIcon(filter.name),
              size: 16,
              color: active
                  ? Theme.of(context).colorScheme.onPrimary
                  : QuranTheme.subText(context),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_filterLabel(filter)),
                if (counts != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.18)
                          : QuranTheme.softFill(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${counts![filter] ?? 0}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Theme.of(context).colorScheme.onPrimary
                            : QuranTheme.subText(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: active,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? Theme.of(context).colorScheme.onPrimary
                  : QuranTheme.text(context),
            ),
            side: BorderSide(
              color: active ? Colors.transparent : QuranTheme.outline(context),
            ),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

// Counts and filtering share one mapping, matching the search document codec.
OfflineSearchFilter _resultSource(OfflineSearchPassage passage) =>
    switch (passage.kind) {
      'quran' => OfflineSearchFilter.quran,
      'hadith' => OfflineSearchFilter.hadith,
      'azkar' => OfflineSearchFilter.azkar,
      'tafsir' => OfflineSearchFilter.tafsir,
      'notes' => OfflineSearchFilter.notes,
      'saved' => OfflineSearchFilter.saved,
      'timings' => OfflineSearchFilter.timings,
      _ => OfflineSearchFilter.tools,
    };

Map<OfflineSearchFilter, int> _resultCounts(OfflineSearchResponse response) {
  final counts = <OfflineSearchFilter, int>{
    OfflineSearchFilter.all: response.hits.length,
  };
  for (final hit in response.hits) {
    final source = _resultSource(hit.passage);
    counts.update(source, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

OfflineSearchResponse _filterResponse(
  OfflineSearchResponse response,
  OfflineSearchFilter filter,
) {
  if (filter == OfflineSearchFilter.all) return response;
  return OfflineSearchResponse(
    hits: response.hits
        .where((hit) => _resultSource(hit.passage) == filter)
        .toList(growable: false),
    timingsMs: response.timingsMs,
    semanticAvailable: response.semanticAvailable,
    warning: response.warning,
    pendingDocuments: response.pendingDocuments,
  );
}

class _SearchDiscovery extends StatelessWidget {
  const _SearchDiscovery({required this.onSearch});
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What would you like\nto explore?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Find Quran verses, Hadith, your notes and useful tools using words or a reference.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TRY A SEARCH',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: QuranTheme.subText(context),
            ),
          ),
          const SizedBox(height: 10),
          for (final example in const [
            (
              Icons.menu_book_rounded,
              'Patience',
              'Find matching Quran and Hadith',
            ),
            (
              Icons.auto_stories_rounded,
              'Quran 2:255',
              'Find a specific verse',
            ),
            (
              Icons.schedule_rounded,
              'Next prayer',
              'See your local prayer time',
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: PremiumSurface(
                padding: const EdgeInsets.all(14),
                onTap: () => onSearch(example.$2),
                child: Row(
                  children: [
                    AppIcon(
                      example.$1,
                      size: 21,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.$2,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            example.$3,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: QuranTheme.subText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(
                      Icons.north_west_rounded,
                      size: 17,
                      color: QuranTheme.subText(context),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'You can also enter a reference, such as Quran 2:255.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({
    required this.filtered,
    required this.onReset,
    required this.onSearch,
  });
  final bool filtered;
  final VoidCallback onReset;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
    child: Column(
      children: [
        AppIcon(
          Icons.search_off_rounded,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text('No results found', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          filtered
              ? 'Try all sources, or use a few words about the topic.'
              : 'Try a few words or a specific reference.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: QuranTheme.subText(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (filtered)
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Search all sources'),
          ),
        Wrap(
          spacing: 8,
          children: [
            for (final topic in ['Patience', 'Forgiveness', 'Quran 2:255'])
              ActionChip(label: Text(topic), onPressed: () => onSearch(topic)),
          ],
        ),
      ],
    ),
  );
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 16, color: QuranTheme.subText(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context),
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SearchingView extends StatelessWidget {
  const _SearchingView();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SearchNotice(
          icon: Icons.manage_search_rounded,
          text: 'Finding relevant passages and content…',
        ),
        for (var index = 0; index < 3; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final width in [0.35, 0.8, 1.0, 0.6])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FractionallySizedBox(
                        widthFactor: width,
                        child: Container(
                          height: 11,
                          decoration: BoxDecoration(
                            color: QuranTheme.softFill(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.response, required this.query});
  final OfflineSearchResponse response;
  final String query;

  @override
  Widget build(BuildContext context) {
    final groups = <List<OfflineSearchPassage>>[];
    for (final hit in response.hits) {
      final passage = hit.passage;
      if (_isPrayer(passage) &&
          groups.isNotEmpty &&
          _isPrayer(groups.last.first) &&
          groups.last.first.metadata['location'] ==
              passage.metadata['location'] &&
          groups.last.first.metadata['date'] == passage.metadata['date']) {
        groups.last.add(passage);
      } else {
        groups.add([passage]);
      }
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15, top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results for “$query”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _onlyLiveResults(response)
                      ? 'Live information'
                      : '${response.hits.length} ${response.hits.length == 1 ? 'result' : 'results'}, ranked by relevance',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemCount: groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = groups[index];
            final passage = group.first;
            return KeyedSubtree(
              key: ValueKey(passage.canonicalId),
              child: _isPrayer(passage)
                  ? _PrayerResultCard(passages: group)
                  : passage.canonicalId == 'live:calendar'
                  ? _CalendarResultCard(passage: passage)
                  : passage.kind == 'tools'
                  ? _ToolResultCard(passage: passage)
                  : passage.isUserContent && passage.arabic.isEmpty
                  ? _PersonalResultCard(passage: passage, query: query)
                  : _PassageTile(passage: passage, query: query),
            );
          },
        ),
      ],
    );
  }
}

bool _onlyLiveResults(OfflineSearchResponse? response) =>
    response != null &&
    response.hits.isNotEmpty &&
    response.hits.every((hit) => hit.passage.canonicalId.startsWith('live:'));

bool _isPrayer(OfflineSearchPassage passage) =>
    passage.canonicalId.startsWith('live:prayer:');

String _filterLabel(OfflineSearchFilter filter) => switch (filter) {
  OfflineSearchFilter.all => 'All',
  OfflineSearchFilter.quran => 'Quran',
  OfflineSearchFilter.hadith => 'Hadith',
  OfflineSearchFilter.azkar => 'Azkar',
  OfflineSearchFilter.tafsir => 'Tafsir',
  OfflineSearchFilter.notes => 'Notes',
  OfflineSearchFilter.saved => 'Saved',
  OfflineSearchFilter.tools => 'Tools',
  OfflineSearchFilter.timings => 'Timings',
};

String _kindLabel(String kind) => switch (kind) {
  'quran' => 'Quran',
  'surah' => 'Surah',
  'hadith' => 'Hadith',
  'azkar' => 'Azkar',
  'tafsir' => 'Tafsir',
  'notes' => 'Note',
  'saved' => 'Saved',
  'timings' => 'Prayer & calendar',
  'names' || 'divine_name' => 'Names of Allah',
  _ => 'In your app',
};

IconData _kindIcon(String kind) => switch (kind) {
  'all' => Icons.grid_view_rounded,
  'quran' || 'surah' => Icons.menu_book_rounded,
  'hadith' => Icons.auto_stories_rounded,
  'azkar' => Icons.favorite_outline_rounded,
  'tafsir' => Icons.library_books_rounded,
  'notes' => Icons.notes_rounded,
  'saved' => Icons.bookmark_border_rounded,
  'timings' => Icons.schedule_rounded,
  _ => Icons.apps_rounded,
};

String _languageLabel(String language) => switch (language) {
  'en' => 'English',
  'ur' => 'Urdu',
  'ar' => 'Arabic',
  'bn' => 'Bengali',
  'tr' => 'Turkish',
  'id' => 'Indonesian',
  'fr' => 'French',
  'de' => 'German',
  'es' => 'Spanish',
  'fa' => 'Persian',
  'ru' => 'Russian',
  _ => language.toUpperCase(),
};

String _translationLabel(
  List<OfflineSearchTranslation> translations,
  int index,
) {
  final translation = translations[index];
  final label = _languageLabel(translation.language);
  final hasOtherEdition =
      translations
          .where((item) => item.language == translation.language)
          .length >
      1;
  return hasOtherEdition && translation.source.isNotEmpty
      ? '$label · ${_sourceDisplayLabel(translation.source)}'
      : label;
}

String _sourceDisplayLabel(String source) {
  if (source == 'quran_with_tafsir_saheeh_international') {
    return 'Saheeh International';
  }
  if (!source.contains('_')) return source;
  return source
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) {
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

void _openPassage(BuildContext context, OfflineSearchPassage passage) {
  final route = Uri.tryParse(passage.route);
  if (route != null &&
      !route.hasScheme &&
      !route.hasAuthority &&
      route.path.startsWith('/')) {
    if (route.path == AppRoutes.shell) {
      final tab = route.queryParameters['tab'];
      for (final destination in ShellDestination.values) {
        if (destination.name == tab) {
          context.read<ShellCubit>().setDestination(destination);
          break;
        }
      }
      context.go(AppRoutes.shell);
    } else {
      context.push(route.toString());
    }
    return;
  }
  if (passage.kind == 'quran' && passage.surahNumber != null) {
    context.push(
      AppRoutes.quranReaderPath(
        passage.surahNumber!,
        ayahNumber: passage.ayahNumber,
      ),
    );
    return;
  }
  final parts = (passage.itemId ?? passage.canonicalId).split(':');
  if (parts.length >= 3 &&
      parts.first == 'hadith' &&
      parts[1] != 'hadeethenc') {
    context.push(AppRoutes.hadithBookPath(parts[1], hadithNumber: parts[2]));
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: _PassageTile(passage: passage, openSource: false),
      ),
    ),
  );
}
