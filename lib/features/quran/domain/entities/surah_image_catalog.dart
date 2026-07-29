class SurahImageCatalog {
  const SurahImageCatalog._();

  static const int firstSurah = 1;
  static const int lastSurah = 114;
  static const String baseUrl = 'http://coreinfinite.tech/quran_cover';

  static int normalize(int surahNumber) {
    return surahNumber.clamp(firstSurah, lastSurah).toInt();
  }

  static String imageUrlFor(int surahNumber) {
    final normalized = normalize(surahNumber);
    return '$baseUrl/cover_$normalized.jpeg';
  }

  @Deprecated('Use imageUrlFor. Surah covers are hosted remotely.')
  static String assetPathFor(int surahNumber) {
    return imageUrlFor(surahNumber);
  }
}
