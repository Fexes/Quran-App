import '../domain/learning_guide.dart';

// Source review is recorded in docs/umrah_research.md. Transliterations and
// English meanings are editorial renderings; Arabic follows the source text.
const List<GuideSource> umrahSources = [
  GuideSource(
    id: 'nusuk',
    title: 'The Umrah journey',
    subtitle: 'Nusuk, Ministry of Hajj and Umrah',
    url: 'https://umrah.nusuk.sa/Journey',
  ),
  GuideSource(
    id: 'nusuk-planning',
    title: 'Plan your Umrah',
    subtitle: 'Nusuk: permits and current arrangements',
    url: 'https://www.nusuk.sa/umrah',
  ),
  GuideSource(
    id: 'ihram-guide',
    title: 'Ihram guidance',
    subtitle: 'Ministry of Hajj and Umrah: Ihram Guide',
    url:
        'https://haj.gov.sa/-/media/Project/HAJJ/Awareness-Guides/'
        'Ihram-Guide/English/EN-Ihram-Guide.pdf',
  ),
  GuideSource(
    id: 'prh-guide',
    title: 'How to perform the rites',
    subtitle: 'Alharamain: Hajj, Umrah and visitation guidance',
    url: 'https://risala.prh.gov.sa/en/contents/114',
  ),
  GuideSource(
    id: 'muslim-1218',
    title: 'The Prophet’s practice',
    subtitle: 'Sahih Muslim 1218a: Jabir’s account',
    url: 'https://sunnah.com/muslim:1218a',
  ),
  GuideSource(
    id: 'bukhari-1549',
    title: 'The talbiyah',
    subtitle: 'Sahih al-Bukhari 1549',
    url: 'https://sunnah.com/bukhari:1549',
  ),
  GuideSource(
    id: 'bukhari-1524',
    title: 'The miqat boundaries',
    subtitle: 'Sahih al-Bukhari 1524',
    url: 'https://sunnah.com/bukhari:1524',
  ),
  GuideSource(
    id: 'bukhari-1838',
    title: 'Clothing in ihram',
    subtitle: 'Sahih al-Bukhari 1838',
    url: 'https://sunnah.com/bukhari:1838',
  ),
  GuideSource(
    id: 'bukhari-1613',
    title: 'Passing the Black Stone',
    subtitle: 'Sahih al-Bukhari 1613',
    url: 'https://sunnah.com/bukhari:1613',
  ),
  GuideSource(
    id: 'abudawud-1883',
    title: 'The right shoulder during tawaf',
    subtitle: 'Sunan Abi Dawud 1883, graded hasan by al-Albani',
    url: 'https://sunnah.com/abudawud:1883',
  ),
  GuideSource(
    id: 'tawaf-dua',
    title: 'Dua during tawaf and sa’i',
    subtitle: 'Ibn Baz: supplication during tawaf, fatwa 15716',
    url: 'https://binbaz.org.sa/fatwas/15716/الدعاء-في-الطواف',
  ),
  GuideSource(
    id: 'abudawud-1892',
    title: 'Dua between the corners',
    subtitle: 'Sunan Abi Dawud 1892, graded hasan by al-Albani',
    url: 'https://sunnah.com/abudawud:1892',
  ),
  GuideSource(
    id: 'quran-2-201',
    title: 'Good in this life and the next',
    subtitle: 'Quran, Al-Baqarah 2:201',
    url: 'https://quran.com/2/201',
  ),
  GuideSource(
    id: 'muslim-713',
    title: 'Entering a mosque',
    subtitle: 'Sahih Muslim 713a',
    url: 'https://sunnah.com/muslim:713a',
  ),
  GuideSource(
    id: 'bukhari-1650',
    title: 'Menstruation and tawaf',
    subtitle: 'Sahih al-Bukhari 1650',
    url: 'https://sunnah.com/bukhari:1650',
  ),
  GuideSource(
    id: 'umrah-rulings',
    title: 'Rites and scholarly differences',
    subtitle: 'Egypt’s Dar al-Ifta: The Umrah, Rulings and Rites',
    url:
        'https://www.dar-alifta.org/en/article/details/103/'
        'the-umrah-rulings-and-rites',
  ),
  GuideSource(
    id: 'tawaf-purity',
    title: 'Wudu during tawaf',
    subtitle: 'Egypt’s Dar al-Ifta: research on interrupted wudu',
    url:
        'https://www.dar-alifta.org/ar/FatwaResearch/details/185/'
        'انتقاض-الوضوء-أثناء-الطواف',
  ),
  GuideSource(
    id: 'tawaf-requirements',
    title: 'Completing tawaf correctly',
    subtitle: 'Egypt’s Dar al-Ifta: duties of tawaf, fatwa 20651',
    url:
        'https://dar-alifta.org/ar/fatwa/details/20651/'
        'بيان-واجبات-الطواف',
  ),
  GuideSource(
    id: 'prayer-ruling',
    title: 'The two rak’ahs after tawaf',
    subtitle: 'Islamweb, fatwa 121305: the schools’ rulings',
    url:
        'https://www.islamweb.net/en/fatwa/121305/'
        'ruling-of-two-rakahs-after-tawaaf',
  ),
  GuideSource(
    id: 'women-face',
    title: 'Women’s face covering',
    subtitle: 'Jordan Iftaa Department, question 1259',
    url: 'https://aliftaa.jo/QuestionPrintEn.aspx?QuestionId=1259',
  ),
  GuideSource(
    id: 'footwear',
    title: 'Footwear in ihram',
    subtitle: 'Islamic Portal: Yusuf Shabbir, scholarly review noted',
    url: 'https://islamicportal.co.uk/footwear-in-ihram/',
  ),
  GuideSource(
    id: 'saudi-health',
    title: 'Current health requirements',
    subtitle: 'Saudi Ministry of Health: Pilgrim’s Health',
    url:
        'https://www.moh.gov.sa/en/healthawareness/'
        'pilgrims-health/pages/default.aspx',
  ),
  GuideSource(
    id: 'bukhari-1727',
    title: 'Shaving or shortening',
    subtitle: 'Sahih al-Bukhari 1727',
    url: 'https://sunnah.com/bukhari:1727',
  ),
  GuideSource(
    id: 'self-haircut',
    title: 'Who may cut the hair?',
    subtitle: 'Egypt’s Dar al-Ifta, fatwa 6343',
    url:
        'https://www.dar-alifta.org/en/fatwa/details/6343/'
        'the-ruling-for-a-muhrim-shaving-his-head-himself-or-for-another-after-finishing-t',
  ),
  GuideSource(
    id: 'haircut-location',
    title: 'Where to cut the hair',
    subtitle: 'Islamic Portal: Hanafi ruling on the Haram boundary',
    url: 'https://islamicportal.co.uk/does-hair-have-to-be-shaved-in-haram/',
  ),
];

const List<GuideChapter> umrahChapters = [
  GuideChapter(
    id: 'overview',
    title: 'Your Umrah journey',
    subtitle: 'A clear path, from preparation to completion.',
    image: 'assets/images/learn/umrah_overview_faceless.webp',
    imageDescription:
        'The Kaaba and an empty marble courtyard in warm morning light.',
    readMinutes: 2,
    category: 'Before you begin',
    introduction:
        'Umrah is worship in Makkah: enter ihram, circle the Kaaba, '
        'walk between Safa and Marwah, then cut your hair to leave ihram.',
    steps: [
      GuideGuidance(
        'Know the order',
        'Ihram → seven circuits of tawaf → seven lengths of sa’i → '
            'shaving or shortening the hair. The following chapters explain '
            'each rite and the worship between them.',
      ),
      GuideGuidance(
        'Arrange the journey',
        'Before travel, check Nusuk for your visa, Umrah permit or booking, '
            'and seasonal access arrangements. Check the Saudi Ministry of '
            'Health for current entry and vaccination requirements.',
      ),
      GuideGuidance(
        'Prepare for the walking',
        'Bring essential medicines, water, suitable footwear and a small bag. '
            'Agree on a meeting point with your companions. Follow staff '
            'directions and use official assistance when needed.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Umrah and Hajj are different',
        'Arafat, Muzdalifah and stoning the Jamarat belong to Hajj. They are '
            'not steps of this Umrah. Visiting Madinah is separate from Umrah.',
      ),
      GuideGuidance(
        'About this guide',
        'A practical guide based on Sunni sources. Schools differ on some '
            'details and legal classifications. For a personal circumstance '
            'or a mistake, ask a qualified scholar familiar with your school.',
      ),
    ],
    sourceIds: ['nusuk', 'nusuk-planning', 'saudi-health', 'umrah-rulings'],
    reminder:
        'Read the steps before you travel. Take your time when you arrive.',
  ),
  GuideChapter(
    id: 'ihram',
    title: 'Ihram & the miqat',
    subtitle: 'Begin with intention, before crossing the boundary.',
    image: 'assets/images/learn/umrah_ihram_faceless.webp',
    imageDescription:
        'Straight rear view of a bareheaded pilgrim in white ihram with both shoulders covered.',
    readMinutes: 3,
    category: 'Entering the rites',
    introduction:
        'Ihram is a sacred state entered with the intention of '
        'Umrah. Putting on the garments alone does not begin it.',
    steps: [
      GuideGuidance(
        'Prepare before entering ihram',
        'Bathing is recommended. Men wear an izar around the waist and a '
            'rida over the upper body. Women wear their usual modest clothing '
            'with the head covered; no special colour is required.',
      ),
      GuideGuidance(
        'Enter by your route’s miqat',
        'If travelling with the intention of Umrah, enter ihram at or before '
            'the miqat, the boundary for your route. On a flight, prepare '
            'early and enter before crossing it. Do not wait to reach Jeddah.',
      ),
      GuideGuidance(
        'Intend Umrah and recite talbiyah',
        'Make the intention in your heart. You may say “Labbayka Allahumma '
            '‘umrah” (O Allah, I respond to You for Umrah), then recite the '
            'talbiyah below. Continue it on your journey until beginning tawaf.',
      ),
      GuideGuidance(
        'Observe the restrictions',
        'While in ihram, avoid perfume, deliberately removing hair or '
            'clipping nails, sexual activity, marriage contracts and hunting '
            'land game. Men also avoid shirts, trousers, underwear and head '
            'coverings. A belt, bag or umbrella is allowed.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Women’s clothing',
        'Do not wear a fitted niqab or gloves in ihram. Draping fabric over '
            'the face is a separate ruling with details that differ by school. '
            'Follow your scholar’s guidance for face covering or medical needs.',
      ),
      GuideGuidance(
        'Choose footwear beforehand',
        'Men should choose suitable open sandals. Scholars differ about '
            'which parts of the foot may be covered, especially in Hanafi '
            'practice. Check your particular footwear before travelling. '
            'The same footwear restriction does not apply to women.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'The talbiyah',
        arabic:
            'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ '
            'لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، '
            'لَا شَرِيكَ لَكَ',
        transliteration:
            'Labbayka Allahumma labbayk. Labbayka la sharika laka '
            'labbayk. Inna al-hamda wa-n-ni‘mata laka wa-l-mulk. La sharika lak.',
        meaning:
            'Here I am, O Allah, answering Your call. You have no partner. '
            'All praise, blessing and sovereignty belong to You. You have no partner.',
        context:
            'Recite after intending Umrah. This is the Prophet’s talbiyah.',
        sourceId: 'bukhari-1549',
      ),
    ],
    sourceIds: [
      'bukhari-1524',
      'bukhari-1838',
      'bukhari-1549',
      'ihram-guide',
      'prh-guide',
      'women-face',
      'footwear',
    ],
    reminder:
        'Already in Makkah, or crossed the miqat without ihram? '
        'Ask a qualified guide about your situation before proceeding.',
  ),
  GuideChapter(
    id: 'tawaf',
    title: 'Around the Kaaba',
    subtitle: 'Seven complete circuits, with the Kaaba on your left.',
    image: 'assets/images/learn/umrah_tawaf_faceless.webp',
    imageDescription:
        'An overhead view of pilgrims circling counterclockwise around the Kaaba, with only the tops of heads visible.',
    readMinutes: 3,
    category: 'Tawaf',
    introduction:
        'Perform tawaf with wudu and appropriate covering. '
        'Begin at the line of the Black Stone and move with the crowd.',
    steps: [
      GuideGuidance(
        'Begin at the Black Stone',
        'When aligned with it, gesture towards it and say “Allahu akbar”. '
            'Touching or kissing it is optional. Do not push, stop the flow '
            'or harm anyone to reach it.',
      ),
      GuideGuidance(
        'Complete seven circuits',
        'Walk counterclockwise, keeping the Kaaba on your left. Go outside '
            'the semicircular wall of the Hijr; do not cut through it. '
            'Returning to the Black Stone completes one circuit.',
      ),
      GuideGuidance(
        'Remember Allah as you walk',
        'Make personal dua, recite Quran or remember Allah. There is no '
            'prescribed dua for each numbered circuit. The dua below is '
            'reported between the Yemeni Corner and the Black Stone.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Recommended for men',
        'Expose the right shoulder during this tawaf only. If there is room, '
            'walk briskly with short steps in the first three circuits, then '
            'normally in the last four. Women walk normally and remain covered.',
      ),
      GuideGuidance(
        'If wudu breaks',
        'Renew it. Most schools treat purity as a condition for valid tawaf; '
            'Hanafis classify it as an obligation. How to resume can differ. '
            'Ask a qualified guide rather than assuming your Umrah is invalid.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'On entering the mosque',
        arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        transliteration: 'Allahumma iftah li abwaba rahmatik.',
        meaning: 'O Allah, open the doors of Your mercy for me.',
        context: 'A recommended dua when entering any mosque.',
        sourceId: 'muslim-713',
      ),
      GuideSupplication(
        title: 'Between the two corners',
        arabic:
            'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ '
            'حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
        transliteration:
            'Rabbana atina fi-d-dunya hasanatan wa fi-l-akhirati '
            'hasanatan wa qina ‘adhaba-n-nar.',
        meaning:
            'Our Lord, give us goodness in this world and the next, '
            'and save us from the punishment of the Fire.',
        context: 'Quran 2:201. Reciting it here is reported in Abu Dawud 1892.',
        sourceId: 'abudawud-1892',
      ),
    ],
    sourceIds: [
      'bukhari-1613',
      'abudawud-1883',
      'muslim-1218',
      'tawaf-dua',
      'tawaf-requirements',
      'prh-guide',
      'tawaf-purity',
      'muslim-713',
      'abudawud-1892',
      'quran-2-201',
    ],
    reminder:
        'Never push to reach the Black Stone. Your circuit counts from a distance.',
  ),
  GuideChapter(
    id: 'prayer',
    title: 'Prayer & Zamzam',
    subtitle: 'A quiet pause after tawaf, before sa’i.',
    image: 'assets/images/learn/umrah_prayer_faceless_mat.webp',
    imageDescription:
        'Rear view of a pilgrim seated after prayer near the courtyard, beside a Zamzam cup and dispenser.',
    readMinutes: 2,
    category: 'After tawaf',
    introduction:
        'After seven circuits, leave the moving crowd safely. '
        'Men cover both shoulders again before praying.',
    steps: [
      GuideGuidance(
        'Pray two rak’ahs',
        'Pray behind Maqam Ibrahim if there is safe space. Otherwise, '
            'pray elsewhere in the mosque. Keep walking routes clear.',
      ),
      GuideGuidance(
        'Recite what you know',
        'After Al-Fatihah, Al-Kafirun in the first rak’ah and Al-Ikhlas '
            'in the second are recommended. Other surahs are also valid.',
      ),
      GuideGuidance(
        'Drink and continue',
        'Drink Zamzam if available and make personal dua. Then follow '
            'the signs to Safa, where sa’i begins. Drinking Zamzam is not '
            'a condition for completing Umrah.',
      ),
    ],
    notes: [
      GuideGuidance(
        'A difference between schools',
        'The two rak’ahs after Umrah tawaf are obligatory in Hanafi and '
            'the well-known Maliki ruling, and recommended in Shafi’i '
            'and Hanbali practice. Include them in your journey.',
      ),
    ],
    sourceIds: ['muslim-1218', 'prh-guide', 'prayer-ruling'],
    reminder: 'You do not need to pray immediately next to Maqam Ibrahim.',
  ),
  GuideChapter(
    id: 'sai',
    title: 'Safa to Marwah',
    subtitle: 'Seven lengths. Begin at Safa and finish at Marwah.',
    image: 'assets/images/learn/umrah_sai_faceless.webp',
    imageDescription:
        'Five pilgrims seen entirely from behind walking through the modern Safa and Marwah gallery.',
    readMinutes: 3,
    category: 'Sa’i',
    introduction:
        'After tawaf, walk the full route between Safa and Marwah '
        'seven times. Each one-way journey counts as one length.',
    steps: [
      GuideGuidance(
        'Start at Safa',
        'At Safa, it is recommended to face the qiblah, praise Allah, say '
            '“Allahu akbar” and make dua. Repeat this remembrance at Marwah. '
            'You do not need to climb the rocks.',
      ),
      GuideGuidance(
        'Count each direction once',
        'Safa → Marwah is 1. Marwah → Safa is 2. Continue to 7, ending '
            'at Marwah. Seven lengths means three return journeys '
            'and one final journey to Marwah.',
      ),
      GuideGuidance(
        'Walk between the markers',
        'For men who are able, running between the green markers is '
            'recommended when safe. Walk elsewhere. Women walk throughout. Keep '
            'making dua without a fixed prayer for each length.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Wudu and accessibility',
        'Wudu is recommended for sa’i, but is not a condition for its '
            'validity. If you need assistance, follow the mosque’s '
            'designated accessible routes and current staff guidance.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'Remembrance at Safa and Marwah',
        arabic:
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
            'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، '
            'وَنَصَرَ عَبْدَهُ، وَهَزَمَ الْأَحْزَابَ وَحْدَهُ',
        transliteration:
            'La ilaha illa Allahu wahdahu la sharika lah. '
            'Lahu-l-mulku wa lahu-l-hamd, wa huwa ‘ala kulli shay’in qadir. '
            'La ilaha illa Allahu wahdah. Anjaza wa‘dah, wa nasara ‘abdah, '
            'wa hazama-l-ahzaba wahdah.',
        meaning:
            'Allah alone is worthy of worship, without a partner. '
            'Sovereignty and praise are His, and He has power over everything. '
            'Allah alone is worthy of worship. He fulfilled His promise, '
            'supported His servant and defeated the allied forces alone.',
        context:
            'At Safa and Marwah, repeating this dhikr three times, with '
            'personal dua between, is recommended, as reported in Muslim 1218a.',
        sourceId: 'muslim-1218',
      ),
    ],
    sourceIds: ['nusuk', 'muslim-1218', 'prh-guide', 'tawaf-dua'],
    reminder: 'Safa → Marwah = one length. Finish your seventh at Marwah.',
  ),
  GuideChapter(
    id: 'completion',
    title: 'Complete your Umrah',
    subtitle: 'Cut your hair after sa’i, then leave ihram.',
    image: 'assets/images/learn/umrah_completion_faceless.webp',
    imageDescription:
        'Straight rear view of a pilgrim with a freshly shaved head after completing Umrah.',
    readMinutes: 2,
    category: 'Leaving ihram',
    introduction:
        'After all seven lengths of sa’i, shave or shorten '
        'your hair. The restrictions of ihram continue until this is done.',
    steps: [
      GuideGuidance(
        'For men',
        'Shave the whole head or shorten the hair across the head. Shaving '
            'is generally preferred for a standalone Umrah. Do not rely on '
            'cutting a token lock: the minimum amount differs by school.',
      ),
      GuideGuidance(
        'For women',
        'Shorten the ends of the hair in private; do not shave the head. '
            'Nusuk advises about 1–2 cm. Exact length and the amount of hair '
            'to include differ by school, so follow your scholar’s guidance.',
      ),
      GuideGuidance(
        'Leave ihram',
        'Once the haircut is complete, your Umrah is complete and the '
            'special ihram restrictions end. You may change into normal '
            'clothes. Thank Allah and continue your worship.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Where and who?',
        'Arrange the haircut within the Haram boundary, the sacred '
            'precinct around Makkah; this is required in Hanafi practice. '
            'If your accommodation is inside it, you may cut your hair '
            'there. After sa’i, you may cut it yourself or have someone help.',
      ),
    ],
    sourceIds: [
      'nusuk',
      'umrah-rulings',
      'bukhari-1727',
      'self-haircut',
      'haircut-location',
    ],
    reminder:
        'Walking the last length does not end ihram. The haircut completes it.',
  ),
];

const List<GuideGuidance> umrahQuestions = [
  GuideGuidance(
    'What if I lose count?',
    'During tawaf or sa’i, use the number you are certain you completed. '
        'If unsure whether it was three or four, count three and continue.',
  ),
  GuideGuidance(
    'What if my period begins?',
    'You can enter ihram while menstruating. Normally, wait until bleeding '
        'ends and perform ghusl before tawaf. If travel timing makes waiting '
        'difficult, seek a qualified scholar’s advice before leaving or '
        'attempting tawaf. Do not assume the Umrah is cancelled.',
  ),
  GuideGuidance(
    'Must I touch the Kaaba?',
    'No. Touching the Kaaba or kissing the Black Stone is not required '
        'to complete Umrah. Stay with the crowd and avoid causing harm.',
  ),
  GuideGuidance(
    'Do I need a dua for every round?',
    'No specific dua is prescribed for each numbered circuit or length. '
        'You may ask Allah in your own language. The guide includes short '
        'supplications with their sources.',
  ),
  GuideGuidance(
    'Are travel requirements fixed?',
    'No. Permits, visa conditions, seasonal access and health requirements '
        'can change. Check Nusuk and the Saudi Ministry of Health again '
        'before departure.',
  ),
];

const umrahGuide = LearningGuide(
  id: 'umrah',
  title: 'Umrah',
  description: 'From ihram to the final haircut.',
  coverImage: 'assets/images/learn/umrah_overview_faceless.webp',
  coverDescription:
      'The Kaaba and an empty marble courtyard in warm morning light.',
  chapters: umrahChapters,
  sources: umrahSources,
  questions: umrahQuestions,
);
