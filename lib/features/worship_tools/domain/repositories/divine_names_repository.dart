import '../entities/divine_name.dart';

abstract interface class DivineNamesRepository {
  Future<List<DivineName>> all();
}
