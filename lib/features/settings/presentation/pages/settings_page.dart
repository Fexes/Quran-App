import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/quran_arabic_script.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/locale_state.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/presentation/widgets/hadith_translation_sheet.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../../quran/domain/entities/quran_tafsir.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_tafsir_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../widgets/prayer_calculation_settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveInsetArea(
      top: true,
      bottom: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: ShellScreenHeader(
              icon: Icons.tune_rounded,
              title: l10n.settingsTitle,
              subtitle: l10n.settingsSubtitle,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                QuranFloatingAudioPlayer.scrollInset(context),
              ),
              children: [
                SectionHeader(title: l10n.appearanceTitle),
                const SizedBox(height: 10),
                const _ThemeSelector(),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.format_size_rounded),
                  title: Text(l10n.textAppearanceTitle),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AppSheet(
                      title: l10n.textAppearanceTitle,
                      child: BlocProvider.value(
                        value: context.read<QuranThemeCubit>(),
                        child: const _FontControls(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(title: l10n.readingPreferencesTitle),
                const _LanguageSelector(),
                const _ArabicScriptSetting(),
                const _ReadingListeningSetting(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.translate_rounded),
                  title: const Text('More reading preferences'),
                  subtitle: const Text(
                    'Tafsir, word meanings, Hadith and Azkar',
                  ),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => AppSheet(
                      title: 'More reading preferences',
                      child: const _ReadingDetailSettings(),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'Prayer preferences'),
                const PrayerCalculationSettingsTile(),
                const SizedBox(height: 22),
                SectionHeader(title: l10n.downloadsDataTitle),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.download_for_offline_outlined),
                  title: Text(l10n.offlineDownloadsTitle),
                  subtitle: Text(l10n.offlineDownloadsSubtitle),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.quranDownloadsPath()),
                ),
                const _BackupSettingsTile(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.verified_outlined),
                  title: Text(l10n.contentSourcesTitle),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                  onTap: () => _showContentSources(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContentSources(BuildContext context) {
    final sources = getIt<QuranRepository>().getContentSources();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AppSheet(
        title: 'Quran content sources',
        child: FutureBuilder(
          future: sources,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Content sources could not be loaded.'),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final source in snapshot.data!) ...[
                  const Divider(height: 24),
                  Text(
                    source.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (source.edition?.isNotEmpty == true) source.edition!,
                      if (source.provider?.isNotEmpty == true) source.provider!,
                      if (source.license?.isNotEmpty == true) source.license!,
                      if (source.cachePolicy.maxAge != null)
                        'Offline cache: up to ${source.cachePolicy.maxAge!.inDays} days',
                      'Release review: ${source.reviewStatus.name}',
                      source.attribution,
                    ].join('\n'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackupSettingsTile extends StatelessWidget {
  const _BackupSettingsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const AppIcon(Icons.lock_person_rounded),
      title: Text(l10n.backupPrivacyTitle),
      subtitle: Text(l10n.backupPrivacySubtitle),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: () => context.push(AppRoutes.backupPath()),
    );
  }
}

class _ArabicScriptSetting extends StatelessWidget {
  const _ArabicScriptSetting();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      buildWhen: (previous, current) =>
          previous.quranArabicScript != current.quranArabicScript,
      builder: (context, state) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const AppIcon(Icons.text_fields_rounded),
        title: Text(AppLocalizations.of(context).arabicScriptTitle),
        subtitle: Text(state.quranArabicScript.label),
        trailing: const AppIcon(Icons.chevron_right_rounded),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => AppSheet(
            title: AppLocalizations.of(context).arabicScriptTitle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final script in QuranArabicScript.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(script.label),
                    trailing: state.quranArabicScript == script
                        ? const AppIcon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      context.read<QuranThemeCubit>().setQuranArabicScript(
                        script,
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingListeningSetting extends StatefulWidget {
  const _ReadingListeningSetting();

  @override
  State<_ReadingListeningSetting> createState() =>
      _ReadingListeningSettingState();
}

class _ReadingListeningSettingState extends State<_ReadingListeningSetting> {
  late final QuranTranslationRepository _repository;
  late Future<QuranTranslationResource?> _selection;
  Listenable? _selectionChanges;

  @override
  void initState() {
    super.initState();
    _repository = getIt<QuranTranslationRepository>();
    _selection = _repository.selectedTranslation();
    if (_repository is QuranTranslationSelectionObservable) {
      _selectionChanges =
          (_repository as QuranTranslationSelectionObservable).selectionChanges;
      _selectionChanges!.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() => _selection = _repository.selectedTranslation());
    }
  }

  @override
  void dispose() {
    _selectionChanges?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranTranslationResource?>(
      future: _selection,
      builder: (context, snapshot) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const AppIcon(Icons.headphones_rounded),
        title: const Text('Reading & listening'),
        subtitle: Text(
          snapshot.connectionState != ConnectionState.done || snapshot.hasError
              ? 'Translation language and reciter'
              : snapshot.data == null
              ? 'Bundled English translation and reciter'
              : '${snapshot.data!.displayLanguage} translation and reciter',
        ),
        trailing: const AppIcon(Icons.chevron_right_rounded),
        onTap: () async {
          await context.push(AppRoutes.quranTranslationsPath());
          _refresh();
        },
      ),
    );
  }
}

class _ReadingDetailOptions {
  const _ReadingDetailOptions({
    required this.tafsirResources,
    required this.azkarLanguageCodes,
  });

  final List<QuranTafsirResource> tafsirResources;
  final List<String> azkarLanguageCodes;
}

class _ReadingDetailSettings extends StatefulWidget {
  const _ReadingDetailSettings();

  @override
  State<_ReadingDetailSettings> createState() => _ReadingDetailSettingsState();
}

class _ReadingDetailSettingsState extends State<_ReadingDetailSettings> {
  late final SettingsStore _store;
  late Future<_ReadingDetailOptions> _optionsFuture;

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsStore>();
    _optionsFuture = _loadOptions();
  }

  Future<_ReadingDetailOptions> _loadOptions() async {
    final tafsirResources = getIt.isRegistered<QuranTafsirRepository>()
        ? await getIt<QuranTafsirRepository>().tafsirResources()
        : const <QuranTafsirResource>[];

    final azkarCodes = <String>{'en', _store.azkarLanguageCode};
    if (getIt.isRegistered<AzkarRepository>()) {
      azkarCodes.addAll(
        await getIt<AzkarRepository>().availableTranslationLanguages(),
      );
    }

    return _ReadingDetailOptions(
      tafsirResources: tafsirResources,
      azkarLanguageCodes: azkarCodes.toList()..sort(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReadingDetailOptions>(
      future: _optionsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Language options could not be loaded.'),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _optionsFuture = _loadOptions()),
                  icon: const AppIcon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final options = snapshot.data;
        if (options == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tafsirId = options.tafsirResources.isEmpty
            ? null
            : _selectedTafsirId(options.tafsirResources);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const AppIcon(Icons.menu_book_outlined),
              title: const Text('Tafsir edition'),
              subtitle: Text(
                tafsirId == null
                    ? 'No editions available'
                    : options.tafsirResources
                          .firstWhere((r) => r.id == tafsirId)
                          .name,
              ),
              trailing: const AppIcon(Icons.chevron_right_rounded),
              onTap: tafsirId == null
                  ? null
                  : () => _chooseTafsir(options, tafsirId),
            ),
            const Divider(height: 24),
            _languageRow(
              label: 'Word meanings',
              icon: Icons.segment_rounded,
              value: _store.wordMeaningLanguageCode,
              values: const ['en', 'fa', 'tr', 'ur'],
              onChanged: _store.setWordMeaningLanguageCode,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const AppIcon(Icons.library_books_outlined),
              title: const Text('Hadith translation'),
              subtitle: Text(libraryLanguageLabel(_store.hadithLanguageCode)),
              trailing: const AppIcon(Icons.chevron_right_rounded),
              onTap: () async {
                await showHadithTranslationSheet(context);
                if (mounted) setState(() {});
              },
            ),
            _languageRow(
              label: 'Azkar translation',
              icon: Icons.auto_stories_outlined,
              value: _store.azkarLanguageCode,
              values: options.azkarLanguageCodes,
              onChanged: _store.setAzkarLanguageCode,
            ),
          ],
        );
      },
    );
  }

  int _selectedTafsirId(List<QuranTafsirResource> resources) {
    final storedId = _store.tafsirResourceId;
    if (storedId != null && resources.any((item) => item.id == storedId)) {
      return storedId;
    }
    return resources
        .firstWhere(
          (resource) =>
              resource.languageName.toLowerCase() ==
              _store.tafsirLanguageName.toLowerCase(),
          orElse: () => resources.first,
        )
        .id;
  }

  Future<void> _chooseTafsir(
    _ReadingDetailOptions options,
    int selectedId,
  ) async {
    final resource = await showModalBottomSheet<QuranTafsirResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => AppSheet(
        title: 'Tafsir edition',
        scrollableChild: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.tafsirResources.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = options.tafsirResources[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(
                [
                  item.displayLanguage,
                  if (item.authorName.isNotEmpty) item.authorName,
                ].join(' · '),
              ),
              trailing: item.id == selectedId
                  ? const AppIcon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(item),
            );
          },
        ),
      ),
    );
    if (resource == null) return;
    await _store.setTafsirPreference(
      languageName: resource.languageName,
      resourceId: resource.id,
    );
    if (mounted) setState(() {});
  }

  Widget _languageRow({
    required String label,
    required IconData icon,
    required String value,
    required List<String> values,
    required Future<void> Function(String value) onChanged,
  }) {
    final codes = {...values, value}.toList()..sort();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(icon),
      title: Text(label),
      subtitle: Text(libraryLanguageLabel(value)),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: () async {
        final next = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => AppSheet(
            title: label,
            scrollableChild: true,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: codes.length,
              itemBuilder: (_, index) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(libraryLanguageLabel(codes[index])),
                trailing: codes[index] == value
                    ? const AppIcon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(codes[index]),
              ),
            ),
          ),
        );
        if (next == null) return;
        await onChanged(next);
        if (mounted) setState(() {});
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      buildWhen: (previous, current) => previous.presetId != current.presetId,
      builder: (context, state) => SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: 'white-glass',
            icon: const AppIcon(Icons.light_mode_outlined),
            label: Text(l10n.themeLight),
          ),
          ButtonSegment(
            value: 'dark-minbar',
            icon: const AppIcon(Icons.dark_mode_outlined),
            label: Text(l10n.themeDark),
          ),
        ],
        selected: {state.presetId},
        onSelectionChanged: (value) =>
            context.read<QuranThemeCubit>().setPreset(value.first),
      ),
    );
  }
}

class _FontControls extends StatefulWidget {
  const _FontControls();

  @override
  State<_FontControls> createState() => _FontControlsState();
}

class _FontControlsState extends State<_FontControls> {
  late double _scale;
  late double _weight;

  @override
  void initState() {
    super.initState();
    final state = context.read<QuranThemeCubit>().state;
    _scale = state.fontScale;
    _weight = state.fontWeightScale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeCubit = context.read<QuranThemeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fontSizeTitle),
          trailing: Text('${(_scale * 100).round()}%'),
        ),
        Slider(
          value: _scale,
          min: 0.88,
          max: 1.28,
          divisions: 8,
          label: '${(_scale * 100).round()}%',
          onChanged: (value) => setState(() => _scale = value),
          onChangeEnd: themeCubit.setFontScale,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fontWeightTitle),
          trailing: Text('${(_weight * 100).round()}%'),
        ),
        Slider(
          value: _weight,
          min: 0.72,
          max: 1.08,
          divisions: 9,
          label: '${(_weight * 100).round()}%',
          onChanged: (value) => setState(() => _weight = value),
          onChangeEnd: themeCubit.setFontWeightScale,
        ),
        AnimatedExpansion(
          expanded:
              (_scale - 1.0).abs() > 0.0001 || (_weight - 0.88).abs() > 0.0001,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _scale = 1.0;
                  _weight = 0.88;
                });
                themeCubit.resetTextAppearance();
              },
              icon: const AppIcon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset to default'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languages = {
      'system': l10n.systemLanguage,
      'en': 'English',
      'ur': 'اردو',
      'ar': 'العربية',
    };
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const AppIcon(Icons.language_rounded),
        title: Text(l10n.languageTitle),
        subtitle: Text(languages[state.preferenceCode] ?? l10n.systemLanguage),
        trailing: const AppIcon(Icons.chevron_right_rounded),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (sheetContext) => AppSheet(
            title: l10n.languageTitle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in languages.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    trailing: entry.key == state.preferenceCode
                        ? const AppIcon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      context.read<LocaleCubit>().setLocale(entry.key);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
