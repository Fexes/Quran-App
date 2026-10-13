import 'package:flutter/foundation.dart';

import '../../../azkar/domain/entities/dhikr_item.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/entities/hadith_item.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../hadith/domain/services/hadith_authenticity_policy.dart';
import '../../../library/domain/library_translation_language_mapper.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';

typedef DailyHadith = ({
  HadithItem item,
  LibraryLanguageSelection language,
  bool translationAvailable,
});

typedef DailyDua = ({
  DhikrItem item,
  LibraryLanguageSelection language,
  bool translationAvailable,
});

class DailyLibraryContentService {
  const DailyLibraryContentService({
    required this.hadithRepository,
    required this.azkarRepository,
    required this.translationRepository,
    this.azkarLanguageCode,
  });

  final HadithRepository hadithRepository;
  final AzkarRepository azkarRepository;
  final QuranTranslationRepository translationRepository;
  final String? azkarLanguageCode;

  Future<DailyHadith?> loadHadith(DateTime date) async {
    final shared = await _language();
    final code = shared.resource?.resolvedLanguageCode ?? shared.hadithCode;
    if (code == null || code.isEmpty) return null;
    final language = LibraryLanguageSelection(
      label: shared.label,
      hadithCode: code,
      azkarCode: shared.azkarCode,
      resource: shared.resource,
    );
    final books = [...await hadithRepository.getBooks()]
      ..sort(
        (a, b) => a.id == b.id
            ? 0
            : a.id == 'bukhari'
            ? -1
            : b.id == 'bukhari'
            ? 1
            : a.sortOrder.compareTo(b.sortOrder),
      );
    for (final book in books) {
      if (!await hadithRepository.hasDownloadedTranslation(book.id, code)) {
        continue;
      }
      final items = await hadithRepository.getHadiths(
        bookId: book.id,
        languageCode: code,
        limit: 100000,
      );
      final translated = await compute(_translatedDailyHadiths, items);
      if (translated.isNotEmpty) {
        return (
          item: translated[_dayIndex(date, translated.length)],
          language: language,
          translationAvailable: true,
        );
      }
    }
    if (await hadithRepository.hasHadeethEncLanguage(code)) {
      final items = await hadithRepository.getHadeethEncItems(
        languageCode: code,
        limit: 100000,
      );
      final translated = await compute(
        _translatedDailyHadiths,
        items.map((item) => item.toHadithItem()).toList(growable: false),
      );
      if (translated.isNotEmpty) {
        return (
          item: translated[_dayIndex(date, translated.length)],
          language: language,
          translationAvailable: true,
        );
      }
    }
    return null;
  }

  static bool _eligibleDailyHadith(HadithItem item) =>
      item.arabic.trim().isNotEmpty &&
      item.translation.trim().isNotEmpty &&
      HadithAuthenticityPolicy.shouldShow(item);

  static List<HadithItem> _translatedDailyHadiths(List<HadithItem> items) =>
      items.where(_eligibleDailyHadith).toList(growable: false);

  Future<DailyDua> loadDua(DateTime date) async {
    final shared = await _language();
    final language = azkarLanguageCode == null
        ? shared
        : libraryLanguageFromCode(
            azkarLanguageCode!,
            resource: shared.azkarCode == azkarLanguageCode
                ? shared.resource
                : null,
          );
    final items = await azkarRepository.getDhikr(
      categoryId: 'joy-and-distress',
      languageCode: language.azkarCode ?? 'ar',
    );
    const dailyDuaIds = {
      'azkar:joy-and-distress:140',
      'azkar:joy-and-distress:141',
      'azkar:joy-and-distress:142',
      'azkar:joy-and-distress:143',
      'azkar:joy-and-distress:144',
      'azkar:joy-and-distress:145',
      'azkar:joy-and-distress:156',
      'azkar:joy-and-distress:157',
      'azkar:joy-and-distress:174',
      'azkar:joy-and-distress:223',
    };
    final duas = items
        .where(
          (item) =>
              dailyDuaIds.contains(item.id) &&
              item.arabic.trim().isNotEmpty &&
              item.translation.trim().isNotEmpty &&
              item.reference.trim().isNotEmpty &&
              item.repeatCount > 0,
        )
        .toList(growable: false);
    if (duas.isEmpty) {
      throw StateError('The daily dua collection is unavailable.');
    }
    final item = duas[_dayIndex(date, duas.length)];
    final code = language.azkarCode;
    return (
      item: item,
      language: language,
      translationAvailable: code != null && item.translation.trim().isNotEmpty,
    );
  }

  Future<LibraryLanguageSelection> _language() async {
    final resource = await translationRepository.selectedTranslation();
    return libraryLanguageFromQuranTranslation(resource);
  }

  static int _dayIndex(DateTime date, int length) {
    final day =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return (day * 7919 + 104729) % length;
  }
}
