class AppRoutes {
  const AppRoutes._();

  static const shell = '/';
  static const onboarding = '/onboarding';
  static const quranReader = '/quran/:surahNumber';
  static const quranSearch = '/quran-search';
  static const quranDownloads = '/quran-downloads';
  static const quranTranslations = '/quran-translations';
  static const quranBookmarks = '/quran-bookmarks';
  static const quranNotes = '/quran-notes';
  static const readingGoals = '/reading-goals';
  static const hifz = '/hifz';
  static const hifzReview = '/hifz/review/:collectionId';
  static const backup = '/backup';
  static const prayerTracking = '/prayer-tracking';
  static const qibla = '/qibla';
  static const fastingJournal = '/fasting-journal';
  static const duas = '/worship-tools/duas';
  static const divineNames = '/worship-tools/names';
  static const zakat = '/worship-tools/zakat';
  static const ramadan = '/worship-tools/ramadan';
  static const achievements = '/worship-tools/achievements';
  static const mosques = '/worship-tools/mosques';
  static const hadithBook = '/library/hadith/:bookId';
  static const azkarCategory = '/library/azkar/:categoryId';
  static const tasbieh = '/tasbieh';

  static String quranReaderPath(
    int surahNumber, {
    int? ayahNumber,
    int? translationResourceId,
  }) {
    if (ayahNumber == null && translationResourceId == null) {
      return '/quran/$surahNumber';
    }
    final parameters = <String, String>{
      if (ayahNumber != null) 'ayah': '$ayahNumber',
      if (translationResourceId != null)
        'translation': '$translationResourceId',
    };
    return Uri(
      path: '/quran/$surahNumber',
      queryParameters: parameters,
    ).toString();
  }

  static String onboardingPath({bool edit = false}) {
    return edit ? '$onboarding?edit=true' : onboarding;
  }

  static String quranSearchPath([String? query]) {
    final normalized = query?.trim();
    if (normalized == null || normalized.isEmpty) {
      return quranSearch;
    }
    return '$quranSearch?query=${Uri.encodeQueryComponent(normalized)}';
  }

  static String quranDownloadsPath({bool showTranslations = false}) {
    return showTranslations
        ? '$quranDownloads?type=translation'
        : quranDownloads;
  }

  static String quranTranslationsPath() => quranTranslations;

  static String quranBookmarksPath() => quranBookmarks;

  static String quranNotesPath({String? noteId}) {
    final normalized = noteId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return quranNotes;
    }
    return '$quranNotes?note=${Uri.encodeQueryComponent(normalized)}';
  }

  static String readingGoalsPath() => readingGoals;

  static String hifzPath() => hifz;

  static String hifzReviewPath(String collectionId) {
    return '/hifz/review/${Uri.encodeComponent(collectionId)}';
  }

  static String backupPath() => backup;

  static String prayerTrackingPath() => prayerTracking;

  static String qiblaPath() => qibla;

  static String fastingJournalPath() => fastingJournal;

  static String duasPath() => duas;

  static String divineNamesPath() => divineNames;

  static String zakatPath() => zakat;

  static String ramadanPath() => ramadan;

  static String achievementsPath() => achievements;

  static String mosquesPath() => mosques;

  static String hadithBookPath(String bookId, {String? hadithNumber}) {
    final encoded = Uri.encodeComponent(bookId);
    final normalized = hadithNumber?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/library/hadith/$encoded';
    }
    return '/library/hadith/$encoded?hadith=${Uri.encodeQueryComponent(normalized)}';
  }

  static String azkarCategoryPath(String categoryId, {String? itemId}) {
    final encoded = Uri.encodeComponent(categoryId);
    final normalized = itemId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '/library/azkar/$encoded';
    }
    return '/library/azkar/$encoded?item=${Uri.encodeQueryComponent(normalized)}';
  }

  static String tasbiehPath() => tasbieh;
}
