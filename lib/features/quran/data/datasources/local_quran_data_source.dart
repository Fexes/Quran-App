import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_with_tafsir/quran_with_tafsir.dart' as source;

import '../../../../core/content/content_cache_policy.dart';
import '../../../../core/content/content_source.dart';
import '../../../../core/constants/quran_arabic_script.dart';
import '../../domain/entities/quran_audio_reciter.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_navigation.dart';
import '../../domain/entities/quran_surah.dart';

Map<String, ({String text, List<int> positions})> _decodeIndoPak(
  String source,
) {
  final entries = jsonDecode(source) as Map<String, dynamic>;
  if (entries.length != 6236) {
    throw const FormatException('Incomplete bundled IndoPak Quran');
  }
  return Map.unmodifiable(
    entries.map((key, value) {
      final record = value as Map<String, dynamic>;
      final text = record['text'] as String;
      final positions = List<int>.unmodifiable(record['positions'] as List);
      if (text.trim().isEmpty ||
          positions.length != text.split(RegExp(r'\s+')).length ||
          positions.any((index) => index < 0)) {
        throw FormatException('Invalid IndoPak verse: $key');
      }
      return MapEntry(key, (text: text, positions: positions));
    }),
  );
}

List<String> _decodeQpcHafs(String source) {
  final entries = jsonDecode(source) as List;
  if (entries.length != 6236) {
    throw const FormatException('Incomplete bundled QPC Hafs Quran');
  }
  final result = <String>[];
  for (var index = 0; index < entries.length; index++) {
    final record = entries[index] as List;
    if (record.length != 2 ||
        record[1] != index + 1 ||
        record[0] is! String ||
        (record[0] as String).trim().isEmpty ||
        RegExp(r'[\uFC00-\uFD1D]').hasMatch(record[0] as String)) {
      throw FormatException('Invalid QPC Hafs verse at ${index + 1}');
    }
    result.add(record[0] as String);
  }
  return List.unmodifiable(result);
}

class LocalQuranDataSource {
  LocalQuranDataSource({source.QuranService? service})
    : _service = service ?? source.QuranService.instance;

  final source.QuranService _service;
  List<String> _qpcHafs = const [];
  Future<void>? _qpcHafsLoad;
  Map<String, ({String text, List<int> positions})> _indoPak = const {};
  Future<void>? _indoPakLoad;
  List<source.Ayah>? _cachedAllAyahs;
  Map<int, source.Ayah>? _cachedPageStartAyahs;
  Set<String>? _cachedPageStartKeys;
  Set<String>? _cachedJuzStartKeys;

  Future<void> ensureIndoPakLoaded() => _indoPakLoad ??= _loadIndoPak();

  Future<void> ensureQpcHafsLoaded() => _qpcHafsLoad ??= _loadQpcHafs();

  Future<void> _loadQpcHafs() async {
    try {
      final text = await rootBundle.loadString(
        'assets/data/quran/qpc_hafs.json',
      );
      _qpcHafs = await compute(_decodeQpcHafs, text);
    } catch (_) {
      _qpcHafsLoad = null;
      rethrow;
    }
  }

  Future<void> _loadIndoPak() async {
    try {
      final source = await rootBundle.loadString(
        'assets/data/quran/indopak.json',
      );
      _indoPak = await compute(_decodeIndoPak, source);
    } catch (_) {
      _indoPakLoad = null;
      rethrow;
    }
  }

  static const _manzilByStartKey = <String, int>{
    '1:1': 1,
    '5:1': 2,
    '10:1': 3,
    '17:1': 4,
    '26:1': 5,
    '37:1': 6,
    '50:1': 7,
  };

  List<ContentSource> getContentSources() {
    return const [
      ContentSource(
        id: 'digitalkhatt_indopak',
        name: 'DigitalKhatt IndoPak Quran',
        attribution:
            'Text by DigitalKhatt, distributed by Quran JSON; '
            'font by Amine Anane and Tarteel Inc.',
        description:
            'Bundled IndoPak script aligned to this app\'s Hafs verse keys. '
            'Al-Fatihah verse boundaries are adapted for audio and translation compatibility.',
        url: 'https://github.com/DigitalKhatt/digitalkhatt-js',
        license: 'Text: MIT and CC BY-SA 4.0; font: SIL OFL 1.1',
        licenseUrl: 'https://github.com/risan/quran-json/blob/main/LICENSE.txt',
        kind: ContentKind.quranText,
        provider: 'DigitalKhatt / Quran JSON',
        edition: 'IndoPak; Hafs verse-key adaptation',
        languageCode: 'ar',
        languageName: 'Arabic',
        script: 'Arab',
        textDirection: ContentTextDirection.rtl,
        retrievalMode: ContentRetrievalMode.bundled,
        cachePolicy: ContentCachePolicy.bundled,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'qpc_hafs_uthmani',
        name: 'QPC Hafs text and UthmanicHafs font',
        attribution:
            'Text and font by the King Fahd Glorious Quran Printing Complex, '
            'from the pinned Uthmanic Hafs v2.2 release archived by Nuqayah. '
            'Font distributed unchanged with its original KFGQPC EULA.',
        description:
            'All 6,236 verses bundled locally, with original letters and diacritics. '
            'Technical comparison against Quran Foundation QPC Hafs found only formatting differences.',
        url:
            'https://github.com/nuqayah/qpc-fonts/tree/8a4f39d563ea69c994416a1692827e38156c548d/text-mushafs/UthmanicHafs_V22',
        license:
            'Font: KFGQPC EULA, free use/copy/distribution, no modification or standalone sale; '
            'text redistribution review remains a release requirement',
        kind: ContentKind.quranText,
        provider: 'King Fahd Complex / Nuqayah source archive',
        edition: 'QPC Hafs Uthmani v2.2',
        revision: '8a4f39d563ea69c994416a1692827e38156c548d',
        languageCode: 'ar',
        languageName: 'Arabic',
        script: 'Arab',
        textDirection: ContentTextDirection.rtl,
        publisher: 'King Fahd Complex for the Printing of the Holy Quran',
        retrievalMode: ContentRetrievalMode.bundled,
        cachePolicy: ContentCachePolicy.bundled,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_with_tafsir_saheeh_international',
        name: 'Saheeh International',
        attribution:
            'Saheeh International English translation supplied by quran_with_tafsir via the King Fahd Complex and QuranEnc.',
        description:
            'Bundled English translation. Edition redistribution approval remains a release requirement.',
        url: 'https://pub.dev/packages/quran_with_tafsir',
        license:
            'Package code is MIT; translation redistribution requires separate edition approval',
        kind: ContentKind.quranTranslation,
        provider: 'quran_with_tafsir',
        edition: 'Saheeh International English translation',
        languageCode: 'en',
        languageName: 'English',
        script: 'Latn',
        textDirection: ContentTextDirection.ltr,
        publisher: 'King Fahd Complex and QuranEnc',
        retrievalMode: ContentRetrievalMode.bundled,
        cachePolicy: ContentCachePolicy.bundled,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_with_tafsir_al_muyassar',
        name: 'Tafsir Al-Muyassar',
        attribution:
            'Arabic Tafsir Al-Muyassar supplied by quran_with_tafsir and attributed by that package to the King Fahd Complex.',
        description:
            'Bundled Arabic tafsir. Content redistribution approval remains a release requirement.',
        url: 'https://pub.dev/packages/quran_with_tafsir',
        license:
            'Package code is MIT; tafsir redistribution requires separate review',
        kind: ContentKind.quranTafsir,
        provider: 'quran_with_tafsir',
        edition: 'Arabic Al-Muyassar',
        languageCode: 'ar',
        languageName: 'Arabic',
        script: 'Arab',
        textDirection: ContentTextDirection.rtl,
        publisher: 'King Fahd Complex for the Printing of the Holy Quran',
        retrievalMode: ContentRetrievalMode.bundled,
        cachePolicy: ContentCachePolicy.bundled,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_foundation_translations',
        name: 'Quran Foundation translation resources',
        attribution:
            'Translation catalog and verse responses supplied by Quran Foundation.',
        description:
            'Downloaded translation data is limited to the provider cache window.',
        url: 'https://api-docs.quran.foundation/docs/quickstart/',
        license: 'Provider terms and individual translation rights apply',
        licenseUrl: 'https://api-docs.quran.foundation/legal/developer-terms/',
        kind: ContentKind.quranTranslation,
        provider: 'Quran Foundation',
        retrievalMode: ContentRetrievalMode.downloaded,
        cachePolicy: ContentCachePolicy.quranFoundation,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_foundation_tafsirs',
        name: 'Quran Foundation tafsir resources',
        attribution:
            'Tafsir catalog and verse responses supplied by Quran Foundation.',
        description:
            'Downloaded tafsir data is limited to the provider cache window.',
        url: 'https://api-docs.quran.foundation/docs/quickstart/',
        license: 'Provider terms and individual tafsir rights apply',
        licenseUrl: 'https://api-docs.quran.foundation/legal/developer-terms/',
        kind: ContentKind.quranTafsir,
        provider: 'Quran Foundation',
        retrievalMode: ContentRetrievalMode.downloaded,
        cachePolicy: ContentCachePolicy.quranFoundation,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_foundation_word_data',
        name: 'Quran Foundation interlinear word data',
        attribution:
            'Interlinear word text and meanings supplied by Quran Foundation.',
        description:
            'Downloaded word data is limited to the provider cache window.',
        url: 'https://api-docs.quran.foundation/docs/quickstart/',
        license: 'Quran Foundation developer terms',
        licenseUrl: 'https://api-docs.quran.foundation/legal/developer-terms/',
        kind: ContentKind.quranWordData,
        provider: 'Quran Foundation',
        languageCode: 'en',
        languageName: 'English',
        retrievalMode: ContentRetrievalMode.downloaded,
        cachePolicy: ContentCachePolicy.quranFoundation,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
      ContentSource(
        id: 'quran_foundation_word_timings',
        name: 'Quran Foundation word timings',
        attribution:
            'Verse audio segment timings supplied by Quran Foundation.',
        description:
            'Downloaded timing data is limited to the provider cache window.',
        url: 'https://api-docs.quran.foundation/docs/quickstart/',
        license: 'Quran Foundation developer terms',
        licenseUrl: 'https://api-docs.quran.foundation/legal/developer-terms/',
        kind: ContentKind.quranWordTiming,
        provider: 'Quran Foundation',
        retrievalMode: ContentRetrievalMode.downloaded,
        cachePolicy: ContentCachePolicy.quranFoundation,
        reviewStatus: ContentReviewStatus.reviewRequired,
      ),
    ];
  }

  List<QuranAudioReciter> getAudioReciters() {
    return _audioReciters;
  }

  List<QuranSurah> getSurahs() {
    return _service.getAllSurahs().map(_mapSurahMetadata).toList();
  }

  QuranSurah getSurah(int surahNumber) {
    return _mapSurahMetadata(_service.getSurahMetadata(surahNumber));
  }

  List<QuranAyah> getAyahs(int surahNumber) {
    final arabicAyahs = _service.getVersesBySurah(
      surahNumber,
      language: source.QuranLanguage.arabic,
    );
    final englishAyahs = _service.getVersesBySurah(
      surahNumber,
      language: source.QuranLanguage.english,
    );
    final tafsir = _service.getTafsir(surahNumber);
    final translations = {for (final ayah in englishAyahs) ayah.id: ayah.text};

    return arabicAyahs.map((ayah) {
      return _mapAyah(
        ayah,
        translation: translations[ayah.id] ?? '',
        tafsir: tafsir[ayah.id],
      );
    }).toList();
  }

  List<QuranAyah> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) {
    final normalizedPage = pageNumber.clamp(1, 604).toInt();
    final arabicAyahs = _service.getPage(
      normalizedPage,
      language: source.QuranLanguage.arabic,
    );
    final englishAyahs = includeTranslation
        ? _service.getPage(
            normalizedPage,
            language: source.QuranLanguage.english,
          )
        : const <source.Ayah>[];
    final translations = {
      for (final ayah in englishAyahs) _verseKey(ayah): ayah.text,
    };
    final tafsirBySurah = <int, Map<int, String>>{};

    return arabicAyahs.map((ayah) {
      final tafsir = includeTafsir
          ? tafsirBySurah.putIfAbsent(
              ayah.surahNumber,
              () => _service.getTafsir(ayah.surahNumber),
            )
          : const <int, String>{};
      return _mapAyah(
        ayah,
        translation: translations[_verseKey(ayah)] ?? '',
        tafsir: tafsir[ayah.id],
      );
    }).toList();
  }

  int getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) {
    final page = _service.getPageNumber(surahNumber, ayahNumber);
    return (page ?? 1).clamp(1, 604).toInt();
  }

  List<QuranNavigationPoint> getNavigationPoints(QuranStructureKind kind) {
    return switch (kind) {
      QuranStructureKind.surah => [
        for (final surah in getSurahs())
          _navigationPoint(
            kind: kind,
            index: surah.number,
            label: surah.englishName,
            ayah: _service.getAyah(surah.number, 1),
          ),
      ],
      QuranStructureKind.juz => [
        for (var index = 1; index <= 30; index++)
          _navigationPoint(
            kind: kind,
            index: index,
            label: 'Juz $index',
            ayah: _service.getJuz(index).first,
          ),
      ],
      QuranStructureKind.hizb => [
        for (final ayah in _allArabicAyahs)
          if (_isHizbStart(ayah))
            _navigationPoint(
              kind: kind,
              index:
                  ((_service.getRubIndex(ayah.surahNumber, ayah.id)! - 1) ~/
                      4) +
                  1,
              label:
                  'Hizb ${((_service.getRubIndex(ayah.surahNumber, ayah.id)! - 1) ~/ 4) + 1}',
              ayah: ayah,
            ),
      ],
      QuranStructureKind.rub => [
        for (final ayah in _allArabicAyahs)
          if (_service.getRubIndex(ayah.surahNumber, ayah.id) case final index?)
            _navigationPoint(
              kind: kind,
              index: index,
              label: 'Rub $index',
              ayah: ayah,
            ),
      ],
      QuranStructureKind.page => [
        for (var index = 1; index <= 604; index++)
          _navigationPoint(
            kind: kind,
            index: index,
            label: 'Page $index',
            ayah: _pageStartAyahs[index]!,
          ),
      ],
      QuranStructureKind.sajdah => [
        for (final ayah in _allArabicAyahs)
          if (ayah.isSajda)
            _navigationPoint(
              kind: kind,
              index: _sajdahIndex(ayah),
              label: 'Sajdah ${_sajdahIndex(ayah)}',
              ayah: ayah,
            ),
      ],
      QuranStructureKind.manzil => [
        for (final entry in _manzilByStartKey.entries)
          _navigationPoint(
            kind: kind,
            index: entry.value,
            label: 'Manzil ${entry.value}',
            ayah: _ayahForKey(entry.key),
          ),
      ],
    };
  }

  List<QuranAyah> search(String query, {int limit = 30}) {
    final results = _service.search(
      query,
      limit: limit,
      language: source.QuranLanguage.arabic,
    );

    return results.map((ayah) {
      final english = _service.getAyah(
        ayah.surahNumber,
        ayah.id,
        language: source.QuranLanguage.english,
      );
      final tafsir = _service.getTafsir(ayah.surahNumber);
      return _mapAyah(ayah, translation: english.text, tafsir: tafsir[ayah.id]);
    }).toList();
  }

  QuranSurah _mapSurahMetadata(source.SurahMetadata metadata) {
    return QuranSurah(
      number: metadata.number,
      englishName: metadata.nameEn,
      arabicName: metadata.nameAr,
      ayahCount: metadata.ayahCount,
      revelationType: metadata.revelationType ?? 'Unknown',
    );
  }

  QuranAyah _mapAyah(
    source.Ayah ayah, {
    required String translation,
    String? tafsir,
  }) {
    final verseKey = _verseKey(ayah);
    final globalNumber = _globalAyahNumber(ayah.surahNumber, ayah.id);
    return QuranAyah(
      surahNumber: ayah.surahNumber,
      number: ayah.id,
      text: _qpcHafs.isEmpty
          ? QuranArabicScript.cleanUthmaniText(ayah.text)
          : _qpcHafs[globalNumber - 1],
      translation: translation,
      page: ayah.page,
      juz: ayah.juz,
      isSajda: ayah.isSajda,
      isPageStart: _pageStartKeys.contains(verseKey),
      isJuzStart: _juzStartKeys.contains(verseKey),
      rubIndex: _service.getRubIndex(ayah.surahNumber, ayah.id),
      manzil: _manzilByStartKey[verseKey],
      globalNumber: globalNumber,
      tafsir: tafsir,
      indoPakText: _indoPak[verseKey]?.text,
      indoPakWordPositions: _indoPak[verseKey]?.positions ?? const [],
    );
  }

  int _globalAyahNumber(int surahNumber, int ayahNumber) {
    var total = ayahNumber;
    for (final surah in _service.getAllSurahs()) {
      if (surah.number >= surahNumber) {
        break;
      }
      total += surah.ayahCount;
    }
    return total;
  }

  String _verseKey(source.Ayah ayah) {
    return '${ayah.surahNumber}:${ayah.id}';
  }

  List<source.Ayah> get _allArabicAyahs {
    return _cachedAllAyahs ??= [
      for (var surah = 1; surah <= 114; surah++)
        ..._service.getVersesBySurah(surah),
    ];
  }

  Map<int, source.Ayah> get _pageStartAyahs {
    final cached = _cachedPageStartAyahs;
    if (cached != null) {
      return cached;
    }
    final starts = <int, source.Ayah>{};
    for (final ayah in _allArabicAyahs) {
      starts.putIfAbsent(ayah.page, () => ayah);
    }
    return _cachedPageStartAyahs = starts;
  }

  Set<String> get _pageStartKeys {
    return _cachedPageStartKeys ??= {
      for (final ayah in _pageStartAyahs.values) _verseKey(ayah),
    };
  }

  Set<String> get _juzStartKeys {
    return _cachedJuzStartKeys ??= {
      for (var juz = 1; juz <= 30; juz++)
        if (_service.getJuz(juz).isNotEmpty)
          _verseKey(_service.getJuz(juz).first),
    };
  }

  bool _isHizbStart(source.Ayah ayah) {
    final index = _service.getRubIndex(ayah.surahNumber, ayah.id);
    return index != null && (index - 1) % 4 == 0;
  }

  int _sajdahIndex(source.Ayah target) {
    var index = 0;
    for (final ayah in _allArabicAyahs) {
      if (!ayah.isSajda) {
        continue;
      }
      index++;
      if (ayah.surahNumber == target.surahNumber && ayah.id == target.id) {
        return index;
      }
    }
    return index;
  }

  source.Ayah _ayahForKey(String key) {
    final parts = key.split(':');
    return _service.getAyah(int.parse(parts.first), int.parse(parts.last));
  }

  QuranNavigationPoint _navigationPoint({
    required QuranStructureKind kind,
    required int index,
    required String label,
    required source.Ayah ayah,
  }) {
    return QuranNavigationPoint(
      kind: kind,
      index: index,
      label: label,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.id,
      page: ayah.page,
      juz: ayah.juz,
      rubIndex: _service.getRubIndex(ayah.surahNumber, ayah.id),
    );
  }

  static const _audioReciters = [
    QuranAudioReciter(
      id: 'everyayah:Alafasy_128kbps',
      name: 'Mishary Alafasy',
      arabicName: 'مشاري العفاسي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Alafasy_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 7,
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdul_Basit_Murattal_192kbps',
      name: 'Abdul Basit (Murattal)',
      arabicName: 'عبد الباسط عبد الصمد (مرتل)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdul_Basit_Murattal_192kbps',
      qualityLabel: '192 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 2,
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdul_Basit_Mujawwad_128kbps',
      name: 'Abdul Basit (Mujawwad)',
      arabicName: 'عبد الباسط عبد الصمد (مجود)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdul_Basit_Mujawwad_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 1,
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdurrahmaan_As-Sudais_192kbps',
      name: 'Abdurrahman As-Sudais',
      arabicName: 'عبد الرحمن السديس',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdurrahmaan_As-Sudais_192kbps',
      qualityLabel: '192 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 3,
    ),
    QuranAudioReciter(
      id: 'everyayah:Saood_ash-Shuraym_128kbps',
      name: 'Saood Ash-Shuraym',
      arabicName: 'سعود الشريم',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Saood_ash-Shuraym_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 10,
    ),
    QuranAudioReciter(
      id: 'everyayah:Ghamadi_40kbps',
      name: 'Saad Al-Ghamdi',
      arabicName: 'سعد الغامدي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ghamadi_40kbps',
      qualityLabel: '40 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Husary_128kbps',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Husary_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 6,
    ),
    QuranAudioReciter(
      id: 'everyayah:Husary_128kbps_Mujawwad',
      name: 'Al-Husary (Mujawwad)',
      arabicName: 'محمود خليل الحصري (مجود)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Husary_128kbps_Mujawwad',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Husary_Muallim_128kbps',
      name: 'Mahmoud Khalil Al-Husary (Muallim)',
      arabicName: 'محمود خليل الحصري (معلم)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Husary_Muallim_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 12,
    ),
    QuranAudioReciter(
      id: 'everyayah:Minshawy_Murattal_128kbps',
      name: 'Mohamed Siddiq Al-Minshawi',
      arabicName: 'محمد صديق المنشاوي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Minshawy_Murattal_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 9,
    ),
    QuranAudioReciter(
      id: 'everyayah:Minshawy_Mujawwad_192kbps',
      name: 'Al-Minshawi (Mujawwad)',
      arabicName: 'محمد صديق المنشاوي (مجود)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Minshawy_Mujawwad_192kbps',
      qualityLabel: '192 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 8,
    ),
    QuranAudioReciter(
      id: 'everyayah:MaherAlMuaiqly128kbps',
      name: 'Maher Al-Muaiqly',
      arabicName: 'ماهر المعيقلي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'MaherAlMuaiqly128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abu_Bakr_Ash-Shaatree_128kbps',
      name: 'Abu Bakr Ash-Shatri',
      arabicName: 'أبو بكر الشاطري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abu_Bakr_Ash-Shaatree_128kbps',
      qualityLabel: '128 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 4,
    ),
    QuranAudioReciter(
      id: 'everyayah:Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
      name: 'Ahmed Al-Ajamy',
      arabicName: 'أحمد العجمي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdullaah_3awwaad_Al-Juhaynee_128kbps',
      name: 'Abdullah Awad Al-Juhany',
      arabicName: 'عبدالله عواد الجهني',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdullah_Basfar_192kbps',
      name: 'Abdullah Basfar',
      arabicName: 'عبدالله بصفر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdullah_Basfar_192kbps',
      qualityLabel: '192 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdullah_Matroud_128kbps',
      name: 'Abdullah Matroud',
      arabicName: 'عبدالله مطرود',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdullah_Matroud_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Hudhaify_128kbps',
      name: 'Ali Al-Hudhaify',
      arabicName: 'علي الحذيفي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Hudhaify_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ibrahim_Akhdar_32kbps',
      name: 'Ibrahim Al-Akhdar',
      arabicName: 'إبراهيم الأخضر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ibrahim_Akhdar_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Karim_Mansoori_40kbps',
      name: 'Karim Mansoori',
      arabicName: 'كريم منصوري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Karim_Mansoori_40kbps',
      qualityLabel: '40 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Khaalid_Abdullaah_al-Qahtaanee_192kbps',
      name: 'Khalid Al-Qahtani',
      arabicName: 'خالد القحطاني',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Khaalid_Abdullaah_al-Qahtaanee_192kbps',
      qualityLabel: '192 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Parhizgar_48kbps',
      name: 'Shahriar Parhizgar',
      arabicName: 'شهريار برهيزقار',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Parhizgar_48kbps',
      qualityLabel: '48 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Salaah_AbdulRahman_Bukhatir_128kbps',
      name: 'Salah Bukhatir',
      arabicName: 'صلاح بو خاطر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Salaah_AbdulRahman_Bukhatir_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Salah_Al_Budair_128kbps',
      name: 'Salah Al-Budair',
      arabicName: 'صلاح البدير',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Salah_Al_Budair_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Yasser_Ad-Dussary_128kbps',
      name: 'Yasser Al-Dosari',
      arabicName: 'ياسر الدوسري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Yasser_Ad-Dussary_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Nasser_Alqatami_128kbps',
      name: 'Nasser Al-Qatami',
      arabicName: 'ناصر القطامي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Nasser_Alqatami_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Hani_Rifai_192kbps',
      name: 'Hani Ar-Rifai',
      arabicName: 'هاني الرفاعي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Hani_Rifai_192kbps',
      qualityLabel: '192 kbps',
      timingProvider: QuranAudioTimingProvider.quranFoundation,
      timingRecitationId: 5,
    ),
    QuranAudioReciter(
      id: 'everyayah:Ali_Hajjaj_AlSuesy_128kbps',
      name: 'Ali Hajjaj Al-Suesy',
      arabicName: 'علي حجاج السويسي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ali_Hajjaj_AlSuesy_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ali_Jaber_64kbps',
      name: 'Ali Jaber',
      arabicName: 'علي جابر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ali_Jaber_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Fares_Abbad_64kbps',
      name: 'Fares Abbad',
      arabicName: 'فارس عباد',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Fares_Abbad_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ayman_Sowaid_64kbps',
      name: 'Ayman Sowaid',
      arabicName: 'أيمن سويد',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ayman_Sowaid_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_Jibreel_128kbps',
      name: 'Muhammad Jibreel',
      arabicName: 'محمد جبريل',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_Jibreel_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhsin_Al_Qasim_192kbps',
      name: 'Muhsin Al-Qasim',
      arabicName: 'محسن القاسم',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhsin_Al_Qasim_192kbps',
      qualityLabel: '192 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Mustafa_Ismail_48kbps',
      name: 'Mustafa Ismail',
      arabicName: 'مصطفى إسماعيل',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Mustafa_Ismail_48kbps',
      qualityLabel: '48 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Nabil_Rifa3i_48kbps',
      name: 'Nabil Ar-Rifai',
      arabicName: 'نبيل الرفاعي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Nabil_Rifa3i_48kbps',
      qualityLabel: '48 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Sahl_Yassin_128kbps',
      name: 'Sahl Yassin',
      arabicName: 'سهل ياسين',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Sahl_Yassin_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Yaser_Salamah_128kbps',
      name: 'Yaser Salamah',
      arabicName: 'ياسر سلامة',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Yaser_Salamah_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Akram_AlAlaqimy_128kbps',
      name: 'Akram Al-Alaqimy',
      arabicName: 'أكرم العلاقمي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Akram_AlAlaqimy_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ahmed_Neana_128kbps',
      name: 'Ahmed Neana',
      arabicName: 'أحمد نعينع',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ahmed_Neana_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_Ayyoub_128kbps',
      name: 'Muhammad Ayyoub',
      arabicName: 'محمد أيوب',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_Ayyoub_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:AbdulSamad_64kbps_QuranExplorer.Com',
      name: 'Abdul Samad',
      arabicName: 'عبد الباسط عبد الصمد',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'AbdulSamad_64kbps_QuranExplorer.Com',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdul_Basit_Murattal_64kbps',
      name: 'Abdul Basit (Murattal)',
      arabicName: 'عبد الباسط عبد الصمد (مرتل)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdul_Basit_Murattal_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdullah_Basfar_64kbps',
      name: 'Abdullah Basfar',
      arabicName: 'عبدالله بصفر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdullah_Basfar_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdullah_Basfar_32kbps',
      name: 'Abdullah Basfar',
      arabicName: 'عبدالله بصفر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdullah_Basfar_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abdurrahmaan_As-Sudais_64kbps',
      name: 'Abdurrahman As-Sudais',
      arabicName: 'عبد الرحمن السديس',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abdurrahmaan_As-Sudais_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Abu_Bakr_Ash-Shaatree_64kbps',
      name: 'Abu Bakr Ash-Shatri',
      arabicName: 'أبو بكر الشاطري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Abu_Bakr_Ash-Shaatree_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ahmed_ibn_Ali_al-Ajamy_64kbps_QuranExplorer.Com',
      name: 'Ahmed Al-Ajamy',
      arabicName: 'أحمد العجمي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ahmed_ibn_Ali_al-Ajamy_64kbps_QuranExplorer.Com',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Alafasy_64kbps',
      name: 'Mishary Alafasy',
      arabicName: 'مشاري العفاسي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Alafasy_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Hani_Rifai_64kbps',
      name: 'Hani Ar-Rifai',
      arabicName: 'هاني الرفاعي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Hani_Rifai_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Hudhaify_64kbps',
      name: 'Ali Al-Hudhaify',
      arabicName: 'علي الحذيفي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Hudhaify_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Hudhaify_32kbps',
      name: 'Ali Al-Hudhaify',
      arabicName: 'علي الحذيفي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Hudhaify_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Husary_64kbps',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Husary_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Husary_Mujawwad_64kbps',
      name: 'Al-Husary (Mujawwad)',
      arabicName: 'محمود خليل الحصري (مجود)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Husary_Mujawwad_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Ibrahim_Akhdar_64kbps',
      name: 'Ibrahim Al-Akhdar',
      arabicName: 'إبراهيم الأخضر',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Ibrahim_Akhdar_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Maher_AlMuaiqly_64kbps',
      name: 'Maher Al-Muaiqly',
      arabicName: 'ماهر المعيقلي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Maher_AlMuaiqly_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Menshawi_32kbps',
      name: 'Mohamed Siddiq Al-Minshawi',
      arabicName: 'محمد صديق المنشاوي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Menshawi_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Menshawi_16kbps',
      name: 'Mohamed Siddiq Al-Minshawi',
      arabicName: 'محمد صديق المنشاوي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Menshawi_16kbps',
      qualityLabel: '16 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Minshawy_Mujawwad_64kbps',
      name: 'Al-Minshawi (Mujawwad)',
      arabicName: 'محمد صديق المنشاوي (مجود)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Minshawy_Mujawwad_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Minshawy_Teacher_128kbps',
      name: 'Al-Minshawi (Teacher)',
      arabicName: 'محمد صديق المنشاوي (معلم)',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Minshawy_Teacher_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Mohammad_al_Tablaway_128kbps',
      name: 'Mohammad Al-Tablaway',
      arabicName: 'محمد الطبلاوي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Mohammad_al_Tablaway_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Mohammad_al_Tablaway_64kbps',
      name: 'Mohammad Al-Tablaway',
      arabicName: 'محمد الطبلاوي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Mohammad_al_Tablaway_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_AbdulKareem_128kbps',
      name: 'Muhammad AbdulKareem',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_AbdulKareem_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_Ayyoub_64kbps',
      name: 'Muhammad Ayyoub',
      arabicName: 'محمد أيوب',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_Ayyoub_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_Ayyoub_32kbps',
      name: 'Muhammad Ayyoub',
      arabicName: 'محمد أيوب',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_Ayyoub_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Muhammad_Jibreel_64kbps',
      name: 'Muhammad Jibreel',
      arabicName: 'محمد جبريل',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Muhammad_Jibreel_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:Saood_ash-Shuraym_64kbps',
      name: 'Saood Ash-Shuraym',
      arabicName: 'سعود الشريم',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Saood_ash-Shuraym_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:ahmed_ibn_ali_al_ajamy_128kbps',
      name: 'Ahmed Al-Ajamy',
      arabicName: 'أحمد العجمي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'ahmed_ibn_ali_al_ajamy_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:aziz_alili_128kbps',
      name: 'Aziz Alili',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'aziz_alili_128kbps',
      qualityLabel: '128 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:khalefa_al_tunaiji_64kbps',
      name: 'Khalifa Al-Tunaiji',
      arabicName: 'خليفة الطنيجي',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'khalefa_al_tunaiji_64kbps',
      qualityLabel: '64 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:mahmoud_ali_al_banna_32kbps',
      name: 'Mahmoud Ali Al-Banna',
      arabicName: 'محمود علي البنا',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'mahmoud_ali_al_banna_32kbps',
      qualityLabel: '32 kbps',
    ),
    QuranAudioReciter(
      id: 'everyayah:warsh',
      name: 'Warsh recitation',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'warsh',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.alafasy',
      name: 'Alafasy',
      arabicName: 'مشاري العفاسي',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.alafasy',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.abdullahbasfar',
      name: 'Abdullah Basfar',
      arabicName: 'عبد الله بصفر',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.abdullahbasfar',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.abdurrahmaansudais',
      name: 'Abdurrahmaan As-Sudais',
      arabicName: 'عبدالرحمن السديس',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.abdurrahmaansudais',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.abdulsamad',
      name: 'Abdul Samad',
      arabicName: 'عبدالباسط عبدالصمد',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.abdulsamad',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.shaatree',
      name: 'Abu Bakr Ash-Shaatree',
      arabicName: 'أبو بكر الشاطري',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.shaatree',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.ahmedajamy',
      name: 'Ahmed ibn Ali al-Ajamy',
      arabicName: 'أحمد بن علي العجمي',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.ahmedajamy',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.hanirifai',
      name: 'Hani Rifai',
      arabicName: 'هاني الرفاعي',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.hanirifai',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.husary',
      name: 'Husary',
      arabicName: 'محمود خليل الحصري',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.husary',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.husarymujawwad',
      name: 'Husary (Mujawwad)',
      arabicName: 'محمود خليل الحصري (المجود)',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.husarymujawwad',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.hudhaify',
      name: 'Hudhaify',
      arabicName: 'علي بن عبدالرحمن الحذيفي',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.hudhaify',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.ibrahimakhbar',
      name: 'Ibrahim Akhdar',
      arabicName: 'إبراهيم الأخضر',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.ibrahimakhbar',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.mahermuaiqly',
      name: 'Maher Al Muaiqly',
      arabicName: 'ماهر المعيقلي',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.mahermuaiqly',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.muhammadayyoub',
      name: 'Muhammad Ayyoub',
      arabicName: 'محمد أيوب',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.muhammadayyoub',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.muhammadjibreel',
      name: 'Muhammad Jibreel',
      arabicName: 'محمد جبريل',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.muhammadjibreel',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.saoodshuraym',
      name: 'Saood bin Ibraaheem Ash-Shuraym',
      arabicName: 'سعود الشريم',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.saoodshuraym',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.parhizgar',
      name: 'Parhizgar',
      arabicName: 'شهریار پرهیزگار',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.parhizgar',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ar.aymanswoaid',
      name: 'Ayman Sowaid',
      arabicName: 'أيمن سويد',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ar.aymanswoaid',
    ),
    QuranAudioReciter(
      id: 'alqurancloud:en.walk',
      name: 'Ibrahim Walk',
      languageCode: 'en',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'en.walk',
      audioBitrate: 192,
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ur.khan',
      name: 'Shamshad Ali Khan',
      languageCode: 'ur',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ur.khan',
      audioBitrate: 64,
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:fa.hedayatfarfooladvand',
      name: 'Fooladvand - Hedayatfar',
      languageCode: 'fa',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'fa.hedayatfarfooladvand',
      audioBitrate: 40,
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'everyayah:translations/Makarem_Kabiri_16Kbps',
      name: 'Makarem - Kabiri',
      languageCode: 'fa',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'translations/Makarem_Kabiri_16Kbps',
      qualityLabel: '16 kbps',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:fr.leclerc',
      name: 'Youssouf Leclerc',
      languageCode: 'fr',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'fr.leclerc',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:zh.chinese',
      name: 'Chinese',
      languageCode: 'zh',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'zh.chinese',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ru.kuliev-audio',
      name: 'Elmir Kuliev by 1MuslimApp',
      languageCode: 'ru',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ru.kuliev-audio',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:ru.kuliev-audio-2',
      name: 'Elmir Kuliev 2 by 1MuslimApp',
      languageCode: 'ru',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ru.kuliev-audio-2',
      audioBitrate: 320,
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'alqurancloud:kk.khalifahaltai-audio',
      name: 'Kazakh Translation Audio by Khalifah Altai',
      languageCode: 'kk',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'kk.khalifahaltai-audio',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'everyayah:translations/besim_korkut_ajet_po_ajet',
      name: 'Besim Korkut',
      languageCode: 'bs',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'translations/besim_korkut_ajet_po_ajet',
      qualityLabel: '128 kbps',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:portuguese_nasr',
      name: 'Portuguese Translation - Helmi Nasr',
      languageCode: 'pt',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'portuguese_nasr',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:dutch_center',
      name: 'Dutch Translation - Rowwad Translation Center',
      languageCode: 'nl',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'dutch_center',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:tagalog_rwwad',
      name: 'Filipino Translation (Tagalog) - Rowwad Translation Center',
      languageCode: 'tl',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'tagalog_rwwad',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:chinese_suliman',
      name: 'Chinese Translation - Muhammad Suleiman',
      languageCode: 'zh',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'chinese_suliman',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:vietnamese_rwwad',
      name: 'Vietnamese Translation - Rowwad Translation Center',
      languageCode: 'vi',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'vietnamese_rwwad',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:persian_ih',
      name: 'Persian Translation - Rowwad Translation Center',
      languageCode: 'fa',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'persian_ih',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:assamese_rafeeq',
      name: 'Assamese Translation - Rafiqul Islam Habibur-Rahman',
      languageCode: 'as',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'assamese_rafeeq',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:sinhalese_mahir',
      name: 'Sinhalese Translation - Rowwad Translation Center',
      languageCode: 'si',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'sinhalese_mahir',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'quranenc:somali_yacob',
      name: 'Somali Translation - Abdullah Hasan Yaqoub',
      languageCode: 'so',
      provider: QuranAudioProvider.quranEnc,
      identifier: 'somali_yacob',
      isTranslation: true,
    ),
  ];
}
