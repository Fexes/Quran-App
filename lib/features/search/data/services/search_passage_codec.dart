import '../../domain/entities/offline_search_result.dart';

Map<String, Object?> encodePassage(OfflineSearchPassage p) => {
  'canonicalId': p.canonicalId,
  'kind': p.kind,
  'reference': p.reference,
  'title': p.title,
  'arabic': p.arabic,
  'body': p.body,
  'route': p.route,
  'language': p.language,
  'sourceLabel': p.sourceLabel,
  'isUserContent': p.isUserContent,
  'metadata': p.metadata,
  'surahNumber': p.surahNumber,
  'ayahNumber': p.ayahNumber,
  'itemId': p.itemId,
  'translations': [
    for (final t in p.translations)
      {'language': t.language, 'text': t.text, 'source': t.source},
  ],
  'grades': [
    for (final g in p.grades) {'grade': g.grade, 'grader': g.grader},
  ],
};

OfflineSearchPassage decodePassage(Map<String, dynamic> p) =>
    OfflineSearchPassage(
      canonicalId: p['canonicalId'] as String,
      kind: p['kind'] as String,
      reference: p['reference'] as String,
      title: p['title'] as String,
      arabic: p['arabic'] as String,
      body: p['body'] as String? ?? '',
      route: p['route'] as String? ?? '',
      language: p['language'] as String? ?? '',
      sourceLabel: p['sourceLabel'] as String? ?? '',
      isUserContent: p['isUserContent'] as bool? ?? false,
      metadata: (p['metadata'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      surahNumber: p['surahNumber'] as int?,
      ayahNumber: p['ayahNumber'] as int?,
      itemId: p['itemId'] as String?,
      translations: [
        for (final t in p['translations'] as List)
          OfflineSearchTranslation.fromJson(
            Map<String, dynamic>.from(t as Map),
          ),
      ],
      grades: [
        for (final g in p['grades'] as List)
          OfflineHadithGrade.fromJson(Map<String, dynamic>.from(g as Map)),
      ],
    );

bool matchesSearchFilter(String kind, OfflineSearchFilter filter) =>
    filter == OfflineSearchFilter.all ||
    kind == filter.name ||
    (filter == OfflineSearchFilter.tools &&
        const {'tool', 'widget', 'divine_name', 'surah'}.contains(kind));
