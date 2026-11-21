import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/search/data/services/offline_search_overlay.dart';
import 'package:quran/features/search/domain/entities/offline_search_result.dart';
import 'package:quran/features/search/domain/entities/search_document.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  late String path;
  late OfflineSearchOverlay overlay;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('search-overlay-test-');
    path = '${directory.path}/overlay.sqlite';
    overlay = OfflineSearchOverlay(path, 'model-v1');
  });
  tearDown(() {
    overlay.dispose();
    directory.deleteSync(recursive: true);
  });

  test('verse references find downloaded, linked, and personal content', () {
    overlay.upsert('content', '1', [
      _document('translation', 'quran:2:255', 'quran'),
      _document(
        'tafsir',
        'tafsir:42:2:255',
        'tafsir',
        metadata: {'verseKey': '2:255'},
      ),
      _document('note', 'note:quran:one', 'notes', reference: '۲ : ۲۵۵'),
      _document(
        'saved',
        'saved:quran:one',
        'saved',
        route: '/quran/2?ayah=255',
      ),
    ]);
    for (final filter in [
      OfflineSearchFilter.quran,
      OfflineSearchFilter.tafsir,
      OfflineSearchFilter.notes,
      OfflineSearchFilter.saved,
    ]) {
      final matches = overlay.exactReferences('Quran ٢:٢٥٥', filter);
      expect(matches, hasLength(1));
      expect(matches.single.kind, filter.name);
    }
    expect(
      overlay.exactReferences('2:255', OfflineSearchFilter.all),
      hasLength(4),
    );
    expect(
      overlay.exactReferences('TAFSIR:42:2:255', OfflineSearchFilter.tafsir),
      hasLength(1),
    );
  });

  test('Hadith aliases use canonical IDs, never chapter-local labels', () {
    overlay.upsert('content', '1', [
      _document(
        'one',
        'hadith:bukhari:1',
        'hadith',
        reference: 'Sahih al-Bukhari 1',
      ),
      _document(
        'fifty-nine',
        'hadith:bukhari:59',
        'hadith',
        reference: 'Sahih al-Bukhari 1',
      ),
      _document(
        'numeric-label',
        'hadith:bukhari:60',
        'hadith',
        reference: '2:255',
      ),
      _document(
        'note',
        'note:library:one',
        'notes',
        reference: 'Sahih al-Bukhari 1',
        route: '/library/hadith/bukhari?hadith=1',
      ),
    ]);
    expect(
      overlay.exactReferences('Sahih al-Bukhari 1', OfflineSearchFilter.all),
      isEmpty,
    );
    expect(overlay.exactReferences('2:255', OfflineSearchFilter.all), isEmpty);
    final matches = overlay.exactReferences(
      'Sahih al-Bukhari 1',
      OfflineSearchFilter.all,
      canonicalIds: ['hadith:bukhari:1'],
    );
    expect(matches.map((p) => p.canonicalId), [
      'hadith:bukhari:1',
      'note:library:one',
    ]);
    expect(
      overlay
          .exactReferences('hadith:bukhari:59', OfflineSearchFilter.hadith)
          .single
          .canonicalId,
      'hadith:bukhari:59',
    );
  });

  test('reference updates and deletion persist without stale aliases', () {
    overlay.upsert('notes', '1', [
      _document('one', 'note:one', 'notes', reference: '2:255'),
    ]);
    overlay.upsert('notes', '2', [
      _document('one', 'note:one', 'notes', reference: '94:5'),
    ]);
    expect(
      overlay.exactReferences('2:255', OfflineSearchFilter.notes),
      isEmpty,
    );
    expect(
      overlay.exactReferences('94:5', OfflineSearchFilter.notes),
      hasLength(1),
    );
    overlay.finish('notes', '3');
    overlay.dispose();
    overlay = OfflineSearchOverlay(path, 'model-v1');
    expect(overlay.exactReferences('94:5', OfflineSearchFilter.notes), isEmpty);
    final database = sqlite3.open(path);
    expect(
      database.select('SELECT count(*) n FROM reference_aliases').single['n'],
      0,
    );
    database.close();
  });

  test(
    'existing overlays backfill aliases while retaining completed vectors',
    () {
      overlay.upsert('old', '1', [
        _document('one', 'tafsir:42:2:255', 'tafsir', reference: 'Quran 2:255'),
      ]);
      final pending = overlay.nextPending()!;
      overlay.addVector(pending.id, 0, _vector(0.8));
      overlay.finishEmbedding(pending.id);
      overlay.dispose();
      final database = sqlite3.open(path);
      database.execute('DROP TABLE reference_aliases');
      database.close();
      overlay = OfflineSearchOverlay(path, 'model-v1');
      expect(
        overlay.exactReferences('2:255', OfflineSearchFilter.tafsir),
        hasLength(1),
      );
      expect(overlay.pendingDocuments, 0);
      expect(
        overlay.vectorScores(_vector(1), OfflineSearchFilter.tafsir, 1),
        hasLength(1),
      );
    },
  );

  test('keyword limits count canonical passages, not translation editions', () {
    overlay.upsert('translations', '1', [
      _document('a-en', 'quran:2:153', 'quran', text: 'patience'),
      _document('a-ur', 'quran:2:153', 'quran', text: 'patience'),
      _document('b', 'quran:94:5', 'quran', text: 'patience during hardship'),
    ]);
    final scores = overlay.keywordScores(
      'patience',
      OfflineSearchFilter.quran,
      2,
    );
    final passages = overlay.passages(scores.keys).values;
    expect(passages.map((p) => p.canonicalId).toSet(), {
      'quran:2:153',
      'quran:94:5',
    });
  });

  test('new personal notes are indexed before waiting language packs', () {
    overlay.upsert('content', '1', [
      _document('translation', 'quran:2:255', 'quran', text: 'translation'),
      _document('tool', 'tool:prayer', 'tools', text: 'prayer times'),
      _document('note', 'note:one', 'notes', text: 'my personal note'),
    ]);
    var pending = overlay.nextPending()!;
    expect(pending.text, 'my personal note');
    overlay.finishEmbedding(pending.id);
    pending = overlay.nextPending()!;
    expect(pending.text, 'prayer times');
    overlay.finishEmbedding(pending.id);
    expect(overlay.nextPending()!.text, 'translation');
  });

  test(
    'vector limits keep the winning edition and chunk per canonical passage',
    () {
      overlay.upsert('translations', '1', [
        _document(
          'a-en',
          'quran:2:153',
          'quran',
          text: 'a-en',
          route: '/quran/2?ayah=153&translation=1',
        ),
        _document(
          'a-ur',
          'quran:2:153',
          'quran',
          text: 'a-ur',
          route: '/quran/2?ayah=153&translation=2',
        ),
        _document('b', 'quran:94:5', 'quran', text: 'b'),
        _document('c', 'quran:94:6', 'quran', text: 'c'),
      ]);
      while (true) {
        final pending = overlay.nextPending();
        if (pending == null) break;
        final score = {
          'a-en': 0.9,
          'a-ur': 0.8,
          'b': 0.7,
          'c': 0.6,
        }[pending.text]!;
        overlay.addVector(pending.id, 0, _vector(score));
        if (pending.text == 'a-ur') {
          overlay.addVector(pending.id, 1, _vector(0.95));
          overlay.addVector(pending.id, 2, _vector(0.2));
        }
        overlay.finishEmbedding(pending.id);
      }
      final scores = overlay.vectorScores(
        _vector(1),
        OfflineSearchFilter.quran,
        2,
      );
      final passages = overlay.passages(scores.keys);
      expect(passages.values.map((p) => p.canonicalId).toSet(), {
        'quran:2:153',
        'quran:94:5',
      });
      expect(passages[scores.keys.first]!.route, contains('translation=2'));
      expect(scores.values.first, closeTo(0.95, 0.00001));
    },
  );
}

Float32List _vector(double score) => Float32List(384)
  ..[0] = score
  ..[1] = math.sqrt(1 - score * score);

SearchDocument _document(
  String id,
  String canonical,
  String kind, {
  String reference = '',
  String route = '',
  String text = 'content',
  Map<String, String> metadata = const {},
}) => SearchDocument(
  id: id,
  text: text,
  passage: OfflineSearchPassage(
    canonicalId: canonical,
    kind: kind,
    reference: reference,
    title: id,
    arabic: '',
    translations: const [],
    grades: const [],
    route: route,
    metadata: metadata,
  ),
);
