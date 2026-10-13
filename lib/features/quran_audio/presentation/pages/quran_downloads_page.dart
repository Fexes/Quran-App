import 'dart:async';

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
import '../../../quran/domain/entities/quran_tafsir.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_tafsir_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/domain/services/quran_translation_audio_pairings.dart';
import '../../../quran/presentation/widgets/quran_translation_download_sheet.dart';
import '../../../quran/presentation/widgets/quran_translation_picker.dart';
import '../../data/repositories/quran_audio_download_repository.dart';
import '../../data/services/quran_audio_download_service.dart';
import '../../domain/entities/quran_audio_download_item.dart';
import '../cubit/quran_audio_cubit.dart';
import '../cubit/quran_audio_downloads_cubit.dart';
import '../cubit/quran_audio_downloads_state.dart';
import '../widgets/quran_download_progress_badge.dart';
import '../widgets/quran_floating_audio_player.dart';
import '../widgets/quran_reciter_picker.dart';
import '../widgets/quran_translation_voice_change.dart';

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

class _TafsirCacheStatus {
  const _TafsirCacheStatus({required this.resource, required this.downloaded});

  final QuranTafsirResource? resource;
  final bool downloaded;
}

Future<_TafsirCacheStatus> _tafsirCacheStatus(
  QuranTafsirRepository repository,
  String languageName,
) async {
  final resource = await repository.defaultResourceForLanguage(languageName);
  if (resource == null) {
    return const _TafsirCacheStatus(resource: null, downloaded: false);
  }
  for (var surah = 1; surah <= 114; surah++) {
    if (!await repository.hasDownloadedSurahTafsir(
      surahNumber: surah,
      languageName: languageName,
    )) {
      return _TafsirCacheStatus(resource: resource, downloaded: false);
    }
    if (surah % 12 == 0) await Future<void>.delayed(Duration.zero);
  }
  return _TafsirCacheStatus(resource: resource, downloaded: true);
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
                QuranAudioDownloadsStatus.success => Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: _DownloadsContent(state: state),
                  ),
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

Future<bool> _confirmRemoveAudio(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _performDownloadAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update this download. Try again.'),
        ),
      );
    }
  }
}

Future<void> _removeDownloadGroup(
  BuildContext context,
  QuranAudioDownloadGroup group,
) async {
  final cubit = context.read<QuranAudioDownloadsCubit>();
  final confirmed = await _confirmRemoveAudio(
    context,
    title: 'Remove ${group.title} audio?',
    message:
        'Saved audio for this surah and voice will be removed. Pending downloads will be cancelled.',
  );
  if (confirmed && context.mounted) {
    await _performDownloadAction(context, () => cubit.deleteGroup(group));
  }
}

class _DownloadsContent extends StatefulWidget {
  const _DownloadsContent({required this.state});

  final QuranAudioDownloadsState state;

  @override
  State<_DownloadsContent> createState() => _DownloadsContentState();
}

class _DownloadsContentState extends State<_DownloadsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _updatingPreferences = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final canChooseVoice = state.reciters.any(
      (voice) =>
          !voice.isTranslation ||
          quranTranslationPairForVoice(voice.id) != null,
    );
    final groupsById = {for (final group in state.surahGroups) group.id: group};
    for (final group in [...state.activeGroups, ...state.downloadedGroups]) {
      groupsById.putIfAbsent(group.id, () => group);
    }
    final query = _query.trim().toLowerCase();
    final groups =
        groupsById.values
            .where((group) {
              return query.isEmpty ||
                  group.title.toLowerCase().contains(query) ||
                  group.subtitle.toLowerCase().contains(query) ||
                  group.items.firstOrNull?.reciterName.toLowerCase().contains(
                        query,
                      ) ==
                      true ||
                  group.surahNumber?.toString() == query;
            })
            .toList(growable: false)
          ..sort((a, b) {
            final surah = (a.surahNumber ?? 0).compareTo(b.surahNumber ?? 0);
            if (surah != 0) return surah;
            final aSelected = a.reciterId == state.selectedReciter?.id;
            final bSelected = b.reciterId == state.selectedReciter?.id;
            if (aSelected != bSelected) return aSelected ? -1 : 1;
            return a.id.compareTo(b.id);
          });
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverList.list(
            children: [
              _TranslationLanguageTile(
                translation: state.selectedTranslation,
                onTap: _updatingPreferences ? null : _chooseTranslation,
              ),
              if (state.selectedTranslation != null)
                _TranslationTextDownloadActions(
                  translation: state.selectedTranslation!,
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.menu_book_outlined),
                  title: const Text('Arabic Quran text'),
                  subtitle: const Text('Ready offline'),
                  trailing: const AppIcon(Icons.check_circle_rounded),
                ),
              const Divider(height: 28),
              Text('Audio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _AudioTypeSelector(state: state, enabled: !_updatingPreferences),
              const SizedBox(height: 8),
              _SelectedAudioSummary(
                state: state,
                onTap:
                    !_updatingPreferences &&
                        (canChooseVoice ||
                            (state.audioType ==
                                    QuranAudioDownloadAudioType.translation &&
                                state.selectedTranslation == null))
                    ? _chooseReciter
                    : null,
              ),
              if (_updatingPreferences)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              _DownloadOptions(state: state, enabled: !_updatingPreferences),
              const SizedBox(height: 12),
              if (groupsById.isNotEmpty)
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search surahs or voices',
                    prefixIcon: const AppIcon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const AppIcon(Icons.close_rounded),
                          ),
                  ),
                ),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    query.isNotEmpty
                        ? 'No surahs match your search.'
                        : _emptyMessage(state),
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
              showVoice: groups[index].reciterId != state.selectedReciter?.id,
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

  String _emptyMessage(QuranAudioDownloadsState state) {
    if (state.audioType == QuranAudioDownloadAudioType.translation) {
      if (state.selectedTranslation == null) {
        return 'Select a translation language above to choose its audio.';
      }
      return 'No matching audio is available for this ${state.selectedTranslation!.displayLanguage} translation.';
    }
    return 'Choose a reciter above to download surahs.';
  }

  Future<void> _chooseTranslation() async {
    if (_updatingPreferences) return;
    final repository = getIt<QuranTranslationRepository>();
    final cubit = context.read<QuranAudioDownloadsCubit>();
    final selected = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranTranslationPicker(
        repository: repository,
        currentResource: cubit.state.selectedTranslation,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _updatingPreferences = true);
    try {
      if (!await repository.hasReadyReadingLanguage(selected.id)) {
        if (!mounted) return;
        final prepared = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (_) => QuranTranslationDownloadSheet(
            repository: repository,
            resource: selected,
            activateOnComplete: false,
          ),
        );
        if (prepared != true || !mounted) return;
      }
      if (!mounted) return;
      await cubit.selectTranslation(selected.id);
      if (!mounted) return;
      await context.read<QuranAudioCubit>().synchronizeTranslationSelection();
    } catch (_) {
      _showPreferenceError();
    } finally {
      if (mounted) setState(() => _updatingPreferences = false);
    }
  }

  Future<void> _chooseReciter() async {
    if (_updatingPreferences) return;
    final cubit = context.read<QuranAudioDownloadsCubit>();
    final state = cubit.state;
    final translationAudio =
        state.audioType == QuranAudioDownloadAudioType.translation;
    final voices = state.reciters
        .where(
          (reciter) =>
              !translationAudio ||
              quranTranslationPairForVoice(reciter.id) != null,
        )
        .toList(growable: false);
    if (voices.isEmpty) {
      if (state.selectedTranslation == null) await _chooseTranslation();
      return;
    }
    final selected = await showQuranReciterPickerSheet(
      context,
      reciters: voices,
      selectedReciterId: state.selectedReciter?.id,
      title: translationAudio ? 'Translation voice' : 'Arabic reciter',
    );
    if (selected == null || !mounted) return;
    if (selected.id == state.selectedReciter?.id) return;
    setState(() => _updatingPreferences = true);
    try {
      if (translationAudio) {
        final prepared = await prepareQuranTranslationVoiceChange(
          context: context,
          repository: getIt<QuranTranslationRepository>(),
          voice: selected,
        );
        if (!prepared || !mounted) return;
      }
      await cubit.selectReciter(selected);
      if (!mounted) return;
      final audio = context.read<QuranAudioCubit>();
      if (translationAudio) {
        await audio.synchronizeTranslationSelection();
      } else {
        await audio.changeReciter(selected.id);
      }
    } catch (_) {
      _showPreferenceError();
    } finally {
      if (mounted) setState(() => _updatingPreferences = false);
    }
  }

  void _showPreferenceError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not update your choice. Please try again.'),
      ),
    );
  }
}

class _TranslationLanguageTile extends StatelessWidget {
  const _TranslationLanguageTile({required this.translation, this.onTap});

  final QuranTranslationResource? translation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const AppIcon(Icons.translate_rounded),
      title: const Text('Translation language'),
      subtitle: Text(translation?.displayLanguage ?? 'Select language'),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _DownloadOptions extends StatelessWidget {
  const _DownloadOptions({required this.state, this.enabled = true});

  final QuranAudioDownloadsState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranAudioDownloadsCubit>();
    final hasSelectedDownloads = state.surahGroups.any(
      (group) => group.items.isNotEmpty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.selectedReciter != null)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: enabled
                      ? () => _confirmFullDownload(context)
                      : null,
                  icon: const AppIcon(Icons.download_rounded, size: 20),
                  label: const Text('Download all surahs'),
                ),
              ),
              if (hasSelectedDownloads) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Remove selected voice downloads',
                  onPressed: enabled
                      ? () => _confirmDeleteSelected(context)
                      : null,
                  icon: const AppIcon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: const Text('Storage & preferences'),
          subtitle: Text(
            '${_formatBytes(state.storageUsedBytes)} audio saved'
            '${state.activeDownloadCount > 0 ? ' • ${state.activeDownloadCount} ayahs downloading' : ''}',
          ),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.wifiOnlyLargeDownloads,
              onChanged: enabled ? cubit.setWifiOnlyLargeDownloads : null,
              title: const Text('Use Wi-Fi for full Quran audio'),
              subtitle: const Text('Individual surahs can use mobile data.'),
            ),
            if (state.selectedArabicReciter != null &&
                state.selectedTranslationReciter != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(Icons.offline_bolt_rounded),
                title: const Text('Download Arabic and translation audio'),
                subtitle: const Text('All surahs using your reading setup.'),
                onTap: enabled ? () => _confirmCompleteOffline(context) : null,
              ),
            if (state.storageUsedBytes > 0 || state.activeGroups.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(Icons.delete_sweep_rounded),
                title: const Text('Remove all audio downloads'),
                onTap: enabled ? () => _confirmDeleteAll(context) : null,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmFullDownload(BuildContext context) async {
    final reciter = state.selectedReciter;
    if (reciter == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Download all ${state.audioTypeLabel.toLowerCase()} audio?',
        ),
        content: Text(
          'Save all 114 surahs by ${reciter.name}. '
          'This may use a lot of storage. You can pause or remove downloads at any time.',
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
      await _performDownloadAction(
        context,
        context.read<QuranAudioDownloadsCubit>().downloadFullReciter,
      );
    }
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final reciter = state.selectedReciter;
    if (reciter == null) return;
    final confirmed = await _confirmRemoveAudio(
      context,
      title: 'Remove ${reciter.name} audio?',
      message:
          'This removes saved audio and cancels pending downloads for this voice.',
    );
    if (confirmed && context.mounted) {
      await _performDownloadAction(
        context,
        context.read<QuranAudioDownloadsCubit>().deleteSelectedAudio,
      );
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await _confirmRemoveAudio(
      context,
      title: 'Remove all audio downloads?',
      message:
          'This removes saved audio from all voices and cancels pending audio downloads.',
    );
    if (confirmed && context.mounted) {
      await _performDownloadAction(
        context,
        context.read<QuranAudioDownloadsCubit>().deleteAllAudio,
      );
    }
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
        title: const Text('Download both voices for all surahs?'),
        content: Text(
          'Arabic audio: ${arabic.name}.\n'
          '$translationLine\n\n'
          'Save all 114 surahs in both voices. This may use a lot of storage and take time.',
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
      await _performDownloadAction(
        context,
        context.read<QuranAudioDownloadsCubit>().downloadCompleteOffline,
      );
    }
  }
}

class _AudioTypeSelector extends StatelessWidget {
  const _AudioTypeSelector({required this.state, this.enabled = true});

  final QuranAudioDownloadsState state;
  final bool enabled;

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
      onSelectionChanged: !enabled
          ? null
          : (selection) {
              _performDownloadAction(
                context,
                () => context.read<QuranAudioDownloadsCubit>().setAudioType(
                  selection.first,
                ),
              );
            },
    );
  }
}

class _SelectedAudioSummary extends StatelessWidget {
  const _SelectedAudioSummary({required this.state, this.onTap});

  final QuranAudioDownloadsState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reciter = state.selectedReciter;
    final translationAudio =
        state.audioType == QuranAudioDownloadAudioType.translation;
    final hasVerifiedVoices = state.reciters.any(
      (voice) => quranTranslationPairForVoice(voice.id) != null,
    );
    final subtitle = reciter != null
        ? reciter.isTranslation
              ? quranTranslationPairForVoice(reciter.id)?.resource.name ?? ''
              : 'Arabic recitation'
        : !translationAudio
        ? 'Select an Arabic reciter'
        : state.selectedTranslation == null
        ? 'Select a translation language above'
        : hasVerifiedVoices
        ? 'Voices available with another text edition'
        : 'No audio available for this ${state.selectedTranslation!.displayLanguage} translation';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: reciter == null
          ? const AppIcon(Icons.record_voice_over_rounded)
          : QuranReciterAvatar(reciter: reciter, size: 38),
      title: Text(
        reciter?.name ??
            (translationAudio
                ? hasVerifiedVoices
                      ? 'Choose translation voice'
                      : 'Translation audio'
                : 'Choose a reciter'),
      ),
      subtitle: Text(subtitle),
      trailing: onTap == null
          ? null
          : const AppIcon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
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
  Future<_TafsirCacheStatus>? _tafsirStatus;
  bool _openingTafsir = false;

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
    _tafsirStatus = getIt.isRegistered<QuranTafsirRepository>()
        ? _tafsirCacheStatus(
            getIt<QuranTafsirRepository>(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<_TranslationCacheStatus>(
          future: _cacheStatus,
          builder: (context, snapshot) {
            final downloaded = snapshot.data?.downloaded == true;
            final checking =
                snapshot.connectionState == ConnectionState.waiting;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppIcon(
                downloaded
                    ? Icons.offline_pin_rounded
                    : Icons.menu_book_rounded,
              ),
              title: Text('Quran in ${translation.displayLanguage}'),
              subtitle: Text(
                checking
                    ? 'Checking offline availability...'
                    : snapshot.hasError
                    ? 'Could not check offline text.'
                    : downloaded
                    ? 'Ready offline'
                    : 'Download all surahs for offline reading',
              ),
              trailing: checking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : downloaded
                  ? const AppIcon(Icons.check_circle_rounded)
                  : FilledButton(
                      onPressed: () =>
                          _downloadQuranText(context, translationRepository),
                      child: const Text('Download'),
                    ),
            );
          },
        ),
        if (tafsirRepository != null)
          FutureBuilder<_TafsirCacheStatus>(
            future: _tafsirStatus,
            builder: (context, snapshot) {
              final resource = snapshot.data?.resource;
              final downloaded = snapshot.data?.downloaded == true;
              final checking =
                  snapshot.connectionState == ConnectionState.waiting;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(
                  downloaded && !checking
                      ? Icons.offline_pin_rounded
                      : Icons.library_books_outlined,
                ),
                title: const Text('Tafsir'),
                subtitle: Text(
                  checking
                      ? 'Checking availability...'
                      : snapshot.hasError
                      ? 'Could not check offline tafsir.'
                      : resource == null
                      ? quranTafsirUnavailableLabel(translation)
                      : downloaded
                      ? 'Ready offline'
                      : 'Separate commentary download',
                ),
                trailing: checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : snapshot.hasError
                    ? TextButton(
                        onPressed: () => setState(() {
                          _tafsirStatus = _tafsirCacheStatus(
                            tafsirRepository,
                            translation.languageName,
                          );
                        }),
                        child: const Text('Retry'),
                      )
                    : resource == null
                    ? null
                    : downloaded
                    ? const AppIcon(Icons.check_circle_rounded)
                    : TextButton(
                        onPressed: _openingTafsir
                            ? null
                            : () => _downloadTafsir(context, tafsirRepository),
                        child: const Text('Download'),
                      ),
              );
            },
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text('Translation source'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                translation.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<_TranslationCacheStatus>(
              future: _cacheStatus,
              builder: (context, snapshot) => Text(
                _translationSourceLabel(context, snapshot.data),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadQuranText(
    BuildContext context,
    QuranTranslationRepository repository,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => QuranTranslationDownloadSheet(
        repository: repository,
        resource: translation,
        activateOnComplete: false,
      ),
    );
    if (mounted) setState(_loadStatus);
  }

  Future<void> _downloadTafsir(
    BuildContext context,
    QuranTafsirRepository repository,
  ) async {
    if (_openingTafsir) return;
    final selected = translation;
    setState(() => _openingTafsir = true);
    try {
      final status = await _tafsirCacheStatus(
        repository,
        selected.languageName,
      );
      if (!mounted || !context.mounted || translation.id != selected.id) return;
      if (status.downloaded) {
        setState(() => _tafsirStatus = Future.value(status));
        return;
      }
      if (status.resource == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(quranTafsirUnavailableLabel(selected))),
        );
        return;
      }
      final completed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        builder: (context) => _DownloadTafsirSheet(
          repository: repository,
          languageName: selected.languageName,
          languageLabel: selected.displayLanguage,
        ),
      );
      if (!mounted || translation.id != selected.id) return;
      setState(() {
        _tafsirStatus = completed == true
            ? Future.value(
                _TafsirCacheStatus(resource: status.resource, downloaded: true),
              )
            : _tafsirCacheStatus(repository, selected.languageName);
      });
    } catch (_) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check Tafsir. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingTafsir = false);
    }
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
  final Set<int> _completedSurahNumbers = {};
  final Set<int> _sourceGaps = {};
  int get _completedSurahs => _completedSurahNumbers.length;
  String? _error;
  bool _started = false;
  bool _downloading = false;
  int _revision = 0;
  StreamSubscription<QuranTafsirDownloadProgress>? _subscription;
  Completer<bool>? _pendingSurah;

  double get _percent {
    final current = _completedSurahNumbers.contains(_currentSurah)
        ? 0
        : _surahProgress?.percent ?? 0;
    return ((_completedSurahs + current) / _totalSurahs)
        .clamp(0, _completedSurahs == _totalSurahs ? 1 : 0.99)
        .toDouble();
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

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _cancel() {
    _revision++;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    final pending = _pendingSurah;
    _pendingSurah = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  void _close() {
    _cancel();
    Navigator.of(context).pop(false);
  }

  Future<bool> _downloadSurah(int surah, int revision) async {
    final pending = Completer<bool>();
    _pendingSurah = pending;
    final subscription = widget.repository
        .downloadSurahTafsir(
          surahNumber: surah,
          languageName: widget.languageName,
        )
        .listen(
          (progress) {
            if (!mounted || revision != _revision) return;
            setState(() {
              _surahProgress = progress;
              if (progress.unavailableVerses > 0) _sourceGaps.add(surah);
            });
            if (!pending.isCompleted &&
                (progress.isComplete || progress.failed)) {
              pending.complete(progress.isComplete && !progress.failed);
            }
          },
          onError: (Object error) {
            if (!pending.isCompleted) pending.complete(false);
          },
          onDone: () {
            if (!pending.isCompleted) pending.complete(false);
          },
        );
    _subscription = subscription;
    final complete = await pending.future;
    await subscription.cancel();
    if (identical(_subscription, subscription)) _subscription = null;
    if (identical(_pendingSurah, pending)) _pendingSurah = null;
    return complete;
  }

  Future<void> _download() async {
    if (_downloading) return;
    final revision = ++_revision;
    setState(() {
      _downloading = true;
      _error = null;
      _surahProgress = null;
    });
    try {
      final saved = <int>{};
      for (var surah = 1; surah <= _totalSurahs; surah++) {
        if (!mounted || revision != _revision) return;
        if (await widget.repository.hasDownloadedSurahTafsir(
          surahNumber: surah,
          languageName: widget.languageName,
        )) {
          saved.add(surah);
        }
        if (surah % 12 == 0) await Future<void>.delayed(Duration.zero);
      }
      if (!mounted || revision != _revision) return;
      setState(() {
        _completedSurahNumbers
          ..clear()
          ..addAll(saved);
      });
      for (var surah = 1; surah <= _totalSurahs; surah += 1) {
        if (!mounted || revision != _revision) {
          return;
        }
        if (_completedSurahNumbers.contains(surah)) continue;
        setState(() {
          _currentSurah = surah;
          _surahProgress = null;
        });
        final complete = await _downloadSurah(surah, revision);
        if (!mounted || revision != _revision) {
          return;
        }
        if (!complete) {
          final reason = _surahProgress?.errorMessage;
          setState(
            () => _error =
                '${reason == null ? 'Download interrupted at surah $surah.' : 'Surah $surah: $reason'} $_completedSurahs surahs are saved. Resume to continue without downloading them again.',
          );
          return;
        }
        setState(() => _completedSurahNumbers.add(surah));
      }
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (_completedSurahs == _totalSurahs) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || revision != _revision) return;
        if (_sourceGaps.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tafsir downloaded. Some ayahs have no commentary in this edition and remain unavailable.',
              ),
            ),
          );
        }
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(
          () => _error =
              'Download interrupted. Saved progress is kept. Resume to continue.',
        );
      }
    } finally {
      if (mounted && revision == _revision) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Downloading ${widget.languageLabel} tafsir',
      onClose: _close,
      footer: OutlinedButton(onPressed: _close, child: const Text('Close')),
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
              '${_surahProgress!.completedVerses - _surahProgress!.unavailableVerses}/${_surahProgress!.totalVerses} ayahs saved'
              '${_surahProgress!.unavailableVerses > 0 ? ' · ${_surahProgress!.unavailableVerses} unavailable from source' : ''}',
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
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _downloading ? null : _download,
              child: const Text('Resume download'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadGroupTile extends StatelessWidget {
  const _DownloadGroupTile({
    super.key,
    required this.group,
    this.showVoice = false,
  });

  final QuranAudioDownloadGroup group;
  final bool showVoice;

  @override
  Widget build(BuildContext context) {
    final paused = group.items.any(
      (item) => item.status == QuranAudioDownloadStatus.paused,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: QuranTheme.outline(context))),
      ),
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
              _GroupActionButton(group: group, paused: paused),
              if (group.items.isNotEmpty && !group.isDownloaded)
                PopupMenuButton<String>(
                  tooltip: 'More download options',
                  onSelected: (_) => _removeDownloadGroup(context, group),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Cancel and remove audio'),
                    ),
                  ],
                ),
            ],
          ),
          if (group.items.isNotEmpty && !group.isDownloaded) ...[
            const SizedBox(height: 12),
            _GroupLinearProgress(group: group),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                group.isDownloaded
                    ? 'Ready offline'
                    : group.items.isEmpty
                    ? '${group.totalAyahs} audio files'
                    : '${group.downloadedAyahs}/${group.totalAyahs} audio files saved${paused ? ' • Paused' : ''}',
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
    final bytes = group.bytesDownloaded > 0
        ? ' • ${_formatBytes(group.bytesDownloaded)}'
        : '';
    final voice = showVoice && group.items.isNotEmpty
        ? ' • ${group.items.first.reciterName}'
        : '';
    return '${group.subtitle}$voice$bytes';
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
  const _GroupActionButton({required this.group, required this.paused});

  final QuranAudioDownloadGroup group;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranAudioDownloadsCubit>();
    if (group.isActive) {
      return IconButton.filledTonal(
        tooltip: 'Pause',
        onPressed: () =>
            _performDownloadAction(context, () => cubit.pauseGroup(group)),
        icon: const AppIcon(Icons.pause_rounded),
      );
    }
    if (paused) {
      return IconButton.filledTonal(
        tooltip: 'Resume',
        onPressed: () =>
            _performDownloadAction(context, () => cubit.resumeGroup(group)),
        icon: const AppIcon(Icons.play_arrow_rounded),
      );
    }
    if (group.hasFailures) {
      return IconButton.filledTonal(
        tooltip: 'Retry',
        onPressed: () =>
            _performDownloadAction(context, () => cubit.retryGroup(group)),
        icon: const AppIcon(Icons.refresh_rounded),
      );
    }
    if (group.isDownloaded) {
      return IconButton.filledTonal(
        tooltip: 'Remove saved audio',
        onPressed: () => _removeDownloadGroup(context, group),
        icon: const AppIcon(Icons.delete_outline_rounded),
      );
    }
    return IconButton.filled(
      tooltip: 'Download',
      onPressed: group.surahNumber == null
          ? null
          : () => _performDownloadAction(
              context,
              () => cubit.downloadSurah(
                group.surahNumber!,
                reciterId: group.reciterId,
              ),
            ),
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
