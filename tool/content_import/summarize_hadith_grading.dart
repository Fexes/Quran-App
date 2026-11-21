import 'dart:convert';
import 'dart:io';

import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/domain/services/hadith_grading.dart';

/// Audits every bundled record using the grading rules shipped to the reader.
/// Source agreement is reported separately from independent authentication.
void main() {
  final totals = <String, int>{};
  final books = <String, Object?>{};
  final examples = <String, List<String>>{};
  final unknown = <String, int>{};
  final ids = <String>{};
  final files =
      Directory('assets/data/hadith/books')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final counts = <String, int>{};
    for (final raw in data['hadiths'] as List) {
      final item = HadithItem.fromMap(raw as Map<String, dynamic>);
      if (!ids.add(item.id)) throw StateError('Duplicate record: ${item.id}');
      final grading = HadithGrading.fromHadith(item);
      final status = grading.status.name;
      totals.update(status, (n) => n + 1, ifAbsent: () => 1);
      counts.update(status, (n) => n + 1, ifAbsent: () => 1);
      final list = examples.putIfAbsent(status, () => []);
      if (list.length < 8) list.add(item.id);
      for (final assessment in grading.assessments) {
        if (assessment.kind == HadithGradeKind.unknown) {
          unknown.update(
            assessment.attributedText,
            (n) => n + 1,
            ifAbsent: () => 1,
          );
        }
      }
      if (grading.independentlyVerified) {
        throw StateError(
          'Imported record claims independent verification: ${item.id}',
        );
      }
    }
    books[file.uri.pathSegments.last.replaceAll('.json', '')] = counts;
  }
  final report = {
    'records': ids.length,
    'classificationBasis':
        'Attributed source assessments; no independent primary-source verification',
    'independentlyVerifiedRecords': 0,
    'statusCounts': totals,
    'books': books,
    'examples': examples,
    'unrecognizedRawAssessments': unknown,
  };
  final target = File('docs/hadith_grading_classification.json');
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(
    jsonEncode({
      'records': ids.length,
      'statuses': totals,
      'unrecognizedAssessmentVariants': unknown.length,
      'independentlyVerifiedRecords': 0,
      'report': target.path,
    }),
  );
}
