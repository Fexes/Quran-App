import 'package:equatable/equatable.dart';

import '../../../prayer_times/domain/entities/prayer_time_entry.dart';

class PrayerAlertSettings extends Equatable {
  const PrayerAlertSettings({
    required this.enabledPrayerNames,
    required this.notifyAtPrayerTime,
    required this.notifyBeforePrayer,
    required this.beforeMinutes,
    required this.includeSunrise,
  });

  factory PrayerAlertSettings.disabled() {
    return const PrayerAlertSettings(
      enabledPrayerNames: <PrayerTimeName>{},
      notifyAtPrayerTime: true,
      notifyBeforePrayer: false,
      beforeMinutes: 10,
      includeSunrise: false,
    );
  }

  factory PrayerAlertSettings.fromStored({
    required List<String> enabledPrayerNames,
    required bool notifyAtPrayerTime,
    required bool notifyBeforePrayer,
    required int beforeMinutes,
    required bool includeSunrise,
  }) {
    return PrayerAlertSettings(
      enabledPrayerNames: {
        for (final name in enabledPrayerNames)
          for (final prayer in PrayerTimeName.values)
            if (prayer.name == name) prayer,
      },
      notifyAtPrayerTime: notifyAtPrayerTime,
      notifyBeforePrayer: notifyBeforePrayer,
      beforeMinutes: beforeMinutes,
      includeSunrise: includeSunrise,
    );
  }

  static const corePrayerNames = <PrayerTimeName>{
    PrayerTimeName.fajr,
    PrayerTimeName.dhuhr,
    PrayerTimeName.asr,
    PrayerTimeName.maghrib,
    PrayerTimeName.isha,
  };

  final Set<PrayerTimeName> enabledPrayerNames;
  final bool notifyAtPrayerTime;
  final bool notifyBeforePrayer;
  final int beforeMinutes;
  final bool includeSunrise;

  bool get schedulesAnything {
    return (notifyAtPrayerTime || notifyBeforePrayer) &&
        PrayerTimeName.values.any(isEnabledFor);
  }

  bool get allCorePrayersEnabled {
    return corePrayerNames.every(enabledPrayerNames.contains);
  }

  int get activePrayerCount {
    return PrayerTimeName.values.where(isEnabledFor).length;
  }

  bool isEnabledFor(PrayerTimeName name) {
    if (name == PrayerTimeName.sunrise && !includeSunrise) {
      return false;
    }
    return enabledPrayerNames.contains(name);
  }

  PrayerAlertSettings copyWith({
    Set<PrayerTimeName>? enabledPrayerNames,
    bool? notifyAtPrayerTime,
    bool? notifyBeforePrayer,
    int? beforeMinutes,
    bool? includeSunrise,
  }) {
    return PrayerAlertSettings(
      enabledPrayerNames: enabledPrayerNames ?? this.enabledPrayerNames,
      notifyAtPrayerTime: notifyAtPrayerTime ?? this.notifyAtPrayerTime,
      notifyBeforePrayer: notifyBeforePrayer ?? this.notifyBeforePrayer,
      beforeMinutes: beforeMinutes ?? this.beforeMinutes,
      includeSunrise: includeSunrise ?? this.includeSunrise,
    );
  }

  PrayerAlertSettings withPrayer(PrayerTimeName name, bool enabled) {
    final next = {...enabledPrayerNames};
    if (enabled) {
      next.add(name);
    } else {
      next.remove(name);
    }
    return copyWith(
      enabledPrayerNames: next,
      includeSunrise: name == PrayerTimeName.sunrise && enabled
          ? true
          : includeSunrise,
    );
  }

  PrayerAlertSettings withAllCorePrayers(bool enabled) {
    final next = {...enabledPrayerNames};
    if (enabled) {
      next.addAll(corePrayerNames);
    } else {
      next.removeAll(PrayerTimeName.values);
    }
    return copyWith(enabledPrayerNames: next, includeSunrise: false);
  }

  List<String> toStoredPrayerNames() {
    final names = enabledPrayerNames.map((name) => name.name).toList();
    names.sort();
    return names;
  }

  @override
  List<Object> get props => [
    enabledPrayerNames,
    notifyAtPrayerTime,
    notifyBeforePrayer,
    beforeMinutes,
    includeSunrise,
  ];
}
