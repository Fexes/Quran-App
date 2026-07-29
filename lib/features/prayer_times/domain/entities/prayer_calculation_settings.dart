import 'package:equatable/equatable.dart';

enum PrayerCalculationMethod { karachi, muslimWorldLeague, ummAlQura }

enum PrayerAsrMadhab { shafi, hanafi }

class PrayerCalculationSettings extends Equatable {
  const PrayerCalculationSettings({
    required this.method,
    required this.asrMadhab,
  });

  const PrayerCalculationSettings.karachi()
    : method = PrayerCalculationMethod.karachi,
      asrMadhab = PrayerAsrMadhab.hanafi;

  final PrayerCalculationMethod method;
  final PrayerAsrMadhab asrMadhab;

  @override
  List<Object> get props => [method, asrMadhab];
}
