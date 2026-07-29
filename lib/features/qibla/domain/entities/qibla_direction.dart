import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_location.dart';

class QiblaDirection extends Equatable {
  const QiblaDirection({required this.location, required this.bearingDegrees});

  final PrayerLocation location;
  final double bearingDegrees;

  String get cardinalDirection {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearingDegrees + 22.5) ~/ 45) % labels.length;
    return labels[index];
  }

  @override
  List<Object> get props => [location, bearingDegrees];
}
