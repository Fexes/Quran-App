import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_tafsir.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_tafsir_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/quran_translation_picker.dart';
import '../../data/repositories/quran_audio_download_repository.dart';
import '../../data/services/quran_audio_download_service.dart';
import '../../domain/entities/quran_audio_download_item.dart';
import '../../domain/services/quran_translation_audio_selector.dart';
import '../cubit/quran_audio_downloads_cubit.dart';
import '../cubit/quran_audio_downloads_state.dart';
import '../widgets/quran_download_progress_badge.dart';
import '../widgets/quran_floating_audio_player.dart';
import '../widgets/quran_reciter_picker.dart';

String quranTafsirUnavailableLabel(QuranTranslationResource translation) {
  return 'No tafsir available for ${translation.displayLanguage}';
}

class _TranslationCacheStatus {
  const _TranslationCacheStatus({
    required this.downloaded,
    required this.expiresAt,
  });

  final bool downloaded;
  final DateTime? expiresAt;
}

Future<_TranslationCacheStatus> _translationCacheStatus(
  QuranTranslationRepository repository,
  int resourceId,
) async {
  final downloaded = await repository.hasFullTranslation(resourceId);
  final expiresAt =
      downloaded && repository is QuranTranslationCacheMetadataRepository
      ? await (repository as QuranTranslationCacheMetadataRepository)
            .fullTranslationExpiresAt(resourceId)
      : null;
  return _TranslationCacheStatus(downloaded: downloaded, expiresAt: expiresAt);
}

String _translationSourceLabel(
  BuildContext context,
  _TranslationCacheStatus? status,
) {
  final expiresAt = status?.expiresAt;
  if (status?.downloaded == true && expiresAt != null) {
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(expiresAt.toLocal());
    return 'Source: Quran Foundation. Offline cache refresh due by $date. '
        'Translation edition rights also apply.';
  }
  return 'Source: Quran Foundation. Provider terms and translation edition '
      'rights apply. Offline data is cached for up to 7 days.';
}

class QuranDownloadsPage extends StatelessWidget {
  const QuranDownloadsPage({super.key, this.showTranslations = false});

  final bool showTranslations;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuranAudioDownloadsCubit(
        quranRepository: getIt<QuranRepository>(),
        translationRepository: getIt<QuranTranslationRepository>(),
        downloadRepository: getIt<QuranAudioDownloadRepository>(),
        downloadService: getIt<QuranAudioDownloadService>(),
        settingsStore: getIt<SettingsStore>(),
        initialAudioType: showTranslations
            ? QuranAudioDownloadAudioType.translation
            : QuranAudioDownloadAudioType.arabic,
      )..load(),
      child: const _QuranDownloadsView(),
    );
  }
}

class _QuranDownloadsView extends StatelessWidget {
  const _QuranDownloadsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: Stack(
        children: [
          BlocBuilder<QuranAudioDownloadsCubit, QuranAudioDownloadsState>(
            builder: (context, state) {
              return switch (state.status) {
                QuranAudioDownloadsStatus.initial ||
                QuranAudioDownloadsStatus.loading => const AppLoadingView(
                  label: 'Loading downloads',
                ),
                QuranAudioDownloadsStatus.failure => AppErrorView(
                  title: 'Downloads failed',
                  message: state.errorMessage ?? 'Could not load downloads.',
                  onRetry: context.read<QuranAudioDownloadsCubit>().load,
                ),
                QuranAudioDownloadsStatus.success => _DownloadsContent(
                  state: state,
                ),
              };
            },
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: QuranFloatingAudioPlayer(bottomInset: 16),
          ),
        ],
      ),
    );
  }
}

class _DownloadsContent extends StatelessWidget {
  const _DownloadsContent({required this.state});

  final QuranAudioDownloadsState state;

  @override
  Widget build(BuildContext context) {
    final groups = switch (state.filter) {
      QuranAudioDownloadsFilter.surahs => state.surahGroups,
      QuranAudioDownloadsFilter.active => state.activeGroups,
      QuranAudioDownloadsFilter.downloaded => state.downloadedGroups,
    };
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverList.list(
            children: [
              _DownloadsHeader(state: state),
              const Divider(height: 28),
              _AudioTypeSelector(state: state),
              const SizedBox(height: 12),
              _ReciterSelector(state: state),
              const SizedBox(height: 12),
              _DownloadsFilters(state: state),
              const SizedBox(height: 12),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    _emptyMessage(state.filter),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) => _DownloadGroupTile(
              key: ValueKey(groups[index].id),
              group: groups[index],
              filter: state.filter,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: QuranFloatingAudioPlayer.scrollInset(context),
          ),
        ),
      ],
    );
  }

  String _emptyMessage(QuranAudioDownloadsFilter filter) {
    if (filter == QuranAudioDownloadsFilter.surahs &&
        state.audioType == QuranAudioDownloadAudioType.translation) {
      if (state.selectedTranslation == null) {
        return 'Select a translation language before downloading translation audio.';
      }
      return 'No audio available for ${state.selectedTranslation!.displayLanguage} language.';
    }
    return switch (filter) {
      QuranAudioDownloadsFilter.surahs => 'No reciter selected.',
      QuranAudioDownloadsFilter.active => 'No active downloads.',
      QuranAudioDownloadsFilter.downloaded => 'No downloaded audio yet.',
    };
  }
}

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader({required this.state});

  final QuranAudioDownloadsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranAudioDownloadsCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderStat(
                icon: Icons.offline_pin_rounded,
                label: 'Stored',
                value: _formatBytes(state.storageUsedBytes),
              ),
              const SizedBox(width: 10),
              _HeaderStat(
                icon: Icons.downloading_rounded,
                label: 'Active',
                value: state.activeDownloadCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.wifiOnlyLargeDownloads,
            onChanged: cubit.setWifiOnlyLargeDownloads,
            title: const Text('Wi-Fi only for full Quran downloads'),
            subtitle: const Text('Surah downloads can still use cellular.'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: state.selectedArabicReciter == null
                  ? null
                  : () => _confirmCompleteOffline(context),
              icon: const AppIcon(Icons.offline_bolt_rounded),
              label: const Text('Complete Offline'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCompleteOffline(BuildContext context) async {
    final arabic = state.selectedArabicReciter;
    if (arabic == null) {
      return;
    }
    final translation = state.selectedTranslationReciter;
    final translationLine = translation == null
        ? 'No translation audio will be included because no matching translation voice is selected.'
        : 'Translation audio: ${translation.name}.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Download complete offline audio?'),
        content: Text(
          'Arabic audio: ${arabic.name}.\n'
          '$translationLine\n\n'
          'This can queue thousands of files and may take time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().downloadCompleteOffline();
    }
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Row(
        children: [
          AppIcon(icon, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioTypeSelector extends StatelessWidget {
  const _AudioTypeSelector({required this.state});

  final QuranAudioDownloadsState state;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QuranAudioDownloadAudioType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: QuranAudioDownloadAudioType.arabic,
          icon: AppIcon(Icons.menu_book_rounded),
          label: Text('Arabic'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadAudioType.translation,
          icon: AppIcon(Icons.translate_rounded),
          label: Text('Translation'),
        ),
      ],
      selected: {state.audioType},
      onSelectionChanged: (selection) {
        context.read<QuranAudioDownloadsCubit>().setAudioType(selection.first);
      },
    );
  }
}

class _ReciterSelector extends StatelessWidget {
  const _ReciterSelector({required this.state});

  final QuranAudioDownloadsState state;

  @override
  Widget build(BuildContext context) {
    final reciter = state.selectedReciter;
    final isTranslation =
        state.audioType == QuranAudioDownloadAudioType.translation;
    final canChoose = state.reciters.isNotEmpty;
    final title = _title(reciter, isTranslation);
    final subtitle = _subtitle(reciter, isTranslation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isTranslation) ...[
          _TranslationLanguageSelector(
            selectedTranslation: state.selectedTranslation,
          ),
          const SizedBox(height: 10),
          if (state.selectedTranslation != null) ...[
            _TranslationTextDownloadActions(
              translation: state.selectedTranslation!,
            ),
            const SizedBox(height: 10),
          ],
        ],
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: reciter == null
              ? CircleAvatar(
                  radius: 21,
                  backgroundColor: QuranTheme.softFill(
                    context,
                    Theme.of(context).colorScheme.primary,
                  ),
                  child: AppIcon(
                    isTranslation
                        ? Icons.translate_rounded
                        : Icons.record_voice_over_rounded,
                  ),
                )
              : QuranReciterAvatar(reciter: reciter, size: 42),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: canChoose ? const AppIcon(Icons.chevron_right_rounded) : null,
          onTap: canChoose
              ? () => _showReciterSheet(context, state.reciters)
              : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: state.selectedReciter == null
                    ? null
                    : () => _confirmFullDownload(context),
                icon: const AppIcon(Icons.download_for_offline_rounded),
                label: Text('Download Full ${state.audioTypeLabel}'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip:
                  'Delete selected ${state.audioTypeLabel.toLowerCase()} audio',
              onPressed: state.selectedReciter == null
                  ? null
                  : () => _confirmDeleteSelected(context),
              icon: const AppIcon(Icons.delete_sweep_rounded),
            ),
          ],
        ),
      ],
    );
  }

  String _title(QuranAudioReciter? reciter, bool isTranslation) {
    if (reciter != null) {
      return reciter.name;
    }
    if (!isTranslation) {
      return 'Choose reciter';
    }
    if (state.selectedTranslation == null) {
      return quranTranslationAudioLanguageLabel(null);
    }
    return 'No translation audio available';
  }

  String _subtitle(QuranAudioReciter? reciter, bool isTranslation) {
    if (reciter != null) {
      final prefix = isTranslation
          ? 'Translation audio'
          : reciter.qualityLabel ?? 'Audio';
      return [prefix, quranAudioProviderLabel(reciter.provider)].join(' • ');
    }
    if (!isTranslation) {
      return 'Download audio by reciter';
    }
    final language = state.selectedTranslation?.displayLanguage;
    if (language == null || language.isEmpty) {
      return 'Select a translation language.';
    }
    return 'No audio available for $language language.';
  }

  Future<void> _showReciterSheet(
    BuildContext context,
    List<QuranAudioReciter> reciters,
  ) async {
    final selected = await showQuranReciterPickerSheet(
      context,
      reciters: reciters,
      selectedReciterId: state.selectedReciter?.id,
      title: state.audioType == QuranAudioDownloadAudioType.translation
          ? 'Choose translation voice'
          : 'Choose reciter',
    );
    if (selected != null && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().selectReciter(selected);
    }
  }

  Future<void> _confirmFullDownload(BuildContext context) async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text('Download full ${state.audioTypeLabel.toLowerCase()}?'),
        content: Text(
          'This will queue 6,236 audio files for ${reciter.name}. '
          'You can pause, resume, or delete them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().downloadFullReciter();
    }
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final reciter = state.selectedReciter;
    if (reciter == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text('Delete ${state.audioTypeLabel.toLowerCase()} audio?'),
        content: Text(
          'Downloaded audio for ${reciter.name} will be removed. '
          'Other Arabic or translation downloads will stay on device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().deleteSelectedAudio();
    }
  }
}

class _TranslationTextDownloadActions extends StatefulWidget {
  const _TranslationTextDownloadActions({required this.translation});

  final QuranTranslationResource translation;

  @override
  State<_TranslationTextDownloadActions> createState() =>
      _TranslationTextDownloadActionsState();
}

class _TranslationTextDownloadActionsState
    extends State<_TranslationTextDownloadActions> {
  late Future<_TranslationCacheStatus> _cacheStatus;
  Future<QuranTafsirResource?>? _tafsirResource;

  QuranTranslationResource get translation => widget.translation;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(_TranslationTextDownloadActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.translation.id != translation.id) _loadStatus();
  }

  void _loadStatus() {
    _cacheStatus = _translationCacheStatus(
      getIt<QuranTranslationRepository>(),
      translation.id,
    );
    _tafsirResource = getIt.isRegistered<QuranTafsirRepository>()
        ? getIt<QuranTafsirRepository>().defaultResourceForLanguage(
            translation.languageName,
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final translationRepository = getIt<QuranTranslationRepository>();
    final tafsirRepository = getIt.isRegistered<QuranTafsirRepository>()
        ? getIt<QuranTafsirRepository>()
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${translation.displayLanguage} text',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Quran translation and tafsir are downloaded separately for offline reading.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<_TranslationCacheStatus>(
            future: _cacheStatus,
            builder: (context, snapshot) {
              final status = snapshot.data;
              final downloaded = status?.downloaded ?? false;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: downloaded
                        ? null
                        : () => _downloadQuranText(
                            context,
                            translationRepository,
                          ),
                    icon: AppIcon(
                      downloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                    ),
                    label: Text(
                      downloaded
                          ? 'Quran Text Downloaded'
                          : 'Download Quran in ${translation.displayLanguage}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _translationSourceLabel(context, status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          if (tafsirRepository != null) ...[
            const SizedBox(height: 8),
            FutureBuilder<QuranTafsirResource?>(
              future: _tafsirResource,
              builder: (context, snapshot) {
                final resource = snapshot.data;
                final checking =
                    snapshot.connectionState == ConnectionState.waiting;
                return OutlinedButton.icon(
                  onPressed: resource == null || checking
                      ? null
                      : () => _downloadTafsir(context, tafsirRepository),
                  icon: AppIcon(
                    resource == null
                        ? Icons.info_outline_rounded
                        : Icons.library_books_rounded,
                  ),
                  label: Text(
                    checking
                        ? 'Checking tafsir...'
                        : resource == null
                        ? quranTafsirUnavailableLabel(translation)
                        : 'Download Tafsir',
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadQuranText(
    BuildContext context,
    QuranTranslationRepository repository,
  ) async {
    final downloaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => _DownloadQuranTextSheet(
        repository: repository,
        resource: translation,
      ),
    );
    if (downloaded == true && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().load();
    }
  }

  Future<void> _downloadTafsir(
    BuildContext context,
    QuranTafsirRepository repository,
  ) async {
    final resource = await repository.defaultResourceForLanguage(
      translation.languageName,
    );
    if (resource == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(quranTafsirUnavailableLabel(translation))),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => _DownloadTafsirSheet(
        repository: repository,
        languageName: translation.languageName,
        languageLabel: translation.displayLanguage,
      ),
    );
  }
}

class _DownloadQuranTextSheet extends StatefulWidget {
  const _DownloadQuranTextSheet({
    required this.repository,
    required this.resource,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource resource;

  @override
  State<_DownloadQuranTextSheet> createState() =>
      _DownloadQuranTextSheetState();
}

class _DownloadQuranTextSheetState extends State<_DownloadQuranTextSheet> {
  QuranTranslationDownloadProgress? _progress;
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _download();
  }

  Future<void> _download() async {
    try {
      await for (final progress in widget.repository.downloadFullTranslation(
        widget.resource.id,
      )) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        setState(() => _progress = progress);
        if (progress.isComplete) {
          await widget.repository.setSelectedTranslation(widget.resource.id);
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop(true);
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _error = 'Some chapters failed to download.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return AppSheet(
      title: 'Downloading Quran in ${widget.resource.displayLanguage}',
      subtitle: widget.resource.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          LinearProgressIndicator(value: progress?.percent),
          const SizedBox(height: 10),
          Text(
            progress == null
                ? 'Starting download...'
                : '${progress.completedChapters}/${progress.totalChapters} chapters',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_error == null ? 'Cancel' : 'Close'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTafsirSheet extends StatefulWidget {
  const _DownloadTafsirSheet({
    required this.repository,
    required this.languageName,
    required this.languageLabel,
  });

  final QuranTafsirRepository repository;
  final String languageName;
  final String languageLabel;

  @override
  State<_DownloadTafsirSheet> createState() => _DownloadTafsirSheetState();
}

class _DownloadTafsirSheetState extends State<_DownloadTafsirSheet> {
  static const _totalSurahs = 114;

  QuranTafsirDownloadProgress? _surahProgress;
  int _currentSurah = 1;
  int _completedSurahs = 0;
  int _failedSurahs = 0;
  String? _error;
  bool _started = false;

  double get _percent {
    final current = _surahProgress?.percent ?? 0;
    return ((_completedSurahs + current) / _totalSurahs).clamp(0, 1).toDouble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _download();
  }

  Future<void> _download() async {
    try {
      for (var surah = 1; surah <= _totalSurahs; surah += 1) {
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        setState(() {
          _currentSurah = surah;
          _surahProgress = null;
        });
        var complete = false;
        await for (final progress in widget.repository.downloadSurahTafsir(
          surahNumber: surah,
          languageName: widget.languageName,
        )) {
          if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
            return;
          }
          setState(() => _surahProgress = progress);
          if (progress.failed) {
            break;
          }
          if (progress.isComplete) {
            complete = true;
            break;
          }
        }
        if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        setState(() {
          if (complete) {
            _completedSurahs += 1;
          } else {
            _failedSurahs += 1;
          }
        });
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (_failedSurahs == 0) {
        Navigator.of(context).pop(true);
      } else {
        setState(
          () => _error = '$_failedSurahs surah tafsir downloads failed.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Downloading ${widget.languageLabel} tafsir',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          LinearProgressIndicator(value: _percent),
          const SizedBox(height: 10),
          Text(
            'Surah $_currentSurah of $_totalSurahs • $_completedSurahs complete',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_surahProgress != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_surahProgress!.completedVerses}/${_surahProgress!.totalVerses} ayahs in current surah',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.58),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_error == null ? 'Cancel' : 'Close'),
          ),
        ],
      ),
    );
  }
}

class _TranslationLanguageSelector extends StatelessWidget {
  const _TranslationLanguageSelector({required this.selectedTranslation});

  final QuranTranslationResource? selectedTranslation;

  @override
  Widget build(BuildContext context) {
    final label = quranTranslationAudioLanguageLabel(selectedTranslation);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _showTranslationSheet(context),
      leading: const AppIcon(Icons.language_rounded),
      title: const Text('Translation language'),
      subtitle: Text(label),
      trailing: const AppIcon(Icons.chevron_right_rounded),
    );
  }

  Future<void> _showTranslationSheet(BuildContext context) async {
    final repository = getIt<QuranTranslationRepository>();
    final selected = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuranTranslationPicker(
        repository: repository,
        currentResource: selectedTranslation,
      ),
    );
    if (selected != null && context.mounted) {
      await context.read<QuranAudioDownloadsCubit>().selectTranslation(
        selected.id,
      );
    }
  }
}

class _DownloadsFilters extends StatelessWidget {
  const _DownloadsFilters({required this.state});

  final QuranAudioDownloadsState state;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QuranAudioDownloadsFilter>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: QuranAudioDownloadsFilter.surahs,
          label: Text('Surahs'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadsFilter.active,
          label: Text('Active'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadsFilter.downloaded,
          label: Text('Saved'),
        ),
      ],
      selected: {state.filter},
      onSelectionChanged: (selection) {
        context.read<QuranAudioDownloadsCubit>().setFilter(selection.first);
      },
    );
  }
}

class _DownloadGroupTile extends StatelessWidget {
  const _DownloadGroupTile({
    super.key,
    required this.group,
    required this.filter,
  });

  final QuranAudioDownloadGroup group;
  final QuranAudioDownloadsFilter filter;

  @override
  Widget build(BuildContext context) {
    final paused = group.items.any(
      (item) => item.status == QuranAudioDownloadStatus.paused,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QuranDownloadProgressBadge(group: group),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _subtitle(group),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                  ],
                ),
              ),
              _GroupActionButton(group: group, paused: paused, filter: filter),
            ],
          ),
          const SizedBox(height: 12),
          _GroupLinearProgress(group: group),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '${group.downloadedAyahs}/${group.totalAyahs} ayahs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
              if (group.hasFailures)
                Text(
                  '${group.failedAyahs} failed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(QuranAudioDownloadGroup group) {
    final bytes = group.bytesTotal > 0
        ? ' • ${_formatBytes(group.bytesDownloaded)}'
        : '';
    return '${group.subtitle}$bytes';
  }
}

class _GroupLinearProgress extends StatelessWidget {
  const _GroupLinearProgress({required this.group});

  final QuranAudioDownloadGroup group;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
      child: LinearProgressIndicator(
        minHeight: 3,
        value: group.progress,
        backgroundColor: QuranTheme.softFill(context, primary),
      ),
    );
  }
}

class _GroupActionButton extends StatelessWidget {
  const _GroupActionButton({
    required this.group,
    required this.paused,
    required this.filter,
  });

  final QuranAudioDownloadGroup group;
  final bool paused;
  final QuranAudioDownloadsFilter filter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranAudioDownloadsCubit>();
    if (group.isActive) {
      return IconButton.filledTonal(
        tooltip: 'Pause',
        onPressed: () => cubit.pauseGroup(group),
        icon: const AppIcon(Icons.pause_rounded),
      );
    }
    if (paused) {
      return IconButton.filledTonal(
        tooltip: 'Resume',
        onPressed: () => cubit.resumeGroup(group),
        icon: const AppIcon(Icons.play_arrow_rounded),
      );
    }
    if (group.hasFailures) {
      return IconButton.filledTonal(
        tooltip: 'Retry',
        onPressed: () => cubit.retryGroup(group),
        icon: const AppIcon(Icons.refresh_rounded),
      );
    }
    if (group.isDownloaded || filter == QuranAudioDownloadsFilter.downloaded) {
      return IconButton.filledTonal(
        tooltip: 'Delete',
        onPressed: () => cubit.deleteGroup(group),
        icon: const AppIcon(Icons.delete_outline_rounded),
      );
    }
    return IconButton.filled(
      tooltip: 'Download',
      onPressed: group.surahNumber == null
          ? null
          : () => cubit.downloadSurah(group.surahNumber!),
      icon: const AppIcon(Icons.download_rounded),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return '${mb.toStringAsFixed(1)} MB';
  }
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB';
}
