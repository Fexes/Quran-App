import 'prayer_time_entry.dart';

enum PrayerBannerPhase {
  fajr,
  sunrise,
  dhuhr,
  asr,
  sunset,
  maghrib,
  isha;

  String get assetPath => 'assets/images/prayer_banners/$name.jpg';

  static PrayerBannerPhase at({
    required List<PrayerTimeEntry> entries,
    required DateTime now,
  }) {
    PrayerTimeEntry? current;
    DateTime? maghribTime;
    for (final entry in entries) {
      if (entry.name == PrayerTimeName.maghrib) maghribTime = entry.time;
      if (!entry.time.isAfter(now) &&
          (current == null || entry.time.isAfter(current.time))) {
        current = entry;
      }
    }

    // The sunset artwork window is visual only; prayer times stay unchanged.
    if (current?.name == PrayerTimeName.asr &&
        maghribTime != null &&
        now.isBefore(maghribTime) &&
        !now.isBefore(maghribTime.subtract(const Duration(minutes: 20)))) {
      return sunset;
    }

    return switch (current?.name) {
      PrayerTimeName.fajr => fajr,
      PrayerTimeName.sunrise => sunrise,
      PrayerTimeName.dhuhr => dhuhr,
      PrayerTimeName.asr => asr,
      PrayerTimeName.maghrib => maghrib,
      PrayerTimeName.isha || null => isha,
    };
  }
}
