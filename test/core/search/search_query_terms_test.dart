import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/search/offline_search_normalizer.dart';
import 'package:quran/core/search/search_query_terms.dart';

void main() {
  group('keyword plans', () {
    test(
      'recognizes multilingual paraphrases without changing source input',
      () {
        const questions = [
          'I am worried about my mother',
          'مجھے اپنی ماں کی فکر ہے',
          'mujhe apni ammi ki pareshani hai',
          'أنا قلق على أمي',
        ];
        for (final question in questions) {
          final semantic = OfflineSearchNormalizer.semantic(question);
          final terms = SearchQueryTerms.keywords(question);
          expect(terms, containsAll(['worry', 'parents', 'خوف']));
          expect(OfflineSearchNormalizer.semantic(question), semantic);
          expect(terms.length, lessThanOrEqualTo(24));
          expect(terms.toSet(), hasLength(terms.length));
        }
      },
    );

    test('includes common inflections and Roman Urdu spellings', () {
      for (final query in [
        'worried',
        'worries',
        'پریشانی',
        'پریشان',
        'فکر',
        'fikar',
        'pareshan',
        'pareshaan',
        'pareshani',
        'pareshaani',
      ]) {
        expect(SearchQueryTerms.keywords(query), contains('worry'));
      }
      expect(
        SearchQueryTerms.keywords('sabar aur shukar'),
        containsAll(['patience', 'grateful']),
      );
      expect(
        SearchQueryTerms.keywords('qarz ki dua'),
        containsAll(['debt', 'supplication']),
      );
      expect(
        SearchQueryTerms.keywords('أشعر بالقلق بشأن مستقبلي'),
        contains('worry'),
      );
      expect(SearchQueryTerms.keywords('apne apni apna'), isEmpty);
    });

    test('does not expand or retain common grammar words', () {
      for (final query in [
        'ki hai hain ke ko',
        'کی ہے ہیں کے کو',
        'what is it and how',
        'في من إلى هذا هل',
      ]) {
        expect(SearchQueryTerms.keywords(query), isEmpty);
        expect(
          SearchQueryTerms.lexicalCoverage(
            query,
            'king hair kindness الكيل كتب',
          ),
          0,
        );
      }
    });

    test('is deterministic and bounded for many repeated topics', () {
      final query = List.filled(
        80,
        'parents prayer charity fasting illness travel notes downloads',
      ).join(' ');
      final terms = SearchQueryTerms.keywords(query);
      expect(terms.length, lessThanOrEqualTo(SearchQueryTerms.maxKeywords));
      expect(terms, SearchQueryTerms.keywords(query));
      expect(terms, containsAll(['parents', 'prayer', 'charity', 'notes']));
      expect(
        terms.every((term) => term == OfflineSearchNormalizer.keyword(term)),
        isTrue,
      );
    });

    test('preserves informative words outside the vocabulary', () {
      expect(SearchQueryTerms.keywords('Please find Zanzibar textiles'), [
        'zanzibar',
        'textiles',
      ]);
      expect(
        SearchQueryTerms.lexicalCoverage(
          'Zanzibar textiles',
          'Textiles from Zanzibar',
        ),
        1,
      );
    });

    test('reserves every topic before spending the expansion budget', () {
      const topics = [
        'parents',
        'prayer',
        'charity',
        'fasting',
        'illness',
        'travel',
        'notes',
        'downloads',
        'hope',
        'debt',
        'forgiveness',
        'repentance',
        'gratitude',
        'family',
        'hajj',
        'zakat',
      ];
      final terms = SearchQueryTerms.keywords(topics.join(' '));
      expect(terms, containsAll(topics));
      expect(terms.length, lessThanOrEqualTo(24));
    });
  });

  group('concept coverage', () {
    test('counts a topic once across repetitions and synonyms', () {
      expect(
        SearchQueryTerms.lexicalCoverage('worried anxiety worry', 'پریشانی'),
        1,
      );
      expect(
        SearchQueryTerms.lexicalCoverage(
          'worried about my parents',
          'Honour your mother and father',
        ),
        0.5,
      );
      expect(
        SearchQueryTerms.lexicalCoverage(
          'worried about my parents',
          'فکر اور والدین',
        ),
        1,
      );
      expect(
        SearchQueryTerms.lexicalCoverage(
          'worried about my parents',
          'My and about the or',
        ),
        0,
      );
    });

    test('matches whole words and phrases, not misleading substrings', () {
      expect(SearchQueryTerms.lexicalCoverage('debt', 'debtscape'), 0);
      expect(SearchQueryTerms.lexicalCoverage('illness', 'willingness'), 0);
      expect(SearchQueryTerms.lexicalCoverage('calm down', 'سَكِينَة'), 1);
      expect(SearchQueryTerms.lexicalCoverage('calm down', 'طمأنينة'), 1);
      expect(
        SearchQueryTerms.lexicalCoverage(
          'calm down',
          'calm weather farther down the valley',
        ),
        0,
      );
      expect(
        SearchQueryTerms.lexicalCoverage('kindness', 'what kind of book'),
        0,
      );
      expect(SearchQueryTerms.lexicalCoverage('debt', 'الدين'), 0);
    });

    test('keeps related but different religious and app concepts separate', () {
      expect(SearchQueryTerms.lexicalCoverage('zakat', 'general charity'), 0);
      expect(SearchQueryTerms.lexicalCoverage('prayer', 'supplication'), 0);
      expect(SearchQueryTerms.lexicalCoverage('hajj', 'umrah'), 0);
      expect(SearchQueryTerms.lexicalCoverage('fonts', 'language settings'), 0);
      expect(SearchQueryTerms.lexicalCoverage('hope', 'mercy'), 0);
    });

    test('supports common domain topics across scripts', () {
      const examples = {
        'hardship': 'مشکلات',
        'patience': 'الصابرين',
        'family': 'خاندان',
        'forgiveness': 'مغفرة',
        'repentance': 'توبہ',
        'gratitude': 'شکر',
        'charity': 'صدقہ',
        'prayer': 'نماز',
        'fasting': 'صيام',
        'hajj': 'حج',
        'zakat': 'زكاة',
        'supplication': 'دعائیں',
        'health': 'صحت',
        'sickness': 'بیماری',
        'death': 'وفات',
        'knowledge': 'تعلیم',
        'work': 'روزگار',
        'debt': 'قرض',
        'travel': 'مسافر',
        'notes': 'ملاحظات',
        'downloads': 'ڈاؤن لوڈ',
        'saved': 'محفوظ',
        'widgets': 'ویجٹ',
        'timings': 'اوقات',
      };
      for (final entry in examples.entries) {
        expect(
          SearchQueryTerms.lexicalCoverage(entry.key, entry.value),
          1,
          reason: '${entry.key} -> ${entry.value}',
        );
      }
    });
  });
}
