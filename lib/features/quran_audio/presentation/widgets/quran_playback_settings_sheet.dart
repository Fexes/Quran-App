import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/animated_expansion.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/services/quran_translation_audio_pairings.dart';
import '../../domain/entities/quran_audio_state.dart';
import '../../domain/services/quran_translation_audio_selector.dart';
import '../cubit/quran_audio_cubit.dart';
import 'quran_reciter_picker.dart';
import 'quran_translation_voice_change.dart';

Future<void> showQuranPlaybackSettingsSheet({
  required BuildContext context,
  required QuranAudioState audioState,
  required List<QuranAudioReciter> reciters,
  required Future<void> Function(QuranAudioReciter reciter) onReciterSelected,
  QuranAudioReciter? selectedReciter,
  QuranTranslationResource? selectedTranslation,
  String? audioMeaningLanguageCode,
  String? currentRangeLabel,
}) async {
  final callerContext = context;
  final arabicReciters = reciters
      .where((reciter) => !reciter.isTranslation)
      .toList(growable: false);
  final sheetTranslation = selectedTranslation;
  final translationLanguageLabel = selectedTranslation == null
      ? 'English'
      : quranTranslationAudioLanguageLabel(selectedTranslation);
  final hasTranslationAudio = quranCompatibleTranslationAudioReciters(
    reciters: reciters,
    selectedTranslation: sheetTranslation,
  ).isNotEmpty;
  var changingTranslation = false;
  var openSetupRequested = false;

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
  final audioCubit = callerContext.read<QuranAudioCubit>();
  final sheetTranslationReciter = audioCubit.preferredTranslationReciter(
    quranCompatibleTranslationAudioReciters(
      reciters: reciters,
      selectedTranslation: sheetTranslation,
    ),
  );
  var sheetSpeed = audioState.speed.clamp(0.75, 2.0).toDouble();
  var sheetRepeatMode = audioState.repeatMode;
  var sheetRepeatCount = audioState.repeatCount;
  var sheetRepeatAfterAction = audioState.repeatAfterAction;
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

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.16),
    builder: (sheetContext) {
      Future<bool> applyChange(Future<void> change) async {
        try {
          await change;
          return true;
        } catch (_) {
          if (sheetContext.mounted) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(
                content: Text('Could not update playback settings. Try again.'),
              ),
            );
          }
          return false;
        }
      }

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
        if (!sheetContext.mounted) {
          return;
        }
        final previousReciter = sheetReciter;
        final previousName = sheetReciterName;
        final previousId = sheetReciterId;
        setSheetState(() {
          sheetReciter = selected;
          sheetReciterName = selected.name;
          sheetReciterId = selected.id;
        });
        if (!await applyChange(onReciterSelected(selected)) &&
            sheetContext.mounted) {
          setSheetState(() {
            sheetReciter = previousReciter;
            sheetReciterName = previousName;
            sheetReciterId = previousId;
          });
        }
      }

      void openReadingSetup() {
        openSetupRequested = true;
        Navigator.of(sheetContext).pop();
      }

      Future<void> toggleTranslationAudio(
        StateSetter setSheetState,
        bool enabled,
      ) async {
        if (changingTranslation) return;
        final voice = sheetTranslationReciter;
        final repository = audioCubit.translationRepository;
        if (enabled && (voice == null || repository == null)) {
          openReadingSetup();
          return;
        }
        setSheetState(() => changingTranslation = true);
        try {
          if (enabled &&
              !await prepareQuranTranslationVoiceChange(
                context: sheetContext,
                repository: repository!,
                voice: voice!,
              )) {
            return;
          }
          if (!sheetContext.mounted) return;
          await applyChange(audioCubit.setPlayTranslationAudio(enabled));
        } finally {
          if (sheetContext.mounted) {
            setSheetState(() {
              changingTranslation = false;
              sheetPlayTranslationAudio = audioCubit.state.playTranslationAudio;
            });
          }
        }
      }

      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return AppSheet(
            title: 'Playback',
            subtitle: rangeLabel == 'No active range' ? null : rangeLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlaybackOptionTile(
                  icon: Icons.record_voice_over_rounded,
                  leading:
                      sheetReciter == null ||
                          sheetReciter?.effectiveImageUrl == null
                      ? null
                      : QuranReciterAvatar(reciter: sheetReciter!, size: 42),
                  title: 'Reciter',
                  subtitle: sheetReciterName,
                  onTap: () => unawaited(chooseReciter(setSheetState)),
                ),
                _PlaybackOptionTile(
                  icon: Icons.translate_rounded,
                  title: 'Translation language',
                  subtitle:
                      sheetTranslation?.displayLanguage ?? 'English (bundled)',
                  onTap: openReadingSetup,
                ),
                const Divider(height: 20),
                PlaybackTranslationAudioTile(
                  enabled: sheetPlayTranslationAudio && hasTranslationAudio,
                  translationRecitersAvailable: hasTranslationAudio,
                  languageLabel: translationLanguageLabel,
                  selectedReciter: sheetTranslationReciter,
                  selectedTranslation: sheetTranslation,
                  showVoiceDetails: false,
                  busy: changingTranslation,
                  onEnabledChanged: (enabled) =>
                      unawaited(toggleTranslationAudio(setSheetState, enabled)),
                  onVoiceTap: openReadingSetup,
                ),
                const Divider(height: 20),
                _PlaybackSpeedTile(
                  speed: sheetSpeed,
                  onChanged: (value) {
                    setSheetState(() {
                      sheetSpeed = value;
                    });
                    unawaited(applyChange(audioCubit.setSpeed(value)));
                  },
                ),
                const Divider(height: 20),
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
                    unawaited(applyChange(audioCubit.setRepeatMode(nextMode)));
                  },
                  onModeChanged: (mode) {
                    setSheetState(() {
                      sheetRepeatMode = mode;
                    });
                    unawaited(applyChange(audioCubit.setRepeatMode(mode)));
                  },
                  onRepeatCountChanged: (count) {
                    setSheetState(() {
                      sheetRepeatCount = count;
                    });
                    callerContext.read<QuranAudioCubit>().setRepeatCount(count);
                  },
                  onRepeatAfterActionChanged: (action) {
                    setSheetState(() {
                      sheetRepeatAfterAction = action;
                    });
                    callerContext.read<QuranAudioCubit>().setRepeatAfterAction(
                      action,
                    );
                  },
                  onRangeChanged: ({required startAyah, required endAyah}) {
                    setSheetState(() {
                      sheetRangeStartAyah = startAyah;
                      sheetRangeEndAyah = endAyah;
                    });
                    unawaited(
                      applyChange(
                        audioCubit.setRepeatRange(
                          startAyah: startAyah,
                          endAyah: endAyah,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
  if (openSetupRequested && callerContext.mounted) {
    await callerContext.push(AppRoutes.quranTranslationsPath());
    if (callerContext.mounted && !audioCubit.isClosed) {
      try {
        await audioCubit.synchronizeTranslationSelection();
      } catch (_) {
        if (callerContext.mounted) {
          ScaffoldMessenger.of(callerContext).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not update translation playback. Try again.',
              ),
            ),
          );
        }
      }
    }
  }
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading ?? AppIcon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _PlaybackSpeedTile extends StatefulWidget {
  const _PlaybackSpeedTile({required this.speed, required this.onChanged});

  final double speed;
  final ValueChanged<double> onChanged;

  @override
  State<_PlaybackSpeedTile> createState() => _PlaybackSpeedTileState();
}

class _PlaybackSpeedTileState extends State<_PlaybackSpeedTile> {
  late double _speed = widget.speed;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant _PlaybackSpeedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _speed = widget.speed;
  }

  @override
  Widget build(BuildContext context) {
    final label =
        '${_speed.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}x';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const AppIcon(Icons.speed_rounded),
          title: const Text('Playback speed'),
          trailing: Text(label),
        ),
        Slider(
          min: 0.75,
          max: 2,
          divisions: 5,
          value: _speed.clamp(0.75, 2).toDouble(),
          label: label,
          onChangeStart: (_) => _dragging = true,
          onChanged: (value) => setState(() => _speed = value),
          onChangeEnd: (value) {
            _dragging = false;
            widget.onChanged(value);
          },
        ),
      ],
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
    this.selectedTranslation,
    this.canChooseCompatibleEdition = false,
    this.busy = false,
    this.showVoiceDetails = true,
  });

  final bool enabled;
  final bool translationRecitersAvailable;
  final String languageLabel;
  final QuranAudioReciter? selectedReciter;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onVoiceTap;
  final QuranTranslationResource? selectedTranslation;
  final bool canChooseCompatibleEdition;
  final bool busy;
  final bool showVoiceDetails;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && translationRecitersAvailable;
    final selectedName = selectedReciter?.name ?? 'Choose translation voice';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const AppIcon(Icons.translate_rounded),
          title: const Text('Play translation'),
          subtitle: Text(
            translationRecitersAvailable
                ? 'Arabic, then $languageLabel'
                : selectedTranslation == null
                ? 'Bundled English text. Choose a translation with audio to listen.'
                : 'Translation audio is unavailable in $languageLabel.',
          ),
          value: isEnabled,
          onChanged: translationRecitersAvailable && !busy
              ? onEnabledChanged
              : null,
        ),
        AnimatedExpansion(
          expanded: isEnabled && showVoiceDetails,
          child: ListTile(
            key: const ValueKey('translation-voice'),
            contentPadding: EdgeInsets.zero,
            leading: QuranReciterAvatar(
              reciter: selectedReciter,
              name: selectedName,
              size: 36,
            ),
            title: const Text('Translation voice'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedName),
                Text(
                  'Translation: ${quranTranslationPairForVoice(selectedReciter?.id ?? '')?.resource.name ?? 'Edition not verified'}',
                ),
              ],
            ),
            trailing: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const AppIcon(Icons.chevron_right_rounded),
            onTap: busy ? null : onVoiceTap,
          ),
        ),
        if (showVoiceDetails && !isEnabled && canChooseCompatibleEdition)
          TextButton.icon(
            onPressed: busy ? null : onVoiceTap,
            icon: const AppIcon(Icons.record_voice_over_outlined, size: 18),
            label: Text(
              busy
                  ? 'Preparing translation...'
                  : 'Choose an audio-supported translation',
            ),
          ),
      ],
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
    final enabled = mode != QuranAudioRepeatMode.off;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const AppIcon(Icons.repeat_rounded),
          title: const Text('Repeat'),
          value: enabled,
          onChanged: onRepeatEnabledChanged,
        ),
        AnimatedExpansion(
          expanded: enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              SegmentedButton<QuranAudioRepeatMode>(
                showSelectedIcon: false,
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
              ),
              const SizedBox(height: 16),
              Text(
                'Repeat count',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final count in const [1, 2, 3, 5, 10])
                    ChoiceChip(
                      label: Text(count == 1 ? 'Once' : '${count}x'),
                      selected: repeatCount == count,
                      onSelected: (_) => onRepeatCountChanged(count),
                    ),
                ],
              ),
              AnimatedExpansion(
                expanded: mode == QuranAudioRepeatMode.queue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 32),
                    _RepeatRangeTile(
                      startAyah: rangeStartAyah,
                      endAyah: rangeEndAyah,
                      minAyah: rangeMinAyah,
                      maxAyah: rangeMaxAyah,
                      onChanged: onRangeChanged,
                    ),
                    const Divider(height: 32),
                    _RepeatAfterActionTile(
                      action: repeatAfterAction,
                      onChanged: onRepeatAfterActionChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
              fontWeight: FontWeight.w600,
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
                AppIcon(Icons.view_week_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Repeat range',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rangeLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
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
              icon: const AppIcon(Icons.check_rounded),
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
                AppIcon(Icons.flag_rounded, color: primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'After repeat is done',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
