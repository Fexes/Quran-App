import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran/domain/entities/surah_image_catalog.dart';

void main() {
  test('surah image catalog maps valid and invalid surah numbers safely', () {
    expect(
      SurahImageCatalog.imageUrlFor(1),
      'http://coreinfinite.tech/quran_cover/cover_1.jpeg',
    );
    expect(
      SurahImageCatalog.imageUrlFor(114),
      'http://coreinfinite.tech/quran_cover/cover_114.jpeg',
    );
    expect(
      SurahImageCatalog.imageUrlFor(0),
      'http://coreinfinite.tech/quran_cover/cover_1.jpeg',
    );
    expect(
      SurahImageCatalog.imageUrlFor(999),
      'http://coreinfinite.tech/quran_cover/cover_114.jpeg',
    );
  });

  test('surah image manifest covers every surah once with server URLs', () {
    final manifestFile = File('assets/data/surah_image_attributions.json');
    expect(manifestFile.existsSync(), true);

    final entries = (jsonDecode(manifestFile.readAsStringSync()) as List)
        .cast<Map<String, Object?>>();
    expect(entries.length, 114);

    final numbers = <int>{};
    final sourceUrls = <String>{};
    for (final entry in entries) {
      final surahNumber = entry['surahNumber']! as int;
      final assetPath = entry['assetPath']! as String;

      expect(numbers.add(surahNumber), true);
      expect(sourceUrls.add(assetPath), true);
      expect(assetPath, SurahImageCatalog.imageUrlFor(surahNumber));
      expect(Uri.parse(assetPath).hasScheme, true);
    }

    expect(numbers, {for (var i = 1; i <= 114; i++) i});
  });
}
