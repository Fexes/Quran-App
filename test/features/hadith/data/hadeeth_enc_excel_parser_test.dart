import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/hadith/data/services/hadeeth_enc_excel_parser.dart';

void main() {
  group('HadeethEncExcelParser', () {
    test('parses shared string worksheet rows into hadith items', () {
      const sharedStrings = '''
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <si><t># Last update: 2025-11-29 10:11:26 (v1.24.0)</t></si>
  <si><t>id</t></si>
  <si><t>title_ar</t></si>
  <si><t>title</t></si>
  <si><t>hadith_text_ar</t></si>
  <si><t>hadith_text</t></si>
  <si><t>explanation_ar</t></si>
  <si><t>explanation</t></si>
  <si><t>benefits_ar</t></si>
  <si><t>benefits</t></si>
  <si><t>grade_ar</t></si>
  <si><t>takhrij_ar</t></si>
  <si><t>grade</t></si>
  <si><t>takhrij</t></si>
  <si><t>lang</t></si>
  <si><t>link</t></si>
  <si><t>إنما الأعمال بالنيات</t></si>
  <si><t>Actions are by intentions</t></si>
  <si><t>عَنْ عُمَرَ: إنما الأعمال بالنيات</t></si>
  <si><t>Narrated Umar: Actions are by intentions.</t></si>
  <si><t>شرح عربي</t></si>
  <si><t>Explanation text.</t></si>
  <si><t>فوائد</t></si>
  <si><t>Benefit one\\nBenefit two</t></si>
  <si><t>صحيح</t></si>
  <si><t>متفق عليه</t></si>
  <si><t>Authentic</t></si>
  <si><t>Agreed upon</t></si>
  <si><t>en</t></si>
  <si><t>https://hadeethenc.com/en/browse/hadith/1</t></si>
</sst>
''';
      const sheet = '''
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1"><c r="A1" t="s"><v>0</v></c></row>
    <row r="2">
      <c r="A2" t="s"><v>1</v></c><c r="B2" t="s"><v>2</v></c>
      <c r="C2" t="s"><v>3</v></c><c r="D2" t="s"><v>4</v></c>
      <c r="E2" t="s"><v>5</v></c><c r="F2" t="s"><v>6</v></c>
      <c r="G2" t="s"><v>7</v></c><c r="H2" t="s"><v>8</v></c>
      <c r="I2" t="s"><v>9</v></c><c r="J2" t="s"><v>10</v></c>
      <c r="K2" t="s"><v>11</v></c><c r="L2" t="s"><v>12</v></c>
      <c r="M2" t="s"><v>13</v></c><c r="N2" t="s"><v>14</v></c>
      <c r="O2" t="s"><v>15</v></c>
    </row>
    <row r="3">
      <c r="A3"><v>1</v></c><c r="B3" t="s"><v>16</v></c>
      <c r="C3" t="s"><v>17</v></c><c r="D3" t="s"><v>18</v></c>
      <c r="E3" t="s"><v>19</v></c><c r="F3" t="s"><v>20</v></c>
      <c r="G3" t="s"><v>21</v></c><c r="H3" t="s"><v>22</v></c>
      <c r="I3" t="s"><v>23</v></c><c r="J3" t="s"><v>24</v></c>
      <c r="K3" t="s"><v>25</v></c><c r="L3" t="s"><v>26</v></c>
      <c r="M3" t="s"><v>27</v></c><c r="N3" t="s"><v>28</v></c>
      <c r="O3" t="s"><v>29</v></c>
    </row>
  </sheetData>
</worksheet>
''';

      final result = HadeethEncExcelParser.parseWorksheetXml(
        sharedStringsXml: sharedStrings,
        sheetXml: sheet,
        languageCode: 'en',
      );

      expect(result.version, 'v1.24.0');
      expect(result.items, hasLength(1));
      expect(result.items.single.id, '1');
      expect(result.items.single.title, 'Actions are by intentions');
      expect(result.items.single.hadithText, contains('Narrated Umar'));
      expect(result.items.single.benefits, ['Benefit one', 'Benefit two']);
      expect(result.items.single.grade, 'Authentic');
      expect(result.items.single.languageCode, 'en');
    });
  });
}
