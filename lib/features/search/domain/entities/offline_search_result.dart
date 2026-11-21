enum OfflineSearchFilter {
  all,
  quran,
  hadith,
  azkar,
  tafsir,
  notes,
  saved,
  tools,
  timings,
}

class OfflineSearchTranslation {
  const OfflineSearchTranslation({
    required this.language,
    required this.text,
    required this.source,
  });

  final String language;
  final String text;
  final String source;

  factory OfflineSearchTranslation.fromJson(Map<String, dynamic> json) =>
      OfflineSearchTranslation(
        language: json['language'] as String,
        text: json['text'] as String,
        source: json['source'] as String,
      );
}

class OfflineHadithGrade {
  const OfflineHadithGrade({required this.grade, required this.grader});

  final String grade;
  final String grader;

  factory OfflineHadithGrade.fromJson(Map<String, dynamic> json) =>
      OfflineHadithGrade(
        grade: json['grade'] as String,
        grader: json['grader'] as String,
      );
}

class OfflineSearchPassage {
  const OfflineSearchPassage({
    required this.canonicalId,
    required this.kind,
    required this.reference,
    required this.title,
    required this.arabic,
    required this.translations,
    required this.grades,
    this.surahNumber,
    this.ayahNumber,
    this.itemId,
    this.body = '',
    this.route = '',
    this.language = '',
    this.sourceLabel = '',
    this.isUserContent = false,
    this.metadata = const {},
  });

  final String canonicalId;
  final String kind;
  final String reference;
  final String title;
  final String arabic;
  final List<OfflineSearchTranslation> translations;
  final List<OfflineHadithGrade> grades;
  final int? surahNumber;
  final int? ayahNumber;
  final String? itemId;
  final String body;
  final String route;
  final String language;
  final String sourceLabel;
  final bool isUserContent;
  final Map<String, String> metadata;
}

class OfflineSearchHit {
  const OfflineSearchHit({required this.passage, required this.score});

  final OfflineSearchPassage passage;
  // Retrieval score only. It does not express authenticity or religious authority.
  final double score;
}

class OfflineSearchResponse {
  const OfflineSearchResponse({
    required this.hits,
    required this.timingsMs,
    required this.semanticAvailable,
    this.warning,
    this.pendingDocuments = 0,
  });

  final List<OfflineSearchHit> hits;
  final Map<String, int> timingsMs;
  final bool semanticAvailable;
  final String? warning;
  final int pendingDocuments;
}

class OfflineSearchConfig {
  const OfflineSearchConfig({
    this.candidateLimit = 75,
    this.rrfConstant = 60,
    this.keywordWeight = 1,
    this.semanticWeight = 1,
    this.vectorBatchSize = 256,
    this.inferenceThreads = 2,
  }) : assert(candidateLimit > 0 && candidateLimit <= 1000),
       assert(rrfConstant > 0),
       assert(keywordWeight > 0 && semanticWeight > 0),
       assert(vectorBatchSize > 0),
       assert(inferenceThreads > 0);

  final int candidateLimit;
  final int rrfConstant;
  final double keywordWeight;
  final double semanticWeight;
  final int vectorBatchSize;
  final int inferenceThreads;
}
