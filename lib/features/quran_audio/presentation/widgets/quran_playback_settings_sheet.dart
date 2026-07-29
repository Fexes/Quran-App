import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../domain/entities/quran_audio_state.dart';
import '../../domain/services/quran_translation_audio_selector.dart';
import '../cubit/quran_audio_cubit.dart';
import 'quran_reciter_picker.dart';

Future<void> showQuranPlaybackSettingsSheet({
  required BuildContext context,
  required QuranAudioState audioState,
  required List<QuranAudioReciter> reciters,
  required Future<void> Function(QuranAudioReciter reciter) onReciterSelected,
  QuranAudioReciter? selectedReciter,
  QuranTranslationResource? selectedTranslation,
  String? audioMeaningLanguageCode,
  String? currentRangeLabel,
}) {
  final callerContext = context;
  final arabicReciters = reciters
      .where((reciter) => !reciter.isTranslation)
      .toList(growable: false);
  final translationReciters = quranTranslationAudioRecitersFor(
    reciters: reciters,
    selectedTranslation: selectedTranslation,
    preferredLanguageCode: audioMeaningLanguageCode,
  );
  final translationLanguageLabel = quranTranslationAudioLanguageLabel(
    selectedTranslation,
    preferredLanguageCode: audioMeaningLanguageCode,
  );
  final hasTranslationAudio = translationReciters.isNotEmpty;

  QuranAudioReciter? arabicReciterById(String? id) {
    if (id == null) {
      return null;
    }
    for (final reciter in arabicReciters) {
      if (reciter.id == id) {
        return reciter;
      }
    }
    return null;
  }

  QuranAudioReciter? translationReciterById(String? id) {
    if (id == null) {
      return null;
    }
    for (final reciter in translationReciters) {
      if (reciter.id == id) {
        return reciter;
      }
    }
    return null;
  }

  var sheetReciter =
      selectedReciter ??
      arabicReciterById(
        audioState.currentItem?.isTranslationSegment == true
            ? null
            : audioState.currentItem?.reciterId,
      );
  if (sheetReciter?.isTranslation == true) {
    sheetReciter = null;
  }
  var sheetReciterName = sheetReciter?.name ?? 'Choose reciter';
  var sheetReciterId = sheetReciter?.id;
  var sheetPlayTranslationAudio =
      audioState.playTranslationAudio && hasTranslationAudio;
  var sheetTranslationReciter =
      translationReciterById(audioState.translationReciterId) ??
      (audioState.currentItem?.isTranslationSegment == true
          ? translationReciterById(audioState.currentItem?.reciterId)
          : null);
  if (sheetPlayTranslationAudio &&
      sheetTranslationReciter == null &&
      hasTranslationAudio) {
    sheetTranslationReciter = translationReciters.first;
  }
  var sheetSpeed = audioState.speed.clamp(0.75, 2.0).toDouble();
  var sheetRepeatMode = audioState.repeatMode;
  var sheetRepeatCount = audioState.repeatCount;
  var sheetRepeatAfterAction = audioState.repeatAfterAction;
  final audioCubit = callerContext.read<QuranAudioCubit>();
  final activeSurah = audioCubit.activeSurah;
  final activeSurahAyahCount =
      activeSurah != null &&
          activeSurah.number == audioState.currentItem?.surahNumber
      ? activeSurah.ayahCount
      : null;
  final rangeBounds = _repeatRangeBounds(
    audioState,
    activeSurahAyahCount: activeSurahAyahCount,
  );
  var sheetRangeStartAyah =
      audioState.rangeStartAyah ??
      audioState.currentItem?.ayahNumber ??
      rangeBounds.minAyah;
  var sheetRangeEndAyah =
      audioState.rangeEndAyah ??
      audioState.currentItem?.ayahNumber ??
      rangeBounds.maxAyah;
  final rangeLabel =
      currentRangeLabel ??
      (audioState.scopeLabel.trim().isEmpty
          ? 'No active range'
          : audioState.scopeLabel);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.16),
    builder: (sheetContext) {
      Future<void> chooseReciter(StateSetter setSheetState) async {
        final selected = await showQuranReciterPickerSheet(
          sheetContext,
          reciters: arabicReciters,
          selectedReciterId: sheetReciterId,
          title: 'Choose reciter',
        );
        if (selected == null || !callerContext.mounted) {
          return;
        }
        await onReciterSelected(selected);
        if (!sheetContext.mounted) {
          return;
        }
        setSheetState(() {
          sheetReciter = selected;
          sheetReciterName = selected.name;
          sheetReciterId = selected.id;
        });
      }

      Future<QuranAudioReciter?> chooseTranslationReciter(
        StateSetter setSheetState,
      ) async {
        final selected = await showQuranReciterPickerSheet(
          sheetContext,
          reciters: translationReciters,
          selectedReciterId: sheetTranslationReciter?.id,
          title: 'Choose translation voice',
        );
        if (selected == null || !callerContext.mounted) {
          return null;
        }
        await audioCubit.changeTranslationReciter(selected.id);
        if (!sheetContext.mounted) {
          return selected;
        }
        setSheetState(() {
          sheetTranslationReciter = selected;
        });
        return selected;
      }

      Future<void> toggleTranslationAudio(
        StateSetter setSheetState,
        bool enabled,
      ) async {
        if (!enabled) {
          await audioCubit.setPlayTranslationAudio(false);
          if (sheetContext.mounted) {
            setSheetState(() {
              sheetPlayTranslationAudio = false;
            });
          }
          return;
        }

        var selected = sheetTranslationReciter;
        if (selected == null) {
          selected = await chooseTranslationReciter(setSheetState);
          if (selected == null) {
            return;
          }
        }
        await audioCubit.setPlayTranslationAudio(true);
        if (sheetContext.mounted) {
          setSheetState(() {
            sheetPlayTranslationAudio = true;
            sheetTranslationReciter = selected;
          });
        }
      }

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.24,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.78],
        shouldCloseOnMinExtent: true,
        builder: (dragContext, scrollController) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return SafeArea(
                top: false,
                child: PremiumSurface(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  radius: QuranTheme.radiusSheet,
                  prominent: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _PlaybackSheetHandle(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Playback',
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$sheetReciterName • $rangeLabel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: QuranTheme.subText(
                                            sheetContext,
                                            0.68,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Close playback settings',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _PlaybackOptionTile(
                          icon: Icons.record_voice_over_rounded,
                          leading:
                              sheetReciter == null ||
                                  sheetReciter?.effectiveImageUrl == null
                              ? null
                              : QuranReciterAvatar(
                                  reciter: sheetReciter!,
                                  size: 42,
                                ),
                          title: 'Reciter',
                          subtitle: '$sheetReciterName. Tap to change voice.',
                          onTap: () => unawaited(chooseReciter(setSheetState)),
                        ),
                        PlaybackTranslationAudioTile(
                          enabled:
                              sheetPlayTranslationAudio && hasTranslationAudio,
                          translationRecitersAvailable: hasTranslationAudio,
                          languageLabel: translationLanguageLabel,
                          selectedReciter: sheetTranslationReciter,
                          onEnabledChanged: (enabled) => unawaited(
                            toggleTranslationAudio(setSheetState, enabled),
                          ),
                          onVoiceTap: () => unawaited(
                            chooseTranslationReciter(setSheetState),
                          ),
                        ),
                        _PlaybackSpeedTile(
                          speed: sheetSpeed,
                          onChanged: (value) {
                            setSheetState(() {
                              sheetSpeed = value;
                            });
                            unawaited(
                              callerContext.read<QuranAudioCubit>().setSpeed(
                                value,
                              ),
                            );
                          },
                        ),
                        PlaybackRepeatTile(
                          mode: sheetRepeatMode,
                          repeatCount: sheetRepeatCount,
                          repeatAfterAction: sheetRepeatAfterAction,
                          rangeStartAyah: sheetRangeStartAyah,
                          rangeEndAyah: sheetRangeEndAyah,
                          rangeMinAyah: rangeBounds.minAyah,
                          rangeMaxAyah: rangeBounds.maxAyah,
                          onRepeatEnabledChanged: (enabled) {
                            final nextMode = enabled
                                ? QuranAudioRepeatMode.ayah
                                : QuranAudioRepeatMode.off;
                            setSheetState(() {
                              sheetRepeatMode = nextMode;
                            });
                            unawaited(
                              callerContext
                                  .read<QuranAudioCubit>()
                                  .setRepeatMode(nextMode),
                            );
                          },
                          onModeChanged: (mode) {
                            setSheetState(() {
                              sheetRepeatMode = mode;
                            });
                            unawaited(
                              callerContext
                                  .read<QuranAudioCubit>()
                                  .setRepeatMode(mode),
                            );
                          },
                          onRepeatCountChanged: (count) {
                            setSheetState(() {
                              sheetRepeatCount = count;
                            });
                            callerContext
                                .read<QuranAudioCubit>()
                                .setRepeatCount(count);
                          },
                          onRepeatAfterActionChanged: (action) {
                            setSheetState(() {
                              sheetRepeatAfterAction = action;
                            });
                            callerContext
                                .read<QuranAudioCubit>()
                                .setRepeatAfterAction(action);
                          },
                          onRangeChanged:
                              ({required startAyah, required endAyah}) {
                                setSheetState(() {
                                  sheetRangeStartAyah = startAyah;
                                  sheetRangeEndAyah = endAyah;
                                });
                                unawaited(
                                  callerContext
                                      .read<QuranAudioCubit>()
                                      .playRange(
                                        startAyah: startAyah,
                                        endAyah: endAyah,
                                      ),
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

_RepeatRangeBounds _repeatRangeBounds(
  QuranAudioState state, {
  int? activeSurahAyahCount,
}) {
  if (activeSurahAyahCount != null && activeSurahAyahCount > 0) {
    return _RepeatRangeBounds(1, activeSurahAyahCount);
  }
  final currentSurahNumber = state.currentItem?.surahNumber;
  final ayahNumbers = state.queue
      .where(
        (item) =>
            currentSurahNumber == null ||
            item.surahNumber == currentSurahNumber,
      )
      .map((item) => item.ayahNumber)
      .where((ayah) => ayah > 0)
      .toList(growable: false);
  if (ayahNumbers.isEmpty) {
    return const _RepeatRangeBounds(null, null);
  }
  var minAyah = ayahNumbers.first;
  var maxAyah = ayahNumbers.first;
  for (final ayah in ayahNumbers.skip(1)) {
    if (ayah < minAyah) {
      minAyah = ayah;
    }
    if (ayah > maxAyah) {
      maxAyah = ayah;
    }
  }
  return _RepeatRangeBounds(minAyah, maxAyah);
}

class _RepeatRangeBounds {
  const _RepeatRangeBounds(this.minAyah, this.maxAyah);

  final int? minAyah;
  final int? maxAyah;
}

class _PlaybackOptionTile extends StatelessWidget {
  const _PlaybackOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
  });

  final IconData icon;
  final Widget? leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: QuranTheme.surface(context),
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                leading ??
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: QuranTheme.outline(context)),
                      ),
                      child: Icon(icon, color: primary),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackSheetHandle extends StatelessWidget {
  const _PlaybackSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: QuranTheme.outline(context),
          borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
        ),
      ),
    );
  }
}

class _PlaybackSpeedTile extends StatelessWidget {
  const _PlaybackSpeedTile({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumSurface(
        radius: QuranTheme.radiusCard,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QuranTheme.outline(context)),
                  ),
                  child: Icon(Icons.speed_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playback speed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${speed.toStringAsFixed(1)}x',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              min: 0.75,
              max: 2,
              divisions: 5,
              value: speed.clamp(0.75, 2).toDouble(),
              label: '${speed.toStringAsFixed(1)}x',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class PlaybackTranslationAudioTile extends StatelessWidget {
  const PlaybackTranslationAudioTile({
    super.key,
    required this.enabled,
    required this.translationRecitersAvailable,
    required this.languageLabel,
    required this.selectedReciter,
    required this.onEnabledChanged,
    required this.onVoiceTap,
  });

  final bool enabled;
  final bool translationRecitersAvailable;
  final String languageLabel;
  final QuranAudioReciter? selectedReciter;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final selectedName = selectedReciter?.name ?? 'Choose translation voice';
    final isAvailable = translationRecitersAvailable;
    final isEnabled = enabled && isAvailable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumSurface(
        radius: QuranTheme.radiusCard,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Opacity(
          opacity: isAvailable ? 1 : 0.56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: QuranTheme.outline(context)),
                    ),
                    child: Icon(Icons.translate_rounded, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Play translation',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          isAvailable
                              ? 'Play Arabic first, then $languageLabel audio.'
                              : 'No $languageLabel translation voice available.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: QuranTheme.subText(context, 0.68),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: isAvailable ? onEnabledChanged : null,
                    activeThumbColor: primary,
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: isEnabled
                    ? Padding(
                        key: const ValueKey('translation-voice'),
                        padding: const EdgeInsets.only(top: 12),
                        child: Material(
                          color: QuranTheme.surface(context),
                          borderRadius: BorderRadius.circular(
                            QuranTheme.radiusControl,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              QuranTheme.radiusControl,
                            ),
                            onTap: onVoiceTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  QuranReciterAvatar(
                                    reciter: selectedReciter,
                                    name: selectedName,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Translation voice',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        Text(
                                          selectedName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: QuranTheme.subText(
                                                  context,
                                                  0.68,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: QuranTheme.subText(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('translation-voice-hidden'),
                        height: 0,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaybackRepeatTile extends StatelessWidget {
  const PlaybackRepeatTile({
    super.key,
    required this.mode,
    required this.repeatCount,
    required this.repeatAfterAction,
    required this.rangeStartAyah,
    required this.rangeEndAyah,
    required this.rangeMinAyah,
    required this.rangeMaxAyah,
    required this.onRepeatEnabledChanged,
    required this.onModeChanged,
    required this.onRepeatCountChanged,
    required this.onRepeatAfterActionChanged,
    required this.onRangeChanged,
  });

  final QuranAudioRepeatMode mode;
  final int repeatCount;
  final QuranAudioRepeatAfterAction repeatAfterAction;
  final int? rangeStartAyah;
  final int? rangeEndAyah;
  final int? rangeMinAyah;
  final int? rangeMaxAyah;
  final ValueChanged<bool> onRepeatEnabledChanged;
  final ValueChanged<QuranAudioRepeatMode> onModeChanged;
  final ValueChanged<int> onRepeatCountChanged;
  final ValueChanged<QuranAudioRepeatAfterAction> onRepeatAfterActionChanged;
  final void Function({required int startAyah, required int endAyah})
  onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = mode != QuranAudioRepeatMode.off;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumSurface(
        radius: QuranTheme.radiusCard,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QuranTheme.outline(context)),
                  ),
                  child: Icon(Icons.repeat_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeat',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _repeatSubtitle(mode, repeatCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onRepeatEnabledChanged,
                  activeThumbColor: primary,
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: enabled
                  ? Column(
                      key: const ValueKey('repeat-expanded'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        SegmentedButton<QuranAudioRepeatMode>(
                          segments: const [
                            ButtonSegment(
                              value: QuranAudioRepeatMode.ayah,
                              label: Text('Ayah'),
                            ),
                            ButtonSegment(
                              value: QuranAudioRepeatMode.queue,
                              label: Text('Range'),
                            ),
                          ],
                          selected: {
                            mode == QuranAudioRepeatMode.off
                                ? QuranAudioRepeatMode.ayah
                                : mode,
                          },
                          onSelectionChanged: (selection) =>
                              onModeChanged(selection.first),
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStatePropertyAll(
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final count in const [1, 2, 3, 5, 10])
                              ChoiceChip(
                                label: Text(count == 1 ? 'Once' : '${count}x'),
                                selected: repeatCount == count,
                                onSelected: (_) => onRepeatCountChanged(count),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                                side: BorderSide(
                                  color: QuranTheme.outline(context),
                                ),
                              ),
                          ],
                        ),
                        if (mode == QuranAudioRepeatMode.queue) ...[
                          const SizedBox(height: 12),
                          _RepeatRangeTile(
                            startAyah: rangeStartAyah,
                            endAyah: rangeEndAyah,
                            minAyah: rangeMinAyah,
                            maxAyah: rangeMaxAyah,
                            onChanged: onRangeChanged,
                          ),
                          const SizedBox(height: 12),
                          _RepeatAfterActionTile(
                            action: repeatAfterAction,
                            onChanged: onRepeatAfterActionChanged,
                          ),
                        ],
                      ],
                    )
                  : const SizedBox(
                      key: ValueKey('repeat-collapsed'),
                      height: 0,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _repeatSubtitle(QuranAudioRepeatMode mode, int count) {
    if (mode == QuranAudioRepeatMode.off) {
      return 'Repeat disabled';
    }
    final modeLabel = switch (mode) {
      QuranAudioRepeatMode.off => 'Repeat disabled',
      QuranAudioRepeatMode.ayah => 'Repeat ayah',
      QuranAudioRepeatMode.queue => 'Repeat range',
    };
    final countLabel = count == 1 ? 'once' : '$count times';
    return '$modeLabel • $countLabel';
  }
}

class _RepeatRangeTile extends StatefulWidget {
  const _RepeatRangeTile({
    required this.startAyah,
    required this.endAyah,
    required this.minAyah,
    required this.maxAyah,
    required this.onChanged,
  });

  final int? startAyah;
  final int? endAyah;
  final int? minAyah;
  final int? maxAyah;
  final void Function({required int startAyah, required int endAyah}) onChanged;

  @override
  State<_RepeatRangeTile> createState() => _RepeatRangeTileState();
}

class _RepeatRangeTileState extends State<_RepeatRangeTile> {
  late int? _startAyah;
  late int? _endAyah;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _RepeatRangeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startAyah != widget.startAyah ||
        oldWidget.endAyah != widget.endAyah ||
        oldWidget.minAyah != widget.minAyah ||
        oldWidget.maxAyah != widget.maxAyah) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final min = widget.minAyah;
    final max = widget.maxAyah;
    if (min == null || max == null || min > max) {
      _startAyah = null;
      _endAyah = null;
      return;
    }
    final start = (widget.startAyah ?? min).clamp(min, max).toInt();
    final end = (widget.endAyah ?? start).clamp(start, max).toInt();
    _startAyah = start;
    _endAyah = end;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final min = widget.minAyah;
    final max = widget.maxAyah;
    if (min == null || max == null || min > max) {
      return Material(
        color: QuranTheme.surface(context),
        borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Repeat range will be available after audio starts.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.70),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    final values = [for (var ayah = min; ayah <= max; ayah += 1) ayah];
    final start = (_startAyah ?? min).clamp(min, max).toInt();
    final end = (_endAyah ?? start).clamp(start, max).toInt();
    final rangeLabel = start == end ? 'Ayah $start' : 'Ayahs $start-$end';

    return Material(
      color: QuranTheme.surface(context),
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.view_week_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Repeat range',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  rangeLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (min < max) ...[
              RangeSlider(
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                values: RangeValues(start.toDouble(), end.toDouble()),
                labels: RangeLabels(start.toString(), end.toString()),
                onChanged: (range) {
                  setState(() {
                    final nextStart = range.start
                        .round()
                        .clamp(min, max)
                        .toInt();
                    final nextEnd = range.end
                        .round()
                        .clamp(nextStart, max)
                        .toInt();
                    _startAyah = nextStart;
                    _endAyah = nextEnd;
                  });
                },
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: _RepeatRangeDropdown(
                    label: 'From',
                    value: start,
                    values: values,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _startAyah = value;
                        _endAyah = end < value ? value : end;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RepeatRangeDropdown(
                    label: 'To',
                    value: end,
                    values: [
                      for (var ayah = start; ayah <= max; ayah += 1) ayah,
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _endAyah = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => widget.onChanged(startAyah: start, endAyah: end),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply range'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatRangeDropdown extends StatelessWidget {
  const _RepeatRangeDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: values.contains(value) ? value : values.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      items: [
        for (final value in values)
          DropdownMenuItem(value: value, child: Text(value.toString())),
      ],
      onChanged: onChanged,
    );
  }
}

class _RepeatAfterActionTile extends StatelessWidget {
  const _RepeatAfterActionTile({required this.action, required this.onChanged});

  final QuranAudioRepeatAfterAction action;
  final ValueChanged<QuranAudioRepeatAfterAction> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: QuranTheme.surface(context),
      borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'After repeat is done',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<QuranAudioRepeatAfterAction>(
              segments: const [
                ButtonSegment(
                  value: QuranAudioRepeatAfterAction.stop,
                  label: Text('Stop'),
                ),
                ButtonSegment(
                  value: QuranAudioRepeatAfterAction.continuePlayback,
                  label: Text('Continue'),
                ),
              ],
              selected: {action},
              onSelectionChanged: (selection) => onChanged(selection.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
