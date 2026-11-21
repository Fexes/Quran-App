import 'offline_search_normalizer.dart';

/// A small, inspectable vocabulary for lexical retrieval alongside embeddings.
///
/// This does not rewrite the semantic query, infer rulings, or select passages.
/// Aliases are whole normalized words or contiguous phrases. Inflections and
/// Roman Urdu spellings are listed explicitly; there is no substring stemming.
/// Concepts describe retrieval topics, not assertions that their words have
/// identical religious meanings (for example illness and healing).
/// Lexical planning examines the first 128 query tokens; semantic input stays
/// untouched and can still represent context beyond this bounded vocabulary.
abstract final class SearchQueryTerms {
  static const maxKeywords = 24;
  static const _maxQueryTokens = 128;

  /// Separates the requested topic from conversational/source scaffolding.
  /// This is deterministic retrieval preparation, never an answer generator.
  static SearchQueryAnalysis analyze(String query) {
    final tokens = _tokens(query).take(_maxQueryTokens).toList();
    final normalized = tokens.join(' ');
    final isQuestion =
        query.contains('?') ||
        query.contains('؟') ||
        _questionStart.hasMatch(normalized) ||
        tokens.any(_questionMarkers.contains);
    var focus = normalized;
    if (isQuestion) {
      for (final scaffold in _questionScaffolds) {
        focus = focus.replaceAll(scaffold, ' ');
      }
    }
    final focusTokens = _tokens(focus);
    final plan = _scan(focusTokens);
    final meaningful = <String>[...plan.anchors, ...plan.otherWords];
    final focusText = meaningful.join(' ');
    return SearchQueryAnalysis._(
      isQuestion: isQuestion,
      focusText: focusText,
      semanticFocus: _semanticFocus(focusTokens),
      plan: plan,
      keywords: _keywords(focusTokens, plan),
    );
  }

  /// Reserves one original word/phrase per concept, then informative originals
  /// and multilingual terms. Each concept gets an equal expansion opportunity.
  static List<String> keywords(String query) => analyze(query).keywords;

  static List<String> _keywords(List<String> tokens, _ConceptPlan plan) {
    final original = tokens.where(_informative).toSet().toList();
    final result = <String>{...plan.anchors.take(maxKeywords)};
    final originalBudget = plan.concepts.isEmpty ? maxKeywords : 12;
    for (final token in original) {
      if (result.length >= originalBudget) break;
      result.add(token);
    }
    for (var round = 0; result.length < maxKeywords; round++) {
      var hasMore = false;
      for (final concept in plan.concepts) {
        if (round >= concept.terms.length) continue;
        hasMore = true;
        result.add(concept.terms[round]);
        if (result.length == maxKeywords) break;
      }
      if (!hasMore) break;
    }
    for (final token in original) {
      if (result.length == maxKeywords) break;
      result.add(token);
    }
    return List.unmodifiable(result);
  }

  /// Lexical topic coverage is not correctness or religious authority.
  static double lexicalCoverage(String query, String text) =>
      _unweightedCoverage(query, text);

  static double _unweightedCoverage(String query, String text) {
    final plan = analyze(query);
    return plan.topicCount == 0
        ? 0
        : plan.evidence(text).matchedTopics / plan.topicCount;
  }

  static RegExp _questionPattern(String pattern) => RegExp(
    pattern
        .replaceAll(RegExp(r'[آأإٱ]'), 'ا')
        .replaceAll('ی', 'ي')
        .replaceAll('ى', 'ي')
        .replaceAll('ک', 'ك'),
  );

  // Unlike keywords, the semantic topic view retains polarity and conditions.
  static final _semanticConnectors = _tokens(
    'not no never without while during after before unless except if '
    'لا ليس بدون دون قبل بعد اذا في عند '
    'نہیں نہ بغیر پہلے بعد دوران جب اگر '
    'nahi nahin na baghair bina pehle baad dauran jab agar',
  ).toSet();

  static String _semanticFocus(List<String> words) {
    final result = <String>[];
    final seen = <_Concept>{};
    for (var index = 0; index < words.length;) {
      _Alias? matched;
      for (final alias
          in _aliasesByFirstWord[words[index]] ?? const <_Alias>[]) {
        if (index + alias.words.length > words.length) continue;
        var matches = true;
        for (var offset = 1; offset < alias.words.length; offset++) {
          if (words[index + offset] != alias.words[offset]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          matched = alias;
          break;
        }
      }
      if (matched != null) {
        if (seen.add(matched.concept)) result.add(matched.concept.terms.first);
        index += matched.words.length;
      } else {
        final word = words[index++];
        if (_informative(word) || _semanticConnectors.contains(word)) {
          result.add(word);
        }
      }
    }
    return result.join(' ');
  }

  static final _questionStart = _questionPattern(
    r'^(?:what|why|how|when|where|can|could|should|would|is|are|does|do|did|'
    r'هل|كيف|لماذا|ماذا|متى|أين|اين|ما|کیا|کیسے|کیوں|کب|کہاں|'
    r'kya|kaise|kaisay|kyun|kab|kahan)(?: |$)',
  );
  static final _questionMarkers = <String>{
    'کیسے',
    'کیوں',
    'کیا',
    'kaise',
    'kaisay',
    'kya',
  }.map(OfflineSearchNormalizer.keyword).toSet();
  static final _questionScaffolds = <RegExp>[
    _questionPattern(
      r'\b(?:what (?:does|do)|according to|in|from) (?:the )?(?:holy )?(?:quran|koran|hadiths?|sunnah|islam)(?: and (?:the )?(?:quran|hadiths?|sunnah))?(?: say| says| teach| teaches)?(?: about| regarding| on)?\b',
    ),
    _questionPattern(
      r'\b(?:quran|koran|hadiths?|sunnah|islam)(?: and (?:the )?(?:quran|hadiths?|sunnah))? (?:say|says|teach|teaches|tell|tells)(?: about| regarding| on)?\b',
    ),
    _questionPattern(
      r'\b(?:verses?|ayahs?|ahadith|hadiths?) (?:about|regarding|on)\b',
    ),
    _questionPattern(
      r'(?:ماذا يقول|ماذا قال|ما يقول|يقول|وفقا ل|وفق) (?:القران|القرآن|الحديث|الاسلام|الإسلام|السنة)(?: عن)?',
    ),
    _questionPattern(
      r'(?:قرآن|قران|حدیث|احادیث|اسلام|quran|hadith|islam) (?:(?:کے|کی|کے مطابق|ki|ke|mein|me) )?(?:مطابق|کہتا|کہتی|کہتے|کہا|فرماتا|فرماتی|کہتی ہے|kehta|kehti|kehtay|says)',
    ),
    _questionPattern(r'(?:قرآن|قران|حدیث|احادیث|اسلام)(?= |$)'),
    _questionPattern(
      r'\b(?:allowed|permissible|permitted|possible|important|importance)\b',
    ),
  ];

  static List<String> _tokens(String text) => OfflineSearchNormalizer.keyword(
    text,
  ).split(' ').where((word) => word.isNotEmpty).toList(growable: false);

  static bool _informative(String word) =>
      word.runes.length >= 2 && !_stopwords.contains(word);

  static _ConceptPlan _scan(List<String> words) {
    final concepts = <_Concept>{};
    final anchors = <String>[];
    final otherWords = <String>{};
    for (var index = 0; index < words.length;) {
      _Alias? matched;
      for (final alias
          in _aliasesByFirstWord[words[index]] ?? const <_Alias>[]) {
        if (index + alias.words.length > words.length) continue;
        var matches = true;
        for (var offset = 1; offset < alias.words.length; offset++) {
          if (words[index + offset] != alias.words[offset]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          matched = alias;
          break;
        }
      }
      if (matched != null) {
        if (concepts.add(matched.concept)) {
          anchors.add(matched.words.join(' '));
        }
        index += matched.words.length;
      } else {
        if (_informative(words[index])) otherWords.add(words[index]);
        index++;
      }
    }
    return _ConceptPlan(concepts.toList(growable: false), anchors, otherWords);
  }

  static final _aliasesByFirstWord = () {
    final result = <String, List<_Alias>>{};
    for (final concept in _concepts) {
      for (final value in concept.aliases) {
        final words = value.split(' ');
        result.putIfAbsent(words.first, () => []).add(_Alias(concept, words));
      }
    }
    for (final aliases in result.values) {
      aliases.sort((left, right) {
        final length = right.words.length.compareTo(left.words.length);
        return length != 0
            ? length
            : left.concept.id.compareTo(right.concept.id);
      });
    }
    return result;
  }();

  // Keep short grammatical words out of FTS, especially Urdu کی/کے and Roman
  // Urdu ki/hai. Prefixing these would match unrelated Arabic or English words.
  static final _stopwords = _tokens('''
    a an the and or but of to in on at by for from with without about into as
    i me my mine we us our you your he him his she her it its they them their
    is am are was were be been being do does did have has had can could would
    should will shall may might must not no yes if then than that this these
      while during after before unless except still
    those there here when where why how what which who whom whose please tell
    show find search looking look information explain question want need help feel
    feeling very really also some any all just like get give say says said
    according regarding something anything everything don dont cannot
      says teaches teaching taught guidance evidence sources source verses verse ayah ayat
      someone somebody person people shouldnt couldnt isnt arent
      کہتا کہتی کہتے فرماتا فرماتی مطابق متعلق کروں کریں آئے چاہیے رکھنے ساتھ سلوک کرنا جاؤں جاوں تو
      يجوز أفعل افعل إذا اذا بالنسبة
      rakh rakhna sakte sakta sakti karun karoon sath saath acha achha sulook
    ما ماذا متى أين اين كيف لماذا هل عن في من إلى الى على مع هذا هذه ذلك تلك
    أنا انا أنت انت أن ان إن إنه انه هو هي هم نحن كان يكون لي لنا لك لا نعم
    أريد اريد ابحث أخبرني اخبرني التي الذي الذين ماذا هناك هنا جدا
    أشعر اشعر بشأن بشان عندما بسبب حول
    میں ہم آپ تم مجھے مجھ میرا میری میرے ہمارا ہماری اپنے اپنی اپنا یہ وہ
    ہے ہیں تھا تھی تھے ہو ہوں ہونا کیا کیسے کیوں کب کہاں کس کون کو کا کی کے
    سے پر اور یا بھی نہ نہیں لیے لئے بارے بہت کوئی کچھ بتائیں بتاؤ چاہتا چاہتی
    mujhe mujhay mera meri mere apni apna apne hum ham hamara hamari aap tum tumhara tumhari
    main mein mai hai hain hy ho hun hoon tha thi thay the ki ke ka ko se par
    aur ya bhi nahi nahin na kya kaise kaisay kyun kyu kab kahan kis kaun
    liye lie bare baray bohat bahut zyada kuch koi please batao bataye batayen
    batain bataein kar karo karein karta karti karna chahiye chahta chahti
  ''').toSet();

  // Expansion order is English, Arabic, Urdu, then useful additional forms.
  // The lists are deliberately finite. Add reviewed whole-word variants here,
  // rather than broad substring rules, passage IDs, or query-specific answers.
  static final _concepts = <_Concept>[
    _Concept(
      'anxiety',
      'anxiety|anxious|worry|worried|worries|worrying|distress|distressed|panic|panic attack|fear|afraid|scared|قلق|القلق|بالقلق|وبالقلق|خوف|الخوف|بخوف|بالخوف|وبخوف|يخاف|غم|پریشان|پریشانی|پریشانیوں|فکرمند|گھبراہٹ|ڈر|فکر|pareshan|pareshaan|pareshani|pareshaani|ghabrahat|ghabrana|dar|khauf|fikr|fikar|fikarmand|fikrmand|pareshaniyon',
      ['worry', 'خوف', 'پریشانی', 'anxiety', 'fear', 'غم', 'قلق', 'distress'],
    ),
    _Concept(
      'hope',
      'hope|hopeful|hopes|hopeless|hopelessness|despair|despairing|optimism|رجاء|الرجاء|أمل|الأمل|يأس|اليأس|تقنطوا|امید|ناامید|مایوسی|umeed|ummid|naumeed|mayusi|mayoosi',
      ['hope', 'رجاء', 'امید', 'despair', 'أمل', 'تقنطوا', 'hopeless'],
    ),
    _Concept(
      'peace',
      'peace|peaceful|tranquility|tranquillity|serenity|calm down|inner peace|طمأنينة|الطمأنينة|سكينة|السكينة|اطمئنان|سکون|اطمینان|sukoon|sukun|itminan',
      ['peace', 'سكينة', 'سکون', 'tranquility', 'طمأنينة', 'اطمینان'],
    ),
    _Concept(
      'hardship',
      'hardship|hardships|difficult|difficulty|difficulties|adversity|suffering|suffer|suffers|tribulation|tribulations|عسر|العسر|بلاء|البلاء|مصيبة|مصائب|ابتلاء|مشکل|مشکلات|مصیبت|آزمائش|mushkil|mushkilat|museebat|musibat|azmaish',
      ['hardship', 'عسر', 'مشکل', 'difficulty', 'مصيبة', 'آزمائش', 'suffering'],
    ),
    _Concept(
      'patience',
      'patience|patiently|be patient|remain patient|perseverance|persevere|steadfast|steadfastness|endurance|صبر|الصبر|بالصبر|اصبر|اصبروا|صابر|الصابرين|الصابرون|والصابرين|صابرين|تحمل|sabr|sabar',
      ['patience', 'صبر', 'تحمل', 'be patient', 'الصابرين', 'steadfast'],
    ),
    _Concept(
      'parents',
      'parent|parents|mother|mothers|father|fathers|والدين|الوالدين|بالوالدين|وبالوالدين|والديه|بوالديه|والدي|الأم|أمي|أب|الأب|أبي|والدین|والد|والدہ|ماں|باپ|امی|ابو|والدہ|walidain|waliden|walid|walida|maa|maan|ammi|abu|abbu|baap',
      ['parents', 'الوالدين', 'والدین', 'mother', 'father', 'ماں', 'والدي'],
    ),
    _Concept(
      'family',
      'family|families|relative|relatives|kinship|kin|household|عائلة|العائلة|أسرة|الأسرة|أقارب|الأقارب|الأرحام|ارحام|رشتہ|رشتے|رشتہ دار|خاندان|گھر والے|rishtay|rishte|rishtedar|khandan|khandaan|ghar walay',
      ['family', 'الأرحام', 'خاندان', 'relatives', 'kinship', 'أقارب'],
    ),
    _Concept(
      'forgiveness',
      'forgiveness|forgive|forgiven|forgiving|forgives|pardon|pardoning|غفران|مغفرة|المغفرة|اغفر|يغفر|العفو|عفو|معافی|معاف|بخشش|مغفرت|maafi|maaf|muafi|bakhshish|maghfirat',
      ['forgive', 'مغفرة', 'معافی', 'forgiveness', 'يغفر', 'اغفر', 'معاف'],
    ),
    _Concept(
      'repentance',
      'repentance|repent|repents|repenting|repented|توبة|التوبة|توبوا|تاب|تائب|استغفار|توبہ|tauba|tawba|tawbah|istighfar|astaghfar',
      ['repent', 'توبة', 'توبہ', 'repentance', 'استغفار', 'التوبة'],
    ),
    _Concept(
      'gratitude',
      'gratitude|grateful|thankful|thankfulness|thanks|thank|شكر|الشكر|شاكر|شاكرين|تشكرون|شکر|شکریہ|شکرگزار|shukr|shukar|shukriya',
      ['grateful', 'شكر', 'شکر', 'gratitude', 'thankful', 'تشكرون'],
    ),
    _Concept(
      'charity',
      'charity|charitable|donate|donation|donations|alms|giving charity|صدقة|الصدقة|صدقات|الصدقات|إنفاق|انفاق|صدقہ|صدقات|خیرات|عطیہ|sadaqa|sadaqah|sadqa|sadqah|khairat|khairaat',
      ['charity', 'صدقة', 'صدقہ', 'alms', 'donation', 'صدقات', 'خیرات'],
    ),
    _Concept(
      'prayer',
      'prayer|prayers|pray|praying|prayed|salah|salaah|salat|salaat|namaz|namaaz|صلوة|صلاة|الصلاة|صلوات|الصلوات|يصلون|نماز|نمازیں',
      ['prayer', 'صلاة', 'نماز', 'salah', 'الصلاة', 'prayers'],
    ),
    _Concept(
      'fasting',
      'fasting|fast|fasts|fasted|ramadan|ramadhan|roza|roze|rozay|rozae|صوم|الصوم|صيام|الصيام|رمضان|روزہ|روزے',
      ['fasting', 'صيام', 'روزہ', 'ramadan', 'رمضان', 'صوم'],
    ),
    _Concept('hajj', 'hajj|haj|pilgrimage|pilgrim|pilgrims|الحج|حج|حاج|حجاج', [
      'hajj',
      'الحج',
      'حج',
      'pilgrimage',
      'pilgrim',
    ]),
    _Concept('umrah', 'umrah|umra|عمرہ|عمرة|العمرة', [
      'umrah',
      'عمرة',
      'عمرہ',
      'umra',
      'العمرة',
    ]),
    _Concept('zakat', 'zakat|zakaat|zakah|زكاة|الزكاة|زکوٰۃ|زکات|زکوۃ|زکوة', [
      'zakat',
      'زكاة',
      'زکوۃ',
      'zakah',
      'الزكاة',
    ]),
    _Concept(
      'supplication',
      'supplication|supplications|invocation|invocations|dua|duaa|duas|duain|duayein|دعاء|الدعاء|أدعية|الأدعية|ادعوني|دعا|دعائیں|دعاؤں',
      ['supplication', 'دعاء', 'دعا', 'dua', 'invocation', 'أدعية'],
    ),
    _Concept(
      'health',
      'health|healthy|wellbeing|wellness|صحة|الصحة|عافية|العافية|صحت|تندرستی|صحت مند|sehat|sihat|tandurusti',
      ['health', 'صحة', 'صحت', 'healthy', 'عافية', 'تندرستی'],
    ),
    _Concept(
      'illness',
      'sickness|sick|illness|ill|disease|diseases|healing|heal|recovery|مرض|المرض|مريض|المريض|شفاء|الشفاء|بیماری|بیمار|شفا|bimari|beemari|bimar|beemar|shifa',
      ['sick', 'مرض', 'بیماری', 'illness', 'شفاء', 'healing', 'بیمار'],
    ),
    _Concept(
      'death',
      'death|die|dies|died|dying|deceased|funeral|burial|موت|الموت|مات|ميت|الميت|جنازة|الجنازة|وفات|میت|جنازہ|maut|mout|wafat|janaza|janazah',
      ['death', 'موت', 'وفات', 'funeral', 'جنازة', 'جنازہ'],
    ),
    _Concept(
      'knowledge',
      'knowledge|learn|learning|learned|study|studying|education|wisdom|علم|العلم|تعلم|تعليم|حكمة|الحكمة|تعلیم|سیکھنا|سیکھیں|ilm|taleem|seekhna|seekho|hikmat',
      ['knowledge', 'علم', 'تعلیم', 'learn', 'wisdom', 'حكمة'],
    ),
    _Concept(
      'work',
      'work|working|job|jobs|employment|livelihood|earning|earnings|رزق|الرزق|كسب|معاش|محنت|روزگار|نوکری|ملازمت|کام|rizq|rozi|rozgar|rozgaar|naukri|nokri|kaam|mehnat',
      ['work', 'رزق', 'روزگار', 'livelihood', 'earning', 'نوکری'],
    ),
    _Concept(
      'debt',
      'debt|debts|debtor|indebted|indebtedness|borrow|borrowing|loan|loans|owe|owed|owing|ديون|قرض|القرض|قروض|قرضہ|ادھار|qarz|karz|udhar|udhaar',
      ['debt', 'ديون', 'قرض', 'loan', 'borrowing', 'قروض'],
    ),
    _Concept(
      'travel',
      'travel|traveling|travelling|traveler|traveller|journey|journeys|trip|trips|سفر|السفر|مسافر|المسافر|رحلة|الرحلة|سفر|مسافر|safar|musafir',
      ['travel', 'سفر', 'مسافر', 'journey', 'traveller', 'السفر'],
    ),
    _Concept(
      'marriage',
      'marriage|married|marry|wedding|spouse|husband|wife|زواج|الزواج|زوج|زوجة|نكاح|نکاح|شادی|شوہر|بیوی|shadi|shaadi|nikah|nikaah|shohar|biwi',
      ['marriage', 'زواج', 'شادی', 'spouse', 'نكاح', 'شوہر', 'بیوی'],
    ),
    _Concept(
      'children',
      'child|children|parenting|daughter|son|أطفال|الأطفال|طفل|أولاد|اولاد|بچے|بچہ|بیٹی|بیٹا|bachay|bache|bachche|bachon|aulad|aulaad|beti|mera beta',
      ['children', 'أطفال', 'بچے', 'child', 'اولاد', 'daughter', 'son'],
    ),
    _Concept(
      'anger',
      'anger|angry|rage|temper|غضب|الغضب|غاضب|غيظ|الغيظ|غصہ|غصے|gussa|ghussa',
      ['anger', 'غضب', 'غصہ', 'angry', 'غيظ'],
    ),
    _Concept(
      'kindness',
      'kindness|be kind|kind to|good treatment|kindly|حسن سلوک|الإحسان|احسان|احسانا|حسن المعاملة|acha sulook|achha sulook|إحسان|مہربانی|نرمی|meherbani|mehrbani|narmi',
      ['kindness', 'إحسان', 'مہربانی', 'good treatment', 'احسانا', 'kindly'],
    ),
    _Concept(
      'treatment',
      'treat|treats|treated|treating|treatment|معاملة|المعاملة|يعامل|تعامل|سلوک|سلوك',
      ['treat', 'معاملة', 'سلوک', 'treating', 'treated', 'treatment'],
    ),
    _Concept(
      'mercy',
      'mercy|merciful|compassion|compassionate|رحمة|الرحمة|رحيم|الرحيم|رحم|raham|rahm',
      ['mercy', 'رحمة', 'رحم', 'compassion', 'merciful', 'رحيم'],
    ),
    _Concept(
      'lying',
      'lying|lies|lie|liar|liars|falsehood|كذب|الكذب|كاذب|جھوٹ|جھوٹا|jhoot|jhut',
      ['lying', 'كذب', 'جھوٹ', 'lie', 'falsehood', 'liar'],
    ),
    _Concept(
      'honesty',
      'honesty|honest|truthfulness|truthful|صدق|الصدق|صادق|سچ|سچائی|sach|sachai',
      ['honesty', 'صدق', 'سچ', 'truthful', 'truthfulness', 'صادق'],
    ),
    _Concept(
      'remembrance',
      'remembrance|dhikr|zikr|zikir|azkar|adhkar|tasbih|tasbeeh|tasbieh|ذكر|الذكر|أذكار|الأذكار|تسبيح|اذکار|تسبیح',
      ['remembrance', 'ذكر', 'اذکار', 'dhikr', 'أذكار', 'تسبيح', 'تسبیح'],
    ),
    _Concept(
      'self_control',
      'control|controls|controlling|self control|restraint|restrain|restrains|restraining|suppress|suppresses|suppressing|أسيطر|اسيطر|يسيطر|كظم|يكظم|الكاظمين|والكاظمين|ضبط النفس|قابو|کابو|قابو رکھنا|qabu|qaboo|control karna',
      ['control', 'كظم', 'قابو', 'restrain', 'الكاظمين', 'suppress'],
    ),
    _Concept(
      'ablution',
      'ablution|ablutions|wudu|wudhu|wudoo|وضوء|الوضوء|وضو|wuzu|wuzoo',
      ['ablution', 'وضوء', 'وضو', 'wudu', 'الوضوء', 'wudhu'],
    ),
    _Concept(
      'forgetfulness',
      'forget|forgot|forgotten|forgets|forgetting|forgetful|نسي|نسيت|نسيان|ينسى|بھول|بھولنا|بھولے|bhool|bhul|bhoolna',
      ['forget', 'نسي', 'بھول', 'forgotten', 'نسيت', 'forgetting'],
    ),
    _Concept(
      'neighbours',
      'neighbor|neighbors|neighbour|neighbours|neighboring|neighbouring|جار|الجار|جيران|الجيران|پڑوسی|پڑوسیوں|ہمسایہ|parosi|parosiyon|hamsaya',
      ['neighbor', 'الجار', 'پڑوسی', 'neighbour', 'جيران', 'neighbors'],
    ),
    _Concept(
      'sin',
      'sin|sins|sinful|sinned|sinning|wrongdoing|ذنب|ذنوب|الذنوب|إثم|الإثم|گناہ|گناہوں|gunah|gunaah',
      ['sin', 'ذنوب', 'گناہ', 'sins', 'ذنب', 'wrongdoing'],
    ),
    _Concept(
      'leaving_home',
      'leaving the house|leave the house|leaving the home|leave the home|leaving home|leave home|going out of the house|الخروج من المنزل|الخروج من البيت|گھر سے نکلتے|گھر سے نکلنے|ghar se nikalte|ghar se nikalne',
      [
        'leaving the house',
        'leaving the home',
        'الخروج من المنزل',
        'گھر سے نکلتے',
        'leave home',
        'الخروج من البيت',
      ],
    ),
    _Concept(
      'notes',
      'note|notes|annotation|annotations|journal|journaling|reflection|reflections|ملاحظات|ملاحظة|تدوين|نوٹ|نوٹس|یادداشت',
      ['notes', 'ملاحظات', 'نوٹس', 'note', 'reflection', 'annotation'],
    ),
    _Concept(
      'downloads',
      'download|downloads|downloaded|downloading|offline|تنزيل|تنزيلات|تحميل|التحميل|ڈاؤن لوڈ|ڈاون لوڈ|آف لائن|download kiya',
      ['download', 'تنزيل', 'ڈاؤن لوڈ', 'offline', 'تحميل'],
    ),
    _Concept(
      'saved',
      'saved|save|bookmark|bookmarks|bookmarked|favorite|favorites|favourite|favourites|محفوظ|المحفوظات|المفضلة|پسندیدہ|بک مارک|mehfooz|mahfooz',
      ['bookmark', 'محفوظ', 'پسندیدہ', 'saved', 'favorite', 'favourite'],
    ),
    _Concept(
      'timings',
      'time|times|timing|timings|schedule|schedules|scheduled|وقت|الوقت|أوقات|مواعيد|اوقات|ٹائم|waqt|auqat|awqat',
      ['time', 'أوقات', 'اوقات', 'schedule', 'timing', 'وقت'],
    ),
    _Concept(
      'widgets',
      'widget|widgets|home screen|homescreen|ودجت|عنصر واجهة|ویجٹ|وجیٹ',
      ['widget', 'ودجت', 'ویجٹ', 'widgets', 'home screen'],
    ),
    _Concept('qibla', 'qibla|qiblah|qiblah direction|قبلة|القبلة|قبلہ', [
      'qibla',
      'قبلة',
      'قبلہ',
      'qiblah',
      'القبلة',
    ]),
    _Concept(
      'calendar',
      'calendar|date|hijri|islamic date|تقويم|التقويم|هجري|تاريخ|ہجری|کیلنڈر|تاریخ|hijri tareekh|tareekh',
      ['calendar', 'تقويم', 'ہجری', 'hijri', 'تاريخ', 'کیلنڈر'],
    ),
    _Concept(
      'memorization',
      'memorization|memorisation|memorize|memorise|memorizing|memorising|hifz|revision|حفظ|الحفظ|مراجعة|یاد کرنا|دہرائی|hifz|hifaz|yaad karna',
      ['memorization', 'حفظ', 'دہرائی', 'memorisation', 'hifz', 'revision'],
    ),
    _Concept(
      'recitation',
      'recitation|recite|reciting|reciter|audio|listen|listening|تلاوة|التلاوة|تلاوت|قاري|قارئ|صوت|آڈیو|سننا|tilawat|tilaawat|qari|sunain|sunayein',
      ['recitation', 'تلاوة', 'تلاوت', 'audio', 'reciter', 'listen'],
    ),
    _Concept(
      'sleep',
      'sleep|sleeping|sleepy|asleep|bedtime|insomnia|sleepless|sleeplessness|نوم|النوم|أرق|الأرق|نیند|سونا|سوتے|neend|nind|sona|sotay',
      ['sleep', 'نوم', 'نیند', 'bedtime', 'insomnia', 'أرق'],
    ),
    _Concept(
      'food',
      'food|eat|eats|eating|meal|meals|طعام|الطعام|أكل|الأكل|کھانا|کھانے|غذا|khana|khaana|khanay',
      ['food', 'طعام', 'کھانا', 'eating', 'meal', 'غذا'],
    ),
    _Concept(
      'gossip',
      'gossip|gossiping|backbiting|backbite|slander|slandering|غيبة|الغيبة|نميمة|النميمة|غیبت|چغلی|gheebat|ghebat|ghibat|chugli',
      ['backbiting', 'غيبة', 'غیبت', 'gossip', 'slander', 'چغلی'],
    ),
    _Concept(
      'loneliness',
      'loneliness|lonely|isolated|isolation|feeling alone|feel alone|وحدة|الوحدة|وحشة|الوحشة|تنہائی|تنہا|اکیلا|tanhai|tanha|akela|akeli',
      ['lonely', 'وحدة', 'تنہائی', 'loneliness', 'وحشة', 'تنہا'],
    ),
    _Concept(
      'settings',
      'settings|preferences|setting|إعدادات|الإعدادات|ترتیبات|سیٹنگ',
      ['settings', 'إعدادات', 'ترتیبات', 'preferences'],
    ),
    _Concept(
      'languages',
      'language|languages|لغة|اللغة|لغات|زبان|زبانیں|zaban|zubaan',
      ['language', 'لغة', 'زبان', 'languages', 'لغات'],
    ),
    _Concept(
      'translation',
      'translation|translations|translated|translate|ترجمة|الترجمة|ترجمات|ترجمہ|ترجمے|tarjuma|tarjumah',
      ['translation', 'ترجمة', 'ترجمہ', 'translated', 'ترجمات'],
    ),
    _Concept('fonts', 'font|fonts|typeface|text size|حجم الخط|خط|فونٹ|لکھائی', [
      'font',
      'خط',
      'فونٹ',
      'text size',
      'typeface',
    ]),
  ];
}

/// A compiled query is reused across candidates, avoiding repeated query scans.
class SearchQueryAnalysis {
  const SearchQueryAnalysis._({
    required this.isQuestion,
    required this.focusText,
    required this.semanticFocus,
    required _ConceptPlan plan,
    required this.keywords,
  }) : _plan = plan;

  final bool isQuestion;
  final String focusText;
  final String semanticFocus;
  final List<String> keywords;
  final _ConceptPlan _plan;
  Set<String> get conceptIds => {
    for (final concept in _plan.concepts) concept.id,
  };
  int get topicCount => _plan.concepts.length + _plan.otherWords.length;

  /// Try a bounded conjunction before broad recall. Terms are normalized words,
  /// quoted here so a user's FTS operators cannot become executable syntax.
  List<String> get ftsExpressions => expressionsFor('');

  List<String> expressionsFor(String contentKind) {
    if (keywords.isEmpty) return const [];
    String quote(String value) =>
        '"${value.replaceAll('"', '""')}"'
        '${value.runes.length >= 3 ? '*' : ''}';
    final broad = keywords.map(quote).join(' OR ');
    final concepts = _plan.concepts
        .where(
          (concept) =>
              !(contentKind == 'azkar' &&
                  topicCount > 1 &&
                  concept.id == 'supplication'),
        )
        .toList();
    final groupCount = concepts.length + _plan.otherWords.length;
    if (groupCount < 1 ||
        groupCount > 5 ||
        (groupCount == 1 && concepts.length == _plan.concepts.length)) {
      return [broad];
    }
    final groups = <String>[
      for (final concept in concepts)
        '(${<String>{...concept.terms.take(5), ...concept.aliases.where(keywords.contains)}.map(quote).join(' OR ')})',
      for (final word in _plan.otherWords) quote(word),
    ];
    return [groups.join(' AND '), broad];
  }

  SearchQueryEvidence evidence(String text) {
    if (topicCount == 0) return const SearchQueryEvidence(0, 0, 0);
    final words = SearchQueryTerms._tokens(text);
    final wanted = _plan.concepts.toSet();
    final events = <(int, String)>[];
    final matchedConcepts = <_Concept>{};
    final matchedWords = <String>{};
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      if (_plan.otherWords.contains(word)) {
        matchedWords.add(word);
        events.add((index, 'word:$word'));
      }
      for (final alias
          in SearchQueryTerms._aliasesByFirstWord[word] ?? const <_Alias>[]) {
        if (!wanted.contains(alias.concept) ||
            index + alias.words.length > words.length) {
          continue;
        }
        var matches = true;
        for (var offset = 1; offset < alias.words.length; offset++) {
          if (words[index + offset] != alias.words[offset]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          matchedConcepts.add(alias.concept);
          events.add((index, alias.concept.id));
          break;
        }
      }
    }
    // Unknown words remain useful, but conversational details must not outweigh
    // a recognized core topic merely because they were not in the vocabulary.
    final otherWeight = _plan.concepts.isEmpty ? 1.0 : 0.4;
    final totalWeight =
        _plan.concepts.length + otherWeight * _plan.otherWords.length;
    final coverage =
        (matchedConcepts.length + otherWeight * matchedWords.length) /
        totalWeight;
    final matched = matchedConcepts.length + matchedWords.length;
    var compactness = 0.0;
    if (matched >= 2) {
      var left = 0;
      var minimumSpan = words.length;
      final counts = <String, int>{};
      for (var right = 0; right < events.length; right++) {
        counts.update(
          events[right].$2,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        while (counts.length == matched) {
          final span = events[right].$1 - events[left].$1;
          if (span < minimumSpan) minimumSpan = span;
          final key = events[left++].$2;
          if (counts[key] == 1) {
            counts.remove(key);
          } else {
            counts[key] = counts[key]! - 1;
          }
        }
      }
      compactness = 1 / (1 + minimumSpan / 24);
    }
    return SearchQueryEvidence(
      coverage,
      matched,
      words.length,
      compactness,
      _plan.concepts.isEmpty
          ? 0
          : matchedConcepts.length / _plan.concepts.length,
    );
  }
}

class SearchQueryEvidence {
  const SearchQueryEvidence(
    this.coverage,
    this.matchedTopics,
    this.wordCount, [
    this.compactness = 0,
    this.conceptCoverage = 0,
  ]);
  final double coverage;
  final int matchedTopics;
  final int wordCount;
  final double compactness;
  final double conceptCoverage;
}

class _Concept {
  _Concept(this.id, String variants, List<String> expansion)
    : terms = expansion.map(OfflineSearchNormalizer.keyword).toList(),
      aliases = {
        ...variants.split('|').map(OfflineSearchNormalizer.keyword),
        ...expansion.map(OfflineSearchNormalizer.keyword),
      };

  final String id;
  final List<String> terms;
  final Set<String> aliases;
}

class _Alias {
  const _Alias(this.concept, this.words);
  final _Concept concept;
  final List<String> words;
}

class _ConceptPlan {
  const _ConceptPlan(this.concepts, this.anchors, this.otherWords);
  final List<_Concept> concepts;
  final List<String> anchors;
  final Set<String> otherWords;
}
