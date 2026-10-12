import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../core/constants/quran_arabic_script.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../quran_audio/domain/entities/quran_audio_queue_item.dart';
import '../../../quran_audio/domain/entities/quran_audio_state.dart';
import '../../../quran_audio/presentation/widgets/quran_audio_seek_bar.dart';
import '../../domain/entities/quran_ayah.dart';
import 'surah_image_avatar.dart';

class QuranReaderFloatingControls extends StatelessWidget {
  const QuranReaderFloatingControls({
    super.key,
    required this.selectedAyah,
    required this.audioState,
    required this.showTranslation,
    required this.isBookmarked,
    required this.arabicFontScale,
    required this.onPrimaryPlay,
    this.onPlaySelected,
    required this.onStop,
    required this.onBookmark,
    required this.onTafsir,
    this.onNote,
    this.onShare,
    required this.onPlaybackMenu,
    this.onPrevious,
    this.onTogglePlayPause,
    this.onNext,
    this.onSeek,
  });

  final QuranAyah? selectedAyah;
  final QuranAudioState audioState;
  final bool showTranslation;
  final bool isBookmarked;
  final double arabicFontScale;
  final VoidCallback onPrimaryPlay;
  final VoidCallback? onPlaySelected;
  final VoidCallback onStop;
  final VoidCallback onBookmark;
  final VoidCallback? onTafsir;
  final VoidCallback? onNote;
  final VoidCallback? onShare;
  final VoidCallback onPlaybackMenu;
  final VoidCallback? onPrevious;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final item = audioState.currentItem;
    final visibleAyah = selectedAyah;
    final audioVisible =
        audioState.hasItem && audioState.status != QuranAudioStatus.idle;
    final showVersePreview = !audioVisible && visibleAyah != null;
    if (!showVersePreview && item == null) {
      return const SizedBox.shrink();
    }

    final selectedVerseKey = visibleAyah?.verseKey;
    final activeSelection =
        selectedVerseKey != null && item?.verseKey == selectedVerseKey;
    final primary = Theme.of(context).colorScheme.primary;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PremiumSurface(
        shadowStyle: PremiumSurfaceShadowStyle.floating,
        radius: QuranTheme.radiusDock,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        prominent: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (audioVisible && item != null)
              _AudioSummary(
                item: item,
                selectedAyah: selectedAyah,
                isPlaying: audioState.isPlaying,
                onPlaySelected: onPlaySelected,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VerseBubble(
                    label: visibleAyah?.number.toString() ?? 'Audio',
                    active: activeSelection,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ayah ${visibleAyah?.number ?? ''} selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visibleAyah?.verseKey ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.68),
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (audioVisible) ...[
              const SizedBox(height: 9),
              QuranAudioSeekBar(state: audioState, onSeek: onSeek),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundControl(
                      tooltip: 'Playback options',
                      icon: Icons.tune_rounded,
                      onTap: selectedAyah == null ? null : onPlaybackMenu,
                    ),
                    _RoundControl(
                      tooltip: isBookmarked
                          ? 'Remove bookmark'
                          : 'Bookmark ayah',
                      icon: isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      active: isBookmarked,
                      onTap: selectedAyah == null ? null : onBookmark,
                    ),
                    _RoundControl(
                      tooltip: 'Open tafsir',
                      icon: Icons.menu_book_rounded,
                      onTap: onTafsir,
                    ),
                    if (!audioVisible)
                      _VerseMoreControl(onNote: onNote, onShare: onShare),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (audioVisible) ...[
                      _RoundControl(
                        tooltip: 'Previous ayah',
                        icon: Icons.skip_previous_rounded,
                        onTap: audioState.hasPrevious ? onPrevious : null,
                      ),
                      _RoundControl(
                        tooltip: audioState.status == QuranAudioStatus.completed
                            ? 'Replay recitation'
                            : audioState.isPlaying
                            ? 'Pause recitation'
                            : 'Resume recitation',
                        icon: audioState.status == QuranAudioStatus.completed
                            ? Icons.replay_rounded
                            : audioState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        active: true,
                        loading: audioState.isLoading,
                        onTap: onTogglePlayPause,
                      ),
                      _RoundControl(
                        tooltip: 'Next ayah',
                        icon: Icons.skip_next_rounded,
                        onTap: audioState.hasNext ? onNext : null,
                      ),
                      _RoundControl(
                        tooltip: 'Close and stop audio',
                        icon: Icons.close_rounded,
                        onTap: onStop,
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: onPrimaryPlay,
                        icon: const AppIcon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioSummary extends StatelessWidget {
  const _AudioSummary({
    required this.item,
    required this.selectedAyah,
    required this.isPlaying,
    required this.onPlaySelected,
  });

  final QuranAudioQueueItem item;
  final QuranAyah? selectedAyah;
  final bool isPlaying;
  final VoidCallback? onPlaySelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedAyah;
    final showPlaySelected =
        selected != null && selected.verseKey != item.verseKey;
    return Row(
      children: [
        SurahImageAvatar(
          surahNumber: item.surahNumber,
          active: isPlaying,
          fallbackLabel: item.verseKey,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.surahName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                item.verseKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (showPlaySelected) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onPlaySelected,
            icon: const AppIcon(Icons.play_arrow_rounded, size: 18),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Play selected'),
                Text(
                  selected.verseKey,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsetsDirectional.only(
                start: 10,
                end: 12,
                top: 5,
                bottom: 5,
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class QuranReaderArabicText extends StatelessWidget {
  const QuranReaderArabicText({
    super.key,
    required this.text,
    required this.arabicFontScale,
    this.activeWordIndex,
    this.selected = false,
    this.highlighterActive = false,
    this.maxLines,
    this.textAlign = TextAlign.right,
    this.lineHeight = 1.55,
    this.arabicScript = QuranArabicScript.uthmani,
  });

  final String text;
  final double arabicFontScale;
  final int? activeWordIndex;
  final bool selected;
  final bool highlighterActive;
  final int? maxLines;
  final TextAlign textAlign;
  final double lineHeight;
  final QuranArabicScript arabicScript;

  @override
  Widget build(BuildContext context) {
    final fontSize = 24 * arabicFontScale;
    final effectiveHeight = lineHeight > arabicScript.readerLineHeight
        ? lineHeight
        : arabicScript.readerLineHeight;
    final baseStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: fontSize,
      fontFamily: arabicScript.fontFamily,
      height: effectiveHeight,
      fontWeight: FontWeight.w700,
      color: selected || highlighterActive
          ? QuranTheme.quranTextSelected(context)
          : QuranTheme.quranTextNormal(context),
    );
    final strutStyle = StrutStyle(
      fontSize: fontSize,
      fontFamily: arabicScript.fontFamily,
      height: effectiveHeight,
      fontWeight: FontWeight.w700,
    );
    final activeIndex = activeWordIndex;
    if (activeIndex == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textScaler: MediaQuery.textScalerOf(context),
          strutStyle: strutStyle,
          maxLines: maxLines,
          overflow: maxLines == null
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          textAlign: textAlign,
          text: TextSpan(style: baseStyle, text: text),
        ),
      );
    }

    final words = QuranArabicScript.wordSpans(text);
    final wordHighlight = QuranTheme.wordHighlight(context);
    final inactiveColor = selected || highlighterActive
        ? QuranTheme.quranTextSelected(context)
        : QuranTheme.quranTextNormal(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        strutStyle: strutStyle,
        maxLines: maxLines,
        overflow: maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        textAlign: textAlign,
        text: TextSpan(
          style: baseStyle?.copyWith(color: inactiveColor),
          children: [
            for (var index = 0; index < words.length; index++)
              TextSpan(
                text: words[index],
                style: index + 1 == activeIndex
                    ? TextStyle(color: wordHighlight)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _VerseBubble extends StatelessWidget {
  const _VerseBubble({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      height: 42,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        color: active ? primary : QuranTheme.softFill(context, primary),
        border: Border.all(
          color: active ? primary : QuranTheme.outline(context),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: active ? Colors.white : primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? primary : Colors.transparent,
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: active
                        ? Theme.of(context).colorScheme.onPrimary
                        : primary,
                  ),
                )
              : AppIcon(
                  icon,
                  size: 22,
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : onTap == null
                      ? QuranTheme.subText(context, 0.32)
                      : null,
                ),
        ),
      ),
    );
  }
}

enum _VerseMoreAction { note, share }

class _VerseMoreControl extends StatelessWidget {
  const _VerseMoreControl({required this.onNote, required this.onShare});

  final VoidCallback? onNote;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: PopupMenuButton<_VerseMoreAction>(
        tooltip: 'More ayah actions',
        padding: EdgeInsets.zero,
        icon: const AppIcon(Icons.more_horiz_rounded, size: 22),
        onSelected: (action) {
          switch (action) {
            case _VerseMoreAction.note:
              onNote?.call();
            case _VerseMoreAction.share:
              onShare?.call();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _VerseMoreAction.note,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppIcon(Icons.edit_note_rounded),
              title: Text('Add ayah note'),
            ),
          ),
          PopupMenuItem(
            value: _VerseMoreAction.share,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppIcon(Icons.share_rounded),
              title: Text('Share ayah'),
            ),
          ),
        ],
      ),
    );
  }
}
