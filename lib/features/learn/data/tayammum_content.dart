import '../domain/learning_guide.dart';

const tayammumGuide = LearningGuide(
  id: 'tayammum',
  title: 'Tayammum',
  description: 'Dry purification when water is unavailable or harmful to use.',
  coverImage: 'assets/images/learn/tayammum_faceless.webp',
  coverDescription:
      'A close view of two hands touching a clean natural stone for tayammum.',
  chapters: _tayammumChapters,
  sources: _tayammumSources,
  questions: [
    GuideGuidance(
      'Can it replace ghusl?',
      'Yes, when a valid reason prevents using water. Intend the purification you need. You do not rub dust over the entire body.',
    ),
    GuideGuidance(
      'Is a clean stone enough?',
      'In the Hanafi school, a clean natural stone is sufficient even without loose dust. The Shafi‘i method requires clean transferable earth dust. A plastic or painted surface is not automatically suitable just because it looks clean.',
    ),
    GuideGuidance(
      'Can I choose it just to save time?',
      'Ordinary inconvenience or keeping makeup intact is not a valid reason to replace available, usable water. Tayammum is a concession with conditions.',
    ),
  ],
);

const _tayammumChapters = <GuideChapter>[
  GuideChapter(
    id: 'tayammum-when',
    title: 'Check the reason first',
    subtitle: 'A concession for a real need',
    image: 'assets/images/learn/tayammum_faceless.webp',
    imageDescription:
        'Hands touching a clean natural stone, with the head entirely outside the frame.',
    readMinutes: 2,
    category: 'Before purification',
    introduction:
        'Tayammum can take the place of wudu or ghusl when water is genuinely unavailable or cannot safely be used. The Qur’an establishes this relief.',
    steps: [
      GuideGuidance(
        'Look for usable water',
        'Check accessible sources and ask someone nearby if appropriate. A broken shower is not itself lack of water when another usable supply is available. The detailed search requirement depends on your school and circumstances.',
      ),
      GuideGuidance(
        'Consider actual harm',
        'A credible risk that water will seriously worsen illness or delay recovery can allow tayammum. Ordinary dislike of cold water or the effort of washing does not by itself establish that risk.',
      ),
      GuideGuidance(
        'Use help when possible',
        'If disability prevents washing, consider suitable available assistance. In the Hanafi guidance cited here, a person unable to wash independently or with permissible help may use tayammum.',
      ),
      GuideGuidance(
        'Prepare the correct material',
        'For the Hanafi method next, use clean earth or a clean natural stone. Keep the surface free of impurity. The rules for other materials differ, so do not assume any nearby object will work.',
      ),
    ],
    sourceIds: [
      'tayammum-quran',
      'tayammum-permission',
      'tayammum-search',
      'tayammum-quduri',
      'tayammum-assistance',
      'tayammum-stone',
    ],
  ),
  GuideChapter(
    id: 'tayammum-method',
    title: 'Face, then arms',
    subtitle: 'A Hanafi method with two contacts',
    image: 'assets/images/learn/tayammum_arms.webp',
    imageDescription:
        'A hand wiping the opposite forearm at the elbow beside a dry purification stone.',
    readMinutes: 2,
    category: 'Hanafi method',
    introduction:
        'Make a deliberate wipe over the whole area. You do not need a thick coating of dirt, and you do not wash with water during tayammum.',
    steps: [
      GuideGuidance(
        'Intend purification',
        'Intend in your heart to perform tayammum for the ritual purification needed for prayer. Saying Bismillah is recommended. There is no required spoken intention.',
      ),
      GuideGuidance(
        'Touch and wipe the face',
        'Touch the clean earth or stone with both palms, then wipe the whole face. Do not put earth into the mouth or nose.',
      ),
      GuideGuidance(
        'Touch again and wipe the arms',
        'Touch the surface a second time. With the left hand, wipe the right hand and arm completely, including the elbow. Then wipe the left hand and arm with the right hand, including its elbow.',
      ),
      GuideGuidance(
        'Complete the coverage',
        'Include the hands, between the fingers, and all sides of each forearm. Remove a ring if it prevents the wipe from reaching underneath. No wiping of the head or feet is part of this method.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'Before beginning',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah.',
        meaning: 'In the name of Allah.',
        context: 'Recommended at the start of this Hanafi method.',
        sourceId: 'tayammum-method',
      ),
    ],
    sourceIds: ['tayammum-method', 'tayammum-assistance', 'tayammum-stone'],
    reminder:
        'This method wipes through the elbows. Other recognized methods differ.',
  ),
  GuideChapter(
    id: 'tayammum-after',
    title: 'Pray and know when to renew',
    subtitle: 'Duration and other recognized methods',
    image: 'assets/images/learn/tayammum_prayer.webp',
    imageDescription:
        'A clean natural stone beside a prepared prayer rug in an empty sheltered space.',
    readMinutes: 2,
    category: 'After purification',
    introduction:
        'Follow the conditions of the method you use, including when tayammum must be renewed. The schools differ on more than the number of touches.',
    steps: [
      GuideGuidance(
        'Hanafi: more than one prayer',
        'A single valid tayammum may serve more than one obligatory or voluntary prayer while the excuse continues and it has not been broken. Renew it after a wudu breaker such as passing wind.',
      ),
      GuideGuidance(
        'When water becomes usable',
        'Return to purification with water when the excuse ends. Before the next prayer, make wudu, or ghusl if major impurity was the reason for tayammum. Tayammum does not permanently cancel that requirement.',
      ),
      GuideGuidance(
        'Shafi‘i: dust and prayer time',
        'The Shafi‘i method uses clean transferable earth dust, wiping the face then the arms through the elbows with two contacts. Perform it after the obligatory prayer’s time begins and renew it for each obligatory prayer.',
      ),
      GuideGuidance(
        'Another method: face and hands',
        'Shaykh Ibn Baz teaches one contact with clean earth, followed by wiping the face and both hands to the wrists, based on the report of ‘Ammar. This is a recognized alternative, not the two-contact Hanafi method above.',
      ),
    ],
    notes: [
      GuideGuidance(
        'A completed prayer',
        'A prayer completed with valid tayammum is not automatically repeated just because water later appears. The prophetic report of two travellers illustrates this. Some unusual situations have school-specific repeat-prayer rules.',
      ),
    ],
    sourceIds: [
      'tayammum-duration',
      'tayammum-quduri',
      'tayammum-usable-water',
      'tayammum-quran',
      'tayammum-shafii',
      'tayammum-ibnbaz',
      'tayammum-water',
    ],
  ),
];

const _tayammumSources = <GuideSource>[
  GuideSource(
    id: 'tayammum-quran',
    title: 'Qur’an 5:6',
    subtitle: 'Purification and the concession of tayammum',
    url: 'https://quran.com/5/6',
  ),
  GuideSource(
    id: 'tayammum-permission',
    title: 'Valid reasons for tayammum',
    subtitle: 'Egypt’s Dar Al-Ifta · Dr. Nazir Mohammad Ayyad',
    url:
        'https://dar-alifta.org/en/fatwa/details/21991/tayammum-while-wearing-makeup',
  ),
  GuideSource(
    id: 'tayammum-search',
    title: 'Available water when a shower does not work',
    subtitle: 'Shaykh Salim Ahmad Mauladdawila · Shafi‘i guidance',
    url:
        'https://seekersguidance.org/answers/shafii-fiqh/use-sink-perform-ritual-bath-shower-doesnt-work-shafii/',
  ),
  GuideSource(
    id: 'tayammum-assistance',
    title: 'Purification when unable to wash independently',
    subtitle: 'Mawlana Ilyas Patel · Hanafi assistance and method',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/what-are-the-prayer-rulings-for-a-woman-unable-to-dress-or-wash-herself/',
  ),
  GuideSource(
    id: 'tayammum-stone',
    title: 'Using a clean stone',
    subtitle: 'Shaykh Faraz A. Khan · Hanafi material requirements',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/performing-tayammum-if-paralyzed/',
  ),
  GuideSource(
    id: 'tayammum-method',
    title: 'How to make tayammum',
    subtitle: 'Ustadh Tabraze Azam · Hanafi sequence',
    url:
        'https://seekersguidance.org/uncategorized/how-to-make-dry-ablution-tayammum/',
  ),
  GuideSource(
    id: 'tayammum-duration',
    title: 'Multiple prayers with one tayammum',
    subtitle: 'Ustadh Tabraze Azam · second question in the answer',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/should-i-make-sure-to-get-rid-of-urine-drops-before-getting-to-sleep/',
  ),
  GuideSource(
    id: 'tayammum-shafii',
    title: 'Dry purification with earth dust',
    subtitle: 'Darulfatwa · Shafi‘i method and prayer-time conditions',
    url: 'https://www.darulfatwa.org/islam-basics/tayammum-dry-purification/',
  ),
  GuideSource(
    id: 'tayammum-ibnbaz',
    title: 'The description of tayammum',
    subtitle: 'Shaykh ‘Abd al-‘Aziz Ibn Baz · Arabic transcript',
    url: 'https://ibnbaz.org/audios/333/باب-صفة-التيمم',
  ),
  GuideSource(
    id: 'tayammum-water',
    title: 'Sunan Abi Dawud 338',
    subtitle: 'Finding water after praying with tayammum',
    url: 'https://sunnah.com/abudawud:338',
  ),
  GuideSource(
    id: 'tayammum-quduri',
    title: 'Mukhtasar al-Quduri: tayammum',
    subtitle:
        'Classical Hanafi manual · search, material, and invalidators, PDF pages 16–17',
    url: 'https://data.nur.nu/Kutub/English/Laher_Quduri.pdf',
  ),
  GuideSource(
    id: 'tayammum-usable-water',
    title: 'Finding usable water before prayer',
    subtitle: 'Egypt’s Dar Al-Ifta · Prof. Dr. Shawky Alaam',
    url:
        'https://www.dar-alifta.org/en/fatwa/details/23955/performing-tayammum-and-then-finding-water-before-the-prayer',
  ),
];
