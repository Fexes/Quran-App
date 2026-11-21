import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:quran/core/search/deep_search_index_record.dart';
import 'package:quran/features/hadith/data/datasources/compact_hadith_search_index.dart';
import 'package:quran/features/hadith/domain/services/hadith_grading.dart';

/// Builds and verifies against the source JSONL using the reconstruction and
/// grading functions shipped by the app. --verify-only leaves assets unchanged.
Future<void> main(List<String> args) async {
  if (!args.contains('--verify-only')) {
    final result = await Process.run('python3', [
      'tool/content_import/build_compact_hadith_search_index.py',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }
  const root = 'assets/data/hadith';
  final index =
      jsonDecode(File('$root/search_index.compact.json').readAsStringSync())
          as Map<String, dynamic>;
  if (index['version'] != 1 ||
      sha256
              .convert(File('$root/search_index.jsonl').readAsBytesSync())
              .toString() !=
          index['sourceSha256']) {
    throw StateError('Compact search index does not match source JSONL');
  }
  final visibility =
      jsonDecode(File('$root/visibility.json').readAsStringSync()) as Map;
  final visibleBooks = visibility['books'] as Map;
  final original = File(
    '$root/search_index.jsonl',
  ).openRead().transform(utf8.decoder).transform(const LineSplitter());
  final iterator = StreamIterator(
    original.where((line) => line.trim().isNotEmpty),
  );
  var checked = 0;
  var visibleCount = 0;
  final stopwatch = Stopwatch()..start();
  for (final group in (index['groups'] as List).cast<Map<String, dynamic>>()) {
    final slug = group['book'] as String;
    final bookFile = File('$root/books/$slug.json');
    if (sha256.convert(bookFile.readAsBytesSync()).toString() !=
        (index['bookSha256'] as Map)[slug]) {
      throw StateError('Compact search index does not match book $slug');
    }
    final bookSource = bookFile.readAsStringSync();
    final book = jsonDecode(bookSource) as Map;
    final hadiths = (book['hadiths'] as List).cast<Map<String, dynamic>>();
    final visibleIds =
        (visibleBooks[slug] as Map?)?['ids'] as List? ?? const [];
    final visibleIdSet = visibleIds.cast<String>().toSet();
    final visible = decodeCompactHadithSearchGroup({
      'group': group,
      'normalization': index['normalization'] as Map<String, dynamic>,
      'bookSource': bookSource,
      'visibleIds': visibleIds,
    });
    var visibleOffset = 0;
    for (final record in reconstructCompactHadithSearchGroup(
      group,
      index['normalization'] as Map<String, dynamic>,
      hadiths,
    )) {
      if (!await iterator.moveNext()) {
        throw StateError('Compact index has more records than the source');
      }
      final source = jsonDecode(iterator.current) as Map<String, dynamic>;
      if (!_same(record, source)) {
        final different = {
          for (final key in {...record.keys, ...source.keys})
            if (!_same(record[key], source[key]))
              key: {'reconstructed': record[key], 'source': source[key]},
        };
        throw StateError(
          'Changed ${source['targetId']}: ${jsonEncode(different)}',
        );
      }
      checked++;
      if (visibleIdSet.contains(source['targetId'])) {
        final expected = DeepSearchIndexRecord.fromMap({
          ...source,
          'subtitle': HadithGrading.fromGrades(
            grades: source['grades'] as List? ?? const [],
            fallbackGrade: source['subtitle'] as String? ?? '',
            bookId: source['bookId'] as String? ?? '',
            sourceId: source['sourceId'] as String? ?? '',
            reference: source['title'] as String? ?? '',
          ).summaryLabel,
        });
        if (visibleOffset >= visible.length ||
            visible[visibleOffset] != expected) {
          throw StateError('Visible record changed: ${source['targetId']}');
        }
        visibleOffset++;
        visibleCount++;
      }
    }
    if (visibleOffset != visible.length) {
      throw StateError('Visible record count changed for $slug');
    }
  }
  if (await iterator.moveNext() || checked != index['recordCount']) {
    throw StateError('Compact index is missing source records');
  }
  await iterator.cancel();
  stdout.writeln(
    jsonEncode({
      'recordsVerified': checked,
      'visibleRecordsVerified': visibleCount,
      'allRawFieldsIdentical': true,
      'allVisibleRecordsAndOrderingIdentical': true,
      'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
    }),
  );
}

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _same(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        [for (var i = 0; i < a.length; i++) i].every((i) => _same(a[i], b[i]));
  }
  return a == b;
}
