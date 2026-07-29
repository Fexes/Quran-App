import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/presentation/widgets/quran_translation_text.dart';

class LibraryArabicText extends StatelessWidget {
  const LibraryArabicText({
    super.key,
    required this.text,
    required this.themeState,
    this.selected = false,
  });

  final String text;
  final QuranThemeState themeState;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 25 * themeState.quranArabicFontScale,
        height: 1.72,
        color: selected
            ? QuranTheme.quranTextSelected(context)
            : QuranTheme.quranTextNormal(context),
      ),
    );
  }
}

class LibraryTranslationBody extends StatelessWidget {
  const LibraryTranslationBody({
    super.key,
    required this.text,
    required this.themeState,
    this.resource,
  });

  final String text;
  final QuranThemeState themeState;
  final QuranTranslationResource? resource;

  @override
  Widget build(BuildContext context) {
    return QuranTranslationText(
      text: text,
      resource: resource,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 15 * themeState.quranTranslationFontScale,
        color: QuranTheme.subText(context, 0.82),
        height: 1.48,
      ),
    );
  }
}

class LibraryTranslationUnavailable extends StatelessWidget {
  const LibraryTranslationUnavailable({super.key, required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: QuranTheme.outline(context)),
      ),
      child: Text(
        'Translation not available in $languageLabel.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: QuranTheme.subText(context, 0.72),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LibraryReaderActionBar extends StatelessWidget {
  const LibraryReaderActionBar({
    super.key,
    required this.title,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onNote,
    required this.onCopy,
    required this.onShare,
    required this.onSource,
    required this.onDetails,
  });

  final String title;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSource;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: QuranTheme.radiusDock,
      prominent: true,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _LibraryActionButton(
                  tooltip: isBookmarked ? 'Remove save' : 'Save',
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  onTap: onBookmark,
                ),
                _LibraryActionButton(
                  tooltip: 'Note',
                  icon: Icons.edit_note_rounded,
                  onTap: onNote,
                ),
                _LibraryActionButton(
                  tooltip: 'Copy',
                  icon: Icons.copy_rounded,
                  onTap: onCopy,
                ),
                _LibraryActionButton(
                  tooltip: 'Share',
                  icon: Icons.ios_share_rounded,
                  onTap: onShare,
                ),
                _LibraryActionButton(
                  tooltip: 'Source',
                  icon: Icons.info_outline_rounded,
                  onTap: onSource,
                ),
                _LibraryActionButton(
                  tooltip: 'Details',
                  icon: Icons.more_horiz_rounded,
                  onTap: onDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryReaderSettingsSheet extends StatelessWidget {
  const LibraryReaderSettingsSheet({
    super.key,
    required this.languageLabel,
    required this.showTranslation,
    required this.onTranslationChanged,
    required this.onLanguageTap,
    this.showTransliteration,
    this.onTransliterationChanged,
    this.showExplanation,
    this.onExplanationChanged,
  });

  final String languageLabel;
  final bool showTranslation;
  final ValueChanged<bool> onTranslationChanged;
  final VoidCallback onLanguageTap;
  final bool? showTransliteration;
  final ValueChanged<bool>? onTransliterationChanged;
  final bool? showExplanation;
  final ValueChanged<bool>? onExplanationChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      margin: const EdgeInsets.all(12),
      radius: QuranTheme.radiusSheet,
      prominent: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: BlocBuilder<QuranThemeCubit, QuranThemeState>(
        builder: (context, themeState) {
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reader settings',
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Translation'),
                  subtitle: Text(languageLabel),
                  value: showTranslation,
                  onChanged: onTranslationChanged,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Translation language'),
                  subtitle: Text(languageLabel),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onLanguageTap,
                ),
                if (showTransliteration != null &&
                    onTransliterationChanged != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Transliteration'),
                    value: showTransliteration!,
                    onChanged: onTransliterationChanged,
                  ),
                if (showExplanation != null && onExplanationChanged != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Explanation'),
                    value: showExplanation!,
                    onChanged: onExplanationChanged,
                  ),
                const SizedBox(height: 8),
                _FontScaleControl(
                  title: 'Arabic text size',
                  value: themeState.quranArabicFontScale,
                  onChanged: (value) => context
                      .read<QuranThemeCubit>()
                      .setQuranArabicFontScale(value),
                ),
                const SizedBox(height: 10),
                _FontScaleControl(
                  title: 'Translation text size',
                  value: themeState.quranTranslationFontScale,
                  onChanged: (value) => context
                      .read<QuranThemeCubit>()
                      .setQuranTranslationFontScale(value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FontScaleControl extends StatelessWidget {
  const _FontScaleControl({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        border: Border.all(color: QuranTheme.outline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text('${(value * 100).round()}%'),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => onChanged(value - 0.05),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Slider(
                  value: value.clamp(0.82, 1.42).toDouble(),
                  min: 0.82,
                  max: 1.42,
                  divisions: 12,
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 0.05),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryActionButton extends StatelessWidget {
  const _LibraryActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
    );
  }
}
