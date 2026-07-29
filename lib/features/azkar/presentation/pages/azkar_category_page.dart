import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
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
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/dhikr_item.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../bloc/azkar_library_cubit.dart';
import '../bloc/azkar_library_state.dart';

class AzkarCategoryPage extends StatelessWidget {
  const AzkarCategoryPage({
    super.key,
    required this.categoryId,
    this.initialItemId,
  });

  final String categoryId;
  final String? initialItemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AzkarLibraryCubit(repository: getIt<AzkarRepository>())
            ..load(categoryId: categoryId),
      child: _AzkarCategoryView(
        categoryId: categoryId,
        initialItemId: initialItemId,
      ),
    );
  }
}

class _AzkarCategoryView extends StatefulWidget {
  const _AzkarCategoryView({required this.categoryId, this.initialItemId});

  final String categoryId;
  final String? initialItemId;

  @override
  State<_AzkarCategoryView> createState() => _AzkarCategoryViewState();
}

class _AzkarCategoryViewState extends State<_AzkarCategoryView> {
  late final ScrollController _scrollController;
  late final TextEditingController _jumpController;
  late final SettingsStore _settingsStore;
  late final LibraryUserDataStore _userDataStore;
  bool _showTranslation = true;
  bool _showTransliteration = true;
  QuranTranslationResource? _selectedTranslation;
  LibraryLanguageSelection _language = libraryLanguageFromQuranTranslation(
    null,
  );
  bool _translationAvailable = true;
  String? _selectedItemKey;
  int _currentNumber = 1;
  final _repeatProgress = <String, int>{};

  String get _scopeKey => 'azkar:${widget.categoryId}';

  @override
  void initState() {
    super.initState();
    _settingsStore = getIt<SettingsStore>();
    _userDataStore = getIt<LibraryUserDataStore>();
    _showTranslation = _settingsStore.libraryTranslationEnabled;
    _showTransliteration = _settingsStore.libraryTransliterationEnabled;
    _scrollController = ScrollController()..addListener(_onScroll);
    _jumpController = TextEditingController();
    _loadContentLanguage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _jumpController.dispose();
    super.dispose();
  }

  Future<void> _loadContentLanguage() async {
    final translationRepository = getIt<QuranTranslationRepository>();
    final previousQuranSelection = await translationRepository
        .selectedTranslation();
    var code = _settingsStore.azkarLanguageCodeOrNull;
    if (code == null) {
      code =
          libraryLanguageFromQuranTranslation(
            previousQuranSelection,
          ).azkarCode ??
          'en';
      await _settingsStore.setAzkarLanguageCode(code);
    }
    QuranTranslationResource? displayResource;
    final languages = await translationRepository.translationLanguages();
    for (final language in languages) {
      final resource = language.defaultResource;
      if (libraryLanguageFromQuranTranslation(resource).azkarCode == code) {
        displayResource = resource;
        break;
      }
    }
    final language = libraryLanguageFromCode(code, resource: displayResource);
    final available = await getIt<AzkarRepository>().hasFullTranslation(code);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTranslation = displayResource;
      _language = language;
      _translationAvailable = available;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final dhikr = context.read<AzkarLibraryCubit>().state.dhikr;
    if (dhikr.isEmpty || _scrollController.position.maxScrollExtent <= 0) {
      return;
    }
    final position = _scrollController.position;
    final index =
        ((position.pixels / position.maxScrollExtent) * (dhikr.length - 1))
            .round()
            .clamp(0, dhikr.length - 1)
            .toInt();
    final item = dhikr[index];
    _currentNumber = item.itemSortOrder == 0 ? index + 1 : item.itemSortOrder;
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
            title: BlocBuilder<AzkarLibraryCubit, AzkarLibraryState>(
              buildWhen: (previous, current) =>
                  previous.categories != current.categories ||
                  previous.selectedCategoryId != current.selectedCategoryId,
              builder: (context, state) {
                final category = _selectedCategory(state);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showNavigationMenu(state),
                  child: Text(category?.englishName ?? 'Azkar'),
                );
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Reader settings',
                onPressed: _showSettings,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          body: BlocBuilder<AzkarLibraryCubit, AzkarLibraryState>(
            builder: (context, state) {
              if (state.status == AzkarLibraryStatus.failure) {
                return AppErrorView(
                  title: 'Azkar could not be loaded',
                  message: state.errorMessage ?? 'Please try again.',
                  onRetry: () => context.read<AzkarLibraryCubit>().load(
                    categoryId: widget.categoryId,
                  ),
                );
              }
              if (state.status == AzkarLibraryStatus.loading &&
                  state.dhikr.isEmpty) {
                return const AppLoadingView(label: 'Loading azkar');
              }
              _selectInitialItemIfNeeded(state);
              final category = _selectedCategory(state);
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
                        if (category != null)
                          _CategorySummary(category: category),
                        const SizedBox(height: 14),
                        if (state.status == AzkarLibraryStatus.empty)
                          const _AzkarEmptyState()
                        else
                          for (final item in state.dhikr)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DhikrReaderCard(
                                item: item,
                                themeState: themeState,
                                selected: _selectedItemKey == _itemKey(item),
                                showTranslation: _showTranslation,
                                translationAvailable: _translationAvailable,
                                languageLabel: _language.label,
                                translationResource: _selectedTranslation,
                                showTransliteration: _showTransliteration,
                                repeatProgress:
                                    _repeatProgress[_itemKey(item)] ?? 0,
                                onRepeat: () => _incrementRepeat(item),
                                onTap: () => _selectDhikr(item),
                              ),
                            ),
                      ],
                    ),
                  ),
                  if (state.dhikr.isNotEmpty)
                    PositionedDirectional(
                      end: 8,
                      top: MediaQuery.sizeOf(context).height * 0.38,
                      child: _ProgressPill(label: 'Dhikr $_currentNumber'),
                    ),
                  if (_selectedItem(state) != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LibraryReaderActionBar(
                        title: _selectedItem(state)!.title.isEmpty
                            ? _selectedItem(state)!.reference
                            : _selectedItem(state)!.title,
                        isBookmarked: _userDataStore.isBookmarked(
                          _itemKey(_selectedItem(state)!),
                        ),
                        onBookmark: () =>
                            _toggleBookmark(_selectedItem(state)!),
                        onNote: () => _editNote(_selectedItem(state)!),
                        onCopy: () => _copyDhikr(_selectedItem(state)!),
                        onShare: () => _copyDhikr(
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

  void _selectInitialItemIfNeeded(AzkarLibraryState state) {
    if (_selectedItemKey != null || state.dhikr.isEmpty) {
      return;
    }
    final initial = widget.initialItemId;
    final lastRead = _userDataStore.lastReadFor(_scopeKey);
    final target = initial?.isNotEmpty == true ? initial : lastRead;
    if (target == null || target.isEmpty) {
      return;
    }
    for (final item in state.dhikr) {
      if (item.id == target || _itemKey(item) == target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _selectDhikr(item);
          }
        });
        return;
      }
    }
  }

  AzkarCategory? _selectedCategory(AzkarLibraryState state) {
    for (final category in state.categories) {
      if (category.id == widget.categoryId ||
          category.id == state.selectedCategoryId) {
        return category;
      }
    }
    return null;
  }

  void _selectDhikr(DhikrItem item) {
    final key = _itemKey(item);
    setState(() {
      _selectedItemKey = key;
      _currentNumber = item.itemSortOrder;
    });
    _userDataStore.saveLastRead(scopeKey: _scopeKey, itemKey: key);
  }

  DhikrItem? _selectedItem(AzkarLibraryState state) {
    final key = _selectedItemKey;
    if (key == null) {
      return null;
    }
    for (final item in state.dhikr) {
      if (_itemKey(item) == key) {
        return item;
      }
    }
    return null;
  }

  Future<void> _showNavigationMenu(AzkarLibraryState state) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Azkar navigation',
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
                                _selectedCategory(state)?.englishName ??
                                    'Azkar',
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
                          controller: _jumpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jump to item',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                          onSubmitted: (value) {
                            Navigator.of(dialogContext).pop();
                            _jumpToItem(value, state.dhikr);
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  _jumpToItem(
                                    _jumpController.text,
                                    state.dhikr,
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Go'),
                              ),
                            ),
                          ],
                        ),
                        if (state.categories.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final category = state.categories[index];
                                return ChoiceChip(
                                  label: Text(category.englishName),
                                  selected: category.id == widget.categoryId,
                                  onSelected: (_) {
                                    Navigator.of(dialogContext).pop();
                                    context.go(
                                      AppRoutes.azkarCategoryPath(category.id),
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemCount: state.categories.length,
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

  void _jumpToItem(String value, List<DhikrItem> dhikr) {
    final number = int.tryParse(value.trim());
    if (number == null || dhikr.isEmpty) {
      return;
    }
    final index = (number - 1).clamp(0, dhikr.length - 1).toInt();
    _selectDhikr(dhikr[index]);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        (_scrollController.position.maxScrollExtent / dhikr.length) * index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
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
          showTransliteration: _showTransliteration,
          onTransliterationChanged: (value) {
            setState(() => _showTransliteration = value);
            _settingsStore.setLibraryTransliterationEnabled(value);
          },
        );
      },
    );
  }

  Future<void> _showTranslationPicker() async {
    final repository = getIt<AzkarRepository>();
    final languages = {
      'en',
      ...await repository.availableTranslationLanguages(),
    }.toList()..sort();
    if (!mounted) {
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
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
                  selected: _language.azkarCode == language,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(language),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    if (!await repository.hasFullTranslation(selected)) {
      final downloaded = await _downloadAzkarTranslation(repository, selected);
      if (downloaded != true) {
        return;
      }
    }
    await _settingsStore.setAzkarLanguageCode(selected);
    await _loadContentLanguage();
  }

  Future<bool?> _downloadAzkarTranslation(
    AzkarRepository repository,
    String languageCode,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StreamBuilder(
          stream: repository.downloadTranslation(languageCode),
          builder: (context, snapshot) {
            final progress = snapshot.data;
            if (progress?.isComplete == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
              });
            }
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Downloading ${libraryLanguageLabel(languageCode)}'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress?.percent),
                  const SizedBox(height: 8),
                  Text(
                    progress == null
                        ? 'Preparing download'
                        : '${progress.completedItems} of ${progress.totalItems}',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _incrementRepeat(DhikrItem item) {
    final key = _itemKey(item);
    final current = _repeatProgress[key] ?? 0;
    setState(() {
      _repeatProgress[key] = current >= item.repeatCount ? 0 : current + 1;
    });
  }

  Future<void> _toggleBookmark(DhikrItem item) async {
    await _userDataStore.toggleBookmark(_itemKey(item));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editNote(DhikrItem item) async {
    final controller = TextEditingController(
      text: _userDataStore.noteFor(_itemKey(item)),
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title.isEmpty ? 'Dhikr note' : item.title),
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
      await _userDataStore.saveNote(_itemKey(item), note);
    }
  }

  Future<void> _copyDhikr(DhikrItem item, {bool shareIntent = false}) async {
    await Clipboard.setData(ClipboardData(text: _plainText(item)));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(shareIntent ? 'Copied to share' : 'Copied')),
    );
  }

  void _showSourceSheet(DhikrItem item) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
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
            Text(item.reference),
          ],
        ),
      ),
    );
  }

  void _showDetailsSheet(DhikrItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              item.title.isEmpty ? item.reference : item.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(item.arabic, textDirection: TextDirection.rtl),
            if (item.translation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.translation),
            ],
            if (item.benefit.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.benefit),
            ],
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.notes),
            ],
            const SizedBox(height: 12),
            Text('Repeat ${item.repeatCount}x'),
          ],
        ),
      ),
    );
  }

  String _plainText(DhikrItem item) {
    return [
      if (item.title.isNotEmpty) item.title,
      item.arabic,
      if (_showTransliteration && item.transliteration.isNotEmpty)
        item.transliteration,
      if (_showTranslation && _translationAvailable) item.translation,
      item.reference,
    ].where((line) => line.trim().isNotEmpty).join('\n\n');
  }

  String _itemKey(DhikrItem item) => item.id.startsWith('azkar:')
      ? item.id
      : 'azkar:${item.categoryId}:${item.id}';
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({required this.category});

  final AzkarCategory category;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            category.arabicName,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.englishName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${category.itemCount} items',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DhikrReaderCard extends StatelessWidget {
  const _DhikrReaderCard({
    required this.item,
    required this.themeState,
    required this.selected,
    required this.showTranslation,
    required this.translationAvailable,
    required this.languageLabel,
    required this.translationResource,
    required this.showTransliteration,
    required this.repeatProgress,
    required this.onRepeat,
    required this.onTap,
  });

  final DhikrItem item;
  final QuranThemeState themeState;
  final bool selected;
  final bool showTranslation;
  final bool translationAvailable;
  final String languageLabel;
  final QuranTranslationResource? translationResource;
  final bool showTransliteration;
  final int repeatProgress;
  final VoidCallback onRepeat;
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
                  item.title.isEmpty ? item.reference : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _RepeatButton(
                count: item.repeatCount,
                progress: repeatProgress,
                onTap: onRepeat,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LibraryArabicText(
            text: item.arabic,
            themeState: themeState,
            selected: selected,
          ),
          if (showTransliteration &&
              item.transliteration.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.transliteration,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.72),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (showTranslation) ...[
            const SizedBox(height: 8),
            if (translationAvailable && item.translation.trim().isNotEmpty)
              LibraryTranslationBody(
                text: item.translation,
                themeState: themeState,
                resource: translationResource,
              )
            else
              LibraryTranslationUnavailable(languageLabel: languageLabel),
          ],
          if (selected) ...[
            const SizedBox(height: 8),
            Text(
              item.reference,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({
    required this.count,
    required this.progress,
    required this.onTap,
  });

  final int count;
  final int progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: QuranTheme.softFill(context, primary),
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        ),
        child: Text(
          '$progress/$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
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

class _AzkarEmptyState extends StatelessWidget {
  const _AzkarEmptyState();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('No azkar found.')),
        ],
      ),
    );
  }
}
