import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';

class QuranTranslationManagerPage extends StatefulWidget {
  const QuranTranslationManagerPage({super.key});

  @override
  State<QuranTranslationManagerPage> createState() =>
      _QuranTranslationManagerPageState();
}

class _QuranTranslationManagerPageState
    extends State<QuranTranslationManagerPage> {
  late final QuranTranslationRepository _repository;
  late final QuranMultiTranslationRepository _multiRepository;
  late Future<_ManagerData> _future;
  String _query = '';
  int _surahNumber = 1;
  int? _downloadingResourceId;
  QuranTranslationDownloadProgress? _progress;

  @override
  void initState() {
    super.initState();
    _repository = getIt<QuranTranslationRepository>();
    _multiRepository = _repository as QuranMultiTranslationRepository;
    _future = _load();
  }

  Future<_ManagerData> _load() async {
    final values = await Future.wait<Object>([
      _repository.translationLanguages(),
      _multiRepository.selectedTranslations(),
      getIt<QuranRepository>().getSurahs(),
    ]);
    final languages = values[0] as List<QuranTranslationLanguage>;
    final resources = <int, QuranTranslationResource>{};
    for (final language in languages) {
      for (final resource in language.availableResources) {
        resources[resource.id] = resource;
      }
    }
    final statuses = <int, QuranTranslationPackStatus>{};
    for (final resource in resources.values) {
      statuses[resource.id] = await _multiRepository.translationPackStatus(
        resource.id,
      );
    }
    return _ManagerData(
      resources: resources.values.toList()
        ..sort((a, b) {
          final language = a.displayLanguage.compareTo(b.displayLanguage);
          return language == 0 ? a.name.compareTo(b.name) : language;
        }),
      selected: values[1] as List<QuranTranslationResource>,
      surahs: values[2] as List<QuranSurah>,
      statuses: statuses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quranTranslationsTitle),
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: FutureBuilder<_ManagerData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorView(
              title: 'Translations unavailable',
              message: 'Translation packs could not be loaded.',
              onRetry: _reload,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final selectedIds = data.selected.map((item) => item.id).toList();
          final normalized = _query.trim().toLowerCase();
          final visible = data.resources
              .where((resource) {
                return normalized.isEmpty ||
                    '${resource.displayLanguage} ${resource.displayEndonym} '
                            '${resource.name} ${resource.translator}'
                        .toLowerCase()
                        .contains(normalized);
              })
              .toList(growable: false);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList.list(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.translationCompareTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          Text(l10n.translationCompareDescription),
                          if (data.selected.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            for (
                              var index = 0;
                              index < data.selected.length;
                              index++
                            )
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: AppIcon(
                                  index == 0
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.compare_arrows_rounded,
                                ),
                                title: Text(data.selected[index].name),
                                subtitle: Text(
                                  '${data.selected[index].displayEndonym} • '
                                  '${index == 0 ? l10n.translationPrimary : l10n.translationComparison}',
                                ),
                                trailing: index == 0
                                    ? null
                                    : IconButton(
                                        tooltip: l10n.translationMakePrimary,
                                        onPressed:
                                            _downloadingResourceId != null
                                            ? null
                                            : () => _makePrimary(
                                                data.selected,
                                                data.selected[index],
                                              ),
                                        icon: const AppIcon(
                                          Icons.vertical_align_top_rounded,
                                        ),
                                      ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: l10n.translationSearchHint,
                        prefixIcon: const AppIcon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: _surahNumber,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: InputDecoration(
                        labelText: l10n.translationSurahPack,
                        prefixIcon: const AppIcon(Icons.download_outlined),
                      ),
                      items: [
                        for (final surah in data.surahs)
                          DropdownMenuItem(
                            value: surah.number,
                            child: Text(
                              '${surah.number}. ${surah.englishName}',
                            ),
                          ),
                      ],
                      onChanged: _downloadingResourceId != null
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _surahNumber = value);
                              }
                            },
                    ),
                    if (_downloadingResourceId != null) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _progress?.percent),
                      const SizedBox(height: 5),
                      Text(
                        _progress == null
                            ? 'Starting download'
                            : '${_progress!.completedChapters} of '
                                  '${_progress!.totalChapters} Surah packs',
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No matching translations.'),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final resource = visible[index];
                    return Padding(
                      key: ValueKey(resource.id),
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _TranslationResourceCard(
                        resource: resource,
                        status:
                            data.statuses[resource.id] ??
                            const QuranTranslationPackStatus(
                              downloadedSurahs: [],
                              cachedBytes: 0,
                            ),
                        selected: selectedIds.contains(resource.id),
                        primary:
                            selectedIds.isNotEmpty &&
                            selectedIds.first == resource.id,
                        busy: _downloadingResourceId != null,
                        onToggleSelected: () =>
                            _toggleSelected(selectedIds, resource),
                        onDownloadSurah: () => _downloadSurah(resource),
                        onDownloadFull: () => _downloadFull(resource),
                        onDelete: () => _delete(resource),
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Offline cache and sources'),
                    children: [
                      Text(
                        'Downloaded Quran Foundation resources have a seven-day cache '
                        'window. Each edition keeps its translator, language, direction, '
                        'source, and license attribution. Religious translations are '
                        'never machine generated by this app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSelected(
    List<int> selectedIds,
    QuranTranslationResource resource,
  ) async {
    final next = [...selectedIds];
    if (next.contains(resource.id)) {
      next.remove(resource.id);
    } else {
      if (next.length >= 3) {
        _message('You can compare up to three translations.');
        return;
      }
      next.add(resource.id);
    }
    await _multiRepository.setSelectedTranslations(next);
    _reload();
  }

  Future<void> _makePrimary(
    List<QuranTranslationResource> selected,
    QuranTranslationResource resource,
  ) async {
    await _multiRepository.setSelectedTranslations([
      resource.id,
      ...selected
          .where((item) => item.id != resource.id)
          .map((item) => item.id),
    ]);
    _reload();
  }

  Future<void> _downloadSurah(QuranTranslationResource resource) async {
    setState(() {
      _downloadingResourceId = resource.id;
      _progress = null;
    });
    try {
      await for (final progress in _multiRepository.downloadSurahTranslation(
        resource.id,
        _surahNumber,
      )) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
      final failed = _progress?.failedChapters ?? 1;
      _message(
        failed == 0
            ? 'Surah $_surahNumber downloaded for ${resource.displayEndonym}.'
            : 'Could not download this Surah pack.',
      );
    } catch (_) {
      _message('Could not download this Surah pack. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _downloadingResourceId = null);
        _reload();
      }
    }
  }

  Future<void> _downloadFull(QuranTranslationResource resource) async {
    setState(() {
      _downloadingResourceId = resource.id;
      _progress = null;
    });
    try {
      await for (final progress in _repository.downloadFullTranslation(
        resource.id,
      )) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
      _message(
        _progress?.isComplete == true
            ? '${resource.displayEndonym} full pack downloaded.'
            : 'Download paused with ${_progress?.failedChapters ?? 0} failed packs. Retry resumes completed Surahs.',
      );
    } catch (_) {
      _message('Download interrupted. Retry to resume completed Surahs.');
    } finally {
      if (mounted) {
        setState(() => _downloadingResourceId = null);
        _reload();
      }
    }
  }

  Future<void> _delete(QuranTranslationResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text('Delete ${resource.name}?'),
        content: const Text(
          'Downloaded Surah packs for this edition will be removed. Notes and '
          'other Quran data remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete packs'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _multiRepository.deleteTranslation(resource.id);
      _reload();
    }
  }

  void _reload() {
    if (mounted) {
      setState(() => _future = _load());
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ManagerData {
  const _ManagerData({
    required this.resources,
    required this.selected,
    required this.surahs,
    required this.statuses,
  });

  final List<QuranTranslationResource> resources;
  final List<QuranTranslationResource> selected;
  final List<QuranSurah> surahs;
  final Map<int, QuranTranslationPackStatus> statuses;
}

class _TranslationResourceCard extends StatelessWidget {
  const _TranslationResourceCard({
    required this.resource,
    required this.status,
    required this.selected,
    required this.primary,
    required this.busy,
    required this.onToggleSelected,
    required this.onDownloadSurah,
    required this.onDownloadFull,
    required this.onDelete,
  });

  final QuranTranslationResource resource;
  final QuranTranslationPackStatus status;
  final bool selected;
  final bool primary;
  final bool busy;
  final VoidCallback onToggleSelected;
  final VoidCallback onDownloadSurah;
  final VoidCallback onDownloadFull;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${resource.displayEndonym} • ${resource.displayLanguage}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(resource.name),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: busy ? null : (_) => onToggleSelected(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${status.downloadedSurahs.length}/114 Surah packs • '
            '${_size(status.cachedBytes)} cached',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
          ),
          if (primary)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(l10n.translationPrimary),
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Edition details'),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${l10n.translationTranslator}: ${resource.translator}'),
              Text(
                'Script ${resource.resolvedScript} • '
                '${resource.isRtl ? 'RTL' : 'LTR'} • '
                'Resource ${resource.id}',
              ),
              Text(
                resource.publisher.isEmpty
                    ? l10n.translationPublisherUnavailable
                    : 'Publisher: ${resource.publisher}',
              ),
              Text('${l10n.translationLicense}: ${resource.license}'),
              Text('${l10n.translationSource}: ${resource.sourceUrl}'),
              Text(
                resource.revision.isEmpty
                    ? l10n.translationRevisionUnavailable
                    : 'Revision: ${resource.revision}',
              ),
              const SizedBox(height: 8),
              Text(
                '${status.downloadedSurahs.length}/114 Surah packs • '
                '${_size(status.cachedBytes)} cached'
                '${status.downloadedAt == null ? '' : ' • saved ${DateFormat.yMMMd().format(status.downloadedAt!)}'}'
                '${status.expiresAt == null ? '' : ' • refresh ${DateFormat.yMMMd().format(status.expiresAt!)}'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: busy ? null : onDownloadSurah,
                icon: const AppIcon(Icons.download_outlined),
                label: Text(l10n.translationDownloadSurah),
              ),
              OutlinedButton(
                onPressed: busy ? null : onDownloadFull,
                child: Text(
                  status.isFullDownload
                      ? l10n.translationRefreshAll
                      : l10n.translationGetAll,
                ),
              ),
              if (status.hasAnyDownload)
                IconButton(
                  tooltip: l10n.translationDeletePacks,
                  onPressed: busy ? null : onDelete,
                  icon: const AppIcon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
