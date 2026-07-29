import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:timezone/data/latest_10y.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_calculation_settings.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_time_entry.dart';

class AdhanPrayerCalculationService {
  const AdhanPrayerCalculationService();

  static var _timeZonesInitialized = false;

  DailyPrayerTimes calculate({
    required DateTime date,
    required PrayerLocation location,
    required PrayerCalculationSettings settings,
    DateTime? now,
  }) {
    final parameters = _parameters(settings);
    final timeZone = _timeZone(location.timeZone);
    final locationDate = tz.TZDateTime.from(date, timeZone);
    final prayerTimes = adhan.PrayerTimes(
      date: tz.TZDateTime(
        timeZone,
        locationDate.year,
        locationDate.month,
        locationDate.day,
      ),
      coordinates: adhan.Coordinates(location.latitude, location.longitude),
      calculationParameters: parameters,
    );
    final entries = [
      PrayerTimeEntry(
        name: PrayerTimeName.fajr,
        time: tz.TZDateTime.from(prayerTimes.fajr, timeZone),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.sunrise,
        time: tz.TZDateTime.from(prayerTimes.sunrise, timeZone),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.dhuhr,
        time: tz.TZDateTime.from(prayerTimes.dhuhr, timeZone),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.asr,
        time: tz.TZDateTime.from(prayerTimes.asr, timeZone),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.maghrib,
        time: tz.TZDateTime.from(prayerTimes.maghrib, timeZone),
      ),
      PrayerTimeEntry(
        name: PrayerTimeName.isha,
        time: tz.TZDateTime.from(prayerTimes.isha, timeZone),
      ),
    ];
    return DailyPrayerTimes(
      date: date,
      location: location,
      settings: settings,
      entries: entries,
      nextPrayer: _nextPrayer(entries, now ?? DateTime.now()),
    );
  }

  adhan.CalculationParameters _parameters(PrayerCalculationSettings settings) {
    final parameters = switch (settings.method) {
      PrayerCalculationMethod.karachi =>
        adhan.CalculationMethodParameters.karachi(),
      PrayerCalculationMethod.muslimWorldLeague =>
        adhan.CalculationMethodParameters.muslimWorldLeague(),
      PrayerCalculationMethod.ummAlQura =>
        adhan.CalculationMethodParameters.ummAlQura(),
    };
    parameters.madhab = switch (settings.asrMadhab) {
      PrayerAsrMadhab.shafi => adhan.Madhab.shafi,
      PrayerAsrMadhab.hanafi => adhan.Madhab.hanafi,
    };
    return parameters;
  }

  PrayerTimeEntry _nextPrayer(List<PrayerTimeEntry> entries, DateTime now) {
    for (final entry in entries) {
      if (entry.name == PrayerTimeName.sunrise) {
        continue;
      }
      if (entry.time.isAfter(now)) {
        return entry;
      }
    }
    return entries.firstWhere((entry) => entry.name == PrayerTimeName.fajr);
  }

  tz.Location _timeZone(String timeZone) {
    _ensureTimeZonesInitialized();
    try {
      return tz.getLocation(timeZone);
    } catch (_) {
      return tz.getLocation('Etc/UTC');
    }
  }

  void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) {
      return;
    }
    timezone_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
}
