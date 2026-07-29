import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/entities/quran_translation.dart';

class DailyAyah extends Equatable {
  const DailyAyah({
    required this.date,
    required this.ayah,
    required this.surah,
    required this.translation,
    this.translationResource,
  });

  final DateTime date;
  final QuranAyah ayah;
  final QuranSurah surah;
  final String translation;
  final QuranTranslationResource? translationResource;

  String get reference => '${surah.englishName} (${ayah.verseKey})';

  bool isForDate(DateTime value) {
    return date.year == value.year &&
        date.month == value.month &&
        date.day == value.day;
  }

  String get shareText {
    final source = translationResource;
    final translationCredit = source == null
        ? ''
        : '\n${source.name}${source.authorName.isEmpty ? '' : ' • ${source.authorName}'}';
    return '${ayah.text}\n\n$translation\n\n$reference$translationCredit';
  }

  @override
  List<Object?> get props => [
    date,
    ayah,
    surah,
    translation,
    translationResource,
  ];
}
