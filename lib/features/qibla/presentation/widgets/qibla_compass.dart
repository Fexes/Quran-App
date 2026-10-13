import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({
    super.key,
    required this.heading,
    required this.bearing,
    required this.hasHeading,
    required this.unavailable,
    required this.reliable,
    required this.aligned,
    required this.settling,
    this.recovering = false,
  }) : assert(!aligned || (hasHeading && reliable));

  final Animation<double> heading;
  final double bearing;
  final bool hasHeading;
  final bool unavailable;
  final bool reliable;
  final bool aligned;
  final bool settling;
  final bool recovering;

  @override
  Widget build(BuildContext context) {
    final text = QuranTheme.text(context);
    final accent = aligned
        ? QuranTheme.semantic(context).success
        : reliable || !hasHeading || recovering
        ? text
        : QuranTheme.semantic(context).warning;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _QiblaDialPainter(
                    heading: heading,
                    bearing: bearing,
                    hasHeading: hasHeading,
                    aligned: aligned,
                    accent: accent,
                    text: text,
                    surface: QuranTheme.surface(context),
                    fill: QuranTheme.surfaceVariant(context),
                    outline: QuranTheme.outline(context),
                  ),
                ),
              ),
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.39,
                  heightFactor: 0.39,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: aligned || settling ? 1 : 0),
                        duration: reducedMotion || (!aligned && !settling)
                            ? Duration.zero
                            : settling
                            ? const Duration(milliseconds: 650)
                            : const Duration(milliseconds: 180),
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              strokeWidth: 2,
                              color: accent,
                              backgroundColor: Colors.transparent,
                              strokeCap: StrokeCap.round,
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedBuilder(
                          animation: heading,
                          builder: (context, _) {
                            final relative =
                                (bearing - heading.value + 540) % 360 - 180;
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    aligned
                                        ? Icons.check_rounded
                                        : unavailable
                                        ? Icons.explore_off_outlined
                                        : !hasHeading || recovering
                                        ? Icons.explore_outlined
                                        : !reliable
                                        ? Icons.warning_amber_rounded
                                        : settling
                                        ? Icons.my_location_rounded
                                        : relative > 0
                                        ? Icons.rotate_right_rounded
                                        : Icons.rotate_left_rounded,
                                    size: aligned ? 40 : 24,
                                    color: accent,
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const SizedBox(height: 4),
                                  if (!aligned)
                                    Text(
                                      hasHeading
                                          ? '${relative.abs().round()}°'
                                          : unavailable
                                          ? '--'
                                          : '···',
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 40,
                                        height: 1.1,
                                        fontWeight: FontWeight.w500,
                                        color: text,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    aligned
                                        ? 'Aligned'
                                        : unavailable
                                        ? 'Unavailable'
                                        : !hasHeading
                                        ? 'Finding north'
                                        : recovering
                                        ? 'Settling'
                                        : reliable
                                        ? 'to Qibla'
                                        : 'Approximate',
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: aligned
                                          ? accent
                                          : QuranTheme.subText(context),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QiblaDialPainter extends CustomPainter {
  _QiblaDialPainter({
    required this.heading,
    required this.bearing,
    required this.hasHeading,
    required this.aligned,
    required this.accent,
    required this.text,
    required this.surface,
    required this.fill,
    required this.outline,
  }) : super(repaint: heading);

  final Animation<double> heading;
  final double bearing;
  final bool hasHeading;
  final bool aligned;
  final Color accent;
  final Color text;
  final Color surface;
  final Color fill;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbit = size.shortestSide / 2 - 26;
    final tickRadius = orbit - 24;
    final coreRadius = size.shortestSide * 0.195;
    final relative = (bearing - heading.value + 540) % 360 - 180;
    final targetAngle = relative * math.pi / 180 - math.pi / 2;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, orbit, line..color = outline);
    canvas.drawCircle(center, coreRadius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      tickRadius + 8,
      line
        ..color = aligned ? accent.withValues(alpha: 0.35) : outline
        ..strokeWidth = 1,
    );

    if (hasHeading) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbit),
        -math.pi / 2,
        relative * math.pi / 180,
        false,
        line
          ..color = accent.withValues(alpha: 0.55)
          ..strokeWidth = 3,
      );
    }

    // The top target stays fixed to the phone; the Kaaba moves with heading.
    final target = center + Offset(0, -orbit);
    canvas.drawCircle(target, 23, Paint()..color = surface);
    canvas.drawCircle(
      target,
      23,
      line
        ..color = accent.withValues(alpha: aligned ? 1 : 0.35)
        ..strokeWidth = aligned ? 2 : 1,
    );
    canvas.drawLine(
      target + const Offset(-5, 0),
      target + const Offset(5, 0),
      line..color = accent.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      target + const Offset(0, -5),
      target + const Offset(0, 5),
      line,
    );

    for (var degrees = 0; degrees < 360; degrees += 5) {
      final angle = (degrees - heading.value - 90) * math.pi / 180;
      final vector = Offset(math.cos(angle), math.sin(angle));
      final major = degrees % 30 == 0;
      canvas.drawLine(
        center + vector * (tickRadius - (major ? 12 : 5)),
        center + vector * tickRadius,
        line
          ..color = degrees == 0
              ? accent
              : text.withValues(alpha: major ? 0.65 : 0.28)
          ..strokeWidth = major ? 1.5 : 1,
      );
    }

    for (final entry in const {0: 'N', 90: 'E', 180: 'S', 270: 'W'}.entries) {
      final angle = (entry.key - heading.value - 90) * math.pi / 180;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (tickRadius - 26);
      final label = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: entry.key == 0 ? FontWeight.w700 : FontWeight.w400,
            color: entry.key == 0 ? text : text.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, position - Offset(label.width / 2, label.height / 2));
      label.dispose();
    }

    if (!hasHeading) return;
    final vector = Offset(math.cos(targetAngle), math.sin(targetAngle));
    final kaaba = center + vector * orbit;
    canvas.drawCircle(
      kaaba,
      20,
      Paint()..color = aligned ? accent : const Color(0xFFF1E6CB),
    );
    canvas.drawCircle(
      kaaba,
      20,
      line
        ..color = aligned ? accent : outline
        ..strokeWidth = 1,
    );
    final body = Rect.fromCenter(center: kaaba, width: 22, height: 23);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      Paint()..color = const Color(0xFF232423),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + 6, body.width, 4),
      Paint()..color = const Color(0xFFC4A46A),
    );
    canvas.drawRect(
      Rect.fromLTWH(body.right - 7, body.top + 12, 4, 7),
      Paint()..color = const Color(0xFFC4A46A),
    );
  }

  @override
  bool shouldRepaint(_QiblaDialPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.hasHeading != hasHeading ||
      old.aligned != aligned ||
      old.accent != accent ||
      old.text != text ||
      old.surface != surface ||
      old.fill != fill ||
      old.outline != outline;
}
