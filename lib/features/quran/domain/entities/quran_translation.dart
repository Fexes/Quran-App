import 'dart:ui' show TextAlign, TextDirection;

import 'package:equatable/equatable.dart';

class QuranTranslationResource extends Equatable {
  const QuranTranslationResource({
    required this.id,
    required this.languageName,
    required this.name,
    required this.authorName,
    required this.slug,
    this.languageCode = '',
    this.endonym = '',
    this.script = '',
    this.publisher = '',
    this.license = 'Provider terms and edition rights apply',
    this.revision = '',
    this.sourceUrl = 'https://quran.com',
    this.checksum = '',
    this.supportsFootnotes = false,
  });

  factory QuranTranslationResource.fromJson(Map<dynamic, dynamic> json) {
    return QuranTranslationResource(
      id: _int(json['id']),
      languageName: _string(json['languageName'] ?? json['language_name']),
      name: _string(json['name']),
      authorName: _string(json['authorName'] ?? json['author_name']),
      slug: _string(json['slug']),
      languageCode: _string(
        json['languageCode'] ?? json['language_code'] ?? json['iso_code'],
      ),
      endonym: _string(json['endonym']),
      script: _string(json['script']),
      publisher: _string(json['publisher']),
      license: _string(json['license']).isEmpty
          ? 'Provider terms and edition rights apply'
          : _string(json['license']),
      revision: _string(json['revision']),
      sourceUrl: _string(json['sourceUrl'] ?? json['source_url']).isEmpty
          ? 'https://quran.com'
          : _string(json['sourceUrl'] ?? json['source_url']),
      checksum: _string(json['checksum']),
      supportsFootnotes:
          json['supportsFootnotes'] as bool? ??
          json['supports_footnotes'] as bool? ??
          false,
    );
  }

  final int id;
  final String languageName;
  final String name;
  final String authorName;
  final String slug;
  final String languageCode;
  final String endonym;
  final String script;
  final String publisher;
  final String license;
  final String revision;
  final String sourceUrl;
  final String checksum;
  final bool supportsFootnotes;

  String get resolvedLanguageCode {
    if (languageCode.trim().isNotEmpty) {
      return languageCode.trim().toLowerCase();
    }
    return _languageCodeByName[languageName.trim().toLowerCase()] ?? '';
  }

  String get displayEndonym {
    if (endonym.trim().isNotEmpty) {
      return endonym.trim();
    }
    return _endonymByCode[resolvedLanguageCode] ?? displayLanguage;
  }

  String get resolvedScript {
    if (script.trim().isNotEmpty) {
      return script.trim();
    }
    return isRtl ? 'Arab' : 'Latn';
  }

  String get translator => authorName.trim().isEmpty ? name : authorName;

  bool get isRtl {
    final normalizedCode = resolvedLanguageCode.split('-').first;
    if (_rtlLanguageCodes.contains(normalizedCode) ||
        script.trim().toLowerCase() == 'arab') {
      return true;
    }
    final tokens = languageName
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((token) => token.isNotEmpty)
        .toSet();
    return tokens.any(_rtlLanguageTokens.contains);
  }

  TextDirection get textDirection {
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign get textAlign {
    return isRtl ? TextAlign.right : TextAlign.left;
  }

  String? get wordTranslationLanguageCode {
    final tokens = languageName
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((token) => token.isNotEmpty)
        .toSet();
    for (final token in tokens) {
      final code = _wordTranslationLanguageCodes[token];
      if (code != null) {
        return code;
      }
    }
    return null;
  }

  String get displayLanguage {
    if (languageName.isEmpty) {
      return '';
    }
    return languageName
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) {
            return part;
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'languageName': languageName,
      'name': name,
      'authorName': authorName,
      'slug': slug,
      'languageCode': resolvedLanguageCode,
      'endonym': displayEndonym,
      'script': resolvedScript,
      'publisher': publisher,
      'license': license,
      'revision': revision,
      'sourceUrl': sourceUrl,
      'checksum': checksum,
      'supportsFootnotes': supportsFootnotes,
    };
  }

  @override
  List<Object> get props => [
    id,
    languageName,
    name,
    authorName,
    slug,
    resolvedLanguageCode,
    displayEndonym,
    resolvedScript,
    publisher,
    license,
    revision,
    sourceUrl,
    checksum,
    supportsFootnotes,
  ];
}

const _languageCodeByName = {
  'amazigh': 'ber',
  'albanian': 'sq',
  'amharic': 'am',
  'assamese': 'as',
  'azeri': 'az',
  'bambara': 'bm',
  'bosnian': 'bs',
  'bulgarian': 'bg',
  'central khmer': 'km',
  'chechen': 'ce',
  'czech': 'cs',
  'dari': 'prs',
  'divehi': 'dv',
  'divehi, dhivehi, maldivian': 'dv',
  'dutch': 'nl',
  'finnish': 'fi',
  'ganda': 'lg',
  'gujarati': 'gu',
  'hausa': 'ha',
  'hebrew': 'he',
  'italian': 'it',
  'japanese': 'ja',
  'kannada': 'kn',
  'kazakh': 'kk',
  'kinyarwanda': 'rw',
  'korean': 'ko',
  'kurdish': 'ku',
  'malayalam': 'ml',
  'maranao': 'mrw',
  'marathi': 'mr',
  'nepali': 'ne',
  'norwegian': 'no',
  'oromo': 'om',
  'polish': 'pl',
  'romanian': 'ro',
  'sinhala, sinhalese': 'si',
  'sinhala': 'si',
  'somali': 'so',
  'swahili': 'sw',
  'swedish': 'sv',
  'tagalog': 'tl',
  'tajik': 'tg',
  'tamil': 'ta',
  'tatar': 'tt',
  'telugu': 'te',
  'thai': 'th',
  'uighur, uyghur': 'ug',
  'uighur': 'ug',
  'uyghur': 'ug',
  'ukrainian': 'uk',
  'uzbek': 'uz',
  'vietnamese': 'vi',
  'yau,yuw': 'yao',
  'yoruba': 'yo',
  'arabic': 'ar',
  'english': 'en',
  'urdu': 'ur',
  'persian': 'fa',
  'farsi': 'fa',
  'turkish': 'tr',
  'indonesian': 'id',
  'malay': 'ms',
  'french': 'fr',
  'german': 'de',
  'spanish': 'es',
  'portuguese': 'pt',
  'russian': 'ru',
  'chinese': 'zh',
  'bengali': 'bn',
  'hindi': 'hi',
  'pashto': 'ps',
  'sindhi': 'sd',
};

const _endonymByCode = {
  'ar': 'العربية',
  'en': 'English',
  'ur': 'اردو',
  'fa': 'فارسی',
  'tr': 'Türkçe',
  'id': 'Bahasa Indonesia',
  'ms': 'Bahasa Melayu',
  'fr': 'Français',
  'de': 'Deutsch',
  'es': 'Español',
  'pt': 'Português',
  'ru': 'Русский',
  'zh': '中文',
  'bn': 'বাংলা',
  'hi': 'हिन्दी',
  'ps': 'پښتو',
  'sd': 'سنڌي',
};

const _rtlLanguageTokens = {
  'arabic',
  'urdu',
  'persian',
  'farsi',
  'pashto',
  'dari',
  'sindhi',
  'uighur',
  'uyghur',
  'hebrew',
  'kurdish',
};

const _rtlLanguageCodes = {'ar', 'ur', 'fa', 'ps', 'sd', 'he', 'ug', 'ku'};

const _wordTranslationLanguageCodes = {
  'english': 'en',
  'urdu': 'ur',
  'persian': 'fa',
  'farsi': 'fa',
  'turkish': 'tr',
};

class QuranTranslationLanguage extends Equatable {
  const QuranTranslationLanguage({
    required this.languageName,
    required this.displayName,
    required this.resourceCount,
    required this.defaultResource,
    this.resources = const [],
  });

  final String languageName;
  final String displayName;
  final int resourceCount;
  final QuranTranslationResource defaultResource;
  final List<QuranTranslationResource> resources;

  List<QuranTranslationResource> get availableResources {
    return resources.isEmpty ? [defaultResource] : resources;
  }

  @override
  List<Object> get props => [
    languageName,
    displayName,
    resourceCount,
    defaultResource,
    resources,
  ];
}

class QuranTranslationDownloadProgress extends Equatable {
  const QuranTranslationDownloadProgress({
    required this.completedChapters,
    required this.totalChapters,
    required this.completedVerses,
    required this.totalVerses,
    required this.failedChapters,
    this.isComplete = false,
  });

  final int completedChapters;
  final int totalChapters;
  final int completedVerses;
  final int totalVerses;
  final int failedChapters;
  final bool isComplete;

  double get percent {
    if (totalVerses <= 0) {
      return 0;
    }
    return (completedVerses / totalVerses).clamp(0, 1).toDouble();
  }

  @override
  List<Object> get props => [
    completedChapters,
    totalChapters,
    completedVerses,
    totalVerses,
    failedChapters,
    isComplete,
  ];
}

class QuranTranslationPackStatus extends Equatable {
  const QuranTranslationPackStatus({
    required this.downloadedSurahs,
    required this.cachedBytes,
    this.downloadedAt,
    this.expiresAt,
  });

  final List<int> downloadedSurahs;
  final int cachedBytes;
  final DateTime? downloadedAt;
  final DateTime? expiresAt;

  bool get hasAnyDownload => downloadedSurahs.isNotEmpty;
  bool get isFullDownload => downloadedSurahs.length == 114;

  @override
  List<Object?> get props => [
    downloadedSurahs,
    cachedBytes,
    downloadedAt,
    expiresAt,
  ];
}

class QuranCachedTranslationVerse extends Equatable {
  const QuranCachedTranslationVerse({
    required this.resourceId,
    required this.verseKey,
    required this.text,
    this.resourceName,
    this.languageName,
  });

  final int resourceId;
  final String verseKey;
  final String text;
  final String? resourceName;
  final String? languageName;

  @override
  List<Object?> get props => [
    resourceId,
    verseKey,
    text,
    resourceName,
    languageName,
  ];
}

String _string(Object? value) => value is String ? value : '';

int _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
