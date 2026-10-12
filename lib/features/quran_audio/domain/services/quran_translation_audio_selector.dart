import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';

List<QuranAudioReciter> quranTranslationAudioRecitersFor({
  required List<QuranAudioReciter> reciters,
  required QuranTranslationResource? selectedTranslation,
  String? preferredLanguageCode,
}) {
  final preferredCode = preferredLanguageCode?.trim().toLowerCase();
  final languageCodes = preferredCode?.isNotEmpty == true
      ? {preferredCode!}
      : quranTranslationAudioLanguageCodesFor(selectedTranslation);
  final matching = reciters
      .where(
        (reciter) =>
            reciter.isTranslation &&
            languageCodes.contains(reciter.languageCode.toLowerCase()),
      )
      .toList(growable: false);
  return [
    ...matching.where(
      (voice) => _defaultVoiceIds[voice.languageCode] == voice.id,
    ),
    ...matching.where(
      (voice) => _defaultVoiceIds[voice.languageCode] != voice.id,
    ),
  ];
}

QuranAudioReciter? preferredQuranTranslationVoice(
  List<QuranAudioReciter> voices, {
  String? preferredId,
  String? legacyId,
}) {
  for (final id in [preferredId, legacyId]) {
    for (final voice in voices) {
      if (voice.id == id) return voice;
    }
  }
  return voices.firstOrNull;
}

// Stable catalog defaults, not a popularity ranking. User preferences take priority.
const _defaultVoiceIds = {
  'en': 'alqurancloud:en.walk',
  'ur': 'alqurancloud:ur.khan',
  'fa': 'alqurancloud:fa.hedayatfarfooladvand',
  'fr': 'alqurancloud:fr.leclerc',
  'zh': 'alqurancloud:zh.chinese',
  'ru': 'alqurancloud:ru.kuliev-audio',
  'kk': 'alqurancloud:kk.khalifahaltai-audio',
  'bs': 'everyayah:translations/besim_korkut_ajet_po_ajet',
  'pt': 'quranenc:portuguese_nasr',
  'nl': 'quranenc:dutch_center',
  'tl': 'quranenc:tagalog_rwwad',
  'vi': 'quranenc:vietnamese_rwwad',
  'as': 'quranenc:assamese_rafeeq',
  'si': 'quranenc:sinhalese_mahir',
  'so': 'quranenc:somali_yacob',
};

Set<String> quranTranslationAudioLanguageCodesFor(
  QuranTranslationResource? selectedTranslation,
) {
  if (selectedTranslation == null) {
    return const {};
  }

  final codes = <String>{};
  final languageCode = selectedTranslation.resolvedLanguageCode;
  if (languageCode.isNotEmpty) {
    codes.add(languageCode);
  }

  final tokens = selectedTranslation.languageName
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((token) => token.isNotEmpty);
  for (final token in tokens) {
    final code = _languageCodeByToken[token];
    if (code != null) {
      codes.add(code);
    }
  }

  return codes;
}

String quranTranslationAudioLanguageLabel(
  QuranTranslationResource? selectedTranslation, {
  String? preferredLanguageCode,
}) {
  final preferredCode = preferredLanguageCode?.trim().toLowerCase();
  if (preferredCode?.isNotEmpty == true) {
    return _languageLabelByCode[preferredCode!] ?? preferredCode.toUpperCase();
  }
  final label = selectedTranslation?.displayLanguage.trim();
  return label == null || label.isEmpty ? 'Select translation language' : label;
}

const _languageCodeByToken = {
  'english': 'en',
  'persian': 'fa',
  'farsi': 'fa',
  'urdu': 'ur',
  'chinese': 'zh',
  'french': 'fr',
  'russian': 'ru',
  'kazakh': 'kk',
  'bosnian': 'bs',
  'portuguese': 'pt',
  'dutch': 'nl',
  'tagalog': 'tl',
  'filipino': 'tl',
  'vietnamese': 'vi',
  'assamese': 'as',
  'sinhalese': 'si',
  'sinhala': 'si',
  'somali': 'so',
};

const _languageLabelByCode = {
  'ar': 'Arabic',
  'as': 'Assamese',
  'bs': 'Bosnian',
  'en': 'English',
  'fa': 'Persian',
  'fr': 'French',
  'kk': 'Kazakh',
  'nl': 'Dutch',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'si': 'Sinhala',
  'so': 'Somali',
  'tl': 'Tagalog',
  'ur': 'Urdu',
  'vi': 'Vietnamese',
  'zh': 'Chinese',
};
