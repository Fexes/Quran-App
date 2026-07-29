import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/prayer_time_entry.dart';

class PrayerNowTicker extends StatefulWidget {
  const PrayerNowTicker({
    super.key,
    required this.builder,
    this.interval = const Duration(minutes: 1),
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration interval;

  @override
  State<PrayerNowTicker> createState() => _PrayerNowTickerState();
}

class _PrayerNowTickerState extends State<PrayerNowTicker> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _now);
  }
}

class AnimatedPrayerArc extends StatelessWidget {
  const AnimatedPrayerArc({
    super.key,
    required this.progress,
    required this.color,
    this.height = 76,
    this.strokeWidth = 1.8,
    this.showGlow = true,
  });

  final double progress;
  final Color color;
  final double height;
  final double strokeWidth;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, animatedColor, _) {
            final effectiveColor = animatedColor ?? color;
            return SizedBox(
              height: height,
              child: CustomPaint(
                painter: PrayerArcPainter(
                  color: effectiveColor,
                  progress: animatedProgress,
                  outlineColor: QuranTheme.outline(context),
                  strokeWidth: strokeWidth,
                  showGlow: showGlow,
                ),
                child: const SizedBox.expand(),
              ),
            );
          },
        );
      },
    );
  }
}

class PrayerArcPainter extends CustomPainter {
  const PrayerArcPainter({
    required this.color,
    required this.progress,
    required this.outlineColor,
    this.strokeWidth = 1.8,
    this.showGlow = true,
  });

  final Color color;
  final double progress;
  final Color outlineColor;
  final double strokeWidth;
  final bool showGlow;

  static const _startAngle = 3.56;
  static const _sweepAngle = 2.30;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height * 1.35);
    final trackPaint = Paint()
      ..color = outlineColor.withValues(alpha: 0.62)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = color.withValues(alpha: 0.76)
      ..strokeWidth = strokeWidth + 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawArc(rect, _startAngle, _sweepAngle, false, trackPaint)
      ..drawArc(
        rect,
        _startAngle,
        _sweepAngle * progress.clamp(0, 1),
        false,
        activePaint,
      );

    final marker = _pointOnArc(rect, progress.clamp(0, 1).toDouble());
    if (showGlow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(marker, 17, glowPaint);
    }

    final markerFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final markerStroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas
      ..drawCircle(marker, 6.2, markerFill)
      ..drawCircle(marker, 6.2, markerStroke);
  }

  Offset _pointOnArc(Rect rect, double value) {
    final angle = _startAngle + (_sweepAngle * value);
    final center = rect.center;
    return Offset(
      center.dx + math.cos(angle) * rect.width / 2,
      center.dy + math.sin(angle) * rect.height / 2,
    );
  }

  @override
  bool shouldRepaint(covariant PrayerArcPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showGlow != showGlow;
  }
}

Color prayerPhaseColor(PrayerTimeName? name) {
  return switch (name) {
    PrayerTimeName.fajr => const Color(0xFF4F8CC9),
    PrayerTimeName.sunrise => const Color(0xFFD19A16),
    PrayerTimeName.dhuhr => const Color(0xFFD19A16),
    PrayerTimeName.asr => const Color(0xFFC57A1A),
    PrayerTimeName.maghrib => const Color(0xFFC96E5A),
    PrayerTimeName.isha => const Color(0xFF4B5BA7),
    null => const Color(0xFFD19A16),
  };
}
