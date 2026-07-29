import 'package:equatable/equatable.dart';

import 'content_cache_policy.dart';

enum ContentKind {
  quranText,
  quranTranslation,
  quranTafsir,
  quranWordData,
  quranWordTiming,
  quranAudio,
  hadith,
  azkar,
  other,
}

enum ContentRetrievalMode {
  bundled,
  downloaded,
  runtime,
  generated,
  userCreated,
}

enum ContentReviewStatus { approved, reviewRequired, blocked }

enum ContentTextDirection { ltr, rtl }

class ContentSource extends Equatable {
  const ContentSource({
    required this.id,
    required this.name,
    required this.attribution,
    this.description,
    this.url,
    this.license,
    this.kind = ContentKind.other,
    this.provider,
    this.edition,
    this.languageCode,
    this.languageName,
    this.script,
    this.textDirection,
    this.publisher,
    this.revision,
    this.licenseUrl,
    this.retrievalMode = ContentRetrievalMode.bundled,
    this.cachePolicy = ContentCachePolicy.bundled,
    this.reviewStatus = ContentReviewStatus.reviewRequired,
  });

  final String id;
  final String name;
  final String attribution;
  final String? description;
  final String? url;
  final String? license;
  final ContentKind kind;
  final String? provider;
  final String? edition;
  final String? languageCode;
  final String? languageName;
  final String? script;
  final ContentTextDirection? textDirection;
  final String? publisher;
  final String? revision;
  final String? licenseUrl;
  final ContentRetrievalMode retrievalMode;
  final ContentCachePolicy cachePolicy;
  final ContentReviewStatus reviewStatus;

  @override
  List<Object?> get props => [
    id,
    name,
    attribution,
    description,
    url,
    license,
    kind,
    provider,
    edition,
    languageCode,
    languageName,
    script,
    textDirection,
    publisher,
    revision,
    licenseUrl,
    retrievalMode,
    cachePolicy,
    reviewStatus,
  ];
}
