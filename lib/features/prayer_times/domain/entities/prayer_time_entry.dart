import 'package:equatable/equatable.dart';

enum PrayerTimeName { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerTimeEntry extends Equatable {
  const PrayerTimeEntry({required this.name, required this.time});

  final PrayerTimeName name;
  final DateTime time;

  bool get isFridayDhuhr {
    return name == PrayerTimeName.dhuhr && time.weekday == DateTime.friday;
  }

  String get displayName {
    if (isFridayDhuhr) {
      return 'Jummah';
    }
    return switch (name) {
      PrayerTimeName.fajr => 'Fajr',
      PrayerTimeName.sunrise => 'Sunrise',
      PrayerTimeName.dhuhr => 'Dhuhr',
      PrayerTimeName.asr => 'Asr',
      PrayerTimeName.maghrib => 'Maghrib',
      PrayerTimeName.isha => 'Isha',
    };
  }

  @override
  List<Object> get props => [name, time];
}
