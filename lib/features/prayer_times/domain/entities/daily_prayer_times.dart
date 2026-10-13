import 'package:equatable/equatable.dart';

import 'prayer_calculation_settings.dart';
import 'prayer_location.dart';
import 'prayer_time_entry.dart';

class DailyPrayerTimes extends Equatable {
  const DailyPrayerTimes({
    required this.date,
    required this.location,
    required this.settings,
    required this.entries,
    required this.nextPrayer,
    this.nextDayFajr,
  });

  final DateTime date;
  final PrayerLocation location;
  final PrayerCalculationSettings settings;
  final List<PrayerTimeEntry> entries;
  final PrayerTimeEntry nextPrayer;
  final PrayerTimeEntry? nextDayFajr;

  @override
  List<Object?> get props => [
    date,
    location,
    settings,
    entries,
    nextPrayer,
    nextDayFajr,
  ];
}
