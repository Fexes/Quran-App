import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/shell_screen_header.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../prayer/presentation/pages/prayer_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/shell_cubit.dart';
import '../bloc/shell_state.dart';
import '../widgets/app_bottom_nav.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, ShellState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        // Match the safe area and all five tabs' header padding.
                        height:
                            MediaQuery.paddingOf(context).top +
                            18 +
                            ShellScreenHeader.height(context) +
                            16,
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: RepaintBoundary(
                              child: ClipRect(
                                child: CustomPaint(
                                  painter: _HeaderPatternPainter(
                                    QuranTheme.text(context).withValues(
                                      alpha: QuranTheme.isDark(context)
                                          ? 0.06
                                          : 0.035,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: _ShellTabTransition(
                          index: state.index,
                          child: IndexedStack(
                            index: state.index,
                            children: [
                              for (final (index, page) in const [
                                HomePage(),
                                QuranPage(),
                                PrayerPage(),
                                LibraryPage(),
                                SettingsPage(),
                              ].indexed)
                                TickerMode(
                                  enabled: index == state.index,
                                  child: page,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: QuranFloatingAudioPlayer(bottomInset: 12),
                      ),
                    ],
                  ),
                ),
              ),
              AppBottomNav(
                currentDestination: state.destination,
                onDestinationSelected: context
                    .read<ShellCubit>()
                    .setDestination,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellTabTransition extends StatefulWidget {
  const _ShellTabTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_ShellTabTransition> createState() => _ShellTabTransitionState();
}

class _ShellTabTransitionState extends State<_ShellTabTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final _curve = _controller.drive(CurveTween(curve: Curves.easeOutCubic));
  late final _opacity = _curve.drive(Tween<double>(begin: 0.55, end: 1));
  double _direction = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _ShellTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          textDirection: Directionality.of(context),
          position: _curve.drive(
            Tween<Offset>(
              begin: Offset(0.035 * _direction, 0),
              end: Offset.zero,
            ),
          ),
          child: widget.child,
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
