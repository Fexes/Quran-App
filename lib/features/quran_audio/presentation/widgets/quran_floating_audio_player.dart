import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/surah_image_avatar.dart';
import '../../domain/entities/quran_audio_state.dart';
import '../cubit/quran_audio_cubit.dart';
import 'quran_playback_settings_sheet.dart';
import 'quran_audio_seek_bar.dart';

class QuranFloatingAudioPlayer extends StatelessWidget {
  const QuranFloatingAudioPlayer({super.key, this.bottomInset = 90});

  final double bottomInset;

  static double scrollInset(BuildContext context) {
    final visible = context.select<QuranAudioCubit, bool>((cubit) {
      final state = cubit.state;
      return state.hasItem &&
          state.status != QuranAudioStatus.idle &&
          state.status != QuranAudioStatus.completed;
    });
    return visible ? 132 : 24;
  }

  @override
  Widget build(BuildContext context) {
    return QuranAudioDock(bottomInset: bottomInset);
  }
}

class QuranAudioDock extends StatelessWidget {
  const QuranAudioDock({super.key, required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioCubit, QuranAudioState>(
      builder: (context, state) {
        if (!state.hasItem ||
            state.status == QuranAudioStatus.idle ||
            state.status == QuranAudioStatus.completed) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _MiniPlayer(state: state),
          ),
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.state});

  final QuranAudioState state;

  @override
  Widget build(BuildContext context) {
    final item = state.currentItem;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final cubit = context.read<QuranAudioCubit>();
    final showProgress = state.isPlaying || state.isLoading;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: PremiumSurface(
        shadowStyle: PremiumSurfaceShadowStyle.floating,
        radius: QuranTheme.radiusDock,
        padding: EdgeInsets.zero,
        prominent: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SurahImageAvatar(
                    surahNumber: item.surahNumber,
                    active: state.isPlaying,
                    fallbackLabel: item.surahNumber.toString(),
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        QuranTheme.radiusControl,
                      ),
                      onTap: () => context.push(
                        AppRoutes.quranReaderPath(
                          item.surahNumber,
                          ayahNumber: item.ayahNumber,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.surahName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.isBismillah
                                  ? 'Bismillah'
                                  : 'Ayah ${item.ayahNumber}${item.isTranslationSegment ? ' • Translation' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: QuranTheme.subText(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _IconControl(
                    prominent: true,
                    outlined: true,
                    tooltip: state.isPlaying
                        ? 'Pause recitation'
                        : 'Resume recitation',
                    icon: state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: context.read<QuranAudioCubit>().togglePlayPause,
                  ),
                  _IconControl(
                    tooltip: 'Playback settings',
                    icon: Icons.tune_rounded,
                    onPressed: () => _showPlaybackSettings(context),
                  ),
                  _IconControl(
                    tooltip: 'Close audio',
                    icon: Icons.close_rounded,
                    onPressed: cubit.stopAndClear,
                  ),
                ],
              ),
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: showProgress
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: QuranAudioSeekBar(
                          state: state,
                          onSeek: cubit.seek,
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPlaybackSettings(BuildContext context) async {
    final audioCubit = context.read<QuranAudioCubit>();
    final reciters = await audioCubit.getAudioReciters();
    if (!context.mounted) {
      return;
    }

    QuranAudioReciter? selectedReciter = audioCubit.activeReciter;
    QuranTranslationResource? selectedTranslation;
    if (getIt.isRegistered<QuranTranslationRepository>()) {
      selectedTranslation = await getIt<QuranTranslationRepository>()
          .selectedTranslation();
    }
    if (!context.mounted) {
      return;
    }

    await showQuranPlaybackSettingsSheet(
      context: context,
      audioState: state,
      reciters: reciters,
      selectedReciter: selectedReciter,
      selectedTranslation: selectedTranslation,
      onReciterSelected: (reciter) => audioCubit.changeReciter(reciter.id),
    );
  }
}

class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.icon,
    required this.onPressed,
    this.prominent = false,
    this.outlined = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool outlined;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget withSemantics(Widget child) {
      return Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: child,
      );
    }

    if (prominent) {
      if (outlined) {
        return withSemantics(
          IconButton.outlined(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: const Size.square(36),
              padding: const EdgeInsets.all(7),
              iconSize: 22,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: onPressed,
            tooltip: tooltip,
            icon: AppIcon(icon),
          ),
        );
      }
      return withSemantics(
        IconButton.filled(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: AppIcon(icon),
        ),
      );
    }
    return withSemantics(
      IconButton(onPressed: onPressed, tooltip: tooltip, icon: AppIcon(icon)),
    );
  }
}
