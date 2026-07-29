import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/hadeeth_enc_item.dart';

class HadeethEncExcelParser {
  const HadeethEncExcelParser._();

  static HadeethEncImportResult parseXlsx({
    required Uint8List bytes,
    required String languageCode,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final shared = archive.findFile('xl/sharedStrings.xml');
    final sheet = archive.findFile('xl/worksheets/sheet1.xml');
    if (shared == null || sheet == null) {
      return HadeethEncImportResult(
        languageCode: languageCode,
        version: '',
        items: const [],
      );
    }
    return parseWorksheetXml(
      sharedStringsXml: utf8.decode(shared.content as List<int>),
      sheetXml: utf8.decode(sheet.content as List<int>),
      languageCode: languageCode,
    );
  }

  static HadeethEncImportResult parseWorksheetXml({
    required String sharedStringsXml,
    required String sheetXml,
    required String languageCode,
  }) {
    final shared = _sharedStrings(sharedStringsXml);
    final version = _versionFrom(shared.isEmpty ? '' : shared.first);
    final rows = _rows(sheetXml, shared);
    if (rows.length < 2) {
      return HadeethEncImportResult(
        languageCode: languageCode,
        version: version,
        items: const [],
      );
    }

    final header = {
      for (final entry in rows[1].entries) entry.value.trim(): entry.key,
    };
    final items = <HadeethEncItem>[];
    for (final row in rows.skip(2)) {
      final id = row[header['id'] ?? -1]?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      final item = HadeethEncItem(
        id: id,
        languageCode: languageCode,
        title: row[header['title'] ?? -1] ?? '',
        titleArabic: row[header['title_ar'] ?? -1] ?? '',
        hadithText: row[header['hadith_text'] ?? -1] ?? '',
        hadithTextArabic: row[header['hadith_text_ar'] ?? -1] ?? '',
        explanation: row[header['explanation'] ?? -1] ?? '',
        explanationArabic: row[header['explanation_ar'] ?? -1] ?? '',
        benefits: _lines(row[header['benefits'] ?? -1]),
        benefitsArabic: _lines(row[header['benefits_ar'] ?? -1]),
        grade: row[header['grade'] ?? -1] ?? '',
        gradeArabic: row[header['grade_ar'] ?? -1] ?? '',
        attribution: row[header['takhrij'] ?? -1] ?? '',
        attributionArabic: row[header['takhrij_ar'] ?? -1] ?? '',
        link: row[header['link'] ?? -1] ?? '',
      );
      if (item.hadithText.trim().isNotEmpty ||
          item.hadithTextArabic.trim().isNotEmpty) {
        items.add(item);
      }
    }
    return HadeethEncImportResult(
      languageCode: languageCode,
      version: version,
      items: List.unmodifiable(items),
    );
  }

  static List<String> _sharedStrings(String xml) {
    final document = XmlDocument.parse(xml);
    return [
      for (final item in document.findAllElements('si'))
        item.findAllElements('t').map((node) => node.innerText).join(),
    ];
  }

  static List<Map<int, String>> _rows(String xml, List<String> shared) {
    final document = XmlDocument.parse(xml);
    return [
      for (final row in document.findAllElements('row')) _row(row, shared),
    ];
  }

  static Map<int, String> _row(XmlElement row, List<String> shared) {
    final cells = <int, String>{};
    for (final cell in row.findElements('c')) {
      final ref = cell.getAttribute('r') ?? '';
      final index = _columnIndex(ref);
      if (index < 0) {
        continue;
      }
      final value = cell.findElements('v').firstOrNull?.innerText ?? '';
      if (cell.getAttribute('t') == 's') {
        final sharedIndex = int.tryParse(value);
        if (sharedIndex != null &&
            sharedIndex >= 0 &&
            sharedIndex < shared.length) {
          cells[index] = shared[sharedIndex].trim();
        }
      } else {
        cells[index] = value.trim();
      }
    }
    return cells;
  }

  static int _columnIndex(String ref) {
    final letters = RegExp(r'^[A-Z]+').stringMatch(ref);
    if (letters == null || letters.isEmpty) {
      return -1;
    }
    var index = 0;
    for (final unit in letters.codeUnits) {
      index = (index * 26) + (unit - 64);
    }
    return index - 1;
  }

  static String _versionFrom(String text) {
    final match = RegExp(r'\(v[^)]+\)').firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[()]'), '') ?? '';
  }

  static List<String> _lines(String? text) {
    return (text ?? '')
        .split(RegExp(r'\\n|\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
