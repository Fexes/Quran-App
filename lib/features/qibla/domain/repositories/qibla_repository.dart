import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../entities/qibla_direction.dart';

abstract interface class QiblaRepository {
  Future<QiblaDirection> getDirection({PrayerLocation? location});
}
