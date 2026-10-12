import 'package:flutter/material.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/reader_text_size_control.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/theme/quran_theme_state.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../core/widgets/app_sheet.dart';
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
    this.languageCode,
  });

  final String text;
  final QuranThemeState themeState;
  final QuranTranslationResource? resource;
  final String? languageCode;

  @override
  Widget build(BuildContext context) {
    return QuranTranslationText(
      text: text,
      resource: resource,
      style: QuranTheme.translationStyle(
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15 * themeState.quranTranslationFontScale,
          color: QuranTheme.subText(context, 0.82),
          height: 1.48,
        ),
        languageCode ?? resource?.resolvedLanguageCode,
      ),
    );
  }
}

class LibraryTranslationUnavailable extends StatelessWidget {
  const LibraryTranslationUnavailable({super.key, required this.languageLabel});

  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Translation not available in $languageLabel.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: QuranTheme.subText(context, 0.72),
          fontWeight: FontWeight.w400,
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

  static double bottomClearance(BuildContext context) =>
      96 +
      MediaQuery.textScalerOf(context).scale(14) * 1.4 +
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: PremiumSurface(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        radius: QuranTheme.radiusDock,
        prominent: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}

class LibraryReaderSettingsSheet extends StatefulWidget {
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
  State<LibraryReaderSettingsSheet> createState() =>
      _LibraryReaderSettingsSheetState();
}

class _LibraryReaderSettingsSheetState
    extends State<LibraryReaderSettingsSheet> {
  late bool _translation = widget.showTranslation;
  late bool _transliteration = widget.showTransliteration ?? false;
  late bool _explanation = widget.showExplanation ?? false;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Reader settings',
      child: BlocBuilder<QuranThemeCubit, QuranThemeState>(
        builder: (context, themeState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Translation'),
                subtitle: Text(widget.languageLabel),
                value: _translation,
                onChanged: (value) {
                  setState(() => _translation = value);
                  widget.onTranslationChanged(value);
                },
              ),
              AnimatedExpansion(
                expanded: _translation,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const AppIcon(Icons.language_rounded),
                  title: const Text('Translation language'),
                  subtitle: Text(widget.languageLabel),
                  trailing: const AppIcon(Icons.chevron_right_rounded),
                  onTap: widget.onLanguageTap,
                ),
              ),
              if (widget.showTransliteration != null &&
                  widget.onTransliterationChanged != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Transliteration'),
                  value: _transliteration,
                  onChanged: (value) {
                    setState(() => _transliteration = value);
                    widget.onTransliterationChanged!(value);
                  },
                ),
              if (widget.showExplanation != null &&
                  widget.onExplanationChanged != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Explanation'),
                  value: _explanation,
                  onChanged: (value) {
                    setState(() => _explanation = value);
                    widget.onExplanationChanged!(value);
                  },
                ),
              const SizedBox(height: 8),
              ReaderTextSizeControl(
                title: 'Arabic text size',
                value: themeState.quranArabicFontScale,
                onChanged: (value) => context
                    .read<QuranThemeCubit>()
                    .setQuranArabicFontScale(value),
              ),
              AnimatedExpansion(
                expanded: _translation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ReaderTextSizeControl(
                    title: 'Translation text size',
                    value: themeState.quranTranslationFontScale,
                    onChanged: (value) => context
                        .read<QuranThemeCubit>()
                        .setQuranTranslationFontScale(value),
                  ),
                ),
              ),
            ],
          );
        },
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
      icon: AppIcon(icon),
      visualDensity: VisualDensity.compact,
    );
  }
}
