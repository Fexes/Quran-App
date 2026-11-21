import 'offline_search_result.dart';

/// One searchable representation. Multiple languages can share a canonical ID.
class SearchDocument {
  const SearchDocument({
    required this.id,
    required this.passage,
    required this.text,
    this.language = 'und',
  });

  final String id;
  final OfflineSearchPassage passage;
  final String text;
  final String language;
}

/// A complete, bounded-batch snapshot of one locally available source.
/// Stable IDs support updates; missing IDs are removed after successful sync.
abstract interface class SearchContentSource {
  String get id;
  String get revision;
  Stream<List<SearchDocument>> documents();
}
