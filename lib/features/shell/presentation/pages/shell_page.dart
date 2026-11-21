import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/scroll_under_header_shadow.dart';
import '../../../../core/widgets/shell_screen_header.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../prayer/presentation/pages/prayer_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../bloc/shell_cubit.dart';
import '../bloc/shell_state.dart';
import '../widgets/app_bottom_nav.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, ShellState>(
      builder: (context, state) {
        final headerExtent =
            MediaQuery.paddingOf(context).top +
            18 +
            ShellScreenHeader.height(context) +
            16;
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
                        // Match the safe area and the tabs’ header padding.
                        height: headerExtent,
                        child: const HeaderPatternBackdrop(),
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
                              ].indexed)
                                TickerMode(
                                  enabled: index == state.index,
                                  child: ScrollUnderHeaderShadow(
                                    headerExtent: headerExtent,
                                    child: page,
                                  ),
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
