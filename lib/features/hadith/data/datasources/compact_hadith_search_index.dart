import 'dart:convert';

import '../../../../core/search/deep_search_index_record.dart';
import '../../../../core/search/search_text_normalizer.dart';
import '../../domain/services/hadith_grading.dart';

/// Reconstructs the legacy index from canonical book text without rounding,
/// changing normalization, or keeping another copy of the full source text.
List<DeepSearchIndexRecord> decodeCompactHadithSearchGroup(
  Map<String, Object> arguments,
) {
  final group = arguments['group']! as Map<String, dynamic>;
  final normalization = arguments['normalization']! as Map<String, dynamic>;
  final visibleIds = (arguments['visibleIds']! as List).cast<String>().toSet();
  final book = jsonDecode(arguments['bookSource']! as String) as Map;
  final hadiths = (book['hadiths'] as List).cast<Map<String, dynamic>>();
  return [
    for (final record in reconstructCompactHadithSearchGroup(
      group,
      normalization,
      hadiths,
      visibleIds: visibleIds,
    ))
      DeepSearchIndexRecord.fromMap({
        ...record,
        'subtitle': HadithGrading.fromGrades(
          grades: record['grades'] as List? ?? const [],
          fallbackGrade: record['subtitle'] as String? ?? '',
          bookId: record['bookId'] as String? ?? '',
          sourceId: record['sourceId'] as String? ?? '',
          reference: record['title'] as String? ?? '',
        ).summaryLabel,
      }),
  ];
}

/// Also used by the build verifier to compare every reconstructed field with
/// the source JSONL before the smaller asset is shipped.
Iterable<Map<String, dynamic>> reconstructCompactHadithSearchGroup(
  Map<String, dynamic> group,
  Map<String, dynamic> normalization,
  List<Map<String, dynamic>> hadiths, {
  Set<String>? visibleIds,
}) sync* {
  final fields = (group['fields'] as List).cast<String>();
  final runeNormalization = {
    for (final entry in normalization.entries)
      entry.key.runes.single: entry.value as String,
  };
  final entries = group['records'] as List?;
  final overrides = group['overrides'] as Map? ?? const {};
  final byId = entries == null
      ? null
      : {for (final hadith in hadiths) hadith['id'] as String: hadith};
  final orderedHadiths = entries == null
      ? hadiths
      : entries.map((entry) {
          final id = 'hadith:${group['book']}:$entry';
          final hadith = byId![id];
          if (hadith == null) {
            throw FormatException('Missing compact search source: $id');
          }
          return hadith;
        });
  for (final hadith in orderedHadiths) {
    final id = hadith['id'] as String;
    if (visibleIds != null && !visibleIds.contains(id)) {
      continue;
    }
    yield {
      'id': id,
      'category': 'hadith',
      'title': hadith['reference'] as String? ?? '',
      'subtitle': hadith['grade'] as String? ?? '',
      'primaryPreview': _preview(hadith['arabic'] as String? ?? ''),
      'secondaryPreview': _preview(hadith['translation'] as String? ?? ''),
      'normalizedText': _normalizeLegacyText(
        [for (final field in fields) hadith[field] as String? ?? ''].join(' '),
        runeNormalization,
      ),
      'targetType': 'hadith',
      'targetId': id,
      'bookId': hadith['bookId'] as String? ?? '',
      'sourceId': hadith['sourceId'] as String? ?? '',
      'grades': hadith['grades'] as List? ?? const [],
      if (overrides[id] case final Map changes)
        ...changes.cast<String, dynamic>(),
    };
  }
}

String _preview(String value) {
  final text = SearchTextNormalizer.cleanVisibleText(value);
  final runes = text.runes.take(241).toList(growable: false);
  return runes.length <= 240
      ? text
      : '${String.fromCharCodes(runes.take(239)).trimRight()}…';
}

String _normalizeLegacyText(String value, Map<int, String> normalization) {
  final buffer = StringBuffer();
  for (final rune in SearchTextNormalizer.cleanVisibleText(value).runes) {
    final mapped = normalization[rune];
    if (mapped == null) {
      throw FormatException('Unmapped compact search character: $rune');
    }
    buffer.write(mapped);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
