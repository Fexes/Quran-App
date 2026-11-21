import '../domain/learning_guide.dart';

const travelIllnessGuide = LearningGuide(
  id: 'travel-illness',
  title: 'Travel & illness',
  description: 'Shortening, combining, and adapting prayer to your ability.',
  coverImage: 'assets/images/learn/prayer_travel_faceless_mat.webp',
  coverDescription: 'A traveller standing in prayer in a quiet place.',
  chapters: _travelIllnessChapters,
  sources: _travelIllnessSources,
  questions: [
    GuideGuidance(
      'Does illness allow two units instead of four?',
      'Illness alone does not permit shortening a four-unit prayer. Adapt its postures to your ability and retain the normal number of units. Shortening is a separate concession for qualifying travel.',
    ),
    GuideGuidance(
      'Do Fajr and Maghrib become shorter?',
      'No. Fajr remains two obligatory units and Maghrib remains three. Qasr changes Dhuhr, Asr, and Isha from four obligatory units to two.',
    ),
    GuideGuidance(
      'Can a traveller leave after two behind a resident imam?',
      'No. If the imam is praying four units, complete four with him. This applies even when you would shorten while praying alone.',
    ),
    GuideGuidance(
      'Can illness allow combining?',
      'Some schools and scholars permit combining for substantial illness-related hardship. Hanafi practice normally keeps each prayer in its own time. A concession from another school includes its conditions; it is not permission to merge all five prayers into one session.',
    ),
  ],
);

const _travelIllnessChapters = <GuideChapter>[
  GuideChapter(
    id: 'travel-shorten',
    title: 'Know when to shorten',
    subtitle: 'Distance, city limits, and intended stay',
    image: 'assets/images/learn/prayer_travel_faceless_mat.webp',
    imageDescription:
        'A traveller with a prayer mat in a quiet travel setting.',
    readMinutes: 3,
    category: 'Qualifying travel',
    introduction:
        'Qasr shortens the four-unit obligatory prayers to two. The distance and intended-stay rules differ between schools. These examples are labelled so they can be followed consistently.',
    steps: [
      GuideGuidance(
        'Hanafi: check the journey',
        'A widely used Hanafi threshold is 48 miles, about 77 km, along the route beyond your town or city. Begin shortening only after leaving its built-up boundary on that intended journey. You need not first travel the whole distance.',
      ),
      GuideGuidance(
        'Hanafi: check your destination',
        'At a destination that is not your permanent home, intending at least 15 complete days in one place makes you a resident on arrival. If already there, a new intention to stay that long ends traveller status then. A shorter intended stay normally retains it.',
      ),
      GuideGuidance(
        'Shorten the correct prayers',
        'In Hanafi practice, a qualifying traveller praying alone must pray Dhuhr, Asr, and Isha as two obligatory units. Keep Fajr at two and Maghrib at three. Behind an imam praying four, pray all four.',
      ),
      GuideGuidance(
        'Shafi‘i comparison',
        'The cited Shafi‘i guidance uses roughly 80 km for a lawful journey, after leaving the city. Intending four full days at the destination, excluding arrival and departure days, ends the concession there. Intend shortening with the opening takbir, and do not shorten behind an imam praying in full.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Distances are scholarly estimates',
        'Hanafi scholars also use other estimates for the classical travel distance. The 77 km figure here is a named scholarly position, not an agreed universal boundary. Returning to your permanent home ends traveller status.',
      ),
    ],
    sourceIds: [
      'travel-hanafi',
      'travel-boundary',
      'travel-distance',
      'travel-route',
      'travel-stay',
      'travel-home',
      'travel-imam',
      'travel-shafii',
    ],
  ),
  GuideChapter(
    id: 'travel-combine',
    title: 'Combining is a separate question',
    subtitle: 'Keep the conditions with the concession',
    image: 'assets/images/learn/prayer_travel_faceless_mat.webp',
    imageDescription: 'A traveller making space for prayer during a journey.',
    readMinutes: 2,
    category: 'Prayer times',
    introduction:
        'Shortening changes the number of units. Combining means praying Dhuhr with Asr, or Maghrib with Isha, in one of the pair’s times. Fajr is never part of those pairs.',
    steps: [
      GuideGuidance(
        'Hanafi ordinary travel',
        'Pray each prayer within its own time. If useful, pray Dhuhr near the end of its time and Asr as soon as Asr begins, allowing enough time to finish Dhuhr before its time ends. Both remain in their own times. Hajj has specific exceptions.',
      ),
      GuideGuidance(
        'Shafi‘i early-combining example',
        'On a qualifying journey, you may pray Dhuhr then Asr in Dhuhr’s time, or Maghrib then Isha in Maghrib’s time. Intend combining during the first prayer, keep that order, and begin the second without a long gap. Remain a traveller through the start of the second prayer.',
      ),
      GuideGuidance(
        'Keep each prayer complete',
        'These are two separate prayers, each with its own intention, opening takbir, and salam. If also shortening validly, the pair is two plus two for Dhuhr and Asr, or three plus two for Maghrib and Isha.',
      ),
      GuideGuidance(
        'Do not mix incompatible conditions',
        'If taking another school’s combining concession, meet that school’s relevant purification, prayer, distance, and stay conditions. Do not combine using the Shafi‘i rule while relying on a Hanafi stay allowance that has already ended Shafi‘i traveller status.',
      ),
    ],
    sourceIds: [
      'travel-combining-hanafi',
      'travel-shafii',
      'travel-combining-conditions',
    ],
    reminder:
        'Plan prayer stops and check local prayer times before setting out.',
  ),
  GuideChapter(
    id: 'illness-sitting',
    title: 'Pray according to your ability',
    subtitle: 'Standing, sitting, and prostrating',
    image: 'assets/images/learn/prayer_illness_faceless_mat.webp',
    imageDescription: 'A worshipper using a chair to pray during illness.',
    readMinutes: 2,
    category: 'Illness and mobility',
    introduction:
        'The Prophet taught standing when able, sitting when unable, and lying on one’s side when sitting is not possible. The practical details below use Hanafi guidance.',
    steps: [
      GuideGuidance(
        'Keep the movements you can do',
        'If you cannot stand but can bow and prostrate on the ground, sit for the standing portions and perform actual bowing and prostration. Do not replace possible prostration with a nod merely because you began seated.',
      ),
      GuideGuidance(
        'Stand for the part you can manage',
        'If standing is possible for only part of the prayer and you can still perform its normal bowing and prostration, stand for that part, then sit when needed. Support may make standing possible.',
      ),
      GuideGuidance(
        'When prostration is not possible',
        'In Hanafi practice, if illness prevents actual bowing and prostration, pray seated using head movements, even if you could stand. Make the head movement for prostration lower than the one for bowing. Use a stable chair if needed.',
      ),
      GuideGuidance(
        'Keep the recitations and number of units',
        'Continue the usual recitations, the two prostrations in each unit, and the required sittings, adapting the physical movements. Illness does not itself turn four units into two.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Inability includes harmful difficulty',
        'These concessions address inability or undue difficulty from illness, including a credible risk of worsening it. They are not limited to complete paralysis. Use the posture that your actual condition allows.',
      ),
    ],
    sourceIds: ['illness-hadith', 'illness-hanafi', 'illness-bed'],
  ),
  GuideChapter(
    id: 'illness-bed',
    title: 'If you cannot sit',
    subtitle: 'A Hanafi method for praying in bed',
    image: 'assets/images/learn/illness_bed.webp',
    imageDescription:
        'A covered worshipper lying on their side in bed, viewed from behind.',
    readMinutes: 2,
    category: 'Praying while lying down',
    introduction:
        'When sitting itself is not possible or causes undue difficulty, lying down is allowed. Keep the prayer within its time and use the movements you can make.',
    steps: [
      GuideGuidance(
        'Position yourself',
        'In the Hanafi method, lie on your back with the head supported so your face is directed towards the qibla. Alternatively, lie on your side facing it, preferably the right side if that is manageable.',
      ),
      GuideGuidance(
        'Use distinct head movements',
        'Keep the head relatively upright for the standing and sitting portions. Tilt it for bowing, return, then tilt it lower for prostration. Return between the two prostrations. Even small movements can suffice when the prostration is distinctly lower.',
      ),
      GuideGuidance(
        'Do not lift an object to the forehead',
        'When using head gestures, do not raise a pillow, table, or other object to create a substitute prostration surface. The prescribed adaptation is the head movement itself.',
      ),
      GuideGuidance(
        'Adapt purification and direction',
        'Use wudu with suitable assistance when feasible. If water cannot be used, follow the tayammum conditions. If you cannot turn towards the qibla, the cited Hanafi guidance permits the direction you can manage.',
      ),
    ],
    notes: [
      GuideGuidance(
        'If even head movement is impossible',
        'Consciousness, the duration of incapacity, and your school affect the ruling. Hanafi law does not simply replace head gestures with blinking. Obtain a ruling for that situation rather than assuming the bed method covers it.',
      ),
      GuideGuidance(
        'When prayer times are exceptionally difficult',
        'Some scholars permit combining for substantial illness-related hardship. This is a separate concession with conditions. Ordinary Hanafi practice keeps each prayer in its own time, including by placing two prayers close to a shared time boundary.',
      ),
    ],
    sourceIds: [
      'illness-bed',
      'illness-hanafi',
      'illness-combining',
      'illness-purification',
    ],
  ),
];

const _travelIllnessSources = <GuideSource>[
  GuideSource(
    id: 'travel-hanafi',
    title: 'Basic rulings of prayer during travel',
    subtitle: 'Shaykh Faraz A. Khan · Hanafi distance and prayer counts',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/the-basic-rulings-of-travel/',
  ),
  GuideSource(
    id: 'travel-boundary',
    title: 'The proprieties of travel',
    subtitle: 'Ustadh Tabraze Azam · leaving the city before shortening',
    url:
        'https://seekersguidance.org/articles/islam/adab-08-proprieties-travel/',
  ),
  GuideSource(
    id: 'travel-distance',
    title: 'Scholarly estimates of travel distance',
    subtitle: 'Ustadh Tabraze Azam · Hanafi differences',
    url:
        'https://seekersguidance.org/answers/when-should-i-start-shorten-my-prayers/',
  ),
  GuideSource(
    id: 'travel-stay',
    title: 'Intending a stay of fifteen days',
    subtitle: 'Shaykh Faraz Rabbani · when resident status begins',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/can-i-shorten-my-prayers-if-i-stay-less-than-15-days-in-each-town/',
  ),
  GuideSource(
    id: 'travel-home',
    title: 'Returning to a permanent home',
    subtitle: 'Ustadh Tabraze Azam · Hanafi traveller status',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/when-is-a-person-considered-a-traveler-who-can-shorten-their-prayers/',
  ),
  GuideSource(
    id: 'travel-imam',
    title: 'A traveller behind a resident imam',
    subtitle: 'Sidi Waseem Hussain · completing four units',
    url:
        'https://seekersguidance.org/uncategorized/a-traveler-praying-behind-a-resident-imam-do-i-shorten-my-prayers/',
  ),
  GuideSource(
    id: 'travel-shafii',
    title: 'When am I considered a traveller?',
    subtitle: 'Shaykh Shuaib Ally · Shafi‘i distance, stay, and combining',
    url:
        'https://seekersguidance.org/answers/shafii-fiqh/considered-traveller-shafii/',
  ),
  GuideSource(
    id: 'travel-combining-hanafi',
    title: 'Prayer during frequent work travel',
    subtitle: 'Shaykh Faraz Rabbani · Hanafi shortening and prayer times',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/do-i-shorten-prayers-during-frequent-work-travel/',
  ),
  GuideSource(
    id: 'travel-combining-conditions',
    title: 'Following a combining concession consistently',
    subtitle: 'Ustadh Nail Kandi · the relevant Shafi‘i conditions',
    url:
        'https://seekersguidance.org/answers/prayer-shafii-fiqh/for-how-many-days-can-a-hanafi-combine-his-prayers-as-a-traveler/',
  ),
  GuideSource(
    id: 'illness-hadith',
    title: 'Sahih al-Bukhari 1117',
    subtitle: 'Standing, sitting, or lying on one’s side according to ability',
    url: 'https://sunnah.com/bukhari:1117',
  ),
  GuideSource(
    id: 'illness-hanafi',
    title: 'How should a sick person pray?',
    subtitle: 'Shaykh Abdurrahman al-Kharsa · Hanafi posture distinctions',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/how-should-a-sick-person-pray/',
  ),
  GuideSource(
    id: 'illness-bed',
    title: 'Praying while lying down',
    subtitle: 'Shaykh Yusuf Weltch · Hanafi direction and head gestures',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/can-i-pray-laying-down-due-to-sickness-and-surgery-if-so-how/',
  ),
  GuideSource(
    id: 'illness-combining',
    title: 'Combining for illness-related hardship',
    subtitle: 'Shaykh Yusuf Weltch · concessions and prayer-time boundaries',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/is-it-permissible-for-the-elderly-to-combine-prayers-in-hanafi-school/',
  ),
  GuideSource(
    id: 'illness-purification',
    title: 'Purification when unable to wash independently',
    subtitle: 'Mawlana Ilyas Patel · assistance and tayammum',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/what-are-the-prayer-rulings-for-a-woman-unable-to-dress-or-wash-herself/',
  ),
  GuideSource(
    id: 'travel-route',
    title: 'Measuring the actual route',
    subtitle: 'Ustadh Tabraze Azam · distance beyond the city boundary',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/calculate-distance-two-cities-know-traveler/',
  ),
];
