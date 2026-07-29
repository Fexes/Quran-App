import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/divine_name.dart';
import '../../domain/repositories/divine_names_repository.dart';

class LocalDivineNamesRepository implements DivineNamesRepository {
  LocalDivineNamesRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<List<DivineName>>? _cache;

  @override
  Future<List<DivineName>> all() => _cache ??= _load();

  Future<List<DivineName>> _load() async {
    final raw = await _bundle.loadString('assets/data/worship/asma.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final names = [
      for (final item in json['names'] as List? ?? const [])
        DivineName.fromJson(Map<String, dynamic>.from(item as Map)),
    ].where((item) => item.number > 0 && item.arabic.isNotEmpty).toList();
    if (names.length != 99) {
      throw const FormatException('The bundled Names dataset is incomplete.');
    }
    return List.unmodifiable(names);
  }
}
