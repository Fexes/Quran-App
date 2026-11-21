import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/quran_theme.dart';

/// Adds a soft shadow beneath fixed headers when their content has scrolled.
class ScrollUnderHeaderShadow extends StatefulWidget {
  const ScrollUnderHeaderShadow({
    super.key,
    required this.headerExtent,
    required this.child,
  });

  final double headerExtent;
  final Widget child;

  @override
  State<ScrollUnderHeaderShadow> createState() =>
      _ScrollUnderHeaderShadowState();
}

class _ScrollUnderHeaderShadowState extends State<ScrollUnderHeaderShadow> {
  bool _scrolledUnder = false;
  bool _pendingScrolledUnder = false;
  bool _updateScheduled = false;

  void _updateShadow(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;
    _pendingScrolledUnder = metrics.extentBefore > 0;
    if (_scrolledUnder == _pendingScrolledUnder) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_updateScheduled) return;
      _updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        if (mounted) _applyShadow();
      });
      return;
    }
    _applyShadow();
  }

  void _applyShadow() {
    if (_scrolledUnder == _pendingScrolledUnder) return;
    setState(() => _scrolledUnder = _pendingScrolledUnder);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) _updateShadow(notification.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) _updateShadow(notification.metrics);
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            Positioned(
              top: widget.headerExtent,
              left: 0,
              right: 0,
              height: 8,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: AnimatedOpacity(
                    opacity: _scrolledUnder ? 1 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(
                              alpha: QuranTheme.isDark(context) ? 0.10 : 0.045,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
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
