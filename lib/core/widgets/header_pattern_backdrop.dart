import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';

class HeaderPatternBackdrop extends StatelessWidget {
  const HeaderPatternBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRect(
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _HeaderPatternPainter(
                  QuranTheme.text(context).withValues(
                    alpha: QuranTheme.isDark(context) ? 0.06 : 0.035,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  const _HeaderPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..strokeJoin = StrokeJoin.round;
    final tile = Path()
      ..addPolygon(const [
        Offset(0, -30),
        Offset(9, -21),
        Offset(21, -21),
        Offset(21, -9),
        Offset(30, 0),
        Offset(21, 9),
        Offset(21, 21),
        Offset(9, 21),
        Offset(0, 30),
        Offset(-9, 21),
        Offset(-21, 21),
        Offset(-21, 9),
        Offset(-30, 0),
        Offset(-21, -9),
        Offset(-21, -21),
        Offset(-9, -21),
      ], true)
      ..addPolygon(const [
        Offset(0, -22),
        Offset(6.5, -15.5),
        Offset(15.5, -15.5),
        Offset(15.5, -6.5),
        Offset(22, 0),
        Offset(15.5, 6.5),
        Offset(15.5, 15.5),
        Offset(6.5, 15.5),
        Offset(0, 22),
        Offset(-6.5, 15.5),
        Offset(-15.5, 15.5),
        Offset(-15.5, 6.5),
        Offset(-22, 0),
        Offset(-15.5, -6.5),
        Offset(-15.5, -15.5),
        Offset(-6.5, -15.5),
      ], true)
      ..addPolygon(const [
        Offset(0, -9),
        Offset(9, 0),
        Offset(0, 9),
        Offset(-9, 0),
      ], true)
      ..moveTo(0, -22)
      ..lineTo(0, -9)
      ..moveTo(22, 0)
      ..lineTo(9, 0)
      ..moveTo(0, 22)
      ..lineTo(0, 9)
      ..moveTo(-22, 0)
      ..lineTo(-9, 0)
      ..moveTo(30, 0)
      ..lineTo(46, 0)
      ..moveTo(0, 30)
      ..lineTo(0, 46)
      ..addPolygon(const [
        Offset(38, 27),
        Offset(49, 38),
        Offset(38, 49),
        Offset(27, 38),
      ], true);
    final pattern = Path();
    for (var y = -12.0; y < size.height + 38; y += 76) {
      for (var x = -12.0; x < size.width + 38; x += 76) {
        pattern.addPath(tile, Offset(x, y));
      }
    }
    canvas.drawPath(pattern, paint);
  }

  @override
  bool shouldRepaint(_HeaderPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
