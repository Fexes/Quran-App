import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../domain/entities/prayer_time_entry.dart';

enum PrayerTimeImageVariant { prayer, sunset }

class PrayerTimeImage extends StatelessWidget {
  const PrayerTimeImage({
    required this.name,
    required this.size,
    this.monochrome = false,
    this.fallbackColor,
    this.semanticLabel,
    this.variant = PrayerTimeImageVariant.prayer,
    super.key,
  });

  final PrayerTimeName name;
  final double size;
  final bool monochrome;
  final Color? fallbackColor;
  final String? semanticLabel;
  final PrayerTimeImageVariant variant;

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPathFor(
      name,
      monochrome: monochrome,
      variant: variant,
    );
    final effectiveSemanticLabel = semanticLabel ?? '${_labelFor(name)} prayer';
    return Semantics(
      image: true,
      label: effectiveSemanticLabel,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: Transform.scale(
            scale: _assetScaleFor(
              name,
              monochrome: monochrome,
              variant: variant,
            ),
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: 384,
              cacheHeight: 384,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => AppIcon(
                _fallbackIconFor(name),
                color: fallbackColor,
                size: size * 0.72,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _labelFor(PrayerTimeName name) {
  return switch (name) {
    PrayerTimeName.fajr => 'Fajr',
    PrayerTimeName.sunrise => 'Sunrise',
    PrayerTimeName.dhuhr => 'Dhuhr',
    PrayerTimeName.asr => 'Asr',
    PrayerTimeName.maghrib => 'Maghrib',
    PrayerTimeName.isha => 'Isha',
  };
}

String _assetPathFor(
  PrayerTimeName name, {
  required bool monochrome,
  required PrayerTimeImageVariant variant,
}) {
  final fileName = variant == PrayerTimeImageVariant.sunset
      ? 'sunset'
      : switch (name) {
          PrayerTimeName.fajr => 'fajar',
          PrayerTimeName.sunrise => 'sunrise_v2',
          PrayerTimeName.dhuhr => 'dhuhr',
          PrayerTimeName.asr => 'asr',
          PrayerTimeName.maghrib => 'maghrib_twilight',
          PrayerTimeName.isha => 'isha',
        };
  final suffix = monochrome ? '_bw' : '';
  return 'assets/images/prayers/$fileName$suffix.png';
}

double _assetScaleFor(
  PrayerTimeName name, {
  required bool monochrome,
  required PrayerTimeImageVariant variant,
}) {
  if (variant == PrayerTimeImageVariant.sunset) {
    return 1.12;
  }
  return switch ((name, monochrome)) {
    (PrayerTimeName.fajr, false) => 1.14,
    (PrayerTimeName.fajr, true) => 1.42,
    (PrayerTimeName.sunrise, _) => 1.07,
    (PrayerTimeName.dhuhr, false) => 1.20,
    (PrayerTimeName.dhuhr, true) => 1.18,
    (PrayerTimeName.asr, _) => 1.34,
    (PrayerTimeName.maghrib, _) => 1.07,
    (PrayerTimeName.isha, false) => 1.36,
    (PrayerTimeName.isha, true) => 1.38,
  };
}

IconData _fallbackIconFor(PrayerTimeName name) {
  return switch (name) {
    PrayerTimeName.fajr || PrayerTimeName.sunrise => Icons.wb_twilight_rounded,
    PrayerTimeName.dhuhr || PrayerTimeName.asr => Icons.wb_sunny_rounded,
    PrayerTimeName.maghrib => Icons.wb_twilight_rounded,
    PrayerTimeName.isha => Icons.bedtime_rounded,
  };
}
