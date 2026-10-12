import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_translation_repository.dart';

class QuranTranslationPicker extends StatefulWidget {
  const QuranTranslationPicker({
    super.key,
    required this.repository,
    this.currentResource,
    this.languagesOnly = false,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource? currentResource;
  final bool languagesOnly;

  @override
  State<QuranTranslationPicker> createState() => _QuranTranslationPickerState();
}

class _QuranTranslationPickerState extends State<QuranTranslationPicker> {
  final _queryController = TextEditingController();
  final _cacheChecks = <int, Future<bool>>{};
  late Future<List<QuranTranslationLanguage>> _languages;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _languages = widget.repository.translationLanguages();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Select translation',
      scrollableChild: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _queryController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: widget.languagesOnly
                  ? 'Search language'
                  : 'Search language or translator',
              prefixIcon: const AppIcon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FutureBuilder<List<QuranTranslationLanguage>>(
              future: _languages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load translations.'),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _languages = widget.repository
                                .translationLanguages();
                          }),
                          icon: const AppIcon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entries =
                    <
                      ({
                        QuranTranslationLanguage language,
                        QuranTranslationResource resource,
                      })
                    >[
                      for (final language in snapshot.data!)
                        for (final resource
                            in _query.isEmpty || widget.languagesOnly
                                ? [language.defaultResource]
                                : language.availableResources)
                          if (_matches(language, resource))
                            (language: language, resource: resource),
                    ];
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No translations match your search.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final resource = entry.resource;
                    final selected = widget.languagesOnly
                        ? widget.currentResource?.languageName ==
                              resource.languageName
                        : widget.currentResource?.id == resource.id;
                    final cache = _cacheChecks.putIfAbsent(
                      resource.id,
                      () => widget.repository.hasFullTranslation(resource.id),
                    );
                    return FutureBuilder<bool>(
                      future: cache,
                      builder: (context, cacheSnapshot) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        selected: selected,
                        title: Text(entry.language.displayName),
                        subtitle: Text(
                          [
                                resource.displayEndonym,
                                if (!widget.languagesOnly) resource.name,
                                if (!widget.languagesOnly) resource.translator,
                              ]
                              .where((value) => value.isNotEmpty)
                              .toSet()
                              .join(' \u00b7 '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: selected
                                  ? 'Selected'
                                  : cacheSnapshot.data == true
                                  ? 'Downloaded'
                                  : 'Download required',
                              child: AppIcon(
                                selected
                                    ? Icons.check_rounded
                                    : cacheSnapshot.data == true
                                    ? Icons.offline_pin_outlined
                                    : Icons.download_rounded,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : QuranTheme.subText(context),
                              ),
                            ),
                            if (!widget.languagesOnly &&
                                _query.isEmpty &&
                                entry.language.availableResources.length > 1)
                              IconButton(
                                tooltip: 'Choose translator',
                                icon: const AppIcon(Icons.tune_rounded),
                                onPressed: () => _chooseEdition(entry.language),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(resource),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseEdition(QuranTranslationLanguage language) async {
    final selected = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSheet(
        title: '${language.displayName} translation',
        scrollableChild: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: language.availableResources.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final resource = language.availableResources[index];
            return ListTile(
              title: Text(resource.name),
              subtitle: Text(resource.translator),
              trailing: resource.id == language.defaultResource.id
                  ? const AppIcon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(context).pop(resource),
            );
          },
        ),
      ),
    );
    if (selected != null && mounted) Navigator.of(context).pop(selected);
  }

  bool _matches(
    QuranTranslationLanguage language,
    QuranTranslationResource resource,
  ) {
    if (_query.isEmpty) return true;
    if (widget.languagesOnly) {
      return '${language.displayName} ${resource.displayEndonym} ${resource.languageName}'
          .toLowerCase()
          .contains(_query);
    }
    return '${language.displayName} ${resource.displayEndonym} ${resource.languageName} '
            '${resource.name} ${resource.translator} ${resource.publisher} ${resource.license}'
        .toLowerCase()
        .contains(_query);
  }
}
