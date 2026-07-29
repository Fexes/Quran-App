import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../cubit/tasbieh_cubit.dart';
import '../cubit/tasbieh_state.dart';

class TasbiehPage extends StatelessWidget {
  const TasbiehPage({super.key, this.settingsStore});

  final SettingsStore? settingsStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TasbiehCubit(settingsStore: settingsStore ?? getIt<SettingsStore>())
            ..load(),
      child: const _TasbiehView(),
    );
  }
}

class _TasbiehView extends StatelessWidget {
  const _TasbiehView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasbiehCubit, TasbiehState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TasbiehBackdropPainter(
                    background: Theme.of(context).scaffoldBackgroundColor,
                    primary: Theme.of(context).colorScheme.primary,
                    text: QuranTheme.text(context),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                  child: Column(
                    children: [
                      _TasbiehHeader(state: state),
                      const SizedBox(height: 10),
                      _TasbiehProgressStrip(state: state),
                      const SizedBox(height: 10),
                      Expanded(child: _TasbiehClassicStage(state: state)),
                      const SizedBox(height: 12),
                      _TasbiehControls(state: state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TasbiehHeader extends StatelessWidget {
  const _TasbiehHeader({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PremiumSurface(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          width: 44,
          height: 44,
          padding: EdgeInsets.zero,
          radius: 16,
          child: Icon(
            Icons.arrow_back_rounded,
            color: QuranTheme.text(context),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: QuranTheme.softFill(
                    context,
                    Theme.of(context).colorScheme.primary,
                  ),
                  border: Border.all(color: QuranTheme.outline(context)),
                ),
                child: Icon(
                  Icons.circle_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasbieh',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isComplete
                          ? 'Target complete'
                          : '${state.count} of ${state.target}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QuranTheme.subText(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TasbiehProgressStrip extends StatelessWidget {
  const _TasbiehProgressStrip({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final percent = (state.progress * 100).round();
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 24,
      prominent: true,
      child: Row(
        children: [
          _MiniStat(label: 'Count', value: state.count.toString()),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: QuranTheme.outline(context)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: state.progress,
                      child: ColoredBox(color: primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _MiniStat(label: 'Target', value: state.target.toString()),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, primary),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: QuranTheme.outline(context)),
            ),
            child: Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: QuranTheme.text(context),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: QuranTheme.subText(context, 0.68),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TasbiehClassicStage extends StatelessWidget {
  const _TasbiehClassicStage({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              child: _TasbiehSwipeCounter(
                state: state,
                disableAnimations: disableAnimations,
                onCount: context.read<TasbiehCubit>().increment,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: QuranTheme.outline(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Drag in any direction',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: QuranTheme.subText(context, 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasbiehBackdropPainter extends CustomPainter {
  const _TasbiehBackdropPainter({
    required this.background,
    required this.primary,
    required this.text,
  });

  final Color background;
  final Color primary;
  final Color text;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);

    final topWash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.15, -0.76),
        radius: 0.86,
        colors: [
          primary.withValues(alpha: 0.13),
          primary.withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, topWash);

    final dot = Paint()..color = primary.withValues(alpha: 0.08);
    for (var y = 92.0; y < size.height - 70; y += 54) {
      for (var x = 28.0; x < size.width; x += 54) {
        final drift = math.sin((x + y) * 0.02) * 2.5;
        canvas.drawCircle(Offset(x + drift, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TasbiehBackdropPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.primary != primary ||
        oldDelegate.text != text;
  }
}

class _TasbiehSwipeCounter extends StatefulWidget {
  const _TasbiehSwipeCounter({
    required this.state,
    required this.disableAnimations,
    required this.onCount,
  });

  final TasbiehState state;
  final bool disableAnimations;
  final Future<void> Function() onCount;

  @override
  State<_TasbiehSwipeCounter> createState() => _TasbiehSwipeCounterState();
}

class _TasbiehSwipeCounterState extends State<_TasbiehSwipeCounter>
    with TickerProviderStateMixin {
  static const _threshold = 44.0;
  static const _maxDrag = 96.0;

  late final AnimationController _returnController;
  late final AnimationController _pulseController;
  late final AnimationController _shineController;
  late final AnimationController _classicAmbientController;
  Animation<Offset>? _returnAnimation;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _classicAmbientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAmbient();
  }

  @override
  void didUpdateWidget(covariant _TasbiehSwipeCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAmbient();
    if (oldWidget.state.count != widget.state.count &&
        !widget.disableAnimations) {
      _shineController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _returnController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    _classicAmbientController.dispose();
    super.dispose();
  }

  void _syncAmbient() {
    final shouldAnimate =
        TickerMode.valuesOf(context).enabled &&
        !widget.disableAnimations &&
        mounted;
    if (shouldAnimate) {
      if (!_classicAmbientController.isAnimating) {
        _classicAmbientController.repeat();
      }
    } else {
      _classicAmbientController.stop();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _returnController.stop();
  }

  void _onPointerMove(PointerMoveEvent event) {
    _returnController.stop();
    setState(() {
      final next = _dragOffset + event.delta;
      if (next.distance <= _maxDrag) {
        _dragOffset = next;
      } else {
        _dragOffset = Offset.fromDirection(next.direction, _maxDrag);
      }
    });
  }

  Future<void> _onPointerUp(PointerUpEvent event) async {
    final accepted = _dragOffset.distance >= _threshold;
    if (accepted) {
      await _acceptCount();
    }
    _animateBack();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _animateBack();
  }

  Future<void> _acceptCount() async {
    HapticFeedback.mediumImpact();
    await widget.onCount();
    if (!widget.disableAnimations) {
      _pulseController.forward(from: 0);
    }
  }

  void _animateBack() {
    final begin = _dragOffset;
    _returnAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOutBack),
    );
    _returnController
      ..removeListener(_handleReturnTick)
      ..addListener(_handleReturnTick)
      ..forward(from: 0);
  }

  void _handleReturnTick() {
    if (!mounted) {
      return;
    }
    setState(() {
      _dragOffset = _returnAnimation?.value ?? Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_dragOffset.distance / _threshold).clamp(0.0, 1.0);
    final child = AnimatedBuilder(
      animation: Listenable.merge([
        _returnController,
        _pulseController,
        _shineController,
        _classicAmbientController,
      ]),
      builder: (context, _) {
        return _ClassicBeadConcept(
          key: const ValueKey('tasbieh-classic-bead'),
          data: _TasbiehClassicData(
            count: widget.state.count,
            target: widget.state.target,
            progress: widget.state.progress,
            isComplete: widget.state.isComplete,
            dragOffset: _dragOffset,
            dragProgress: dragProgress,
            pulse: widget.disableAnimations ? 0 : _pulseController.value,
            shine: widget.disableAnimations ? 0 : _shineController.value,
          ),
          ambient: _classicAmbientController.value,
        );
      },
    );

    return Listener(
      key: const ValueKey('tasbieh-bead'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(width: 318, height: 360, child: child),
    );
  }
}

class _TasbiehClassicData {
  const _TasbiehClassicData({
    required this.count,
    required this.target,
    required this.progress,
    required this.isComplete,
    required this.dragOffset,
    required this.dragProgress,
    required this.pulse,
    required this.shine,
  });

  final int count;
  final int target;
  final double progress;
  final bool isComplete;
  final Offset dragOffset;
  final double dragProgress;
  final double pulse;
  final double shine;
}

class _ClassicBeadConcept extends StatelessWidget {
  const _ClassicBeadConcept({
    super.key,
    required this.data,
    required this.ambient,
  });

  final _TasbiehClassicData data;
  final double ambient;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pulse = math.sin(data.pulse * math.pi);
    final dragAngle = data.dragOffset.direction;
    final stretch = 1 + data.dragProgress * 0.12;
    final squeeze = 1 - data.dragProgress * 0.045;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ClassicBeadPainter(
              primary: primary,
              pulse: data.pulse,
              shine: data.shine,
              ambient: ambient,
              complete: data.isComplete,
            ),
          ),
        ),
        Transform.translate(
          offset: data.dragOffset,
          child: Transform.rotate(
            angle: dragAngle,
            child: Transform.scale(
              scaleX: stretch,
              scaleY: squeeze,
              child: Transform.rotate(
                angle: -dragAngle,
                child: Transform.scale(
                  scale: 1 + pulse * 0.05,
                  child: _PearlCountBead(
                    count: data.count,
                    size: 172,
                    foreground: QuranTheme.text(context),
                    glow: primary,
                    shine: data.shine,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PearlCountBead extends StatelessWidget {
  const _PearlCountBead({
    required this.count,
    required this.size,
    required this.foreground,
    required this.glow,
    required this.shine,
  });

  final int count;
  final double size;
  final Color foreground;
  final Color glow;
  final double shine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.42, -0.54),
          radius: 1.15,
          colors: [Colors.white, Color(0xFFF7FAF9), Color(0xFFE4ECE8)],
          stops: [0.0, 0.56, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: glow.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.16,
            left: size * 0.24,
            right: size * 0.24,
            child: Transform.translate(
              offset: Offset((shine - 0.5) * size * 0.18, 0),
              child: Container(
                height: size * 0.14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassicBeadPainter extends CustomPainter {
  const _ClassicBeadPainter({
    required this.primary,
    required this.pulse,
    required this.shine,
    required this.ambient,
    required this.complete,
  });

  final Color primary;
  final double pulse;
  final double shine;
  final double ambient;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: 0.055);
    for (var index = 0; index < 7; index++) {
      final radius = 76.0 + index * 42;
      canvas.drawCircle(center, radius, ripplePaint);
    }

    if (pulse > 0) {
      final p = math.sin(pulse * math.pi);
      canvas.drawCircle(
        center,
        92 + 72 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = primary.withValues(alpha: 0.22 * (1 - pulse)),
      );
      for (var index = 0; index < 18; index++) {
        final angle = index * math.pi * 2 / 18 + shine * math.pi;
        final distance = 88 + p * 88;
        canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * distance,
          1.8 + p * 1.8,
          Paint()..color = primary.withValues(alpha: (1 - pulse) * 0.5),
        );
      }
    }

    if (complete) {
      canvas.drawCircle(
        center,
        136 + math.sin(ambient * math.pi * 2) * 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = primary.withValues(alpha: 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClassicBeadPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.shine != shine ||
        oldDelegate.ambient != ambient ||
        oldDelegate.complete != complete ||
        oldDelegate.primary != primary;
  }
}

class _TasbiehControls extends StatelessWidget {
  const _TasbiehControls({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(10),
      radius: 26,
      prominent: true,
      child: Row(
        children: [
          Expanded(
            child: _TasbiehControlButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onTap: state.count > 0 ? context.read<TasbiehCubit>().undo : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TasbiehControlButton(
              key: const ValueKey('tasbieh-target-button'),
              icon: Icons.flag_rounded,
              label: 'Target ${state.target}',
              onTap: () => _showTargetSheet(context, state.target),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TasbiehControlButton(
              icon: Icons.refresh_rounded,
              label: 'Reset',
              onTap: state.count > 0 ? () => _confirmReset(context) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Tasbieh?'),
          content: const Text('This will clear the current count.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (reset == true && context.mounted) {
      await context.read<TasbiehCubit>().reset();
    }
  }

  Future<void> _showTargetSheet(BuildContext context, int currentTarget) async {
    final cubit = context.read<TasbiehCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _TasbiehTargetSheet(
        currentTarget: currentTarget,
        onTargetSelected: cubit.setTarget,
      ),
    );
  }
}

class _TasbiehControlButton extends StatelessWidget {
  const _TasbiehControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      radius: 20,
      color: QuranTheme.softFill(
        context,
        Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: onTap == null
                ? QuranTheme.subText(context, 0.36)
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onTap == null
                  ? QuranTheme.subText(context, 0.36)
                  : QuranTheme.text(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbiehTargetSheet extends StatefulWidget {
  const _TasbiehTargetSheet({
    required this.currentTarget,
    required this.onTargetSelected,
  });

  final int currentTarget;
  final Future<void> Function(int target) onTargetSelected;

  @override
  State<_TasbiehTargetSheet> createState() => _TasbiehTargetSheetState();
}

class _TasbiehTargetSheetState extends State<_TasbiehTargetSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentTarget == 33 || widget.currentTarget == 99
          ? ''
          : widget.currentTarget.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(int target) async {
    await widget.onTargetSelected(target);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('tasbieh-target-sheet-surface'),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: EdgeInsets.fromLTRB(18, 10, 18, bottom + 18),
        decoration: BoxDecoration(
          color: QuranTheme.surface(context),
          borderRadius: BorderRadius.circular(QuranTheme.radiusSheet),
          border: Border.all(color: QuranTheme.outline(context)),
          boxShadow: QuranTheme.premiumShadow(context, prominent: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: QuranTheme.outline(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QuranTheme.softFill(context, primary),
                    border: Border.all(color: QuranTheme.outline(context)),
                  ),
                  child: Icon(Icons.flag_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasbieh Target',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Current target ${widget.currentTarget}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                PremiumSurface(
                  onTap: () => Navigator.of(context).pop(),
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.zero,
                  radius: 16,
                  child: Icon(
                    Icons.close_rounded,
                    color: QuranTheme.subText(context),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Common targets',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TargetPreset(
                    label: '33',
                    subtitle: 'Classic',
                    icon: Icons.looks_3_rounded,
                    selected: widget.currentTarget == 33,
                    onTap: () => _select(33),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TargetPreset(
                    label: '99',
                    subtitle: 'Full set',
                    icon: Icons.all_inclusive_rounded,
                    selected: widget.currentTarget == 99,
                    onTap: () => _select(99),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            PremiumSurface(
              padding: const EdgeInsets.all(14),
              radius: 24,
              prominent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Custom target',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('tasbieh-custom-target-field'),
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter a number',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      filled: true,
                      fillColor: QuranTheme.surfaceVariant(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          QuranTheme.radiusControl,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submitCustom(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitCustom,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Set Custom Target'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCustom() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      return;
    }
    await _select(value);
  }
}

class _TargetPreset extends StatelessWidget {
  const _TargetPreset({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 24,
      color: selected ? QuranTheme.softFill(context, primary) : null,
      prominent: selected,
      child: Stack(
        children: [
          if (selected)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.check_circle_rounded, color: primary, size: 20),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: QuranTheme.softFill(context, primary),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: QuranTheme.subText(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
