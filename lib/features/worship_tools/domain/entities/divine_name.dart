import 'package:equatable/equatable.dart';

class DivineName extends Equatable {
  const DivineName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.references,
  });

  factory DivineName.fromJson(Map<String, dynamic> json) {
    return DivineName(
      number: json['number'] as int? ?? 0,
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      references: (json['references'] as List? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;
  final List<String> references;

  @override
  List<Object> get props => [
    number,
    arabic,
    transliteration,
    meaning,
    references,
  ];
}
