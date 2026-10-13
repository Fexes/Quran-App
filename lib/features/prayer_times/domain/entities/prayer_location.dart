import 'package:equatable/equatable.dart';

class PrayerLocation extends Equatable {
  const PrayerLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.timeZone = 'Asia/Karachi',
    this.usesDeviceLocation = false,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String timeZone;
  final bool usesDeviceLocation;

  @override
  List<Object> get props => [
    name,
    latitude,
    longitude,
    timeZone,
    usesDeviceLocation,
  ];
}
