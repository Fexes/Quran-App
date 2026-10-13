import '../../../../core/storage/settings_store.dart';
import '../../../prayer/data/services/prayer_location_refresh_service.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../domain/entities/qibla_direction.dart';
import '../../domain/repositories/qibla_repository.dart';
import '../services/qibla_calculation_service.dart';

class QiblaRepositoryImpl implements QiblaRepository {
  const QiblaRepositoryImpl({
    required QiblaCalculationService calculationService,
    required SettingsStore settingsStore,
    PrayerLocationRefreshService? locationRefreshService,
  }) : _calculationService = calculationService,
       _settingsStore = settingsStore,
       _locationRefreshService = locationRefreshService;

  final QiblaCalculationService _calculationService;
  final SettingsStore _settingsStore;
  final PrayerLocationRefreshService? _locationRefreshService;

  @override
  Future<QiblaDirection> getDirection({PrayerLocation? location}) async {
    if (location == null) await _locationRefreshService?.refresh();
    return _calculationService.calculate(location ?? _savedLocation());
  }

  PrayerLocation _savedLocation() {
    return PrayerLocation(
      name: _settingsStore.prayerLocationName,
      latitude: _settingsStore.prayerLatitude,
      longitude: _settingsStore.prayerLongitude,
      timeZone: _settingsStore.prayerTimeZone,
      usesDeviceLocation: _settingsStore.prayerLocationUsesDevice,
    );
  }
}
