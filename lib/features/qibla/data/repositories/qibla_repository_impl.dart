import '../../../../core/storage/settings_store.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../domain/entities/qibla_direction.dart';
import '../../domain/repositories/qibla_repository.dart';
import '../services/qibla_calculation_service.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  const QiblaRepositoryImpl({
    required QiblaCalculationService calculationService,
    required SettingsStore settingsStore,
  }) : _calculationService = calculationService,
       _settingsStore = settingsStore;

  final QiblaCalculationService _calculationService;
  final SettingsStore _settingsStore;

  @override
  Future<QiblaDirection> getDirection({PrayerLocation? location}) async {
    return _calculationService.calculate(location ?? _savedLocation());
  }

  PrayerLocation _savedLocation() {
    return PrayerLocation(
      name: _settingsStore.prayerLocationName,
      latitude: _settingsStore.prayerLatitude,
      longitude: _settingsStore.prayerLongitude,
      timeZone: _settingsStore.prayerTimeZone,
    );
  }
}
