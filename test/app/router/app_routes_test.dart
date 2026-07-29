import 'package:flutter_test/flutter_test.dart';
import 'package:quran/app/router/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('builds Quran reader path with optional ayah anchor', () {
      expect(AppRoutes.quranReaderPath(2), '/quran/2');
      expect(
        AppRoutes.quranReaderPath(2, ayahNumber: 255),
        '/quran/2?ayah=255',
      );
    });

    test('encodes Quran search query', () {
      expect(AppRoutes.quranSearchPath(), '/quran-search');
      expect(
        AppRoutes.quranSearchPath(' الرحمن الرحيم '),
        '/quran-search?query=%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86+%D8%A7%D9%84%D8%B1%D8%AD%D9%8A%D9%85',
      );
    });

    test('builds Quran quick action paths', () {
      expect(AppRoutes.quranDownloadsPath(), '/quran-downloads');
      expect(AppRoutes.quranBookmarksPath(), '/quran-bookmarks');
      expect(AppRoutes.quranNotesPath(), '/quran-notes');
      expect(
        AppRoutes.quranNotesPath(noteId: 'note 1'),
        '/quran-notes?note=note+1',
      );
      expect(AppRoutes.tasbiehPath(), '/tasbieh');
    });
  });
}
