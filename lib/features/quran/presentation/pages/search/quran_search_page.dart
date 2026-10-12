import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/injection.dart';
import '../../../../../app/router/app_routes.dart';
import '../../../../../core/theme/quran_theme.dart';
import '../../../../../core/widgets/app_error_view.dart';
import '../../../../../core/widgets/app_loading_view.dart';
import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/architectural_backdrop.dart';
import '../../../../../core/widgets/premium_surface.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../../search/domain/entities/deep_search_result.dart';
import '../../../../search/domain/repositories/deep_search_repository.dart';
import '../../bloc/search/quran_search_bloc.dart';
import '../../bloc/search/quran_search_event.dart';
import '../../bloc/search/quran_search_state.dart';
import '../../widgets/quran_translation_text.dart';

class QuranSearchPage extends StatelessWidget {
  const QuranSearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = QuranSearchBloc(repository: getIt<DeepSearchRepository>());
        final query = initialQuery?.trim();
        if (query != null && query.isNotEmpty) {
          bloc.add(QuranSearchSubmitted(query));
        }
        return bloc;
      },
      child: _QuranSearchView(initialQuery: initialQuery),
    );
  }
}

class _QuranSearchView extends StatefulWidget {
  const _QuranSearchView({this.initialQuery});

  final String? initialQuery;

  @override
  State<_QuranSearchView> createState() => _QuranSearchViewState();
}

class _QuranSearchViewState extends State<_QuranSearchView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<QuranSearchBloc>().add(const QuranSearchWarmUpRequested());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<QuranSearchBloc>().add(QuranSearchSubmitted(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quranSearchTitle),
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              QuranFloatingAudioPlayer.scrollInset(context),
            ),
            children: [
              TextField(
                controller: _controller,
                autofocus: _controller.text.trim().isEmpty,
                textInputAction: TextInputAction.search,
                onChanged: (value) => context.read<QuranSearchBloc>().add(
                  QuranSearchQueryChanged(value),
                ),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Search Quran, tafsir, notes, hadith, azkar',
                  prefixIcon: const AppIcon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: l10n.commonClear,
                    onPressed: () {
                      _controller.clear();
                      context.read<QuranSearchBloc>().add(
                        const QuranSearchCleared(),
                      );
                    },
                    icon: const AppIcon(Icons.close_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      QuranTheme.radiusControl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BlocBuilder<QuranSearchBloc, QuranSearchState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.sections.isNotEmpty) ...[
                        _CategoryFilters(state: state),
                        const SizedBox(height: 14),
                      ],
                      switch (state.status) {
                        QuranSearchStatus.initial => _SearchPrompt(
                          title: l10n.searchEverythingTitle,
                          subtitle: l10n.searchEverythingSubtitle,
                        ),
                        QuranSearchStatus.loading => AppLoadingView(
                          label: l10n.quranSearching,
                        ),
                        QuranSearchStatus.empty => _SearchPrompt(
                          title: l10n.quranNoSearchResultsTitle,
                          subtitle: l10n.quranNoSearchResultsSubtitle,
                        ),
                        QuranSearchStatus.failure => AppErrorView(
                          title: l10n.quranSearchFailedTitle,
                          message:
                              state.errorMessage ?? l10n.quranLoadFailedMessage,
                          onRetry: _submit,
                        ),
                        QuranSearchStatus.success => _SearchResults(
                          sections: state.visibleSections,
                          query: state.query,
                        ),
                      },
                    ],
                  );
                },
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
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.state});

  final QuranSearchState state;

  @override
  Widget build(BuildContext context) {
    final categories = state.categoryCounts.keys.toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in [null, ...categories])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(
                  category == null
                      ? 'All'
                      : '${_categoryLabel(category)} ${state.categoryCounts[category] ?? 0}',
                ),
                selected: state.selectedCategory == category,
                onSelected: (_) => context.read<QuranSearchBloc>().add(
                  QuranSearchCategorySelected(category),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          AppIcon(
            Icons.manage_search_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.sections, required this.query});

  final List<DeepSearchSection> sections;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const _SearchPrompt(
        title: 'No results in this category',
        subtitle: 'Choose All or try a different search term.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          _SectionHeader(section: section),
          const SizedBox(height: 8),
          for (final result in section.results)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SearchResultTile(result: result, query: query),
            ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final DeepSearchSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(
          _categoryIcon(section.category),
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _categoryLabel(section.category),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          section.totalCount.toString(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: QuranTheme.subText(context, 0.64),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.query});

  final DeepSearchResult result;
  final String query;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryIsArabic = _containsRtl(result.primaryText);
    return PremiumSurface(
      onTap: () => _openResult(context, result),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(_categoryIcon(result.category), color: primary, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result.matchedField,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: QuranTheme.subText(context, 0.64),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (result.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              result.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: QuranTheme.subText(context, 0.62),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _HighlightedText(
            text: result.primaryText,
            query: query,
            textDirection: primaryIsArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            textAlign: primaryIsArabic ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (result.secondaryText.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _HighlightedText(
              text: result.secondaryText,
              query: query,
              maxLines: 3,
              textDirection: _containsRtl(result.secondaryText)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: _containsRtl(result.secondaryText)
                  ? TextAlign.right
                  : TextAlign.left,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.74),
                height: 1.36,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.textDirection,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final normalizedText = text.toLowerCase();
    final normalizedQuery = query.trim().toLowerCase();
    final index = normalizedQuery.isEmpty
        ? -1
        : normalizedText.indexOf(normalizedQuery);
    if (index < 0) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
        textDirection: textDirection,
        textAlign: textAlign,
        style: style,
      );
    }
    final primary = Theme.of(context).colorScheme.primary;
    return RichText(
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      textDirection: textDirection ?? TextDirection.ltr,
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + normalizedQuery.length),
            style: TextStyle(
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.10),
            ),
          ),
          TextSpan(text: text.substring(index + normalizedQuery.length)),
        ],
      ),
    );
  }
}

void _openResult(BuildContext context, DeepSearchResult result) {
  final target = result.target;
  switch (target.type) {
    case DeepSearchTargetType.quranAyah:
      context.push(
        AppRoutes.quranReaderPath(
          target.surahNumber ?? 1,
          ayahNumber: target.ayahNumber,
          translationResourceId: target.translationResourceId,
        ),
      );
    case DeepSearchTargetType.surah:
      context.push(AppRoutes.quranReaderPath(target.surahNumber ?? 1));
    case DeepSearchTargetType.note:
      context.push(AppRoutes.quranNotesPath(noteId: target.noteId));
    case DeepSearchTargetType.hadith:
      final itemId = target.itemId ?? '';
      final parts = itemId.split(':');
      if (parts.length >= 3 && parts.first == 'hadith') {
        context.push(
          AppRoutes.hadithBookPath(parts[1], hadithNumber: parts[2]),
        );
        return;
      }
      _showTextResultSheet(context, result);
    case DeepSearchTargetType.azkar:
      final itemId = target.itemId ?? '';
      final parts = itemId.split(':');
      if (parts.length >= 3) {
        context.push(AppRoutes.azkarCategoryPath(parts[1], itemId: itemId));
        return;
      }
      _showTextResultSheet(context, result);
  }
}

Future<void> _showTextResultSheet(
  BuildContext context,
  DeepSearchResult result,
) {
  final primaryIsArabic = _containsRtl(result.primaryText);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppSheet(
      title: result.title,
      subtitle: result.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            result.primaryText,
            textDirection: primaryIsArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            textAlign: primaryIsArabic ? TextAlign.right : TextAlign.left,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(height: 1.7),
          ),
          if (result.secondaryText.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            QuranTranslationText(
              text: result.secondaryText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _categoryLabel(DeepSearchCategory category) {
  return switch (category) {
    DeepSearchCategory.quran => 'Quran',
    DeepSearchCategory.surah => 'Surahs',
    DeepSearchCategory.translation => 'Translations',
    DeepSearchCategory.tafsir => 'Tafsir',
    DeepSearchCategory.notes => 'Notes',
    DeepSearchCategory.hadith => 'Hadith',
    DeepSearchCategory.azkar => 'Azkar',
  };
}

IconData _categoryIcon(DeepSearchCategory category) {
  return switch (category) {
    DeepSearchCategory.quran => Icons.menu_book_rounded,
    DeepSearchCategory.surah => Icons.list_alt_rounded,
    DeepSearchCategory.translation => Icons.translate_rounded,
    DeepSearchCategory.tafsir => Icons.auto_stories_rounded,
    DeepSearchCategory.notes => Icons.notes_rounded,
    DeepSearchCategory.hadith => Icons.local_library_rounded,
    DeepSearchCategory.azkar => Icons.favorite_rounded,
  };
}

bool _containsRtl(String value) {
  return RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]').hasMatch(value);
}
