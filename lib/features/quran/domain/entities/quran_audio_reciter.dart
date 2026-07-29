import 'package:equatable/equatable.dart';

import 'quran_ayah.dart';

enum QuranAudioProvider { everyAyah, alQuranCloud, quranEnc }

enum QuranAudioTimingProvider { none, quranFoundation, quranAlign }

class QuranAudioReciter extends Equatable {
  const QuranAudioReciter({
    required this.id,
    required this.name,
    required this.provider,
    required this.identifier,
    this.arabicName,
    this.languageCode = 'ar',
    this.qualityLabel,
    this.audioBitrate = 128,
    this.isTranslation = false,
    this.imageUrl,
    this.timingProvider = QuranAudioTimingProvider.none,
    this.timingRecitationId,
    this.timingChapterReciterId,
  });

  final String id;
  final String name;
  final String? arabicName;
  final String languageCode;
  final String? qualityLabel;
  final int audioBitrate;
  final bool isTranslation;
  final QuranAudioProvider provider;
  final String identifier;
  final String? imageUrl;
  final QuranAudioTimingProvider timingProvider;
  final int? timingRecitationId;
  final int? timingChapterReciterId;

  String? get effectiveImageUrl {
    final explicit = imageUrl?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    for (final entry in _knownImageUrls.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  String audioUrlFor(QuranAyah ayah) {
    return switch (provider) {
      QuranAudioProvider.everyAyah => _everyAyahUrl(ayah),
      QuranAudioProvider.alQuranCloud => _alQuranCloudUrl(ayah),
      QuranAudioProvider.quranEnc => _quranEncUrl(ayah),
    };
  }

  String _everyAyahUrl(QuranAyah ayah) {
    final surah = ayah.surahNumber.toString().padLeft(3, '0');
    final ayahNumber = ayah.number.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$identifier/$surah$ayahNumber.mp3';
  }

  String _alQuranCloudUrl(QuranAyah ayah) {
    return 'https://cdn.islamic.network/quran/audio/$audioBitrate/$identifier/${ayah.globalNumber}.mp3';
  }

  String _quranEncUrl(QuranAyah ayah) {
    final surah = ayah.surahNumber.toString().padLeft(3, '0');
    final ayahNumber = ayah.number.toString().padLeft(3, '0');
    return 'https://d.quranenc.com/data/audio/$identifier/$surah$ayahNumber.mp3';
  }

  @override
  List<Object?> get props => [
    id,
    name,
    arabicName,
    languageCode,
    qualityLabel,
    audioBitrate,
    isTranslation,
    provider,
    identifier,
    imageUrl,
    timingProvider,
    timingRecitationId,
    timingChapterReciterId,
  ];

  static const Map<String, String> _knownImageUrls = {
    'mishary alafasy':
        'https://static.qurancdn.com/images/reciters/6/mishary-rashid-alafasy-profile.jpeg?v=1',
    'alafasy':
        'https://static.qurancdn.com/images/reciters/6/mishary-rashid-alafasy-profile.jpeg?v=1',
    'abdul basit':
        'https://static.qurancdn.com/images/reciters/1/abdelbasset-profile.jpeg?v=1',
    'abdelbasset':
        'https://static.qurancdn.com/images/reciters/1/abdelbasset-profile.jpeg?v=1',
    'abdul samad':
        'https://static.qurancdn.com/images/reciters/1/abdelbasset-profile.jpeg?v=1',
    'sudais':
        'https://static.qurancdn.com/images/reciters/2/abdul-rahman-al-sudais-profile.jpeg?v=1',
    'as sudais':
        'https://static.qurancdn.com/images/reciters/2/abdul-rahman-al-sudais-profile.jpeg?v=1',
    'abdurrahman as sudais':
        'https://static.qurancdn.com/images/reciters/2/abdul-rahman-al-sudais-profile.jpeg?v=1',
    'abu bakr ash shatri':
        'https://static.qurancdn.com/images/reciters/3/abu-bakr-al-shatri-pofile.jpeg?v=1',
    'abu bakr ash shaatree':
        'https://static.qurancdn.com/images/reciters/3/abu-bakr-al-shatri-pofile.jpeg?v=1',
    'shatri':
        'https://static.qurancdn.com/images/reciters/3/abu-bakr-al-shatri-pofile.jpeg?v=1',
    'hani ar rifai':
        'https://static.qurancdn.com/images/reciters/4/hani-ar-rifai-profile.jpeg?v=1',
    'hani rifai':
        'https://static.qurancdn.com/images/reciters/4/hani-ar-rifai-profile.jpeg?v=1',
    'mahmoud khalil al husary':
        'https://static.qurancdn.com/images/reciters/5/mahmoud-khalil-al-hussary-profile.png?v=1',
    'al husary':
        'https://static.qurancdn.com/images/reciters/5/mahmoud-khalil-al-hussary-profile.png?v=1',
    'husary':
        'https://static.qurancdn.com/images/reciters/5/mahmoud-khalil-al-hussary-profile.png?v=1',
    'mohamed siddiq al minshawi':
        'https://static.qurancdn.com/images/reciters/7/mohamed-siddiq-el-minshawi-profile.jpeg?v=1',
    'minshawi':
        'https://static.qurancdn.com/images/reciters/7/mohamed-siddiq-el-minshawi-profile.jpeg?v=1',
    'saood ash shuraym':
        'https://static.qurancdn.com/images/reciters/8/saoud-shuraim-profile.jpeg?v=1',
    'saud ash shuraim':
        'https://static.qurancdn.com/images/reciters/8/saoud-shuraim-profile.jpeg?v=1',
    'saood bin ibraaheem':
        'https://static.qurancdn.com/images/reciters/8/saoud-shuraim-profile.jpeg?v=1',
    'shuraym':
        'https://static.qurancdn.com/images/reciters/8/saoud-shuraim-profile.jpeg?v=1',
    'khalifa al tunaiji':
        'https://static.qurancdn.com/images/reciters/11/khalifa-al-tunaiji-profile.jpeg?v=1',
    'tunaiji':
        'https://static.qurancdn.com/images/reciters/11/khalifa-al-tunaiji-profile.jpeg?v=1',
    'saad al ghamdi':
        'https://static.qurancdn.com/images/reciters/16/saad-al-ghamdi-profile.png?v=1',
    'ghamdi':
        'https://static.qurancdn.com/images/reciters/16/saad-al-ghamdi-profile.png?v=1',
    'maher al muaiqly':
        'https://static.qurancdn.com/images/reciters/25/Maher-al-Muaiqly-profile.png?v=1',
    'ahmed al ajamy':
        'https://static.qurancdn.com/images/reciters/22/Ahmed-ibn-Ali-al-Ajmy-profile.png?v=1',
    'ahmed ibn ali al ajamy':
        'https://static.qurancdn.com/images/reciters/22/Ahmed-ibn-Ali-al-Ajmy-profile.png?v=1',
    'ajamy':
        'https://static.qurancdn.com/images/reciters/22/Ahmed-ibn-Ali-al-Ajmy-profile.png?v=1',
    'yasser al dosari':
        'https://static.qurancdn.com/images/reciters/20/yasser-profile.png?v=1',
    'yasser ad dussary':
        'https://static.qurancdn.com/images/reciters/20/yasser-profile.png?v=1',
    'dosari':
        'https://static.qurancdn.com/images/reciters/20/yasser-profile.png?v=1',
    'ali jaber':
        'https://static.qurancdn.com/images/reciters/23/Abdullah-Ali-Jabir-profile.png?v=1',
    'abdullah ali jabir':
        'https://static.qurancdn.com/images/reciters/23/Abdullah-Ali-Jabir-profile.png?v=1',
  };
}
