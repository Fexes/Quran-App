import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/search/e5_tokenizer.dart';
import 'package:quran/core/search/offline_search_normalizer.dart';

void main() {
  group('OfflineSearchNormalizer', () {
    test('semantic keeps Arabic, Urdu, case, and combining characters', () {
      const input = '  اَللّٰهُ\u00a0کے\u2009بارے\nCafé e\u0301  ';
      expect(
        OfflineSearchNormalizer.semantic(input),
        'اَللّٰهُ کے بارے Café e\u0301',
      );
      expect(
        OfflineSearchNormalizer.semantic(' \ufeffسلام\u001c '),
        '\ufeffسلام\u001c',
      );
    });

    test('semantic collapses the shared Unicode whitespace class', () {
      const whitespace =
          '\u0009\u000a\u000b\u000c\u000d\u0020\u0085\u00a0\u1680'
          '\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008'
          '\u2009\u200a\u2028\u2029\u202f\u205f\u3000';
      expect(
        OfflineSearchNormalizer.semantic('${whitespace}a${whitespace}b'),
        'a b',
      );
    });

    test('keyword folds only the specified Arabic variants and marks', () {
      expect(
        OfflineSearchNormalizer.keyword('آ أ إ ٱ ى ی ک اَللّٰهُ ـ ء ؤ ئ ة'),
        'ا ا ا ا ي ي ك الله ء ؤ ئ ة',
      );
      final removed = String.fromCharCodes([
        for (var c = 0x0610; c <= 0x061a; c++) c,
        for (var c = 0x064b; c <= 0x065f; c++) c,
        0x0670,
        for (var c = 0x06d6; c <= 0x06ed; c++) c,
        0x0640,
      ]);
      expect(OfflineSearchNormalizer.keyword('ا$removedب'), 'اب');
    });

    test('keyword uses NFKC and preserves letters, numbers, and marks', () {
      expect(
        OfflineSearchNormalizer.keyword('Ｆａｉｔｈ—Café…१२३،한글!🙂'),
        'faith café १२३ 한글',
      );
      expect(OfflineSearchNormalizer.keyword('e\u0301 भक्त'), 'é भक्त');
      expect(OfflineSearchNormalizer.keyword('﴿الإِيمَانُ﴾'), 'الايمان');
      expect(
        OfflineSearchNormalizer.keyword('İSTANBUL ΟΣ AΣa'),
        'i\u0307stanbul ος aσa',
      );
    });

    test('reference maps both digit alphabets and preserves separators', () {
      expect(
        OfflineSearchNormalizer.reference('  QURAN\u00a0٢:۲۵۵  '),
        'quran 2:255',
      );
      expect(OfflineSearchNormalizer.reference('Bukhari ۱/٠'), 'bukhari 1/0');
      expect(OfflineSearchNormalizer.reference('٢  :  ۲۵۵'), '2:255');
    });
  });

  group('E5Tokenizer', () {
    late E5Tokenizer tokenizer;

    setUpAll(() {
      tokenizer = E5Tokenizer.fromFile('assets/offline_search/tokenizer.json');
    });

    test('matches the pinned Hugging Face tokenizer on every golden case', () {
      final golden =
          jsonDecode(
                File(
                  'test/fixtures/offline_search/tokenizer_parity.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final fixtures = golden['cases'] as List<dynamic>;
      expect(golden['model_id'], 'intfloat/multilingual-e5-small');
      expect(
        golden['model_revision'],
        '614241f622f53c4eeff9890bdc4f31cfecc418b3',
      );
      expect(fixtures, isNotEmpty);
      for (final raw in fixtures) {
        final fixture = raw as Map<String, dynamic>;
        final input = fixture['input'] as String;
        final kind = fixture['kind'] as String;
        final actual = kind == 'query'
            ? tokenizer.encodeQuery(input)
            : tokenizer.encodePassage(input);
        final reason =
            'Hugging Face parity for $kind: '
            '${input.length > 120 ? input.substring(0, 120) : input}';
        expect(actual.inputIds, fixture['input_ids'], reason: reason);
        expect(actual.attentionMask, fixture['attention_mask'], reason: reason);
        expect(actual.tokenTypeIds, fixture['token_type_ids'], reason: reason);
        expect(actual.length, lessThanOrEqualTo(E5Tokenizer.maxLength));
        expect(actual.inputIds, isA<Int64List>());
        expect(actual.attentionMask, isA<Int64List>());
        expect(actual.tokenTypeIds, isA<Int64List>());
      }
    });

    test('adds distinct query and passage prefixes even for empty text', () {
      final query = tokenizer.encodeQuery(' \n\u00a0 ');
      final passage = tokenizer.encodePassage('');
      expect(query.inputIds, isNot(equals(passage.inputIds)));
      expect(query.length, greaterThan(2));
      expect(query.attentionMask, everyElement(1));
      expect(query.tokenTypeIds, everyElement(0));
    });

    test('local passage windows match build-time Hugging Face token IDs', () {
      final golden =
          jsonDecode(
                File(
                  'test/fixtures/offline_search/passage_chunks.json',
                ).readAsStringSync(),
              )
              as Map;
      for (final item in golden['cases'] as List) {
        final actual = tokenizer
            .encodePassageChunks(item['text'] as String)
            .map((c) => c.inputIds.toList())
            .toList();
        expect(actual, item['chunks']);
      }
    });

    test(
      'very long local documents retain tail content in bounded windows',
      () {
        final text = '${List.filled(3000, 'journey').join(' ')} FINALMARKER';
        final chunks = tokenizer.encodePassageChunks(text).toList();
        expect(chunks.length, greaterThan(2));
        expect(chunks.every((c) => c.length <= 512), isTrue);
        final tail = tokenizer.encodePassage('FINALMARKER').inputIds;
        expect(
          chunks.last.inputIds.toList().join(','),
          contains(tail.sublist(3, tail.length - 1).join(',')),
        );
      },
    );

    test('truncates long content while retaining both special tokens', () {
      final short = tokenizer.encodeQuery('patience');
      final long = tokenizer.encodeQuery(
        List.filled(1200, 'patience').join(' '),
      );
      expect(long.length, E5Tokenizer.maxLength);
      expect(long.inputIds.first, short.inputIds.first);
      expect(long.inputIds.last, short.inputIds.last);
      expect(long.attentionMask, everyElement(1));
      expect(long.tokenTypeIds, everyElement(0));
    });
  });
}
