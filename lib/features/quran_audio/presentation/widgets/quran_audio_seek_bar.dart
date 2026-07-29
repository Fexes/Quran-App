import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/quran_audio_state.dart';

class QuranAudioSeekBar extends StatelessWidget {
  const QuranAudioSeekBar({
    super.key,
    required this.state,
    required this.onSeek,
    this.height = 16,
    this.barHeight = 3,
  });

  final QuranAudioState state;
  final ValueChanged<Duration>? onSeek;
  final double height;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final duration = state.duration;
    final canSeek =
        onSeek != null && duration != null && duration.inMilliseconds > 0;
    final progress = !canSeek
        ? 0.0
        : (state.position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final buffered = duration == null || duration.inMilliseconds <= 0
        ? 0.0
        : (state.bufferedPosition.inMilliseconds / duration.inMilliseconds)
              .clamp(0.0, 1.0);

    return Semantics(
      slider: true,
      enabled: canSeek,
      label: 'Seek current ayah',
      value: duration == null
          ? null
          : '${state.position.inSeconds} of ${duration.inSeconds} seconds',
      child: LayoutBuilder(
        builder: (context, constraints) {
          Duration positionFromLocalDx(double dx) {
            final width = constraints.maxWidth;
            if (width <= 0 || duration == null) {
              return Duration.zero;
            }
            final factor = (dx / width).clamp(0.0, 1.0);
            return Duration(
              milliseconds: (duration.inMilliseconds * factor).round(),
            );
          }

          void seekFromLocalPosition(Offset localPosition) {
            if (!canSeek) {
              return;
            }
            onSeek?.call(positionFromLocalDx(localPosition.dx));
          }

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: canSeek
                ? (details) => seekFromLocalPosition(details.localPosition)
                : null,
            onHorizontalDragUpdate: canSeek
                ? (details) => seekFromLocalPosition(details.localPosition)
                : null,
            child: SizedBox(
              height: height,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
                  child: ColoredBox(
                    color: QuranTheme.outline(context).withValues(alpha: 0.72),
                    child: SizedBox(
                      height: barHeight,
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: buffered,
                            child: ColoredBox(
                              color: QuranTheme.subText(context, 0.20),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: progress,
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.primary,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
