import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:quran/features/qibla/domain/entities/qibla_direction.dart';
import 'package:quran/features/qibla/domain/repositories/qibla_repository.dart';
import 'package:quran/features/qibla/presentation/bloc/qibla_cubit.dart';
import 'package:quran/features/qibla/presentation/bloc/qibla_state.dart';

void main() {
  group('QiblaCubit', () {
    test('loads qibla direction', () async {
      final cubit = QiblaCubit(repository: _FakeQiblaRepository());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<QiblaState>().having(
            (state) => state.status,
            'status',
            QiblaStatus.loading,
          ),
          isA<QiblaState>()
              .having((state) => state.status, 'status', QiblaStatus.success)
              .having(
                (state) => state.direction?.cardinalDirection,
                'cardinalDirection',
                'W',
              ),
        ]),
      );

      await cubit.load();
      await expectation;
      await cubit.close();
    });
  });
}

class _FakeQiblaRepository implements QiblaRepository {
  @override
  Future<QiblaDirection> getDirection({PrayerLocation? location}) async {
    return const QiblaDirection(
      location: PrayerLocation(
        name: 'Karachi',
        latitude: 24.8607,
        longitude: 67.0011,
      ),
      bearingDegrees: 267.7,
    );
  }
}
