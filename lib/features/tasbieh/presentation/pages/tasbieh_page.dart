import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_sheet.dart';
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
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tasbieh'),
              Text(
                state.isComplete
                    ? 'Target complete'
                    : '${state.count} of ${state.target}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              children: [
                _TasbiehProgressStrip(state: state),
                Expanded(child: _TasbiehClassicStage(state: state)),
                _TasbiehControls(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbiehProgressStrip extends StatelessWidget {
  const _TasbiehProgressStrip({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${state.count} / ${state.target}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LinearProgressIndicator(
            value: state.progress,
            minHeight: 3,
            borderRadius: BorderRadius.circular(QuranTheme.radiusPill),
            semanticsLabel: 'Target progress',
            semanticsValue: '${(state.progress * 100).round()}%',
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
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RepaintBoundary(
          child: _TasbiehSwipeCounter(
            state: state,
            disableAnimations: MediaQuery.disableAnimationsOf(context),
            onCount: context.read<TasbiehCubit>().increment,
          ),
        ),
      ),
    );
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
  static const _maxDrag = 72.0;
  static const _stageSize = Size(352, 400);

  late final AnimationController _returnController;
  late final AnimationController _pulseController;
  late final AnimationController _shineController;
  late final AnimationController _pressController;
  Animation<Offset>? _returnAnimation;
  Offset _dragOffset = Offset.zero;
  Offset _grabOffset = Offset.zero;
  Offset _pointerOrigin = Offset.zero;
  Offset _localOrigin = Offset.zero;
  double _travel = 0;
  double _farthestTravel = 0;
  int? _pointer;
  bool _tapStartedOnBead = false;

  Offset get _visualDrag => _returnController.isAnimating
      ? _returnAnimation?.value ?? Offset.zero
      : _dragOffset;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant _TasbiehSwipeCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disableAnimations && !oldWidget.disableAnimations) {
      _dragOffset = Offset.zero;
      _returnController.stop();
      _pulseController.reset();
      _shineController.reset();
      _pressController.reset();
    }
  }

  @override
  void dispose() {
    _returnController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null || event.buttons != kPrimaryButton) return;
    _pointer = event.pointer;
    _pointerOrigin = event.position;
    _localOrigin = event.localPosition;
    _travel = _farthestTravel = 0;
    _grabOffset = _visualDrag;
    final touch =
        event.localPosition - (_stageSize.center(Offset.zero) + _grabOffset);
    _tapStartedOnBead =
        math.pow(touch.dx / 108, 2) + math.pow(touch.dy / 124, 2) <= 1;
    _returnController.stop();
    setState(() => _dragOffset = _grabOffset);
    if (_tapStartedOnBead && !widget.disableAnimations) {
      _pressController.forward();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _travel = (event.position - _pointerOrigin).distance;
    _farthestTravel = math.max(_farthestTravel, _travel);
    setState(() {
      final next = _grabOffset + event.localPosition - _localOrigin;
      if (next.distance <= _maxDrag) {
        _dragOffset = next;
      } else {
        _dragOffset = Offset.fromDirection(next.direction, _maxDrag);
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    final tapped = _tapStartedOnBead && _farthestTravel <= 12;
    if (tapped || _travel >= _threshold) unawaited(_acceptCount());
    _animateBack();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _animateBack();
  }

  Future<void> _acceptCount() async {
    unawaited(HapticFeedback.mediumImpact());
    if (!widget.disableAnimations) {
      _pulseController.forward(from: 0);
      _shineController.forward(from: 0);
    }
    try {
      await widget.onCount();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your count could not be saved. It may reset when you reopen the app.',
            ),
          ),
        );
      }
    }
  }

  void _animateBack() {
    if (widget.disableAnimations) {
      setState(() => _dragOffset = Offset.zero);
      return;
    }
    _pressController.reverse();
    final begin = _dragOffset;
    _dragOffset = Offset.zero;
    _returnAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_returnController);
    _returnController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedBuilder(
      animation: Listenable.merge([
        _returnController,
        _pulseController,
        _shineController,
        _pressController,
      ]),
      builder: (context, _) {
        return _ClassicBeadConcept(
          key: const ValueKey('tasbieh-classic-bead'),
          data: _TasbiehClassicData(
            count: widget.state.count,
            dragOffset: _visualDrag,
            dragProgress: (_visualDrag.distance / _threshold).clamp(0.0, 1.0),
            pulse: widget.disableAnimations ? 0 : _pulseController.value,
            shine: widget.disableAnimations ? 0 : _shineController.value,
            press: widget.disableAnimations ? 0 : _pressController.value,
          ),
        );
      },
    );

    return Semantics(
      button: true,
      label: 'Tasbieh bead',
      value: '${widget.state.count} of ${widget.state.target}',
      onTap: () => unawaited(_acceptCount()),
      child: Listener(
        key: const ValueKey('tasbieh-bead'),
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: ExcludeSemantics(
          child: SizedBox.fromSize(size: _stageSize, child: child),
        ),
      ),
    );
  }
}

class _TasbiehClassicData {
  const _TasbiehClassicData({
    required this.count,
    required this.dragOffset,
    required this.dragProgress,
    required this.pulse,
    required this.shine,
    required this.press,
  });

  final int count;
  final Offset dragOffset;
  final double dragProgress;
  final double pulse;
  final double shine;
  final double press;
}

class _ClassicBeadConcept extends StatelessWidget {
  const _ClassicBeadConcept({super.key, required this.data});

  final _TasbiehClassicData data;

  @override
  Widget build(BuildContext context) {
    final primary = QuranTheme.isDark(context)
        ? const Color(0xFFB7DACC)
        : const Color(0xFF477C68);
    final pulse = math.sin(data.pulse * math.pi);
    final dragAngle = data.dragOffset.direction;
    final stretch = 1 + data.dragProgress * 0.12 + data.press * 0.025;
    final squeeze = 1 - data.dragProgress * 0.045 - data.press * 0.055;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _ClassicBeadPainter(
              primary: primary,
              pulse: data.pulse,
              dragOffset: data.dragOffset,
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
                  scale: 1 + pulse * 0.035 - data.press * 0.025,
                  child: _JadeCountBead(
                    count: data.count,
                    shine: data.shine,
                    dragOffset: data.dragOffset,
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

class _JadeCountBead extends StatelessWidget {
  const _JadeCountBead({
    required this.count,
    required this.shine,
    required this.dragOffset,
  });

  final int count;
  final double shine;
  final Offset dragOffset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 210,
      child: CustomPaint(
        painter: _JadeBeadPainter(shine: shine, dragOffset: dragOffset),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count.toString(),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 52,
                  color: const Color(0xFFFFF9E9),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  height: 1,
                  shadows: const [
                    Shadow(
                      color: Color(0x660D3026),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JadeBeadPainter extends CustomPainter {
  const _JadeBeadPainter({required this.shine, required this.dragOffset});

  final double shine;
  final Offset dragOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 210);
    final body = Path()
      ..moveTo(90, 3)
      ..cubicTo(145, 3, 177, 45, 177, 101)
      ..cubicTo(177, 159, 147, 207, 90, 207)
      ..cubicTo(33, 207, 3, 159, 3, 101)
      ..cubicTo(3, 45, 35, 3, 90, 3)
      ..close();
    const bounds = Rect.fromLTWH(0, 0, 180, 210);
    canvas.drawShadow(body, const Color(0x70203D32), 12, false);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            -0.55 + dragOffset.dx / 350,
            -0.65 + dragOffset.dy / 350,
          ),
          radius: 1.35,
          colors: const [
            Color(0xFFBDDACC),
            Color(0xFF669C84),
            Color(0xFF2C6853),
            Color(0xFF123E31),
            Color(0xFF082B24),
          ],
          stops: const [0, 0.25, 0.54, 0.83, 1],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipPath(body);
    // Carved flutes stay on the stone; only the reflected light moves.
    for (var i = 0; i < 5; i++) {
      final x = 22.0 + i * 31;
      canvas.drawPath(
        Path()
          ..moveTo(90 + (x - 90) * 0.35, 0)
          ..cubicTo(x - 24, 58, x + 18, 142, 90 + (x - 90) * 0.6, 210),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(
            0xFFF0E2BA,
          ).withValues(alpha: i.isEven ? 0.11 : 0.055),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(22, 19, 53, 19),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(22, 19, 53, 19)),
    );
    final sweep = math.sin(shine * math.pi);
    if (sweep > 0.001) {
      final light = Rect.fromLTWH(-100 + shine * 320, -20, 90, 260);
      canvas.drawRect(
        light,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: sweep * 0.15),
              Colors.transparent,
            ],
          ).createShader(light),
      );
    }
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5D5A8), Color(0x4434765D), Color(0xAA9B8759)],
        ).createShader(bounds),
    );
    final engraving = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD6C693);
    for (final y in [53.0, 159.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(75, y)
          ..quadraticBezierTo(83, y - 1, 90, y - 7)
          ..quadraticBezierTo(97, y - 1, 105, y)
          ..quadraticBezierTo(97, y + 1, 90, y + 7)
          ..quadraticBezierTo(83, y + 1, 75, y),
        engraving,
      );
      canvas.drawCircle(Offset(90, y), 1.4, Paint()..color = engraving.color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JadeBeadPainter oldDelegate) =>
      oldDelegate.shine != shine || oldDelegate.dragOffset != dragOffset;
}

class _ClassicBeadPainter extends CustomPainter {
  const _ClassicBeadPainter({
    required this.primary,
    required this.pulse,
    required this.dragOffset,
  });

  final Color primary;
  final double pulse;
  final Offset dragOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero) + dragOffset;

    if (pulse > 0 && pulse < 1) {
      canvas.drawCircle(
        center,
        112 + 45 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = primary.withValues(alpha: 0.16 * math.sin(pulse * math.pi)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClassicBeadPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.dragOffset != dragOffset ||
        oldDelegate.primary != primary;
  }
}

class _TasbiehControls extends StatelessWidget {
  const _TasbiehControls({required this.state});

  final TasbiehState state;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
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
              fontWeight: FontWeight.w500,
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
    final primary = Theme.of(context).colorScheme.primary;
    return AppSheet(
      key: const ValueKey('tasbieh-target-sheet-surface'),
      title: 'Tasbieh Target',
      subtitle: 'Current target ${widget.currentTarget}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIcon(Icons.tune_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Custom target',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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
                  prefixIcon: const AppIcon(Icons.tag_rounded),
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
                icon: const AppIcon(Icons.check_rounded),
                label: const Text('Set Custom Target'),
              ),
            ],
          ),
        ],
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
      ),
      selected: selected,
      selectedTileColor: QuranTheme.softFill(
        context,
        Theme.of(context).colorScheme.primary,
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: selected
          ? const AppIcon(Icons.check_rounded)
          : AppIcon(icon, size: 20),
      onTap: onTap,
    );
  }
}
