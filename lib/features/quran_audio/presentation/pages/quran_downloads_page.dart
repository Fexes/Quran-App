import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_tafsir.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_tafsir_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
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
      appBar: AppBar(title: const Text('Downloads')),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
      children: [
        _DownloadsHeader(state: state),
        const SizedBox(height: 12),
        _AudioTypeSelector(state: state),
        const SizedBox(height: 12),
        _ReciterSelector(state: state),
        const SizedBox(height: 12),
        _DownloadsFilters(state: state),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          PremiumSurface(
            padding: const EdgeInsets.all(18),
            child: Text(
              _emptyMessage(state.filter),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          )
        else
          for (final group in groups) ...[
            _DownloadGroupTile(group: group, filter: state.filter),
            const SizedBox(height: 10),
          ],
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
    return PremiumSurface(
      padding: const EdgeInsets.all(18),
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
              icon: const Icon(Icons.offline_bolt_rounded),
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QuranTheme.softFill(context, primary),
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
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
          icon: Icon(Icons.menu_book_rounded),
          label: Text('Arabic'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadAudioType.translation,
          icon: Icon(Icons.translate_rounded),
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
        PremiumSurface(
          padding: const EdgeInsets.all(14),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: reciter == null
                ? CircleAvatar(
                    radius: 26,
                    backgroundColor: QuranTheme.softFill(
                      context,
                      Theme.of(context).colorScheme.primary,
                    ),
                    child: Icon(
                      isTranslation
                          ? Icons.translate_rounded
                          : Icons.record_voice_over_rounded,
                    ),
                  )
                : QuranReciterAvatar(reciter: reciter, size: 52),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: canChoose
                ? const Icon(Icons.keyboard_arrow_down_rounded)
                : null,
            onTap: canChoose
                ? () => _showReciterSheet(context, state.reciters)
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: state.selectedReciter == null
                    ? null
                    : () => _confirmFullDownload(context),
                icon: const Icon(Icons.download_for_offline_rounded),
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
              icon: const Icon(Icons.delete_sweep_rounded),
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
      return 'Choose a translation language in Quran reader settings.';
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

class _TranslationTextDownloadActions extends StatelessWidget {
  const _TranslationTextDownloadActions({required this.translation});

  final QuranTranslationResource translation;

  @override
  Widget build(BuildContext context) {
    final translationRepository = getIt<QuranTranslationRepository>();
    final tafsirRepository = getIt.isRegistered<QuranTafsirRepository>()
        ? getIt<QuranTafsirRepository>()
        : null;
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${translation.displayLanguage} text',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Quran translation and tafsir are downloaded separately for offline reading.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<_TranslationCacheStatus>(
            future: _translationCacheStatus(
              translationRepository,
              translation.id,
            ),
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
                    icon: Icon(
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
              future: tafsirRepository.defaultResourceForLanguage(
                translation.languageName,
              ),
              builder: (context, snapshot) {
                final resource = snapshot.data;
                final checking =
                    snapshot.connectionState == ConnectionState.waiting;
                return OutlinedButton.icon(
                  onPressed: resource == null || checking
                      ? null
                      : () => _downloadTafsir(context, tafsirRepository),
                  icon: Icon(
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
        if (!mounted) {
          return;
        }
        setState(() => _progress = progress);
        if (progress.isComplete) {
          await widget.repository.setSelectedTranslation(widget.resource.id);
          if (mounted) {
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PremiumSurface(
        radius: QuranTheme.radiusSheet,
        prominent: true,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Downloading Quran in ${widget.resource.displayLanguage}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              widget.resource.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: progress?.percent),
            const SizedBox(height: 10),
            Text(
              progress == null
                  ? 'Starting download...'
                  : '${progress.completedChapters}/${progress.totalChapters} chapters',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
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
        if (!mounted) {
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
          if (!mounted) {
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
        if (!mounted) {
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
      if (!mounted) {
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PremiumSurface(
        radius: QuranTheme.radiusSheet,
        prominent: true,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Downloading ${widget.languageLabel} tafsir',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'This downloads tafsir separately from Quran translation text.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context, 0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: _percent),
            const SizedBox(height: 10),
            Text(
              'Surah $_currentSurah of $_totalSurahs • $_completedSurahs complete',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_surahProgress != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_surahProgress!.completedVerses}/${_surahProgress!.totalVerses} ayahs in current surah',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.58),
                  fontWeight: FontWeight.w800,
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
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      onTap: () => _showTranslationSheet(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: QuranTheme.softFill(
              context,
              Theme.of(context).colorScheme.primary,
            ),
            child: const Icon(Icons.language_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Translation language',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.66),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }

  Future<void> _showTranslationSheet(BuildContext context) async {
    final repository = getIt<QuranTranslationRepository>();
    final selected = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _DownloadTranslationPickerSheet(
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

class _DownloadTranslationPickerSheet extends StatefulWidget {
  const _DownloadTranslationPickerSheet({
    required this.repository,
    required this.currentResource,
  });

  final QuranTranslationRepository repository;
  final QuranTranslationResource? currentResource;

  @override
  State<_DownloadTranslationPickerSheet> createState() =>
      _DownloadTranslationPickerSheetState();
}

class _DownloadTranslationPickerSheetState
    extends State<_DownloadTranslationPickerSheet> {
  final _queryController = TextEditingController();
  late final Future<List<QuranTranslationLanguage>> _languagesFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _languagesFuture = widget.repository.translationLanguages();
    _queryController.addListener(() {
      setState(() => _query = _queryController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.92,
      minChildSize: 0.58,
      builder: (context, scrollController) {
        return PremiumSurface(
          margin: const EdgeInsets.all(12),
          radius: QuranTheme.radiusSheet,
          prominent: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select translation',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Search language or translator',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<QuranTranslationLanguage>>(
                  future: _languagesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups = [
                      for (final language in snapshot.data!)
                        (
                          language: language,
                          resources: _matchingResources(language),
                        ),
                    ].where((group) => group.resources.isNotEmpty).toList();
                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          'No translations match your search.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.66),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      );
                    }
                    return ListView(
                      controller: scrollController,
                      children: [
                        for (final group in groups) ...[
                          if (group.resources.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                              child: Text(
                                '${group.language.displayName} • ${group.resources.length} editions',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: QuranTheme.subText(context, 0.72),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          for (final resource in group.resources) ...[
                            FutureBuilder<bool>(
                              future: widget.repository.hasFullTranslation(
                                resource.id,
                              ),
                              builder: (context, cacheSnapshot) {
                                return _DownloadTranslationLanguageTile(
                                  title: group.resources.length == 1
                                      ? group.language.displayName
                                      : resource.name,
                                  subtitle:
                                      [
                                            resource.displayEndonym,
                                            resource.name,
                                            resource.translator,
                                            resource.isRtl ? 'RTL' : 'LTR',
                                            Uri.tryParse(
                                                  resource.sourceUrl,
                                                )?.host ??
                                                resource.sourceUrl,
                                            resource.license,
                                          ]
                                          .where((item) => item.isNotEmpty)
                                          .join(' • '),
                                  selected:
                                      widget.currentResource?.id == resource.id,
                                  downloaded: cacheSnapshot.data ?? false,
                                  onTap: () =>
                                      Navigator.of(context).pop(resource),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<QuranTranslationResource> _matchingResources(
    QuranTranslationLanguage language,
  ) {
    if (_query.isEmpty) {
      return language.availableResources;
    }
    return language.availableResources
        .where((resource) {
          final haystack =
              '${language.displayName} ${resource.displayEndonym} ${resource.languageName} ${resource.name} ${resource.translator} ${resource.publisher} ${resource.license}'
                  .toLowerCase();
          return haystack.contains(_query);
        })
        .toList(growable: false);
  }
}

class _DownloadTranslationLanguageTile extends StatelessWidget {
  const _DownloadTranslationLanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.downloaded,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      borderColor: selected ? primary.withValues(alpha: 0.42) : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? QuranTheme.softFill(context, primary)
                  : QuranTheme.surfaceVariant(context).withValues(alpha: 0.55),
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.translate_rounded,
              size: 20,
              color: selected ? primary : QuranTheme.subText(context, 0.72),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.66),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            downloaded ? Icons.download_done_rounded : Icons.download_rounded,
            color: downloaded ? primary : QuranTheme.subText(context, 0.58),
          ),
        ],
      ),
    );
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
          icon: Icon(Icons.menu_book_rounded),
          label: Text('Surahs'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadsFilter.active,
          icon: Icon(Icons.downloading_rounded),
          label: Text('Active'),
        ),
        ButtonSegment(
          value: QuranAudioDownloadsFilter.downloaded,
          icon: Icon(Icons.offline_pin_rounded),
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
  const _DownloadGroupTile({required this.group, required this.filter});

  final QuranAudioDownloadGroup group;
  final QuranAudioDownloadsFilter filter;

  @override
  Widget build(BuildContext context) {
    final paused = group.items.any(
      (item) => item.status == QuranAudioDownloadStatus.paused,
    );
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
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
                        fontWeight: FontWeight.w900,
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
          Row(
            children: [
              Text(
                '${group.downloadedAyahs}/${group.totalAyahs} ayahs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
              const Spacer(),
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
        minHeight: 8,
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
        icon: const Icon(Icons.pause_rounded),
      );
    }
    if (paused) {
      return IconButton.filledTonal(
        tooltip: 'Resume',
        onPressed: () => cubit.resumeGroup(group),
        icon: const Icon(Icons.play_arrow_rounded),
      );
    }
    if (group.hasFailures) {
      return IconButton.filledTonal(
        tooltip: 'Retry',
        onPressed: () => cubit.retryGroup(group),
        icon: const Icon(Icons.refresh_rounded),
      );
    }
    if (group.isDownloaded || filter == QuranAudioDownloadsFilter.downloaded) {
      return IconButton.filledTonal(
        tooltip: 'Delete',
        onPressed: () => cubit.deleteGroup(group),
        icon: const Icon(Icons.delete_outline_rounded),
      );
    }
    return IconButton.filled(
      tooltip: 'Download',
      onPressed: group.surahNumber == null
          ? null
          : () => cubit.downloadSurah(group.surahNumber!),
      icon: const Icon(Icons.download_rounded),
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
