import 'prayer_time_entry.dart';

class PrayerDayProgress {
  const PrayerDayProgress({
    required this.progress,
    required this.nextPrayer,
    required this.remaining,
    double? arcProgress,
    this.phasePrayer,
    this.currentPrayer,
  }) : arcProgress = arcProgress ?? progress;

  final double progress;
  final double arcProgress;
  final PrayerTimeEntry nextPrayer;
  final PrayerTimeEntry? phasePrayer;
  final PrayerTimeEntry? currentPrayer;
  final Duration remaining;

  String get remainingLabel {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours <= 0) {
      return '${minutes}m remaining';
    }
    return '${hours}h ${minutes}m remaining';
  }

  static PrayerDayProgress calculate({
    required List<PrayerTimeEntry> entries,
    required DateTime now,
  }) {
    final coreEntries = entries
        .where((entry) => entry.name != PrayerTimeName.sunrise)
        .toList(growable: false);
    if (coreEntries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'No prayer times provided');
    }

    final first = coreEntries.first;
    final last = coreEntries.last;
    final nextPrayer = _nextPrayer(coreEntries, now);
    final activePrayer = _activePrayer(coreEntries, now);
    final currentPrayer = _currentPrayer(entries, now);
    final progress = _progressBetween(first.time, last.time, now);
    final arcProgress = _prayerSlotProgress(coreEntries, now);
    var remaining = nextPrayer.time.difference(now);
    if (!remaining.isNegative && remaining != Duration.zero) {
      return PrayerDayProgress(
        progress: progress,
        arcProgress: arcProgress,
        nextPrayer: nextPrayer,
        phasePrayer: activePrayer ?? nextPrayer,
        currentPrayer: currentPrayer,
        remaining: remaining,
      );
    }
    remaining += const Duration(days: 1);
    return PrayerDayProgress(
      progress: progress,
      arcProgress: arcProgress,
      nextPrayer: nextPrayer,
      phasePrayer: activePrayer ?? nextPrayer,
      currentPrayer: currentPrayer,
      remaining: remaining,
    );
  }

  static PrayerTimeEntry _nextPrayer(
    List<PrayerTimeEntry> entries,
    DateTime now,
  ) {
    for (final entry in entries) {
      if (entry.time.isAfter(now)) {
        return entry;
      }
    }
    return entries.first;
  }

  static PrayerTimeEntry? _activePrayer(
    List<PrayerTimeEntry> entries,
    DateTime now,
  ) {
    PrayerTimeEntry? active;
    for (final entry in entries) {
      if (entry.time.isAfter(now)) {
        break;
      }
      active = entry;
    }
    return active;
  }

  static PrayerTimeEntry? _currentPrayer(
    List<PrayerTimeEntry> entries,
    DateTime now,
  ) {
    PrayerTimeEntry? fajr;
    PrayerTimeEntry? sunrise;
    final laterPrayers = <PrayerTimeEntry>[];
    for (final entry in entries) {
      switch (entry.name) {
        case PrayerTimeName.fajr:
          fajr = entry;
        case PrayerTimeName.sunrise:
          sunrise = entry;
        case PrayerTimeName.dhuhr ||
            PrayerTimeName.asr ||
            PrayerTimeName.maghrib ||
            PrayerTimeName.isha:
          laterPrayers.add(entry);
      }
    }
    if (fajr != null &&
        sunrise != null &&
        !now.isBefore(fajr.time) &&
        now.isBefore(sunrise.time)) {
      return fajr;
    }
    PrayerTimeEntry? current;
    for (final entry in laterPrayers) {
      if (entry.time.isAfter(now)) {
        break;
      }
      current = entry;
    }
    return current;
  }

  static double _progressBetween(DateTime start, DateTime end, DateTime now) {
    if (!now.isAfter(start)) {
      return 0;
    }
    if (!now.isBefore(end)) {
      return 1;
    }
    final total = end.difference(start).inMilliseconds;
    if (total <= 0) {
      return 0;
    }
    final elapsed = now.difference(start).inMilliseconds;
    return (elapsed / total).clamp(0, 1).toDouble();
  }

  static double _prayerSlotProgress(
    List<PrayerTimeEntry> prayers,
    DateTime now,
  ) {
    if (prayers.length < 2 || !now.isAfter(prayers.first.time)) {
      return 0;
    }
    if (!now.isBefore(prayers.last.time)) {
      return 1;
    }
    final segmentCount = prayers.length - 1;
    for (var index = 0; index < segmentCount; index++) {
      final start = prayers[index].time;
      final end = prayers[index + 1].time;
      if (now.isAfter(end)) {
        continue;
      }
      final duration = end.difference(start).inMilliseconds;
      final elapsed = now.difference(start).inMilliseconds;
      final segmentProgress = duration <= 0
          ? 0.0
          : (elapsed / duration).clamp(0.0, 1.0);
      return ((index + segmentProgress) / segmentCount).clamp(0.0, 1.0);
    }
    return 1;
  }
}
