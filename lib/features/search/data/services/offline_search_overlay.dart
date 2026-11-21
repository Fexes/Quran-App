import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../core/search/offline_search_normalizer.dart';
import '../../../../core/search/search_query_terms.dart';
import '../../domain/entities/offline_search_result.dart';
import '../../domain/entities/search_document.dart';
import 'search_passage_codec.dart';

/// Persistent private index for downloads and user-created material.
/// FTS changes become visible before background embedding work finishes.
class OfflineSearchOverlay {
  OfflineSearchOverlay(String path, String modelIdentity)
    : _db = sqlite3.open(path) {
    try {
      _db.execute('PRAGMA journal_mode=WAL');
      _db.execute('PRAGMA foreign_keys=ON');
      _db.execute('PRAGMA cache_size=-2048');
      final hadAliases = _db
          .select(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='reference_aliases'",
          )
          .isNotEmpty;
      _db.execute('''
      CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS docs(
        id INTEGER PRIMARY KEY AUTOINCREMENT, source TEXT NOT NULL, document_id TEXT NOT NULL,
        canonical_id TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL,
        text TEXT NOT NULL, language TEXT NOT NULL, fingerprint TEXT NOT NULL,
        seen TEXT NOT NULL, embedded INTEGER NOT NULL DEFAULT 0,
        UNIQUE(source,document_id));
      CREATE INDEX IF NOT EXISTS docs_canonical ON docs(canonical_id);
      CREATE INDEX IF NOT EXISTS docs_pending ON docs(embedded,id);
      CREATE INDEX IF NOT EXISTS docs_pending_priority ON docs(
        embedded,
        CASE kind WHEN 'notes' THEN 0 WHEN 'tools' THEN 1 WHEN 'tool' THEN 1
          WHEN 'widget' THEN 1 WHEN 'saved' THEN 2 WHEN 'timings' THEN 3 ELSE 4 END,
        length(text),id);
      CREATE VIRTUAL TABLE IF NOT EXISTS docs_fts USING fts5(
        body, tokenize='unicode61 remove_diacritics 2', prefix='2 3 4');
      CREATE TABLE IF NOT EXISTS vectors(
        id INTEGER PRIMARY KEY, document_id INTEGER NOT NULL REFERENCES docs(id) ON DELETE CASCADE,
        chunk INTEGER NOT NULL, embedding BLOB NOT NULL CHECK(length(embedding)=1536));
      CREATE INDEX IF NOT EXISTS vectors_document ON vectors(document_id);
      CREATE TABLE IF NOT EXISTS reference_aliases(
        alias TEXT NOT NULL,
        document_id INTEGER NOT NULL REFERENCES docs(id) ON DELETE CASCADE,
        PRIMARY KEY(alias,document_id));
      CREATE INDEX IF NOT EXISTS aliases_document ON reference_aliases(document_id);
    ''');
      _backfillReferenceAliases(force: !hadAliases);
      final identity = _db.select("SELECT value FROM meta WHERE key='model'");
      if (identity.isEmpty || identity.first['value'] != modelIdentity) {
        _db.execute('DELETE FROM vectors');
        _db.execute('UPDATE docs SET embedded=0');
        _db.execute("INSERT OR REPLACE INTO meta VALUES ('model',?)", [
          modelIdentity,
        ]);
      }
    } catch (_) {
      _db.close();
      rethrow;
    }
  }

  final Database _db;

  void _backfillReferenceAliases({bool force = false}) {
    final version = _db.select(
      "SELECT value FROM meta WHERE key='reference_aliases_version'",
    );
    if (!force && version.isNotEmpty && version.first['value'] == '1') return;
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute('DELETE FROM reference_aliases');
      var lastId = 0;
      while (true) {
        final rows = _db.select(
          'SELECT id,payload FROM docs WHERE id>? ORDER BY id LIMIT 128',
          [lastId],
        );
        if (rows.isEmpty) break;
        for (final row in rows) {
          lastId = row['id'] as int;
          _insertAliases(
            lastId,
            decodePassage(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ),
          );
        }
      }
      _db.execute(
        "INSERT OR REPLACE INTO meta VALUES ('reference_aliases_version','1')",
      );
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void _insertAliases(int id, OfflineSearchPassage passage) {
    for (final alias in _aliasesFor(passage)) {
      _db.execute(
        'INSERT OR IGNORE INTO reference_aliases(alias,document_id) VALUES (?,?)',
        [alias, id],
      );
    }
  }

  static final _quranReferencePattern = RegExp(
    r'^(?:quran[: ]*)?(\d{1,3}):(\d{1,3})$',
  );
  static final _hadithCanonicalPattern = RegExp(
    r'^hadith:[a-z0-9_-]+:[0-9]+[a-z]?$',
  );
  static final _hadeethEncCanonicalPattern = RegExp(
    r'^hadeethenc:[a-z0-9_-]+$',
  );

  static Set<String> _quranAliases(String value) {
    final match = _quranReferencePattern.firstMatch(
      OfflineSearchNormalizer.reference(value),
    );
    if (match == null) return const {};
    final surah = int.parse(match[1]!);
    final ayah = int.parse(match[2]!);
    if (surah < 1 || surah > 114 || ayah < 1 || ayah > 286) return const {};
    return {'$surah:$ayah', 'quran:$surah:$ayah', 'quran $surah:$ayah'};
  }

  static Set<String> _aliasesFor(OfflineSearchPassage passage) {
    final isHadithTarget =
        passage.kind == 'hadith' ||
        passage.canonicalId.startsWith('hadith:') ||
        passage.route.startsWith('/library/hadith/');
    final aliases = <String>{
      OfflineSearchNormalizer.reference(passage.canonicalId),
    };
    void addVerse(String? value) {
      if (value == null || isHadithTarget) return;
      aliases.addAll(_quranAliases(value));
    }

    void addTarget(String? value) {
      if (value == null) return;
      final normalized = OfflineSearchNormalizer.reference(value);
      addVerse(normalized);
      // Human Hadith labels can use chapter-local numbering. Only canonical
      // identifiers are safe; the bundled index resolves human book aliases.
      if (_hadithCanonicalPattern.hasMatch(normalized) ||
          _hadeethEncCanonicalPattern.hasMatch(normalized)) {
        aliases.add(normalized);
      }
    }

    addTarget(passage.canonicalId);
    addTarget(passage.itemId);
    addVerse(passage.reference);
    if (passage.surahNumber != null && passage.ayahNumber != null) {
      addVerse('${passage.surahNumber}:${passage.ayahNumber}');
    }
    for (final key in const [
      'verseKey',
      'reference',
      'canonicalId',
      'sourceCanonicalId',
      'targetCanonicalId',
      'itemId',
      'sourceItemId',
    ]) {
      addTarget(passage.metadata[key]);
    }
    final route = Uri.tryParse(passage.route);
    if (route != null && !route.hasScheme && !route.hasAuthority) {
      final parts = route.pathSegments;
      if (parts.length == 2 && parts[0] == 'quran') {
        addVerse('${parts[1]}:${route.queryParameters['ayah'] ?? ''}');
      } else if (parts.length == 3 &&
          parts[0] == 'library' &&
          parts[1] == 'hadith') {
        addTarget(
          'hadith:${parts[2]}:${route.queryParameters['hadith'] ?? ''}',
        );
      }
    }
    aliases.remove('');
    return aliases;
  }

  List<OfflineSearchPassage> exactReferences(
    String query,
    OfflineSearchFilter filter, {
    Iterable<String> canonicalIds = const [],
  }) {
    final aliases = {
      OfflineSearchNormalizer.reference(query),
      ..._quranAliases(query),
      for (final id in canonicalIds) OfflineSearchNormalizer.reference(id),
    }..remove('');
    if (aliases.isEmpty) return const [];
    final matches = <int, OfflineSearchPassage>{};
    final values = aliases.toList();
    for (var start = 0; start < values.length; start += 400) {
      final batch = values.sublist(
        start,
        (start + 400).clamp(0, values.length),
      );
      for (final row in _db.select(
        'SELECT DISTINCT d.id,d.payload FROM reference_aliases a JOIN docs d ON d.id=a.document_id '
        'WHERE a.alias IN (${List.filled(batch.length, '?').join(',')})${_filterClause(filter)} '
        'ORDER BY d.canonical_id,d.id',
        [...batch, ..._filterParameters(filter)],
      )) {
        matches[row['id'] as int] = decodePassage(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        );
      }
    }
    final entries = matches.entries.toList()
      ..sort((a, b) {
        final canonical = a.value.canonicalId.compareTo(b.value.canonicalId);
        return canonical == 0 ? a.key.compareTo(b.key) : canonical;
      });
    return [for (final entry in entries) entry.value];
  }

  void upsert(String source, String revision, List<SearchDocument> documents) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute('DELETE FROM meta WHERE key=?', ['completed_source:$source']);
      for (final document in documents) {
        if (document.id.isEmpty || document.passage.canonicalId.isEmpty) {
          throw const FormatException('Search documents require stable IDs.');
        }
        final payload = jsonEncode(encodePassage(document.passage));
        final fingerprint = sha256
            .convert(
              utf8.encode(
                '${document.language}\u0000${document.text}\u0000$payload',
              ),
            )
            .toString();
        final old = _db.select(
          'SELECT id,fingerprint FROM docs WHERE source=? AND document_id=?',
          [source, document.id],
        );
        if (old.isNotEmpty && old.first['fingerprint'] == fingerprint) {
          _db.execute('UPDATE docs SET seen=? WHERE id=?', [
            revision,
            old.first['id'],
          ]);
          continue;
        }
        if (old.isNotEmpty) _remove(old.first['id'] as int);
        _db.execute(
          'INSERT INTO docs(source,document_id,canonical_id,kind,payload,text,language,fingerprint,seen) VALUES (?,?,?,?,?,?,?,?,?)',
          [
            source,
            document.id,
            document.passage.canonicalId,
            document.passage.kind,
            payload,
            document.text,
            document.language,
            fingerprint,
            revision,
          ],
        );
        final id = _db.lastInsertRowId;
        _db.execute('INSERT INTO docs_fts(rowid,body) VALUES (?,?)', [
          id,
          OfflineSearchNormalizer.keyword(
            '${document.passage.title} ${document.passage.reference} ${document.text}',
          ),
        ]);
        _insertAliases(id, document.passage);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  Map<String, String> get completedSourceRevisions => {
    for (final row in _db.select(
      "SELECT key,value FROM meta WHERE key LIKE 'completed_source:%'",
    ))
      (row['key'] as String).substring('completed_source:'.length):
          row['value'] as String,
  };

  void finish(String source, String revision, {String? completedRevision}) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      for (final row in _db.select(
        'SELECT id FROM docs WHERE source=? AND seen<>?',
        [source, revision],
      )) {
        _remove(row['id'] as int);
      }
      _db.execute('INSERT OR REPLACE INTO meta VALUES (?,?)', [
        'source:$source',
        revision,
      ]);
      if (completedRevision != null) {
        _db.execute('INSERT OR REPLACE INTO meta VALUES (?,?)', [
          'completed_source:$source',
          completedRevision,
        ]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void _remove(int id) {
    _db.execute('DELETE FROM docs_fts WHERE rowid=?', [id]);
    _db.execute('DELETE FROM docs WHERE id=?', [id]);
  }

  int get pendingDocuments =>
      _db.select('SELECT count(*) AS n FROM docs WHERE embedded=0').first['n']
          as int;

  ({int id, String text})? nextPending() {
    final rows = _db.select(
      "SELECT id,text FROM docs WHERE embedded=0 ORDER BY "
      "CASE kind WHEN 'notes' THEN 0 WHEN 'tools' THEN 1 WHEN 'tool' THEN 1 "
      "WHEN 'widget' THEN 1 WHEN 'saved' THEN 2 WHEN 'timings' THEN 3 ELSE 4 END,"
      'length(text),id LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return (id: rows.first['id'] as int, text: rows.first['text'] as String);
  }

  bool exists(int id) =>
      _db.select('SELECT id FROM docs WHERE id=?', [id]).isNotEmpty;

  void startEmbedding(int id) =>
      _db.execute('DELETE FROM vectors WHERE document_id=?', [id]);

  void addVector(int id, int chunk, Float32List vector) {
    if (!exists(id)) return;
    final bytes = ByteData(384 * 4);
    for (var i = 0; i < 384; i++) {
      bytes.setFloat32(i * 4, vector[i], Endian.little);
    }
    _db.execute(
      'INSERT INTO vectors(document_id,chunk,embedding) VALUES (?,?,?)',
      [id, chunk, bytes.buffer.asUint8List()],
    );
  }

  void finishEmbedding(int id) =>
      _db.execute('UPDATE docs SET embedded=1 WHERE id=?', [id]);

  Map<int, double> keywordScores(
    String query,
    OfflineSearchFilter filter,
    int limit,
  ) {
    if (limit < 1) return const {};
    final expressions = SearchQueryTerms.analyze(
      query,
    ).expressionsFor(filter.name);
    final scores = <int, double>{};
    final canonicalIds = <String>{};
    for (final expression in expressions) {
      final statement = _db.prepare(
        'SELECT d.id,d.canonical_id,bm25(docs_fts) AS score FROM docs_fts JOIN docs d ON d.id=docs_fts.rowid '
        'WHERE docs_fts MATCH ?${_filterClause(filter)} ORDER BY score,d.canonical_id,d.id',
      );
      try {
        final cursor = statement.selectCursor([
          expression,
          ..._filterParameters(filter),
        ]);
        // Collapse editions before the limit, across both retrieval expressions.
        while (scores.length < limit && cursor.moveNext()) {
          final row = cursor.current;
          if (!canonicalIds.add(row['canonical_id'] as String)) continue;
          scores[row['id'] as int] = -(row['score'] as num).toDouble();
        }
      } finally {
        statement.close();
      }
      if (scores.length >= limit) break;
    }
    return scores;
  }

  Map<int, double> vectorScores(
    Float32List query,
    OfflineSearchFilter filter,
    int limit,
  ) {
    if (query.length != 384 || query.any((value) => !value.isFinite)) {
      throw const FormatException('Invalid query vector.');
    }
    if (limit < 1) return const {};
    final top = <String, ({int id, double score})>{};
    var last = 0;
    String? minimumCanonical;
    var minimumScore = double.negativeInfinity;
    while (true) {
      final rows = _db.select(
        'SELECT v.id,v.document_id,v.embedding,d.canonical_id FROM vectors v CROSS JOIN docs d ON d.id=v.document_id '
        'WHERE v.id>? AND d.embedded=1${_filterClause(filter)} ORDER BY v.id LIMIT 256',
        [last, ..._filterParameters(filter)],
      );
      if (rows.isEmpty) break;
      for (final row in rows) {
        last = row['id'] as int;
        final id = row['document_id'] as int;
        final canonicalId = row['canonical_id'] as String;
        final bytes = row['embedding'] as Uint8List;
        if (bytes.length != 384 * 4) {
          throw const FormatException('Corrupt passage vector.');
        }
        final data = ByteData.sublistView(bytes);
        var score = 0.0;
        for (var i = 0; i < 384; i++) {
          score += query[i] * data.getFloat32(i * 4, Endian.little);
        }
        if (!score.isFinite) {
          throw const FormatException('Corrupt vector values.');
        }
        final previous = top[canonicalId];
        if (previous != null &&
            (score < previous.score ||
                (score == previous.score && id >= previous.id))) {
          continue;
        }
        if (previous == null && top.length >= limit) {
          if (score < minimumScore ||
              (score == minimumScore &&
                  canonicalId.compareTo(minimumCanonical!) > 0)) {
            continue;
          }
          top.remove(minimumCanonical);
        }
        top[canonicalId] = (id: id, score: score);
        if (top.length == limit) {
          final worst = top.entries.reduce((a, b) {
            final order = a.value.score.compareTo(b.value.score);
            return order < 0 || (order == 0 && a.key.compareTo(b.key) > 0)
                ? a
                : b;
          });
          minimumCanonical = worst.key;
          minimumScore = worst.value.score;
        }
      }
    }
    final ranked = top.entries.toList()
      ..sort((a, b) {
        final score = b.value.score.compareTo(a.value.score);
        return score == 0 ? a.key.compareTo(b.key) : score;
      });
    return {for (final entry in ranked) entry.value.id: entry.value.score};
  }

  Map<int, OfflineSearchPassage> passages(Iterable<int> ids) {
    final list = ids.toSet().toList();
    if (list.isEmpty) return {};
    return {
      for (final row in _db.select(
        'SELECT id,payload FROM docs WHERE id IN (${List.filled(list.length, '?').join(',')})',
        list,
      ))
        row['id'] as int: decodePassage(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        ),
    };
  }

  List<OfflineSearchPassage> variants(String canonicalId) => [
    for (final row in _db.select(
      'SELECT payload FROM docs WHERE canonical_id=?',
      [canonicalId],
    ))
      decodePassage(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      ),
  ];

  static String _filterClause(OfflineSearchFilter filter) => switch (filter) {
    OfflineSearchFilter.all => '',
    OfflineSearchFilter.tools =>
      " AND d.kind IN ('tools','tool','widget','divine_name','surah')",
    _ => ' AND d.kind=?',
  };
  static List<String> _filterParameters(OfflineSearchFilter filter) =>
      filter == OfflineSearchFilter.all || filter == OfflineSearchFilter.tools
      ? []
      : [filter.name];

  void dispose() => _db.close();
}
