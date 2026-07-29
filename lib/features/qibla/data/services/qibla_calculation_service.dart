import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../domain/entities/qibla_direction.dart';

class QiblaCalculationService {
  const QiblaCalculationService();

  QiblaDirection calculate(PrayerLocation location) {
    final bearing = adhan.Qibla.qibla(
      adhan.Coordinates(location.latitude, location.longitude),
    );
    return QiblaDirection(
      location: location,
      bearingDegrees: _normalize(bearing),
    );
  }

  double _normalize(double degrees) {
    final normalized = degrees % 360;
    if (normalized < 0) {
      return normalized + 360;
    }
    return normalized;
  }
}
