import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../quran_audio/domain/services/quran_translation_audio_selector.dart';
import '../../../quran_audio/presentation/widgets/quran_reciter_picker.dart';
import '../../../quran_audio/presentation/widgets/quran_translation_voice_change.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import '../../domain/services/quran_reading_preferences.dart';
import '../../domain/services/quran_translation_audio_pairings.dart';
import 'quran_translation_picker.dart';

/// A draft preference editor. Its owner decides when to download and save.
class QuranReadingPreferences extends StatefulWidget {
  const QuranReadingPreferences({
    super.key,
    this.translation,
    required this.reciterId,
    this.translationVoiceId,
    required this.onTranslationChanged,
    required this.onReciterChanged,
    this.onTranslationVoiceChanged,
    this.enabled = true,
    this.requireLanguageSelection = false,
    this.arabicReciterFirst = false,
  });

  final QuranTranslationResource? translation;
  final String? reciterId;
  final String? translationVoiceId;
  final ValueChanged<QuranTranslationResource?> onTranslationChanged;
  final ValueChanged<QuranAudioReciter> onReciterChanged;
  final ValueChanged<QuranAudioReciter?>? onTranslationVoiceChanged;
  final bool enabled;
  final bool requireLanguageSelection;
  final bool arabicReciterFirst;

  @override
  State<QuranReadingPreferences> createState() =>
      _QuranReadingPreferencesState();
}

class _QuranReadingPreferencesState extends State<QuranReadingPreferences> {
  late Future<List<QuranAudioReciter>> _reciters;

  @override
  void initState() {
    super.initState();
    _reciters = getIt<QuranRepository>().getAudioReciters();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuranAudioReciter>>(
      future: _reciters,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              const Text('Your reading choices could not be loaded.'),
              TextButton.icon(
                onPressed: () => setState(
                  () => _reciters = getIt<QuranRepository>().getAudioReciters(),
                ),
                icon: const AppIcon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          );
        }
        final reciters = snapshot.data;
        if (reciters == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final arabic = reciters.where((item) => !item.isTranslation).toList();
        final reciter =
            arabic.where((item) => item.id == widget.reciterId).firstOrNull ??
            arabic.firstOrNull;
        final translation = widget.translation;
        final voices = quranCompatibleTranslationAudioReciters(
          reciters: reciters,
          selectedTranslation: translation,
        );
        final voice = preferredQuranTranslationVoice(
          voices,
          preferredId: widget.translationVoiceId,
        );
        final languageVoices =
            quranTranslationAudioRecitersFor(
                  reciters: reciters,
                  selectedTranslation: translation,
                )
                .where((item) => quranTranslationPairForVoice(item.id) != null)
                .toList();
        final arabicSection = [
          const _SectionLabel('Arabic recitation'),
          _ChoiceTile(
            icon: Icons.record_voice_over_rounded,
            leading: reciter == null
                ? null
                : QuranReciterAvatar(reciter: reciter, size: 40),
            label: 'Reciter',
            value: reciter?.name ?? 'Choose reciter',
            onTap: widget.enabled && arabic.isNotEmpty
                ? () async {
                    final selected = await showQuranReciterPickerSheet(
                      context,
                      reciters: arabic,
                      selectedReciterId: reciter?.id,
                    );
                    if (selected != null && mounted) {
                      widget.onReciterChanged(selected);
                    }
                  }
                : null,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.arabicReciterFirst) ...[
              ...arabicSection,
              const Divider(height: 32),
            ],
            _ChoiceTile(
              icon: Icons.translate_rounded,
              label: 'Language',
              value:
                  translation?.displayLanguage ??
                  (widget.requireLanguageSelection
                      ? 'Select language'
                      : 'English'),
              filled: true,
              onTap: widget.enabled ? () => _chooseLanguage(reciters) : null,
            ),
            if (!widget.requireLanguageSelection || translation != null) ...[
              const SizedBox(height: 24),
              const _SectionLabel('Translation'),
              _ChoiceTile(
                icon: Icons.menu_book_outlined,
                label: 'Text edition',
                value: translation?.name ?? 'Bundled English',
                subtitle: translation == null ? 'Available offline' : null,
                onTap: widget.enabled ? () => _chooseEdition(reciters) : null,
              ),
              if (widget.onTranslationVoiceChanged != null) ...[
                const Divider(height: 1, indent: 68, endIndent: 12),
                _ChoiceTile(
                  icon: Icons.headphones_rounded,
                  leading: voice == null
                      ? null
                      : QuranReciterAvatar(reciter: voice, size: 40),
                  label: 'Matching voice',
                  value: voice?.name ?? 'No matching audio',
                  subtitle: voice != null
                      ? 'Reads this text edition'
                      : languageVoices.isNotEmpty
                      ? 'Voices available with another text edition'
                      : translation == null
                      ? 'Choose a text edition for paired audio'
                      : 'Text only in ${translation.displayLanguage}',
                  onTap: !widget.enabled
                      ? null
                      : translation == null
                      ? () => _chooseEdition(reciters)
                      : languageVoices.isNotEmpty
                      ? () => _chooseVoice(languageVoices, voice)
                      : null,
                ),
              ],
            ],
            if (!widget.arabicReciterFirst) ...[
              const Divider(height: 32),
              ...arabicSection,
            ],
          ],
        );
      },
    );
  }

  Future<void> _chooseLanguage(List<QuranAudioReciter> reciters) async {
    final result = await showModalBottomSheet<QuranTranslationResource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranTranslationPicker(
        repository: getIt<QuranTranslationRepository>(),
        currentResource: widget.translation,
        languagesOnly: true,
        reciters: reciters,
      ),
    );
    if (result == null || !mounted) return;
    _selectTranslation(result, reciters);
  }

  Future<void> _chooseEdition(List<QuranAudioReciter> reciters) async {
    final repository = getIt<QuranTranslationRepository>();
    try {
      final languages = await repository.translationLanguages();
      if (!mounted) return;
      final translation = widget.translation;
      final language = languages
          .where(
            (item) => item.availableResources.any((resource) {
              return translation == null
                  ? resource.resolvedLanguageCode == 'en'
                  : resource.id == translation.id;
            }),
          )
          .firstOrNull;
      if (language == null) {
        throw StateError('Translation editions are unavailable.');
      }
      final editions = [...language.availableResources]
        ..sort((a, b) {
          final aAudio = quranTranslationHasMatchingAudio(a, reciters);
          final bAudio = quranTranslationHasMatchingAudio(b, reciters);
          return aAudio == bAudio
              ? a.name.compareTo(b.name)
              : aAudio
              ? -1
              : 1;
        });
      final selected = await showModalBottomSheet<QuranTranslationResource>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AppSheet(
          title: '${language.displayName} text edition',
          scrollableChild: true,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: editions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final resource = editions[index];
              return ListTile(
                title: Text(resource.name),
                subtitle: Text(
                  '${resource.translator} · ${quranTranslationHasMatchingAudio(resource, reciters) ? 'Text + audio' : 'Text only'}',
                ),
                trailing: resource.id == translation?.id
                    ? const AppIcon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, resource),
              );
            },
          ),
        ),
      );
      if (selected != null && mounted) _selectTranslation(selected, reciters);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load editions. Please try again.'),
          ),
        );
      }
    }
  }

  void _selectTranslation(
    QuranTranslationResource? translation,
    List<QuranAudioReciter> reciters,
  ) {
    final voices = quranCompatibleTranslationAudioReciters(
      reciters: reciters,
      selectedTranslation: translation,
    );
    final savedId = translation == null
        ? null
        : getIt<SettingsStore>().translationVoiceForLanguage(
            translation.resolvedLanguageCode,
          );
    final voice = preferredQuranTranslationVoice(
      voices,
      preferredId: savedId,
      legacyId: widget.translationVoiceId,
    );
    widget.onTranslationChanged(translation);
    widget.onTranslationVoiceChanged?.call(voice);
  }

  Future<void> _chooseVoice(
    List<QuranAudioReciter> voices,
    QuranAudioReciter? current,
  ) async {
    final selected = await showQuranReciterPickerSheet(
      context,
      reciters: voices,
      selectedReciterId: current?.id,
      title: 'Translation voice',
    );
    if (selected == null || !mounted) return;
    final pair = quranTranslationPairForVoice(selected.id);
    if (pair == null) return;
    final confirmed = await confirmQuranTranslationVoiceChange(
      context: context,
      voice: selected,
      currentTranslation: widget.translation,
      draftOnly: true,
    );
    if (!confirmed || !mounted) return;
    widget.onTranslationChanged(pair.resource);
    widget.onTranslationVoiceChanged?.call(selected);
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.leading,
    this.filled = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Widget? leading;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? QuranTheme.softFill(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child:
                    leading ??
                    Center(
                      child: AppIcon(
                        icon,
                        size: 24,
                        color: QuranTheme.text(context),
                      ),
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 12),
                AppIcon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: QuranTheme.subText(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
