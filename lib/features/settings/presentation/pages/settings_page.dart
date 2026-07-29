import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/locale_state.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/adaptive_inset_area.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shell_screen_header.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../../quran/domain/entities/quran_tafsir.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_tafsir_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';

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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 112),
              children: [
                SectionHeader(title: l10n.appearanceTitle),
                const SizedBox(height: 10),
                const _ThemeSelector(),
                const SizedBox(height: 14),
                const _FontControls(),
                const SizedBox(height: 22),
                SectionHeader(title: l10n.languageTitle),
                const SizedBox(height: 10),
                const _LanguageSelector(),
                const SizedBox(height: 14),
                const _ContentLanguageSettings(),
                const SizedBox(height: 22),
                SectionHeader(title: l10n.settingsPrivacyDataTitle),
                const SizedBox(height: 10),
                const _BackupSettingsTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupSettingsTile extends StatelessWidget {
  const _BackupSettingsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumSurface(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.lock_person_rounded),
        title: Text(l10n.backupPrivacyTitle),
        subtitle: Text(l10n.backupPrivacySubtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(AppRoutes.backupPath()),
      ),
    );
  }
}

class _ContentLanguageOptions {
  const _ContentLanguageOptions({
    required this.selectedTranslation,
    required this.tafsirResources,
    required this.audioLanguageCodes,
    required this.hadithLanguageCodes,
    required this.azkarLanguageCodes,
  });

  final QuranTranslationResource? selectedTranslation;
  final List<QuranTafsirResource> tafsirResources;
  final List<String> audioLanguageCodes;
  final List<String> hadithLanguageCodes;
  final List<String> azkarLanguageCodes;
}

class _ContentLanguageSettings extends StatefulWidget {
  const _ContentLanguageSettings();

  @override
  State<_ContentLanguageSettings> createState() =>
      _ContentLanguageSettingsState();
}

class _ContentLanguageSettingsState extends State<_ContentLanguageSettings> {
  late final SettingsStore _store;
  late Future<_ContentLanguageOptions> _optionsFuture;

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsStore>();
    _optionsFuture = _loadOptions();
  }

  Future<_ContentLanguageOptions> _loadOptions() async {
    final translationRepository = getIt<QuranTranslationRepository>();
    final selectedTranslation = await translationRepository
        .selectedTranslation();
    final tafsirResources = getIt.isRegistered<QuranTafsirRepository>()
        ? await getIt<QuranTafsirRepository>().tafsirResources()
        : const <QuranTafsirResource>[];

    final reciters = await getIt<QuranRepository>().getAudioReciters();
    final audioCodes = {
      for (final reciter in reciters)
        if (reciter.isTranslation) reciter.languageCode.toLowerCase(),
      _store.audioMeaningLanguageCode,
    }.toList()..sort();

    final hadithCodes = <String>{'en', _store.hadithLanguageCode};
    if (getIt.isRegistered<HadithRepository>()) {
      final repository = getIt<HadithRepository>();
      for (final book in await repository.getBooks()) {
        hadithCodes.addAll(
          await repository.availableTranslationLanguagesForBook(book.id),
        );
      }
    }

    final azkarCodes = <String>{'en', _store.azkarLanguageCode};
    if (getIt.isRegistered<AzkarRepository>()) {
      azkarCodes.addAll(
        await getIt<AzkarRepository>().availableTranslationLanguages(),
      );
    }

    return _ContentLanguageOptions(
      selectedTranslation: selectedTranslation,
      tafsirResources: tafsirResources,
      audioLanguageCodes: audioCodes,
      hadithLanguageCodes: hadithCodes.toList()..sort(),
      azkarLanguageCodes: azkarCodes.toList()..sort(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumSurface(
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<_ContentLanguageOptions>(
        future: _optionsFuture,
        builder: (context, snapshot) {
          final options = snapshot.data;
          if (options == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final selectedTafsirId = _selectedTafsirId(options.tafsirResources);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.contentLanguagesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.contentLanguagesSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.66),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Quran translation'),
                subtitle: Text(
                  options.selectedTranslation == null
                      ? 'Bundled English'
                      : '${options.selectedTranslation!.displayLanguage} • ${options.selectedTranslation!.name}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(
                  AppRoutes.quranDownloadsPath(showTranslations: true),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.quranTranslationsPath()),
                icon: const Icon(Icons.compare_arrows_rounded),
                label: Text(l10n.translationManageAction),
              ),
              if (options.tafsirResources.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: selectedTafsirId,
                  decoration: const InputDecoration(
                    labelText: 'Tafsir edition',
                    prefixIcon: Icon(Icons.menu_book_rounded),
                  ),
                  items: [
                    for (final resource in options.tafsirResources)
                      DropdownMenuItem(
                        value: resource.id,
                        child: Text(
                          '${resource.displayLanguage} • ${resource.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) async {
                    if (id == null) {
                      return;
                    }
                    final resource = options.tafsirResources.firstWhere(
                      (item) => item.id == id,
                    );
                    await _store.setTafsirPreference(
                      languageName: resource.languageName,
                      resourceId: resource.id,
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              _languageDropdown(
                label: 'Word meanings',
                icon: Icons.segment_rounded,
                value: _store.wordMeaningLanguageCode,
                values: const ['en', 'fa', 'tr', 'ur'],
                onChanged: _store.setWordMeaningLanguageCode,
              ),
              const SizedBox(height: 10),
              _languageDropdown(
                label: 'Audio meaning',
                icon: Icons.record_voice_over_rounded,
                value: _store.audioMeaningLanguageCode,
                values: options.audioLanguageCodes,
                onChanged: (code) async {
                  await _store.setAudioMeaningLanguageCode(code);
                  await _store.setAudioTranslationReciterId('');
                },
              ),
              const SizedBox(height: 10),
              _languageDropdown(
                label: 'Hadith translation',
                icon: Icons.library_books_rounded,
                value: _store.hadithLanguageCode,
                values: options.hadithLanguageCodes,
                onChanged: _store.setHadithLanguageCode,
              ),
              const SizedBox(height: 10),
              _languageDropdown(
                label: 'Azkar translation',
                icon: Icons.auto_stories_rounded,
                value: _store.azkarLanguageCode,
                values: options.azkarLanguageCodes,
                onChanged: _store.setAzkarLanguageCode,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.onboardingPath(edit: true)),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Review setup journey'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _selectedTafsirId(List<QuranTafsirResource> resources) {
    final storedId = _store.tafsirResourceId;
    if (storedId != null && resources.any((item) => item.id == storedId)) {
      return storedId;
    }
    for (final resource in resources) {
      if (resource.languageName.toLowerCase() ==
          _store.tafsirLanguageName.toLowerCase()) {
        return resource.id;
      }
    }
    return resources.first.id;
  }

  Widget _languageDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> values,
    required Future<void> Function(String value) onChanged,
  }) {
    final normalizedValues = {...values, value}.toList()..sort();
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        for (final code in normalizedValues)
          DropdownMenuItem(
            value: code,
            child: Text(
              '${libraryLanguageLabel(code)} (${code.toUpperCase()})',
            ),
          ),
      ],
      onChanged: (next) async {
        if (next == null) {
          return;
        }
        await onChanged(next);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _pickTafsir(List<QuranTafsirResource> resources) async {
    final selectedId = _selectedTafsirId(resources);
    final resource = await showModalBottomSheet<QuranTafsirResource>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          for (final item in resources)
            RadioListTile<int>(
              value: item.id,
              groupValue: selectedId,
              title: Text(item.name),
              subtitle: Text('${item.displayLanguage} • ${item.authorName}'),
              onChanged: (_) => Navigator.of(context).pop(item),
            ),
        ],
      ),
    );
    if (resource == null) {
      return;
    }
    await _store.setTafsirPreference(
      languageName: resource.languageName,
      resourceId: resource.id,
    );
    if (mounted) {
      setState(() {});
    }
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      builder: (context, state) {
        return PremiumSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.themeTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _ThemeChoiceTile(
                presetId: 'white-glass',
                label: l10n.themeWhite,
                icon: Icons.grid_view_rounded,
                selected: state.presetId == 'white-glass',
              ),
              const SizedBox(height: 8),
              _ThemeChoiceTile(
                presetId: 'light-sanctuary',
                label: l10n.themeLight,
                icon: Icons.wb_sunny_rounded,
                selected: state.presetId == 'light-sanctuary',
              ),
              const SizedBox(height: 8),
              _ThemeChoiceTile(
                presetId: 'dark-minbar',
                label: l10n.themeDark,
                icon: Icons.bedtime_rounded,
                selected: state.presetId == 'dark-minbar',
              ),
              const SizedBox(height: 8),
              _ThemeChoiceTile(
                presetId: 'black-gold',
                label: l10n.themeBlack,
                icon: Icons.contrast_rounded,
                selected: state.presetId == 'black-gold',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.presetId,
    required this.label,
    required this.icon,
    required this.selected,
  });

  final String presetId;
  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => context.read<QuranThemeCubit>().setPreset(presetId),
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? QuranTheme.softFill(context, primary) : null,
          borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.30)
                : QuranTheme.outline(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: QuranTheme.softFill(context, primary),
                borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : QuranTheme.subText(context, 0.36),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontControls extends StatelessWidget {
  const _FontControls();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      builder: (context, state) {
        final themeCubit = context.read<QuranThemeCubit>();
        return PremiumSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.fontSizeTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Slider(
                value: state.fontScale,
                min: 0.88,
                max: 1.28,
                divisions: 8,
                label: state.fontScale.toStringAsFixed(2),
                onChanged: themeCubit.setFontScale,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.fontWeightTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Slider(
                value: state.fontWeightScale,
                min: 0.72,
                max: 1.08,
                divisions: 9,
                label: state.fontWeightScale.toStringAsFixed(2),
                onChanged: themeCubit.setFontWeightScale,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        return PremiumSurface(
          padding: const EdgeInsets.all(14),
          child: DropdownButtonFormField<String>(
            initialValue: state.preferenceCode,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.language_rounded),
            ),
            items: [
              DropdownMenuItem(
                value: 'system',
                child: Text(l10n.systemLanguage),
              ),
              const DropdownMenuItem(value: 'en', child: Text('English')),
              const DropdownMenuItem(value: 'ur', child: Text('اردو')),
              const DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<LocaleCubit>().setLocale(value);
            },
          ),
        );
      },
    );
  }
}
