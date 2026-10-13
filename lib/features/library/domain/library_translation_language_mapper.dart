import '../../quran/domain/entities/quran_translation.dart';

class LibraryLanguageSelection {
  const LibraryLanguageSelection({
    required this.label,
    required this.hadithCode,
    required this.azkarCode,
    required this.resource,
  });

  final String label;
  final String? hadithCode;
  final String? azkarCode;
  final QuranTranslationResource? resource;

  bool get isEnglish => label.toLowerCase() == 'english';
}

LibraryLanguageSelection libraryLanguageFromQuranTranslation(
  QuranTranslationResource? resource,
) {
  if (resource == null) {
    return const LibraryLanguageSelection(
      label: 'English',
      hadithCode: 'en',
      azkarCode: 'en',
      resource: null,
    );
  }

  final tokens = resource.languageName
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((token) => token.isNotEmpty)
      .toSet();
  String? map(Map<String, String> table) {
    for (final token in tokens) {
      final code = table[token];
      if (code != null) {
        return code;
      }
    }
    return null;
  }

  return LibraryLanguageSelection(
    label: resource.displayLanguage.isEmpty
        ? resource.languageName
        : resource.displayLanguage,
    hadithCode: map(_hadithLanguageCodes),
    azkarCode: tokens.contains('badini')
        ? 'ckb-badini'
        : tokens.contains('kurmanji')
        ? null
        : map(_azkarLanguageCodes),
    resource: resource,
  );
}

LibraryLanguageSelection libraryLanguageFromCode(
  String languageCode, {
  QuranTranslationResource? resource,
}) {
  final normalized = languageCode.trim().toLowerCase().replaceAll('_', '-');
  return LibraryLanguageSelection(
    label: libraryLanguageLabel(normalized),
    hadithCode: _hadithLanguageCodes.containsValue(normalized)
        ? normalized
        : null,
    azkarCode: _azkarLanguageCodes.containsValue(normalized)
        ? normalized
        : null,
    resource: resource,
  );
}

String libraryLanguageLabel(String languageCode) {
  return _languageLabels[languageCode.trim().toLowerCase().replaceAll(
        '_',
        '-',
      )] ??
      languageCode.trim().toUpperCase();
}

const _hadithLanguageCodes = {
  'english': 'en',
  'bengali': 'bn',
  'bangla': 'bn',
  'french': 'fr',
  'indonesian': 'id',
  'russian': 'ru',
  'tamil': 'ta',
  'turkish': 'tr',
  'urdu': 'ur',
};

const _azkarLanguageCodes = {
  'arabic': 'ar',
  'english': 'en',
  'persian': 'fa',
  'farsi': 'fa',
  'russian': 'ru',
  'urdu': 'ur',
  'kurdish': 'ckb',
  'sorani': 'ckb',
  'badini': 'ckb-badini',
};

const _languageLabels = {
  'ar': 'Arabic',
  'bn': 'Bengali',
  'bs': 'Bosnian',
  'ckb': 'Kurdish (Sorani)',
  'ckb-badini': 'Kurdish (Badini)',
  'en': 'English',
  'fa': 'Persian',
  'fr': 'French',
  'id': 'Indonesian',
  'kk': 'Kazakh',
  'nl': 'Dutch',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'so': 'Somali',
  'ta': 'Tamil',
  'tl': 'Tagalog',
  'tr': 'Turkish',
  'ur': 'Urdu',
  'vi': 'Vietnamese',
  'zh': 'Chinese',
};
