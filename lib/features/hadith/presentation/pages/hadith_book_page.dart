import '../../../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/note_editor_sheet.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../../library/presentation/widgets/library_reader_widgets.dart';
import '../../../library/presentation/widgets/library_share_sheet.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../../domain/services/hadith_grading.dart';
import '../bloc/hadith_library_cubit.dart';
import '../bloc/hadith_library_state.dart';
import '../widgets/hadith_translation_sheet.dart';
import '../widgets/hadith_grading_panel.dart';

class HadithBookPage extends StatelessWidget {
  const HadithBookPage({
    super.key,
    required this.bookId,
    this.initialLookup,
    this.initialLanguageCode,
  });

  final String bookId;
  final String? initialLookup;
  final String? initialLanguageCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = HadithLibraryCubit(repository: getIt<HadithRepository>());
        final languageCode =
            initialLanguageCode ??
            getIt<SettingsStore>().hadithLanguageCodeOrNull;
        final lookup = initialLookup?.trim();
        if (lookup != null && lookup.isNotEmpty) {
          cubit.lookupHadith(
            bookId: bookId,
            rawQuery: lookup,
            languageCode: languageCode,
          );
        } else {
          cubit.openBook(bookId, languageCode: languageCode);
        }
        return cubit;
      },
      child: _HadithBookView(
        bookId: bookId,
        initialLookup: initialLookup,
        initialLanguageCode: initialLanguageCode,
      ),
    );
  }
}

String? _lastHadithNumberForBook(String bookId) {
  if (!getIt.isRegistered<LibraryUserDataStore>()) {
    return null;
  }
  final key = getIt<LibraryUserDataStore>().lastReadFor('hadith:$bookId');
  if (key == null) {
    return null;
  }
  final parts = key.split(':');
  return parts.isEmpty ? null : parts.last;
}

class _HadithBookView extends StatefulWidget {
  const _HadithBookView({
    required this.bookId,
    this.initialLookup,
    this.initialLanguageCode,
  });

  final String bookId;
  final String? initialLookup;
  final String? initialLanguageCode;

  @override
  State<_HadithBookView> createState() => _HadithBookViewState();
}

class _HadithBookViewState extends State<_HadithBookView> {
  late final ScrollController _scrollController;
  late final TextEditingController _lookupController;
  late final FocusNode _searchFocusNode;
  late final SettingsStore _settingsStore;
  late final LibraryUserDataStore _userDataStore;
  String? _languageOverride;
  bool _showTranslation = true;
  bool _showExplanation = false;
  QuranTranslationResource? _selectedTranslation;
  LibraryLanguageSelection _language = libraryLanguageFromQuranTranslation(
    null,
  );
  bool _translationAvailable = true;
  bool _translationSupported = true;
  bool _loadingLanguage = true;
  int _languageRequest = 0;
  String? _selectedItemKey;
  late final ValueNotifier<String?> _currentHadithNumber;
  late final String? _resumeHadithNumber;
  String? _lastSavedItemKey;
  final _visibleCards = <_VisibleHadithCardState>{};
  bool _positionUpdateScheduled = false;
  late HadithLibraryState _positionState;

  String get _scopeKey => 'hadith:${widget.bookId}';
  String? get _activeHadithLanguageCode => _language.hadithCode;

  @override
  void initState() {
    super.initState();
    _settingsStore = getIt<SettingsStore>();
    _userDataStore = getIt<LibraryUserDataStore>();
    _languageOverride = widget.initialLanguageCode;
    _showTranslation =
        _languageOverride != null || _settingsStore.libraryTranslationEnabled;
    _showExplanation = _settingsStore.libraryHadithExplanationEnabled;
    _scrollController = ScrollController()..addListener(_onScroll);
    _lookupController = TextEditingController(text: widget.initialLookup ?? '');
    _searchFocusNode = FocusNode();
    _resumeHadithNumber = _lastHadithNumberForBook(widget.bookId);
    _currentHadithNumber = ValueNotifier(null);
    _positionState = context.read<HadithLibraryCubit>().state;
    _loadContentLanguage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _lookupController.dispose();
    _searchFocusNode.dispose();
    _currentHadithNumber.dispose();
    super.dispose();
  }

  Future<void> _loadContentLanguage({bool forceReload = false}) async {
    final request = ++_languageRequest;
    final translationRepository = getIt<QuranTranslationRepository>();
    final previousQuranSelection = await translationRepository
        .selectedTranslation();
    var code = _languageOverride ?? _settingsStore.hadithLanguageCodeOrNull;
    if (code == null) {
      code =
          libraryLanguageFromQuranTranslation(
            previousQuranSelection,
          ).hadithCode ??
          'en';
      await _settingsStore.setHadithLanguageCode(code);
    }
    final displayResource =
        libraryLanguageFromQuranTranslation(
              previousQuranSelection,
            ).hadithCode ==
            code
        ? previousQuranSelection
        : null;
    final language = libraryLanguageFromCode(code, resource: displayResource);
    final repository = getIt<HadithRepository>();
    final supported = await repository.availableTranslationLanguagesForBook(
      widget.bookId,
    );
    final available = await repository.hasDownloadedTranslation(
      widget.bookId,
      code,
    );
    if (!mounted || request != _languageRequest) {
      return;
    }
    setState(() {
      _selectedTranslation = displayResource;
      _language = language;
      _translationAvailable = available;
      _translationSupported = supported.contains(code);
      _loadingLanguage = false;
    });
    _scheduleVisiblePosition();
    final cubit = context.read<HadithLibraryCubit>();
    final loadedLanguageCode =
        cubit.state.selectedTranslationLanguageCode ?? 'en';
    if (forceReload || loadedLanguageCode != code) {
      final query = cubit.state.query;
      if (query.isNotEmpty) {
        await cubit.searchInBook(
          bookId: widget.bookId,
          query: query,
          languageCode: code,
        );
      } else {
        await cubit.openBook(
          widget.bookId,
          chapterId: cubit.state.selectedChapterId,
          languageCode: code,
        );
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final cubit = context.read<HadithLibraryCubit>();
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      cubit.loadMore();
    }
    _scheduleVisiblePosition();
  }

  void _registerVisibleCard(_VisibleHadithCardState card) {
    _visibleCards.add(card);
    _scheduleVisiblePosition();
  }

  void _unregisterVisibleCard(_VisibleHadithCardState card) {
    _visibleCards.remove(card);
  }

  void _scheduleVisiblePosition() {
    if (!mounted || _positionUpdateScheduled) return;
    _positionUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _positionUpdateScheduled = false;
      if (mounted) _updateVisiblePosition();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _updateVisiblePosition() {
    final state = context.read<HadithLibraryCubit>().state;
    if (_loadingLanguage ||
        state.status != HadithLibraryStatus.success ||
        state.hadiths.isEmpty) {
      _currentHadithNumber.value = null;
      return;
    }
    HadithItem? visible;
    var firstTop = double.infinity;
    // Only mounted lazy children are registered. Cached children outside the
    // viewport must not advance the reading position or overwrite last read.
    for (final card in _visibleCards) {
      if (!card.mounted) continue;
      final render = card.context.findRenderObject();
      if (render is! RenderBox || !render.attached || !render.hasSize) continue;
      final viewport = RenderAbstractViewport.maybeOf(render);
      if (viewport == null || viewport is! RenderBox) continue;
      final viewportBox = viewport as RenderBox;
      if (!viewportBox.hasSize) continue;
      final top = render.localToGlobal(Offset.zero, ancestor: viewportBox).dy;
      final bottom = top + render.size.height;
      if (!top.isFinite || bottom <= 0 || top >= viewportBox.size.height) {
        continue;
      }
      if (top < firstTop) {
        firstTop = top;
        visible = card.widget.hadith;
      }
    }
    if (visible == null) {
      _currentHadithNumber.value = null;
      return;
    }
    _recordCurrentHadith(visible);
  }

  void _recordCurrentHadith(HadithItem item) {
    final itemKey = _itemKey(item);
    if (_currentHadithNumber.value != item.hadithNumber) {
      _currentHadithNumber.value = item.hadithNumber;
    }
    if (_lastSavedItemKey != itemKey) {
      _lastSavedItemKey = itemKey;
      _userDataStore.saveLastRead(scopeKey: _scopeKey, itemKey: itemKey);
    }
  }

  void _onHadithStateChanged(
    HadithLibraryState previous,
    HadithLibraryState state,
  ) {
    final scopeChanged =
        previous.query != state.query ||
        previous.selectedBookId != state.selectedBookId ||
        previous.selectedChapterId != state.selectedChapterId ||
        previous.selectedTranslationLanguageCode !=
            state.selectedTranslationLanguageCode;
    final resultsChanged = !identical(previous.hadiths, state.hadiths);
    final appended =
        resultsChanged &&
        previous.hadiths.isNotEmpty &&
        state.hadiths.length > previous.hadiths.length &&
        identical(previous.hadiths.first, state.hadiths.first) &&
        identical(
          previous.hadiths.last,
          state.hadiths[previous.hadiths.length - 1],
        );
    if (scopeChanged ||
        state.status != HadithLibraryStatus.success ||
        (resultsChanged && !appended)) {
      _currentHadithNumber.value = null;
    }
    _scheduleVisiblePosition();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)
            ?.copyWith(height: 1.2);
    final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
      color: QuranTheme.subText(context),
      height: 1.25,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final toolbarHeight =
        (scaler.scale(titleStyle?.fontSize ?? 20) * 1.2 +
                scaler.scale(subtitleStyle?.fontSize ?? 12) * 1.25 +
                15)
            .clamp(kToolbarHeight, double.infinity)
            .toDouble();
    return BlocListener<HadithLibraryCubit, HadithLibraryState>(
      listener: (_, current) {
        final previous = _positionState;
        _positionState = current;
        _onHadithStateChanged(previous, current);
      },
      child: BlocBuilder<QuranThemeCubit, QuranThemeState>(
        builder: (context, themeState) {
          _scheduleVisiblePosition();
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppPageAppBar(
              flexibleSpace: const HeaderPatternBackdrop(),
              toolbarHeight: toolbarHeight,
              titleSpacing: 0,
              title: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
                buildWhen: (previous, current) =>
                    previous.selectedBook != current.selectedBook ||
                    previous.status != current.status ||
                    !identical(previous.hadiths, current.hadiths) ||
                    previous.query != current.query ||
                    previous.selectedChapterId != current.selectedChapterId ||
                    previous.selectedTranslationLanguageCode !=
                        current.selectedTranslationLanguageCode,
                builder: (context, state) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showNavigationMenu(state),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _currentHadithNumber,
                      builder: (context, number, _) {
                        final visibleNumber =
                            number ??
                            (state.hadiths.length == 1
                                ? state.hadiths.first.hadithNumber
                                : null);
                        final showPosition =
                            !_loadingLanguage &&
                            state.status == HadithLibraryStatus.success &&
                            state.hadiths.isNotEmpty &&
                            visibleNumber != null;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedBook?.englishName ?? 'Hadith',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            if (showPosition) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Hadith $visibleNumber',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              actions: [
                IconButton(
                  tooltip: 'Search this book',
                  onPressed: _searchFocusNode.requestFocus,
                  icon: const AppIcon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: 'Reader settings',
                  onPressed: _showSettings,
                  icon: const AppIcon(Icons.tune_rounded),
                ),
              ],
            ),
            body: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
              builder: (context, state) {
                if (state.status == HadithLibraryStatus.failure) {
                  return AppErrorView(
                    title: 'Hadith book could not be loaded',
                    message: state.errorMessage ?? 'Please try again.',
                    onRetry: () => context.read<HadithLibraryCubit>().openBook(
                      widget.bookId,
                      languageCode: _activeHadithLanguageCode,
                    ),
                  );
                }

                if (state.status == HadithLibraryStatus.loading &&
                    state.hadiths.isEmpty) {
                  return const AppLoadingView(label: 'Loading hadith book');
                }

                return Stack(
                  children: [
                    Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
                      child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  if (state.selectedBook != null)
                                    _BookSummary(
                                      book: state.selectedBook!,
                                      resumeHadithNumber: state.query.isEmpty
                                          ? _resumeHadithNumber
                                          : null,
                                      onResume: _resumeHadithNumber == null
                                          ? null
                                          : () {
                                              _lookupController.text =
                                                  _resumeHadithNumber;
                                              _lookup(_resumeHadithNumber);
                                            },
                                    ),
                                  if (_showTranslation &&
                                      !_loadingLanguage &&
                                      !_translationAvailable) ...[
                                    if (_translationSupported)
                                      OutlinedButton.icon(
                                        onPressed: _showTranslationPicker,
                                        icon: const AppIcon(
                                          Icons.download_rounded,
                                        ),
                                        label: Text(
                                          'Download ${_language.label} for all available books',
                                        ),
                                      )
                                    else
                                      Text(
                                        '${_language.label} translation is not available for this book.',
                                      ),
                                  ],
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _lookupController,
                                    focusNode: _searchFocusNode,
                                    textInputAction: TextInputAction.search,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: _searchBook,
                                    decoration: InputDecoration(
                                      hintText: 'Search text or hadith number',
                                      prefixIcon: const AppIcon(
                                        Icons.search_rounded,
                                      ),
                                      suffixIcon:
                                          _lookupController.text.trim().isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: 'Clear search',
                                              onPressed: _clearLookup,
                                              icon: const AppIcon(
                                                Icons.close_rounded,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (state.chapters.isNotEmpty &&
                                      state.query.isEmpty) ...[
                                    const SizedBox(height: 12),
                                    _ChapterStrip(state: state),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (state.status == HadithLibraryStatus.empty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _EmptyLookup(
                                  bookId: widget.bookId,
                                  query: state.query,
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              sliver: SliverList.builder(
                                addAutomaticKeepAlives: false,
                                itemCount: state.hadiths.length,
                                itemBuilder: (context, index) {
                                  final hadith = state.hadiths[index];
                                  return Padding(
                                    key: ValueKey(_itemKey(hadith)),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _VisibleHadithCard(
                                      hadith: hadith,
                                      onMount: _registerVisibleCard,
                                      onUnmount: _unregisterVisibleCard,
                                      onLayoutChanged: _scheduleVisiblePosition,
                                      child: _HadithReaderCard(
                                        hadith: hadith,
                                        themeState: themeState,
                                        selected:
                                            _selectedItemKey ==
                                            _itemKey(hadith),
                                        showTranslation:
                                            _showTranslation &&
                                            !_loadingLanguage &&
                                            _translationAvailable,
                                        translationAvailable:
                                            _translationAvailable,
                                        languageLabel: _language.label,
                                        languageCode: _activeHadithLanguageCode,
                                        translationResource:
                                            _selectedTranslation,
                                        onTap: () => _selectHadith(hadith),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (state.hasMoreHadiths && state.query.isEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                              sliver: SliverToBoxAdapter(
                                child: OutlinedButton.icon(
                                  onPressed: state.loadingMoreHadiths
                                      ? null
                                      : context
                                            .read<HadithLibraryCubit>()
                                            .loadMore,
                                  icon: state.loadingMoreHadiths
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const AppIcon(
                                          Icons.expand_more_rounded,
                                        ),
                                  label: Text(
                                    state.loadingMoreHadiths
                                        ? 'Loading more'
                                        : 'Load more',
                                  ),
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: _selectedItem(state) == null
                                  ? 24
                                  : LibraryReaderActionBar.bottomClearance(
                                      context,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedItem(state) != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LibraryReaderActionBar(
                          title: _selectedItem(state)!.reference,
                          isBookmarked: _userDataStore.isBookmarked(
                            _itemKey(_selectedItem(state)!),
                          ),
                          onBookmark: () =>
                              _toggleBookmark(_selectedItem(state)!),
                          onNote: () => _editNote(_selectedItem(state)!),
                          onCopy: () => _copyHadith(_selectedItem(state)!),
                          onShare: () => showHadithShareSheet(
                            context,
                            _selectedItem(state)!,
                            languageCode: _activeHadithLanguageCode,
                            translationResource: _selectedTranslation,
                            includeTranslation: _showTranslation,
                            translationAvailable:
                                _translationAvailable && !_loadingLanguage,
                          ),
                          onSource: () =>
                              _showGradingSheet(_selectedItem(state)!),
                          sourceLabel: switch (Localizations.localeOf(
                            context,
                          ).languageCode) {
                            'ur' => 'درجہ',
                            'ar' => 'الحكم',
                            _ => 'Grades',
                          },
                          onDetails: () =>
                              _showDetailsSheet(_selectedItem(state)!),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _selectHadith(HadithItem hadith) {
    final key = _itemKey(hadith);
    setState(() {
      _selectedItemKey = key;
    });
    _recordCurrentHadith(hadith);
  }

  HadithItem? _selectedItem(HadithLibraryState state) {
    final key = _selectedItemKey;
    if (key == null) {
      return null;
    }
    for (final hadith in state.hadiths) {
      if (_itemKey(hadith) == key) {
        return hadith;
      }
    }
    return null;
  }

  void _lookup(String value) {
    context.read<HadithLibraryCubit>().lookupHadith(
      bookId: widget.bookId,
      rawQuery: value,
      languageCode: _activeHadithLanguageCode,
    );
  }

  void _searchBook(String value) {
    _searchFocusNode.unfocus();
    context.read<HadithLibraryCubit>().searchInBook(
      bookId: widget.bookId,
      query: value,
      languageCode: _activeHadithLanguageCode,
    );
  }

  void _clearLookup() {
    _lookupController.clear();
    context.read<HadithLibraryCubit>().openBook(
      widget.bookId,
      languageCode: _activeHadithLanguageCode,
    );
  }

  Future<void> _showNavigationMenu(HadithLibraryState state) {
    final cubit = context.read<HadithLibraryCubit>();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hadith navigation',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                62,
                18,
                MediaQuery.viewInsetsOf(dialogContext).bottom + 12,
              ),
              child: SingleChildScrollView(
                child: Material(
                  color: Colors.transparent,
                  child: PremiumSurface(
                    padding: const EdgeInsets.all(14),
                    radius: 24,
                    prominent: true,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state.selectedBook?.englishName ?? 'Hadith',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const AppIcon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _lookupController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              labelText: 'Jump to hadith',
                              prefixIcon: AppIcon(Icons.tag_rounded),
                            ),
                            onSubmitted: (value) {
                              Navigator.of(dialogContext).pop();
                              _lookup(value);
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _lookup(_lookupController.text);
                                  },
                                  icon: const AppIcon(
                                    Icons.arrow_forward_rounded,
                                  ),
                                  label: const Text('Go'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Clear lookup',
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  _clearLookup();
                                },
                                icon: const AppIcon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          if (state.chapters.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: state.selectedChapterId ?? '',
                              isExpanded: true,
                              itemHeight: null,
                              decoration: const InputDecoration(
                                labelText: 'Chapter',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('All chapters'),
                                ),
                                for (final chapter in state.chapters)
                                  DropdownMenuItem(
                                    value: chapter.id,
                                    child: Text(
                                      '${chapter.number}. ${chapter.englishTitle}',
                                    ),
                                  ),
                              ],
                              onChanged: (chapterId) {
                                if (chapterId == null) return;
                                Navigator.of(dialogContext).pop();
                                cubit.openBook(
                                  widget.bookId,
                                  chapterId: chapterId.isEmpty
                                      ? null
                                      : chapterId,
                                  languageCode: _activeHadithLanguageCode,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<void> _showSettings() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return LibraryReaderSettingsSheet(
          languageLabel: _language.label,
          showTranslation: _showTranslation,
          onTranslationChanged: (value) {
            setState(() => _showTranslation = value);
            _settingsStore.setLibraryTranslationEnabled(value);
            if (value && !_translationAvailable && _translationSupported) {
              Navigator.of(sheetContext).pop();
              _showTranslationPicker();
            }
          },
          onLanguageTap: () {
            Navigator.of(sheetContext).pop();
            _showTranslationPicker();
          },
          showExplanation: _showExplanation,
          onExplanationChanged: (value) {
            setState(() => _showExplanation = value);
            _settingsStore.setLibraryHadithExplanationEnabled(value);
          },
        );
      },
    );
  }

  Future<void> _showTranslationPicker() async {
    final selected = await showHadithTranslationSheet(
      context,
      initialLanguageCode: _activeHadithLanguageCode,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _languageOverride = null;
      _showTranslation = true;
      _loadingLanguage = true;
    });
    await _loadContentLanguage(forceReload: true);
  }

  Future<void> _toggleBookmark(HadithItem hadith) async {
    await _userDataStore.toggleBookmark(_itemKey(hadith));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editNote(HadithItem hadith) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorSheet(
        title: 'Note ${hadith.reference}',
        initialText: _userDataStore.noteFor(_itemKey(hadith)),
        allowEmpty: true,
      ),
    );
    if (note != null) {
      await _userDataStore.saveNote(_itemKey(hadith), note);
    }
  }

  Future<void> _copyHadith(HadithItem hadith) async {
    await Clipboard.setData(ClipboardData(text: _plainText(hadith)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  void _showGradingSheet(HadithItem hadith) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheet(
        title: switch (Localizations.localeOf(context).languageCode) {
          'ur' => 'درجہ اور حوالہ',
          'ar' => 'الحكم والمرجع',
          _ => 'Grades & reference',
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hadith.collectionName.isEmpty
                  ? hadith.reference
                  : hadith.collectionName,
            ),
            const SizedBox(height: 12),
            HadithGradingPanel.fromHadith(hadith: hadith),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(HadithItem hadith) {
    final grading = HadithGrading.fromHadith(hadith);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheet(
        title: hadith.reference,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (grading.requiresCaution) ...[
              HadithGradingPanel(grading: grading, compact: true),
              const SizedBox(height: 8),
            ],
            LibraryArabicText(
              text: hadith.arabic,
              themeState: context.read<QuranThemeCubit>().state,
              selected: true,
            ),
            if (_showTranslation &&
                !_loadingLanguage &&
                _translationAvailable &&
                hadith.translation.isNotEmpty) ...[
              const SizedBox(height: 12),
              LibraryTranslationBody(
                text: hadith.translation,
                themeState: context.read<QuranThemeCubit>().state,
                resource: _selectedTranslation,
                languageCode: _activeHadithLanguageCode,
              ),
            ],
            if (_showExplanation &&
                hadithTextReference(hadith.cleanReference).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(hadithTextReference(hadith.cleanReference)),
            ],
          ],
        ),
      ),
    );
  }

  String _plainText(HadithItem hadith) {
    final grading = HadithGrading.fromHadith(hadith);
    return [
      hadith.reference,
      grading.shareSummary,
      hadith.arabic,
      if (_showTranslation && _translationAvailable) hadith.translation,
      if (hadith.grade.isNotEmpty) hadith.grade,
      for (final grade in hadith.grades)
        if (grade is Map && grade['grade'] != null)
          [
            grade['grade'].toString(),
            (grade['name'] ?? grade['grader'] ?? '').toString(),
          ].where((part) => part.trim().isNotEmpty).join(' · ')
        else if (grade != null)
          grade.toString(),
    ].where((line) => line.trim().isNotEmpty).join('\n\n');
  }

  String _itemKey(HadithItem hadith) {
    return 'hadith:${hadith.bookId}:${hadith.hadithNumber}';
  }
}

class _BookSummary extends StatelessWidget {
  const _BookSummary({
    required this.book,
    this.resumeHadithNumber,
    this.onResume,
  });

  final HadithBook book;
  final String? resumeHadithNumber;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            book.arabicName,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${book.hadithCount} hadiths • ${book.chapterCount} chapters',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (resumeHadithNumber != null && onResume != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onResume,
                icon: const AppIcon(Icons.history_rounded, size: 18),
                label: Text('Continue at Hadith $resumeHadithNumber'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterStrip extends StatelessWidget {
  const _ChapterStrip({required this.state});

  final HadithLibraryState state;

  @override
  Widget build(BuildContext context) {
    final book = state.selectedBook;
    if (book == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: (MediaQuery.textScalerOf(context).scale(14) * 1.4 + 28).clamp(
        48.0,
        double.infinity,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('All chapters'),
              selected: state.selectedChapterId == null,
              onSelected: (_) => context.read<HadithLibraryCubit>().openBook(
                book.id,
                languageCode: state.selectedTranslationLanguageCode,
              ),
            );
          }
          final chapter = state.chapters[index - 1];
          final selected = chapter.id == state.selectedChapterId;
          return ChoiceChip(
            label: Text('${chapter.number}. ${chapter.englishTitle}'),
            selected: selected,
            onSelected: (_) => context.read<HadithLibraryCubit>().openBook(
              book.id,
              chapterId: chapter.id,
              languageCode: state.selectedTranslationLanguageCode,
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: state.chapters.length + 1,
      ),
    );
  }
}

class _HadithReaderCard extends StatelessWidget {
  const _HadithReaderCard({
    required this.hadith,
    required this.themeState,
    required this.selected,
    required this.showTranslation,
    required this.translationAvailable,
    required this.languageLabel,
    required this.languageCode,
    required this.translationResource,
    required this.onTap,
  });

  final HadithItem hadith;
  final QuranThemeState themeState;
  final bool selected;
  final bool showTranslation;
  final bool translationAvailable;
  final String languageLabel;
  final String? languageCode;
  final QuranTranslationResource? translationResource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final grading = HadithGrading.fromHadith(hadith);
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
              if (selected)
                AppIcon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
          if (grading.requiresCaution) ...[
            const SizedBox(height: 8),
            HadithGradingPanel(grading: grading, compact: true),
          ],
          if (hadith.arabic.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            LibraryArabicText(
              text: hadith.arabic,
              themeState: themeState,
              selected: selected,
            ),
          ],
          AnimatedExpansion(
            expanded: showTranslation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                if (translationAvailable &&
                    hadith.translation.trim().isNotEmpty)
                  LibraryTranslationBody(
                    text: hadith.translation,
                    themeState: themeState,
                    resource: translationResource,
                    languageCode: languageCode,
                  )
                else
                  LibraryTranslationUnavailable(languageLabel: languageLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Registers only the cards that the lazy sliver has mounted. Its render box
/// gives the real reading position even when narrations have different heights.
class _VisibleHadithCard extends StatefulWidget {
  const _VisibleHadithCard({
    required this.hadith,
    required this.onMount,
    required this.onUnmount,
    required this.onLayoutChanged,
    required this.child,
  });

  final HadithItem hadith;
  final ValueChanged<_VisibleHadithCardState> onMount;
  final ValueChanged<_VisibleHadithCardState> onUnmount;
  final VoidCallback onLayoutChanged;
  final Widget child;

  @override
  State<_VisibleHadithCard> createState() => _VisibleHadithCardState();
}

class _VisibleHadithCardState extends State<_VisibleHadithCard> {
  @override
  void initState() {
    super.initState();
    widget.onMount(this);
  }

  @override
  void didUpdateWidget(covariant _VisibleHadithCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hadith != widget.hadith) widget.onLayoutChanged();
  }

  @override
  void dispose() {
    widget.onUnmount(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          widget.onLayoutChanged();
          return false;
        },
        child: SizeChangedLayoutNotifier(child: widget.child),
      );
}

class _EmptyLookup extends StatelessWidget {
  const _EmptyLookup({required this.bookId, required this.query});

  final String bookId;
  final String query;

  @override
  Widget build(BuildContext context) {
    final text = query.trim().isEmpty
        ? 'No hadith found.'
        : 'No hadith found for $bookId $query.';
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIcon(
            Icons.search_off_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
