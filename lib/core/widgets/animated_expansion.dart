import 'package:flutter/material.dart';

class AnimatedExpansion extends StatefulWidget {
  const AnimatedExpansion({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  State<AnimatedExpansion> createState() => _AnimatedExpansionState();
}

class _AnimatedExpansionState extends State<AnimatedExpansion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.expanded ? 1 : 0,
  )..addStatusListener(_onStatusChanged);
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    _controller.duration = disabled
        ? Duration.zero
        : const Duration(milliseconds: 240);
    if (disabled) _controller.value = widget.expanded ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant AnimatedExpansion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      widget.expanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.expanded && _controller.isDismissed) {
      return const SizedBox.shrink();
    }
    return SizeTransition(
      sizeFactor: _animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _animation,
        child: ExcludeFocus(
          excluding: !widget.expanded,
          child: ExcludeSemantics(
            excluding: !widget.expanded,
            child: IgnorePointer(
              ignoring: !widget.expanded,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
