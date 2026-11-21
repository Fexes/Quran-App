import '../../../../core/search/offline_search_normalizer.dart';
import '../../../../core/search/search_query_terms.dart';
import 'offline_search_result.dart';

/// Conservative source routing. This chooses where to look, never an answer.
class SearchQueryIntent {
  const SearchQueryIntent({
    this.filter = OfflineSearchFilter.all,
    this.sourceKinds = const {},
  });

  final OfflineSearchFilter filter;
  final Set<String> sourceKinds;

  static SearchQueryIntent analyze(String query) {
    final text = OfflineSearchNormalizer.keyword(query);
    bool has(String pattern) => RegExp(
      pattern.replaceAll('ی', 'ي').replaceAll('ک', 'ك').replaceAll('آ', 'ا'),
    ).hasMatch(text);

    // App operations take precedence over a content name used as their object:
    // "download Quran translations" opens the relevant app feature.
    final appObject = has(
      r'\b(app|widget|widgets|font|theme|dark mode|notification|notifications|alert|alerts|settings|download|downloads|language|languages|translation|translations|reciter|backup|restore|journal|tracker|counter)\b|ویجٹ|فونٹ|ترتیبات|ڈاونلوڈ|تنزيل|اعدادات|اشعارات',
    );
    final appAction = has(
      r'\b(open|change|enable|disable|download|install|remove|manage|set up|customize|turn on|turn off|where|find|add|increase)\b|کیسے|کہاں|كيف|اين',
    );
    final trackingAction = has(
      r'\b(track|log|record)\b.*\b(fasting|fasts|prayers|prayer|reading|progress|hifz)\b|\b(reading|prayer|fasting)\s+(tracker|journal)\b',
    );
    final directTool = has(
      r'\b(qibla|compass|zakat calculator|tasbieh|tasbih counter|nearby mosques|mosques near me)\b|\bhow\b.*\b(memorize|memorise)\b|^(quran languages|quran translations|downloaded languages|language downloads)$|قبلہ.*(سمت|کہاں)|اتجاه القبلة',
    );
    final religiousFraming = has(
      r'\b(say|says|teach|teaches|teaching|teachings|ruling|allowed|permissible|forbidden|halal|haram|virtue|virtues)\b|حکم|حلال|حرام|تعلیم|فضیلت|فضائل',
    );
    if (!religiousFraming &&
        ((appObject && appAction) || trackingAction || directTool)) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.tools);
    }
    if (has(
      r'\b(my notes?|my reflections?)\b|میرے نوٹس|میری یادداشت|ملاحظاتي',
    )) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.notes);
    }
    if (has(
      r'\b(my bookmarks?|my saved|my collections?|my reading|my progress|my hifz|my fasting (records|history|log)|my prayer journal|my downloads?)\b|میرے محفوظ|میرا حفظ',
    )) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.saved);
    }

    final quran = has(
      r'\b(quran|qur an|koran|verses?|ayahs?|ayat)\b|قران|قرآن',
    );
    final hadith = has(
      r'\b(hadith|hadiths|hadeeth|ahadith)\b|حدیث|احادیث|حديث|احاديث',
    );
    final tafsir = has(r'\b(tafsir|tafseer|commentary)\b|تفسیر|تفسير');
    if (tafsir) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.tafsir);
    }
    if (quran && hadith) {
      return const SearchQueryIntent(sourceKinds: {'quran', 'hadith'});
    }
    if (quran) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.quran);
    }
    if (hadith) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.hadith);
    }
    if (has(r'\b(duas?|supplications?|azkar|adhkar)\b|دعا|دعاء|اذکار|اذكار')) {
      return const SearchQueryIntent(filter: OfflineSearchFilter.azkar);
    }

    final analysis = SearchQueryTerms.analyze(query);
    // A substantive question should retrieve source passages, while vague or
    // unknown queries retain the full app search. App operations above and live
    // times in the coordinator remain distinct from religious questions.
    if (religiousFraming ||
        (analysis.isQuestion &&
            analysis.conceptIds.any(_sourceConcepts.contains))) {
      return const SearchQueryIntent(
        sourceKinds: {'quran', 'hadith', 'azkar', 'tafsir', 'divine_name'},
      );
    }
    return const SearchQueryIntent();
  }

  static const _sourceConcepts = {
    'anxiety',
    'hope',
    'peace',
    'hardship',
    'patience',
    'parents',
    'family',
    'forgiveness',
    'repentance',
    'gratitude',
    'charity',
    'prayer',
    'fasting',
    'hajj',
    'umrah',
    'zakat',
    'supplication',
    'health',
    'illness',
    'death',
    'knowledge',
    'work',
    'debt',
    'travel',
    'sleep',
    'food',
    'gossip',
    'loneliness',
    'anger',
    'marriage',
    'justice',
    'intention',
    'trust',
    'honesty',
    'children',
    'kindness',
    'treatment',
    'mercy',
    'lying',
    'remembrance',
    'self_control',
    'ablution',
    'forgetfulness',
    'neighbours',
    'sin',
    'leaving_home',
  };
}
