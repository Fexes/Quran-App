import '../entities/quran_translation.dart';

class QuranTranslationAudioPair {
  const QuranTranslationAudioPair({
    required this.resource,
    required this.voiceIds,
    required this.evidenceUrl,
  });

  final QuranTranslationResource resource;
  final List<String> voiceIds;
  final String evidenceUrl;
}

// Stable app IDs above 1,000,000 are reserved for provider-native text editions.
// Never alias editions by language or author alone: publisher revisions can differ.
const quranTranslationAudioPairs = <QuranTranslationAudioPair>[
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 20,
      languageName: 'english',
      languageCode: 'en',
      name: 'Saheeh International',
      authorName: 'Saheeh International',
      slug: 'en-sahih-international',
    ),
    voiceIds: ['alqurancloud:en.walk'],
    evidenceUrl: 'https://quranicaudio.com/quran/57',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource.urduJalandhari,
    voiceIds: ['alqurancloud:ur.khan'],
    evidenceUrl: 'https://www.quran4u.com/QR_Urdu_Index.htm',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1000001,
      languageName: 'persian',
      languageCode: 'fa',
      name: 'Mohammad Mahdi Fooladvand',
      authorName: 'Mohammad Mahdi Fooladvand',
      slug: 'alqurancloud-fa-fooladvand',
      provider: QuranTranslationProvider.alQuranCloud,
      providerKey: 'fa.fooladvand',
      sourceUrl: 'https://alquran.cloud/api',
    ),
    voiceIds: ['alqurancloud:fa.hedayatfarfooladvand'],
    evidenceUrl: 'https://api.alquran.cloud/v1/edition?format=audio',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1000002,
      languageName: 'persian',
      languageCode: 'fa',
      name: 'Naser Makarem Shirazi',
      authorName: 'Naser Makarem Shirazi',
      slug: 'alqurancloud-fa-makarem',
      provider: QuranTranslationProvider.alQuranCloud,
      providerKey: 'fa.makarem',
      sourceUrl: 'https://alquran.cloud/api',
    ),
    voiceIds: ['everyayah:translations/Makarem_Kabiri_16Kbps'],
    evidenceUrl: 'https://everyayah.com/data/recitations.js',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1000003,
      languageName: 'french',
      languageCode: 'fr',
      name: 'Muhammad Hamidullah',
      authorName: 'Muhammad Hamidullah',
      slug: 'alqurancloud-fr-hamidullah',
      provider: QuranTranslationProvider.alQuranCloud,
      providerKey: 'fr.hamidullah',
      sourceUrl: 'https://alquran.cloud/api',
    ),
    voiceIds: ['alqurancloud:fr.leclerc'],
    evidenceUrl: 'https://www.lenoblecoran.fr/audio/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1000004,
      languageName: 'russian',
      languageCode: 'ru',
      name: 'Elmir Kuliev',
      authorName: 'Elmir Kuliev',
      slug: 'alqurancloud-ru-kuliev',
      provider: QuranTranslationProvider.alQuranCloud,
      providerKey: 'ru.kuliev',
      sourceUrl: 'https://alquran.cloud/api',
    ),
    voiceIds: [
      'alqurancloud:ru.kuliev-audio',
      'alqurancloud:ru.kuliev-audio-2',
    ],
    evidenceUrl: 'https://api.alquran.cloud/v1/edition?format=audio',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 222,
      languageName: 'kazakh',
      languageCode: 'kk',
      name: 'Khalifa Altay',
      authorName: 'Khalifa Altay',
      slug: 'kk-khalifa-altay',
    ),
    voiceIds: ['alqurancloud:kk.khalifahaltai-audio'],
    evidenceUrl: 'https://api.alquran.cloud/v1/edition?format=audio',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1000005,
      languageName: 'bosnian',
      languageCode: 'bs',
      name: 'Besim Korkut',
      authorName: 'Besim Korkut',
      slug: 'alqurancloud-bs-korkut',
      provider: QuranTranslationProvider.alQuranCloud,
      providerKey: 'bs.korkut',
      sourceUrl: 'https://alquran.cloud/api',
    ),
    voiceIds: ['everyayah:translations/besim_korkut_ajet_po_ajet'],
    evidenceUrl: 'https://everyayah.com/data/recitations.js',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001001,
      languageName: 'portuguese',
      languageCode: 'pt',
      name: 'Helmi Nasr (QuranEnc)',
      authorName: 'Helmi Nasr',
      slug: 'quranenc-portuguese-nasr',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'portuguese_nasr',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/portuguese_nasr',
    ),
    voiceIds: ['quranenc:portuguese_nasr'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001002,
      languageName: 'dutch',
      languageCode: 'nl',
      name: 'Rowwad Translation Center (QuranEnc)',
      authorName: 'Rowwad Translation Center',
      slug: 'quranenc-dutch-center',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'dutch_center',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/dutch_center',
    ),
    voiceIds: ['quranenc:dutch_center'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001003,
      languageName: 'tagalog',
      languageCode: 'tl',
      name: 'Rowwad Translation Center (QuranEnc)',
      authorName: 'Rowwad Translation Center',
      slug: 'quranenc-tagalog-rwwad',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'tagalog_rwwad',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/tagalog_rwwad',
    ),
    voiceIds: ['quranenc:tagalog_rwwad'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001004,
      languageName: 'chinese',
      languageCode: 'zh',
      name: 'Muhammad Suleiman (QuranEnc)',
      authorName: 'Muhammad Makeen, reviewed by Muhammad Suleiman',
      slug: 'quranenc-chinese-suliman',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'chinese_suliman',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/chinese_suliman',
    ),
    voiceIds: ['quranenc:chinese_suliman'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001005,
      languageName: 'vietnamese',
      languageCode: 'vi',
      name: 'Rowwad Translation Center (QuranEnc)',
      authorName: 'Rowwad Translation Center',
      slug: 'quranenc-vietnamese-rwwad',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'vietnamese_rwwad',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/vietnamese_rwwad',
    ),
    voiceIds: ['quranenc:vietnamese_rwwad'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001006,
      languageName: 'persian',
      languageCode: 'fa',
      name: 'Rowwad Translation Center (QuranEnc)',
      authorName: 'Rowwad Translation Center',
      slug: 'quranenc-persian-ih',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'persian_ih',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/persian_ih',
    ),
    voiceIds: ['quranenc:persian_ih'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001007,
      languageName: 'assamese',
      languageCode: 'as',
      name: 'Rafiqul Islam Habibur-Rahman (QuranEnc)',
      authorName: 'Rafiqul Islam Habibur-Rahman',
      slug: 'quranenc-assamese-rafeeq',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'assamese_rafeeq',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/assamese_rafeeq',
    ),
    voiceIds: ['quranenc:assamese_rafeeq'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001008,
      languageName: 'sinhala, sinhalese',
      languageCode: 'si',
      name: 'Rowwad Translation Center (QuranEnc)',
      authorName: 'Rowwad Translation Center',
      slug: 'quranenc-sinhalese-mahir',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'sinhalese_mahir',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/sinhalese_mahir',
    ),
    voiceIds: ['quranenc:sinhalese_mahir'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
  QuranTranslationAudioPair(
    resource: QuranTranslationResource(
      id: 1001009,
      languageName: 'somali',
      languageCode: 'so',
      name: 'Abdullah Hasan Yaqoub (QuranEnc)',
      authorName: 'Abdullah Hasan Yaqoub',
      slug: 'quranenc-somali-yacob',
      provider: QuranTranslationProvider.quranEnc,
      providerKey: 'somali_yacob',
      publisher: 'QuranEnc',
      sourceUrl: 'https://quranenc.com/en/browse/somali_yacob',
    ),
    voiceIds: ['quranenc:somali_yacob'],
    evidenceUrl: 'https://quranenc.com/en/home/api/',
  ),
];

QuranTranslationAudioPair? quranTranslationPairForVoice(String voiceId) =>
    quranTranslationAudioPairs
        .where((pair) => pair.voiceIds.contains(voiceId))
        .firstOrNull;

QuranTranslationAudioPair? quranTranslationPairForResource(int resourceId) =>
    quranTranslationAudioPairs
        .where((pair) => pair.resource.id == resourceId)
        .firstOrNull;

QuranTranslationResource? quranDefaultPairedTranslation(String languageCode) =>
    quranTranslationAudioPairs
        .where((pair) => pair.resource.resolvedLanguageCode == languageCode)
        .firstOrNull
        ?.resource;

String? quranEditionWordLanguage(QuranTranslationResource? resource) =>
    resource == null || quranTranslationPairForResource(resource.id) != null
    ? null
    : resource.bookWordTranslationLanguageCode;
