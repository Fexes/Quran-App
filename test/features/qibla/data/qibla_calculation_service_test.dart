import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/qibla/data/services/qibla_calculation_service.dart';

void main() {
  group('QiblaCalculationService', () {
    test('calculates bearing from Karachi to the Kaaba', () {
      const service = QiblaCalculationService();

      final direction = service.calculate(
        const PrayerLocation(
          name: 'Karachi',
          latitude: 24.8607,
          longitude: 67.0011,
        ),
      );

      expect(direction.bearingDegrees, closeTo(267.7, 1.0));
      expect(direction.cardinalDirection, 'W');
    });
  });
}
