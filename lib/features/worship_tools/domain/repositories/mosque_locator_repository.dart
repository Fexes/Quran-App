import '../entities/mosque_place.dart';

abstract interface class MosqueLocatorRepository {
  Future<List<MosquePlace>> nearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    bool refresh = false,
  });
}
