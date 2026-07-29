import 'package:equatable/equatable.dart';

class MosquePlace extends Equatable {
  const MosquePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'distanceMeters': distanceMeters,
  };

  factory MosquePlace.fromJson(Map<dynamic, dynamic> json) {
    return MosquePlace(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Mosque',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object> get props => [id, name, latitude, longitude, distanceMeters];
}
