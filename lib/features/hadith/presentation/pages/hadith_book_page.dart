import 'package:flutter/material.dart';
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
import '../../../library/data/stores/library_user_data_store.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../../library/presentation/widgets/library_reader_widgets.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../domain/entities/hadith_book.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/repositories/hadith_repository.dart';
import '../bloc/hadith_library_cubit.dart';
import '../bloc/hadith_library_state.dart';

class HadithBookPage extends StatelessWidget {
  const HadithBookPage({super.key, required this.bookId, this.initialLookup});

  final String bookId;
  final String? initialLookup;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = HadithLibraryCubit(repository: getIt<HadithRepository>());
        final lookup =
            initialLookup?.trim() ?? _lastHadithNumberForBook(bookId);
        if (lookup != null && lookup.isNotEmpty) {
          cubit.lookupHadith(bookId: bookId, rawQuery: lookup);
        } else {
          cubit.openBook(bookId);
        }
        return cubit;
      },
      child: _HadithBookView(bookId: bookId, initialLookup: initialLookup),
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
  const _HadithBookView({required this.bookId, this.initialLookup});

  final String bookId;
  final String? initialLookup;

  @override
  State<_HadithBookView> createState() => _HadithBookViewState();
}

class _HadithBookViewState extends State<_HadithBookView> {
  late final ScrollController _scrollController;
  late final TextEditingController _lookupController;
  late final FocusNode _searchFocusNode;
  late final SettingsStore _settingsStore;
  late final LibraryUserDataStore _userDataStore;
  bool _showTranslation = true;
  bool _showExplanation = false;
  QuranTranslationResource? _selectedTranslation;
  LibraryLanguageSelection _language = libraryLanguageFromQuranTranslation(
    null,
  );
  bool _translationAvailable = true;
  String? _selectedItemKey;
  String? _currentHadithNumber;

  String get _scopeKey => 'hadith:${widget.bookId}';
  String? get _activeHadithLanguageCode => _language.hadithCode;

  @override
  void initState() {
    super.initState();
    _settingsStore = getIt<SettingsStore>();
    _userDataStore = getIt<LibraryUserDataStore>();
    _showTranslation = _settingsStore.libraryTranslationEnabled;
    _showExplanation = _settingsStore.libraryHadithExplanationEnabled;
    _scrollController = ScrollController()..addListener(_onScroll);
    _lookupController = TextEditingController(text: widget.initialLookup ?? '');
    _searchFocusNode = FocusNode();
    _loadContentLanguage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _lookupController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadContentLanguage() async {
    final translationRepository = getIt<QuranTranslationRepository>();
    final previousQuranSelection = await translationRepository
        .selectedTranslation();
    var code = _settingsStore.hadithLanguageCodeOrNull;
    if (code == null) {
      code =
          libraryLanguageFromQuranTranslation(
            previousQuranSelection,
          ).hadithCode ??
          'en';
      await _settingsStore.setHadithLanguageCode(code);
    }
    QuranTranslationResource? displayResource;
    final languages = await translationRepository.translationLanguages();
    for (final language in languages) {
      final resource = language.defaultResource;
      if (libraryLanguageFromQuranTranslation(resource).hadithCode == code) {
        displayResource = resource;
        break;
      }
    }
    final language = libraryLanguageFromCode(code, resource: displayResource);
    final available = await getIt<HadithRepository>().hasFullTranslation(
      widget.bookId,
      code,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTranslation = displayResource;
      _language = language;
      _translationAvailable = available;
    });
    final cubit = context.read<HadithLibraryCubit>();
    if (available && cubit.state.selectedTranslationLanguageCode != code) {
      final query = cubit.state.query;
      if (query.isNotEmpty) {
        cubit.searchInBook(
          bookId: widget.bookId,
          query: query,
          languageCode: code,
        );
      } else {
        cubit.openBook(
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
    final hadiths = cubit.state.hadiths;
    if (hadiths.isEmpty || position.maxScrollExtent <= 0) {
      return;
    }
    final index =
        ((position.pixels / position.maxScrollExtent) * (hadiths.length - 1))
            .round()
            .clamp(0, hadiths.length - 1)
            .toInt();
    final item = hadiths[index];
    _currentHadithNumber = item.hadithNumber;
    _userDataStore.saveLastRead(scopeKey: _scopeKey, itemKey: _itemKey(item));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            title: BlocBuilder<HadithLibraryCubit, HadithLibraryState>(
              buildWhen: (previous, current) =>
                  previous.selectedBook != current.selectedBook ||
                  previous.status != current.status,
              builder: (context, state) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showNavigationMenu(state),
                  child: Text(state.selectedBook?.englishName ?? 'Hadith'),
                );
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Search this book',
                onPressed: _searchFocusNode.requestFocus,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: 'Reader settings',
                onPressed: _showSettings,
                icon: const Icon(Icons.tune_rounded),
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
                    languageCode: _translationAvailable
                        ? _activeHadithLanguageCode
                        : null,
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
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 132),
                      children: [
                        if (state.selectedBook != null)
                          _BookSummary(book: state.selectedBook!),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lookupController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: _searchBook,
                          decoration: InputDecoration(
                            hintText: 'Search text or hadith number',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _lookupController.text.trim().isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: _clearLookup,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        if (state.chapters.isNotEmpty &&
                            state.query.isEmpty) ...[
                          const SizedBox(height: 12),
                          _ChapterStrip(state: state),
                        ],
                        const SizedBox(height: 14),
                        if (state.status == HadithLibraryStatus.empty)
                          _EmptyLookup(
                            bookId: widget.bookId,
                            query: state.query,
                          )
                        else
                          for (final hadith in state.hadiths)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HadithReaderCard(
                                hadith: hadith,
                                themeState: themeState,
                                selected: _selectedItemKey == _itemKey(hadith),
                                showTranslation: _showTranslation,
                                translationAvailable: _translationAvailable,
                                languageLabel: _language.label,
                                translationResource: _selectedTranslation,
                                onTap: () => _selectHadith(hadith),
                              ),
                            ),
                        if (state.hasMoreHadiths && state.query.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: OutlinedButton.icon(
                              onPressed: context
                                  .read<HadithLibraryCubit>()
                                  .loadMore,
                              icon: const Icon(Icons.expand_more_rounded),
                              label: const Text('Load more'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (state.hadiths.isNotEmpty)
                    PositionedDirectional(
                      end: 8,
                      top: MediaQuery.sizeOf(context).height * 0.38,
                      child: _ProgressPill(
                        label:
                            'Hadith ${_currentHadithNumber ?? state.hadiths.first.hadithNumber}',
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
                        onShare: () => _copyHadith(
                          _selectedItem(state)!,
                          shareIntent: true,
                        ),
                        onSource: () => _showSourceSheet(_selectedItem(state)!),
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
    );
  }

  void _selectHadith(HadithItem hadith) {
    final key = _itemKey(hadith);
    setState(() {
      _selectedItemKey = key;
      _currentHadithNumber = hadith.hadithNumber;
    });
    _userDataStore.saveLastRead(scopeKey: _scopeKey, itemKey: key);
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
      languageCode: _translationAvailable ? _activeHadithLanguageCode : null,
    );
  }

  void _searchBook(String value) {
    _searchFocusNode.unfocus();
    context.read<HadithLibraryCubit>().searchInBook(
      bookId: widget.bookId,
      query: value,
      languageCode: _translationAvailable ? _activeHadithLanguageCode : null,
    );
  }

  void _clearLookup() {
    _lookupController.clear();
    context.read<HadithLibraryCubit>().openBook(
      widget.bookId,
      languageCode: _translationAvailable ? _activeHadithLanguageCode : null,
    );
  }

  Future<void> _showNavigationMenu(HadithLibraryState state) {
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
              padding: const EdgeInsets.fromLTRB(26, 62, 26, 0),
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
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              icon: const Icon(Icons.close_rounded),
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
                            prefixIcon: Icon(Icons.tag_rounded),
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
                                icon: const Icon(Icons.arrow_forward_rounded),
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
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (state.chapters.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final chapter = state.chapters[index];
                                return ChoiceChip(
                                  label: Text(
                                    '${chapter.number}. ${chapter.englishTitle}',
                                  ),
                                  selected:
                                      chapter.id == state.selectedChapterId,
                                  onSelected: (_) {
                                    Navigator.of(dialogContext).pop();
                                    context.read<HadithLibraryCubit>().openBook(
                                      widget.bookId,
                                      chapterId: chapter.id,
                                      languageCode: _translationAvailable
                                          ? _activeHadithLanguageCode
                                          : null,
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemCount: state.chapters.length,
                            ),
                          ),
                        ],
                      ],
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
    final repository = getIt<HadithRepository>();
    final languages = {
      'en',
      ...await repository.availableTranslationLanguagesForBook(widget.bookId),
    }.toList()..sort();
    if (!mounted) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _HadithSheetSurface(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Text(
                  'Select translation language',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                for (final language in languages)
                  ListTile(
                    title: Text(libraryLanguageLabel(language)),
                    subtitle: Text(language.toUpperCase()),
                    selected: _activeHadithLanguageCode == language,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pop(language),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    final hadithReady = await _ensureHadithTranslation(selected);
    if (!hadithReady) {
      return;
    }
    await _settingsStore.setHadithLanguageCode(selected);
    await _loadContentLanguage();
  }

  Future<bool> _ensureHadithTranslation(String code) async {
    final repository = getIt<HadithRepository>();
    final supported = await repository.availableTranslationLanguagesForBook(
      widget.bookId,
    );
    if (!supported.contains(code)) {
      return true;
    }
    if (await repository.hasFullTranslation(widget.bookId, code)) {
      return true;
    }
    final downloaded = await _downloadHadithTranslation(
      repository: repository,
      languageCode: code,
      languageLabel: libraryLanguageLabel(code),
    );
    return downloaded == true;
  }

  Future<bool?> _downloadHadithTranslation({
    required HadithRepository repository,
    required String languageCode,
    required String languageLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder(
          stream: repository.downloadBookTranslation(
            widget.bookId,
            languageCode,
          ),
          builder: (context, snapshot) {
            final progress = snapshot.data;
            if (progress?.isComplete == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
              });
            }
            return _HadithSheetSurface(
              padding: const EdgeInsets.all(18),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Downloading $languageLabel Hadith'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress?.percent),
                    const SizedBox(height: 8),
                    Text(
                      progress == null || progress.totalItems <= 1
                          ? 'Preparing download'
                          : '${progress.completedItems} of ${progress.totalItems}',
                    ),
                    if (progress?.hasFailed == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Hadith translation download failed.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Close'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBookmark(HadithItem hadith) async {
    await _userDataStore.toggleBookmark(_itemKey(hadith));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editNote(HadithItem hadith) async {
    final controller = TextEditingController(
      text: _userDataStore.noteFor(_itemKey(hadith)),
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note ${hadith.reference}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Write a note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null) {
      await _userDataStore.saveNote(_itemKey(hadith), note);
    }
  }

  Future<void> _copyHadith(
    HadithItem hadith, {
    bool shareIntent = false,
  }) async {
    await Clipboard.setData(ClipboardData(text: _plainText(hadith)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(shareIntent ? 'Copied to share' : 'Copied')),
    );
  }

  void _showSourceSheet(HadithItem hadith) {
    final matches = context
        .read<HadithLibraryCubit>()
        .state
        .contentSources
        .where((source) => source.id == hadith.sourceId);
    final source = matches.isEmpty ? null : matches.first;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HadithSheetSurface(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Source',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              hadith.collectionName.isEmpty
                  ? hadith.reference
                  : hadith.collectionName,
            ),
            if (hadith.cleanReference.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hadith.cleanReference),
            ],
            if (hadith.grade.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hadith.grade),
            ],
            if (source != null) ...[
              const SizedBox(height: 14),
              Text(
                source.name,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(source.attribution),
              if (source.license?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(source.license!),
              ],
              if (source.url?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 6),
                SelectableText(source.url!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(HadithItem hadith) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, controller) => _HadithSheetSurface(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                hadith.reference,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(hadith.arabic, textDirection: TextDirection.rtl),
              if (hadith.translation.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(hadith.translation),
              ],
              if (_showExplanation && hadith.cleanReference.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(hadith.cleanReference),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _plainText(HadithItem hadith) {
    return [
      hadith.reference,
      hadith.arabic,
      if (_showTranslation && _translationAvailable) hadith.translation,
      if (hadith.grade.isNotEmpty) hadith.grade,
    ].where((line) => line.trim().isNotEmpty).join('\n\n');
  }

  String _itemKey(HadithItem hadith) {
    return 'hadith:${hadith.bookId}:${hadith.hadithNumber}';
  }
}

class _HadithSheetSurface extends StatelessWidget {
  const _HadithSheetSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      margin: const EdgeInsets.all(12),
      padding: padding,
      height: height,
      radius: QuranTheme.radiusSheet,
      prominent: true,
      child: child,
    );
  }
}

class _BookSummary extends StatelessWidget {
  const _BookSummary({required this.book});

  final HadithBook book;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            book.arabicName,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w800,
            ),
          ),
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
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final chapter = state.chapters[index];
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
        itemCount: state.chapters.length,
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
    required this.translationResource,
    required this.onTap,
  });

  final HadithItem hadith;
  final QuranThemeState themeState;
  final bool selected;
  final bool showTranslation;
  final bool translationAvailable;
  final String languageLabel;
  final QuranTranslationResource? translationResource;
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
            ],
          ),
          if (hadith.arabic.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            LibraryArabicText(
              text: hadith.arabic,
              themeState: themeState,
              selected: selected,
            ),
          ],
          if (showTranslation) ...[
            const SizedBox(height: 10),
            if (translationAvailable && hadith.translation.trim().isNotEmpty)
              LibraryTranslationBody(
                text: hadith.translation,
                themeState: themeState,
                resource: translationResource,
              )
            else
              LibraryTranslationUnavailable(languageLabel: languageLabel),
          ],
          if (hadith.grade.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              hadith.grade,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: QuranTheme.subText(context, 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
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
          Icon(
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
