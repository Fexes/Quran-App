import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/qibla/data/repositories/qibla_repository_impl.dart';
import 'package:quran/features/qibla/data/services/qibla_calculation_service.dart';

void main() {
  group('QiblaRepositoryImpl', () {
    test('uses saved prayer location by default', () async {
      final repository = QiblaRepositoryImpl(
        calculationService: const QiblaCalculationService(),
        settingsStore: SettingsStore.memory({
          'prayer_location_name': 'Lahore',
          'prayer_latitude': 31.5204,
          'prayer_longitude': 74.3587,
        }),
      );

      final direction = await repository.getDirection();

      expect(direction.location.name, 'Lahore');
      expect(direction.bearingDegrees, inInclusiveRange(0, 360));
    });
  });
}
