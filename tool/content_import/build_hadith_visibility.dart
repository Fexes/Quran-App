import 'dart:convert';
import 'dart:io';

import 'package:quran/features/hadith/domain/entities/hadith_item.dart';
import 'package:quran/features/hadith/domain/services/hadith_authenticity_policy.dart';

// Run after importing books. Uses the reader's text-availability policy,
// including weak, disputed, and ungraded records. Visibility is not a grading.
void main() {
  final directory = Directory('assets/data/hadith/books');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final books = <String, Object>{};
  for (final file in files) {
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final items = (data['hadiths'] as List)
        .map((raw) => HadithItem.fromMap(raw as Map<String, dynamic>))
        .where(HadithAuthenticityPolicy.shouldShow)
        .toList();
    final slug = file.uri.pathSegments.last.replaceAll('.json', '');
    books[slug] = {
      'ids': items.map((item) => item.id).toList(),
      'hadithCount': items.length,
      'chapterCount': items.map((item) => item.chapterId).toSet().length,
    };
  }
  File('assets/data/hadith/visibility.json').writeAsStringSync(
    jsonEncode({
      'version': 2,
      'policy': 'nonempty-arabic-or-translation',
      'books': books,
    }),
  );
  stdout.writeln('Updated visibility for ${books.length} books.');
}
