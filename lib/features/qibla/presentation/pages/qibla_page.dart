import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../domain/repositories/qibla_repository.dart';
import '../../domain/services/qibla_heading_filter.dart';
import '../bloc/qibla_cubit.dart';
import '../bloc/qibla_state.dart';
import '../widgets/qibla_compass.dart';

const _headingEvents = EventChannel('quran/qibla_heading');

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QiblaCubit(repository: getIt<QiblaRepository>())..load(),
      child: const _QiblaView(),
    );
  }
}

class _QiblaView extends StatelessWidget {
  const _QiblaView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const AppIcon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.shell),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<QiblaCubit, QiblaState>(
          builder: (context, state) {
            if (state.status == QiblaStatus.failure) {
              return AppErrorView(
                title: 'Qibla unavailable',
                message: state.errorMessage ?? 'Check your prayer location.',
                onRetry: context.read<QiblaCubit>().load,
              );
            }
            final direction = state.direction;
            if (direction == null) {
              return const AppLoadingView(label: 'Finding Qibla');
            }
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 480,
                      minHeight: math.max(0, constraints.maxHeight - 44),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              alignment: WrapAlignment.center,
                              children: [
                                AppIcon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: QuranTheme.subText(context),
                                ),
                                Text(
                                  direction.location.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Direction to the Kaaba',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: QuranTheme.subText(context),
                                  ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: _LiveQiblaCompass(
                            qiblaBearing: direction.bearingDegrees,
                            location: direction.location,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiveQiblaCompass extends StatefulWidget {
  const _LiveQiblaCompass({required this.qiblaBearing, required this.location});

  final double qiblaBearing;
  final PrayerLocation location;

  @override
  State<_LiveQiblaCompass> createState() => _LiveQiblaCompassState();
}

class _LiveQiblaCompassState extends State<_LiveQiblaCompass>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _rotation = AnimationController.unbounded(vsync: this);
  final _status = ValueNotifier('Finding compass');
  final _hapticClock = Stopwatch()..start();
  final _headingFilter = QiblaHeadingFilter();
  StreamSubscription<dynamic>? _headingSubscription;
  Timer? _alignmentTimer;
  Timer? _firstReadingTimer;
  Timer? _accuracyTimer;
  double? _heading;
  String? _sensorError;
  bool _active = true;
  bool _aligned = false;
  bool _reliable = false;
  bool _magneticOnly = false;
  bool _accuracyLimited = false;
  int _streamRevision = 0;
  int? _lastHapticAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _startHeadingStream();
  }

  @override
  void didUpdateWidget(covariant _LiveQiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.qiblaBearing != widget.qiblaBearing) {
      _startHeadingStream(resetState: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rotation.stop();
      if (_heading != null) _rotation.value = _heading!;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _startHeadingStream(resetState: true);
    } else {
      ++_streamRevision;
      _headingSubscription?.cancel();
      _alignmentTimer?.cancel();
      _alignmentTimer = null;
      _firstReadingTimer?.cancel();
      _accuracyTimer?.cancel();
      _accuracyTimer = null;
      _headingFilter.reset();
      _rotation.stop();
      setState(() {
        _heading = null;
        _aligned = false;
        _reliable = false;
      });
      _status.value = 'Compass paused';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_streamRevision;
    _headingSubscription?.cancel();
    _alignmentTimer?.cancel();
    _firstReadingTimer?.cancel();
    _accuracyTimer?.cancel();
    _rotation.dispose();
    _status.dispose();
    _hapticClock.stop();
    super.dispose();
  }

  Future<void> _startHeadingStream({bool resetState = false}) async {
    final revision = ++_streamRevision;
    _alignmentTimer?.cancel();
    _alignmentTimer = null;
    _firstReadingTimer?.cancel();
    _accuracyTimer?.cancel();
    _accuracyTimer = null;
    _headingFilter.reset();
    await _headingSubscription?.cancel();
    if (!mounted || !_active || revision != _streamRevision) return;
    if (resetState) {
      _rotation.stop();
      setState(() {
        _heading = null;
        _sensorError = null;
        _aligned = false;
        _reliable = false;
        _magneticOnly = false;
        _accuracyLimited = false;
      });
      _status.value = 'Finding compass';
    }
    _firstReadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted &&
          _active &&
          revision == _streamRevision &&
          _heading == null) {
        _handleHeadingError(const FormatException('No heading received'));
      }
    });
    _headingSubscription = _headingEvents
        .receiveBroadcastStream({
          'latitude': widget.location.latitude,
          'longitude': widget.location.longitude,
          'altitude': 0.0,
        })
        .listen(
          (event) {
            if (revision == _streamRevision) _handleHeading(event);
          },
          onError: (Object error) {
            if (revision == _streamRevision) _handleHeadingError(error);
          },
          onDone: () {
            if (revision == _streamRevision) {
              _handleHeadingError(
                const FormatException('Heading stream ended'),
              );
            }
          },
        );
  }

  void _handleHeading(dynamic event) {
    if (!mounted || !_active) return;
    if (event is! Map) {
      _handleHeadingError(const FormatException('Invalid heading event'));
      return;
    }
    final ({double heading, bool reliable, bool magneticOnly}) reading;
    try {
      reading = _headingFilter.add(event, now: _hapticClock.elapsed);
    } on FormatException {
      // A transient invalid sample must not erase the last valid direction.
      final changed = _reliable || _aligned || _alignmentTimer != null;
      _reliable = false;
      _alignmentTimer?.cancel();
      _alignmentTimer = null;
      _aligned = false;
      _updateAccuracyWarning();
      if (changed) setState(() {});
      _updateStatus();
      return;
    }
    final heading = reading.heading;
    final before = (
      _heading == null,
      _sensorError,
      _aligned,
      _reliable,
      _magneticOnly,
      _accuracyLimited,
      _alignmentTimer != null,
    );
    final firstReading = _heading == null;
    _firstReadingTimer?.cancel();
    _sensorError = null;
    _heading = heading;
    _magneticOnly = reading.magneticOnly;
    _reliable = reading.reliable;
    _updateAccuracyWarning();
    final relative = _signedAngle(widget.qiblaBearing - heading);

    // Warning visibility is independent of whether a reading can confirm Qibla.
    if (!_reliable || relative.abs() > (_aligned ? 9 : 6)) {
      _alignmentTimer?.cancel();
      _alignmentTimer = null;
      _aligned = false;
    } else if (!_aligned && _alignmentTimer == null) {
      _alignmentTimer = Timer(
        const Duration(milliseconds: 650),
        _confirmAlignment,
      );
    }
    assert(!_aligned || (_reliable && relative.abs() <= 9));

    if (before !=
        (
          _heading == null,
          _sensorError,
          _aligned,
          _reliable,
          _magneticOnly,
          _accuracyLimited,
          _alignmentTimer != null,
        )) {
      setState(() {});
    }
    _updateStatus();

    final target = _rotation.value + _signedAngle(heading - _rotation.value);
    if (firstReading || MediaQuery.disableAnimationsOf(context)) {
      _rotation.value = target;
    } else if ((target - _rotation.value).abs() >= 0.35) {
      _rotation.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
  }

  void _confirmAlignment() {
    _alignmentTimer = null;
    if (!mounted || !_active || !_reliable || _heading == null) return;
    final relative = _signedAngle(widget.qiblaBearing - _heading!);
    if (relative.abs() > 6) return;
    assert(_sensorError == null && !_magneticOnly);
    setState(() => _aligned = true);
    _updateStatus();
    final now = _hapticClock.elapsedMilliseconds;
    if (_lastHapticAt == null || now - _lastHapticAt! >= 3000) {
      _lastHapticAt = now;
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _updateStatus() {
    final relative = _signedAngle(widget.qiblaBearing - (_heading ?? 0));
    _status.value = _magneticOnly
        ? 'True north unavailable'
        : !_reliable
        ? _accuracyLimited
              ? 'Direction is approximate'
              : 'Finding accurate direction'
        : _aligned
        ? 'Facing Qibla'
        : _alignmentTimer != null
        ? 'Hold steady'
        : '${relative > 0 ? 'Turn right' : 'Turn left'} '
              '${relative.abs().round()}°';
  }

  void _updateAccuracyWarning() {
    if (_reliable || _magneticOnly) {
      _accuracyTimer?.cancel();
      _accuracyTimer = null;
      _accuracyLimited = false;
      return;
    }
    if (_accuracyLimited || _accuracyTimer != null) return;
    _accuracyTimer = Timer(const Duration(seconds: 3), () {
      _accuracyTimer = null;
      if (!mounted || !_active || _reliable || _magneticOnly) return;
      setState(() => _accuracyLimited = true);
      _updateStatus();
    });
  }

  void _handleHeadingError(Object error) {
    if (!mounted || !_active) return;
    _rotation.stop();
    _firstReadingTimer?.cancel();
    _accuracyTimer?.cancel();
    _accuracyTimer = null;
    _headingFilter.reset();
    _alignmentTimer?.cancel();
    _alignmentTimer = null;
    setState(() {
      _heading = null;
      _aligned = false;
      _reliable = false;
      _magneticOnly = false;
      _accuracyLimited = false;
      _sensorError = error is PlatformException && error.code == 'no_sensor'
          ? 'This device has no compass sensor'
          : 'Compass reading unavailable';
    });
    _status.value = _sensorError!;
  }

  @override
  Widget build(BuildContext context) {
    final text = QuranTheme.text(context);
    final success = QuranTheme.semantic(context).success;
    final warning = QuranTheme.semantic(context).warning;
    final hasHeading = _heading != null;
    final settling = _alignmentTimer != null;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final guidance = _sensorError != null
        ? 'Your Qibla bearing is still available below.'
        : _magneticOnly
        ? 'Allow location access in Settings to use true north.'
        : _accuracyLimited
        ? 'Move away from magnetic cases, chargers, or metal.'
        : hasHeading && !_reliable
        ? 'Hold your phone flat while the sensors settle.'
        : _aligned
        ? 'Your phone is pointing towards the Kaaba.'
        : settling
        ? 'Keep your phone still for a moment.'
        : 'Hold your phone flat. Bring the Kaaba to the top marker.';
    return Column(
      children: [
        QiblaCompass(
          heading: _rotation,
          bearing: widget.qiblaBearing,
          hasHeading: hasHeading,
          unavailable: _sensorError != null,
          reliable: _reliable,
          recovering: !_reliable && !_accuracyLimited && !_magneticOnly,
          aligned: _aligned,
          settling: settling,
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion:
              _aligned || _sensorError != null || (hasHeading && !_reliable),
          child: ValueListenableBuilder<String>(
            valueListenable: _status,
            builder: (context, status, _) => AnimatedDefaultTextStyle(
              duration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              style:
                  (Theme.of(context).textTheme.headlineSmall ??
                          const TextStyle())
                      .copyWith(
                        fontSize: 24,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: _aligned ? success : text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
              textAlign: TextAlign.center,
              child: Text(status),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          guidance,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: QuranTheme.subText(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (_sensorError != null)
          TextButton.icon(
            onPressed: () => _startHeadingStream(resetState: true),
            icon: const AppIcon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry compass'),
          )
        else
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppIcon(
                !hasHeading
                    ? Icons.explore_outlined
                    : _reliable
                    ? Icons.verified_outlined
                    : Icons.info_outline_rounded,
                size: 16,
                color:
                    hasHeading &&
                        !_reliable &&
                        (_accuracyLimited || _magneticOnly)
                    ? warning
                    : QuranTheme.subText(context),
              ),
              Text(
                !hasHeading
                    ? 'Waiting for a compass reading'
                    : _magneticOnly
                    ? 'Magnetic north only'
                    : _reliable
                    ? 'True north'
                    : _accuracyLimited
                    ? 'Low compass confidence'
                    : 'Refining direction',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      hasHeading &&
                          !_reliable &&
                          (_accuracyLimited || _magneticOnly)
                      ? warning
                      : QuranTheme.subText(context),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _rotation,
          builder: (context, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BearingReadout(
                  label: 'Qibla bearing',
                  value: '${widget.qiblaBearing.round() % 360}°',
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _BearingReadout(
                  label: _magneticOnly ? 'Magnetic heading' : 'Your heading',
                  value: hasHeading
                      ? '${(_rotation.value % 360).round() % 360}°'
                      : 'Unavailable',
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BearingReadout extends StatelessWidget {
  const _BearingReadout({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textAlign = alignment == CrossAxisAlignment.end
        ? TextAlign.end
        : TextAlign.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

double _signedAngle(double degrees) => (degrees + 540) % 360 - 180;
