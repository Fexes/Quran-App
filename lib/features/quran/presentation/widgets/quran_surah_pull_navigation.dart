import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/quran_theme.dart';

class QuranSurahPullNavigation extends StatefulWidget {
  const QuranSurahPullNavigation({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.bottomInset,
    required this.onNavigate,
    required this.onDragStart,
    required this.child,
  });

  final bool hasPrevious;
  final bool hasNext;
  final double bottomInset;
  final Future<void> Function(bool previous) onNavigate;
  final VoidCallback onDragStart;
  final Widget child;

  @override
  State<QuranSurahPullNavigation> createState() =>
      _QuranSurahPullNavigationState();
}

class _QuranSurahPullNavigationState extends State<QuranSurahPullNavigation>
    with SingleTickerProviderStateMixin {
  static const _pullDistance = 220.0;
  static const _holdDuration = Duration(milliseconds: 1400);
  static const _returnDuration = Duration(milliseconds: 1000);

  late final _progress = AnimationController(
    vsync: this,
    duration: _returnDuration,
  );
  Timer? _holdTimer;
  double? _startY;
  bool _canPrevious = false;
  bool _canNext = false;
  bool _previous = false;
  bool _triggered = false;
  bool _queued = false;
  double _pendingProgress = 0;

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  void _reset() {
    _cancelHold();
    _startY = null;
    _canPrevious = false;
    _canNext = false;
    if (_triggered) return;
    _pendingProgress = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startY != null || _triggered) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _progress.value = 0;
      } else {
        _progress.animateBack(
          0,
          duration: _returnDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _progress.stop();
  }

  void _holdToNavigate(bool previous) {
    if (_holdTimer != null) return;
    assert(_startY != null && _pendingProgress >= 0.8);
    final timer = Timer(_holdDuration, () {
      _holdTimer = null;
      if (!mounted || _startY == null || _triggered) return;
      assert(_previous == previous && _pendingProgress >= 0.8);
      _triggered = true;
      HapticFeedback.selectionClick();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await widget.onNavigate(previous);
        } finally {
          if (mounted) {
            _triggered = false;
            _reset();
          }
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    _holdTimer = timer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _holdTimer != timer) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _progress.animateTo(1, duration: _holdDuration, curve: Curves.linear);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _showProgress(double progress) {
    _pendingProgress = progress;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _progress.value = progress;
      return;
    }
    if (_queued) return;
    _queued = true;
    // Scroll notifications can arrive during layout. Rebuild only this overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (mounted) _progress.value = _pendingProgress;
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        _triggered) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      widget.onDragStart();
      _cancelHold();
      _showProgress(0);
      _startY = notification.dragDetails!.globalPosition.dy;
      _canPrevious =
          widget.hasPrevious && notification.metrics.extentBefore <= 2;
      _canNext = widget.hasNext && notification.metrics.extentAfter <= 2;
    }
    // The same pointer position can generate both update and overscroll events.
    // Absolute displacement counts it once and excludes ballistic scrolling.
    final position = switch (notification) {
      ScrollUpdateNotification(:final dragDetails) =>
        dragDetails?.globalPosition.dy,
      OverscrollNotification(:final dragDetails) =>
        dragDetails?.globalPosition.dy,
      _ => null,
    };
    final startY = _startY;
    if (position != null && startY != null) {
      final delta = position - startY;
      final previous = delta > 0;
      final allowed = previous ? _canPrevious : _canNext;
      final atEdge = previous
          ? notification.metrics.extentBefore <= 2
          : notification.metrics.extentAfter <= 2;
      final distance = allowed && atEdge ? delta.abs() : 0.0;
      // Diminishing progress matches the reader's bouncing scroll resistance.
      final progress = (2 * distance / (distance + _pullDistance)).clamp(
        0.0,
        1.0,
      );
      if (progress < 1 || previous != _previous) _cancelHold();
      _previous = previous;
      if (_holdTimer == null) {
        // Reserve the last fifth of the ring for a deliberate hold at the edge.
        _showProgress(progress * 0.8);
        if (progress >= 1) _holdToNavigate(previous);
      }
    }
    if (notification is ScrollEndNotification) _reset();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: AnimatedBuilder(
          animation: _progress,
          child: widget.child,
          builder: (context, child) => Stack(
            fit: StackFit.expand,
            children: [
              child!,
              if (_progress.value > 0)
                Positioned(
                  top: _previous ? 12 + 72 * _progress.value : null,
                  bottom: _previous
                      ? null
                      : widget.bottomInset + 72 * _progress.value,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * _progress.value,
                        child: Material(
                          color: QuranTheme.surface(context),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            QuranTheme.radiusPill,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox.square(
                                  dimension: 28,
                                  child: CircularProgressIndicator(
                                    key: const ValueKey('surah-pull-progress'),
                                    value: _progress.value,
                                    strokeWidth: 3,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: QuranTheme.subText(
                                      context,
                                      0.14,
                                    ),
                                    semanticsLabel: _previous
                                        ? 'Previous surah'
                                        : 'Next surah',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    _previous ? 'Previous surah' : 'Next surah',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
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
      ),
    );
  }
}

class SurahNavigationCapsule extends StatelessWidget {
  const SurahNavigationCapsule({super.key, this.previous = false});

  final bool previous;

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      width: 72,
      child: Divider(
        height: 20,
        thickness: 0.5,
        color: QuranTheme.subText(context, 0.12),
      ),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!previous) divider,
          DecoratedBox(
            decoration: BoxDecoration(
              color: QuranTheme.surface(context),
              borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                previous
                    ? 'Swipe down to go to previous surah'
                    : 'Swipe up to go to next surah',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: QuranTheme.subText(context, 0.8),
                ),
              ),
            ),
          ),
          if (previous) divider,
        ],
      ),
    );
  }
}
