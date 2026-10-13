import 'dart:math' as math;

class QiblaHeadingFilter {
  double? _heading;
  Duration? _lastSampleAt;

  void reset() {
    _heading = null;
    _lastSampleAt = null;
  }

  ({double heading, bool reliable, bool magneticOnly}) add(
    Map<dynamic, dynamic> event, {
    required Duration now,
  }) {
    final raw = event['heading'];
    if (raw is! num || !raw.isFinite || raw < 0 || raw > 360) {
      throw const FormatException('Invalid compass heading');
    }
    final source = event['source'];
    final accuracy = _number(event['accuracy']);
    final accuracyDegrees = _number(event['accuracyDegrees']);
    final magneticOnly =
        source == 'ios_core_location_magnetic' ||
        source == 'ios_device_motion_magnetic';
    final reliable = switch (source) {
      'ios_device_motion' =>
        event['accuracyLevel'] == 'medium' || event['accuracyLevel'] == 'high',
      'android_rotation_vector' || 'android_geomagnetic_rotation_vector' =>
        accuracyDegrees != null
            ? accuracyDegrees >= 0 && accuracyDegrees <= 20
            : accuracy != null && accuracy >= 2 && accuracy <= 3,
      'ios_core_location' =>
        accuracy != null && accuracy >= 0 && accuracy <= 20,
      _ => false,
    };
    final heading = raw.toDouble() % 360;
    final previous = _heading;
    final lastSampleAt = _lastSampleAt;
    if (previous == null ||
        lastSampleAt == null ||
        now - lastSampleAt > const Duration(seconds: 1)) {
      _heading = heading;
    } else {
      final delta = (heading - previous + 540) % 360 - 180;
      final elapsed = (now - lastSampleAt).inMicroseconds / 1000000;
      // Smooth small jitter, but follow deliberate turns with less delay.
      final timeConstant = delta.abs() > 12 ? 0.06 : 0.14;
      final gain = 1 - math.exp(-elapsed.clamp(0.001, 1.0) / timeConstant);
      _heading = (previous + delta * gain) % 360;
    }
    _lastSampleAt = now;
    return (heading: _heading!, reliable: reliable, magneticOnly: magneticOnly);
  }

  static double? _number(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}
