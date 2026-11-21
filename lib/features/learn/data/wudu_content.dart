import '../domain/learning_guide.dart';

const wuduGuide = LearningGuide(
  id: 'wudu',
  title: 'Wudu',
  description: 'A clear, complete guide to washing before prayer.',
  coverImage: 'assets/images/learn/wudu_hands_faceless.webp',
  coverDescription:
      'A close view of hands and wrists being washed beneath an ablution tap.',
  chapters: _wuduChapters,
  sources: _wuduSources,
  questions: [
    GuideGuidance(
      'Must I wash everything three times?',
      'One complete wash of each part that must be washed is sufficient. Washing three times is a Sunnah practice. Wipe the head once in this method. Coverage matters more than counting splashes.',
    ),
    GuideGuidance(
      'What breaks wudu?',
      'Passing urine, stool, or wind breaks wudu. Loss of consciousness and sleep have further rules. Schools differ over some kinds of touch, bleeding, and sleep, so follow your school rather than treating every possible trigger as universal.',
    ),
    GuideGuidance(
      'Does touching another person break it?',
      'Not under every school. For example, ordinary skin contact with a spouse does not itself break wudu in the Hanafi school, while direct skin contact with a spouse does in the Shafi‘i school. Other schools have their own conditions.',
    ),
    GuideGuidance(
      'What if I only doubt that it broke?',
      'If you know you made wudu, a mere doubt does not remove that certainty. Do not repeat it solely because of a suspicion that wind passed.',
    ),
    GuideGuidance(
      'What about ghusl, tayammum, or covered feet?',
      'This guide teaches ordinary wudu with water and bare feet. Ghusl, tayammum, wiping over footwear or dressings, and continuing discharge have separate conditions. Ask a qualified teacher about the method for your circumstances.',
    ),
  ],
);

const _wuduChapters = <GuideChapter>[
  GuideChapter(
    id: 'wudu-begin',
    title: 'Begin with clean hands',
    subtitle: 'Intention, hands, mouth, and nose',
    image: 'assets/images/learn/wudu_hands_faceless.webp',
    imageDescription:
        'A close view of both hands being washed, with the head outside the frame.',
    readMinutes: 2,
    category: 'Begin wudu',
    introduction:
        'Use clean, purifying water. Follow the sequence without unnecessary gaps, gently passing a hand over the parts you wash.',
    steps: [
      GuideGuidance(
        'Prepare and intend',
        'Remove anything that prevents water reaching the parts to be washed, such as impermeable nail polish. Intend wudu in your heart and keep that intention as you wash the face. Say “Bismillah,” meaning “In the name of Allah.”',
      ),
      GuideGuidance(
        'Wash both hands',
        'Wash the hands up to the wrists, including between the fingers. Washing them three times at the start is the Sunnah practice.',
      ),
      GuideGuidance(
        'Rinse the mouth',
        'Take a little water into your mouth, move it around, and spit it out. Repeat up to three times. You do not need to swallow it.',
      ),
      GuideGuidance(
        'Rinse the nose',
        'Gently draw a little water into the nostrils, then expel it. Repeat up to three times. Avoid force; while fasting, do not draw water deeply into the nose.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Required and recommended details',
        'Mouth and nose rinsing are included in the prophetic method. Their legal status differs: Hanbalis require them in wudu, while the other three Sunni schools generally treat them as Sunnah. Include them in your normal routine.',
      ),
      GuideGuidance(
        'Keep the sequence flowing',
        'Order and continuity have different legal status between schools. Follow this order and avoid long pauses. Gently rubbing the washed parts also covers the Maliki requirement of rubbing.',
      ),
    ],
    sourceIds: [
      'wudu-quran',
      'wudu-uthman',
      'wudu-bismillah',
      'wudu-nose',
      'wudu-mouth-schools',
      'wudu-order',
      'wudu-continuity',
      'wudu-rubbing',
    ],
  ),
  GuideChapter(
    id: 'wudu-wash',
    title: 'Face, arms, and head',
    subtitle: 'Wash fully, then wipe',
    image: 'assets/images/learn/wudu_face_faceless.webp',
    imageDescription:
        'A person washing the face at an ablution basin, viewed from directly behind.',
    readMinutes: 2,
    category: 'Continue in order',
    introduction:
        'Make sure the water reaches each entire area. Washing and wiping are different actions.',
    steps: [
      GuideGuidance(
        'Wash the whole face',
        'Wash from the usual hairline to the chin and across from ear to ear. Wet the facial hair as well. For a thin beard, water must reach the skin beneath; for a thick beard, wash its outer surface and gently pass wet fingers through it.',
      ),
      GuideGuidance(
        'Wash the arms, including the hands',
        'Wash the right hand and arm from fingertips through the elbow, then the left. Include the palms, between the fingers, and all around each elbow, even though you washed your hands at the beginning. Move a tight ring if needed so water reaches beneath it.',
      ),
      GuideGuidance(
        'Wipe the whole head once',
        'With wet hands, wipe from the front of the head to the back, then return to the front. This is one complete wipe. It is wiping with wet hands, not washing the head three times.',
      ),
      GuideGuidance(
        'Wipe the ears',
        'With wet fingers, wipe the visible folds inside the ears and use the thumbs behind them. Keep this gentle and do not insert fingers into the ear canals.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Once is enough when complete',
        'For the face and arms, one complete wash fulfils the washing requirement; three washes are the Sunnah practice. A splash that leaves an area dry is not a complete wash. The whole-head wipe here covers differences about how much of the head must be wiped.',
      ),
    ],
    sourceIds: [
      'wudu-quran',
      'wudu-uthman',
      'wudu-once',
      'wudu-head',
      'wudu-ears',
      'wudu-beard',
    ],
    reminder: 'Remember the hands and elbows when washing the arms.',
  ),
  GuideChapter(
    id: 'wudu-finish',
    title: 'Wash the feet and finish',
    subtitle: 'Ankles, heels, and the final remembrance',
    image: 'assets/images/learn/wudu_feet.webp',
    imageDescription: 'A person washing a bare foot over a low ablution basin.',
    readMinutes: 2,
    category: 'Complete wudu',
    introduction:
        'Finish by washing both feet thoroughly, then recite the recommended testimony.',
    steps: [
      GuideGuidance(
        'Wash the right foot, then the left',
        'Wash each foot through and including the ankles. Reach the top, sole, heel, and between the toes. One complete wash is sufficient; three is Sunnah.',
      ),
      GuideGuidance(
        'Leave no dry areas',
        'As you finish, make sure water has reached the heels and ankles. Do not turn this into repeated checking once you have washed normally.',
      ),
      GuideGuidance(
        'Say the testimony',
        'The remembrance below is recommended after wudu. It is not a condition for the wudu to count. No fixed supplication for each individual limb is required.',
      ),
    ],
    notes: [
      GuideGuidance(
        'When to renew wudu',
        'Renew after passing urine, stool, or wind. Loss of consciousness also requires purification again. The detailed rules for sleep, touching private parts, skin contact, and bleeding differ by school. Ask about your situation if needed.',
      ),
      GuideGuidance(
        'Certainty is not removed by doubt',
        'Known wudu remains valid when you merely suspect that it broke. Sound and smell in the hadith are examples of certainty about wind, not the only ways you can know that it passed.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'After wudu',
        arabic:
            'أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَنَّ مُحَمَّدًا عَبْدُ اللَّهِ وَرَسُولُهُ',
        transliteration:
            'Ashhadu an la ilaha illallah, wa anna Muhammadan ‘abdullahi wa rasuluh.',
        meaning:
            'I testify that no deity is worthy of worship except Allah, and that Muhammad is Allah’s servant and messenger.',
        context:
            'Recommended after completing wudu. This is the wording in Sahih Muslim 234a; other reported versions are also used.',
        sourceId: 'wudu-testimony',
      ),
    ],
    sourceIds: [
      'wudu-quran',
      'wudu-uthman',
      'wudu-once',
      'wudu-heels',
      'wudu-testimony',
      'wudu-doubt',
      'wudu-touch-hanafi',
      'wudu-touch-shafii',
      'wudu-nullifiers',
    ],
    reminder: 'A complete, unhurried wash is enough.',
  ),
];

const _wuduSources = <GuideSource>[
  GuideSource(
    id: 'wudu-quran',
    title: 'The Quranic instruction for wudu',
    subtitle: 'Quran 5:6',
    url: 'https://quran.com/5/6',
  ),
  GuideSource(
    id: 'wudu-uthman',
    title: 'The prophetic washing sequence',
    subtitle: 'Sahih al-Bukhari 159',
    url: 'https://sunnah.com/bukhari:159',
  ),
  GuideSource(
    id: 'wudu-bismillah',
    title: 'Mentioning Allah’s name',
    subtitle: 'Sunan Abi Dawud 101',
    url: 'https://sunnah.com/abudawud:101',
  ),
  GuideSource(
    id: 'wudu-nose',
    title: 'Rinsing the nose while fasting',
    subtitle: 'Sunan Abi Dawud 142',
    url: 'https://sunnah.com/abudawud:142',
  ),
  GuideSource(
    id: 'wudu-mouth-schools',
    title: 'Mouth and nose rinsing: school differences',
    subtitle: 'Islamweb, fatwa 93852',
    url: 'https://www.islamweb.com/ar/fatwa/print.php?id=93852',
  ),
  GuideSource(
    id: 'wudu-order',
    title: 'Order in the Shafi‘i school',
    subtitle: 'Jordan Iftaa Department, fatwa 3838',
    url: 'https://www.aliftaa.jo/QuestionPrintEn.aspx?QuestionId=3838',
  ),
  GuideSource(
    id: 'wudu-continuity',
    title: 'Order and continuity in the Hanafi school',
    subtitle: 'Ustadh Tabraze Azam, SeekersGuidance',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/forgetting-parts-of-ritual-ablution-wudu-and-maintaining-continuity/',
  ),
  GuideSource(
    id: 'wudu-rubbing',
    title: 'Rubbing in the Maliki school',
    subtitle: 'Islamweb, fatwa 65334',
    url: 'https://www.islamweb.net/amp/ar/fatwa/65334/',
  ),
  GuideSource(
    id: 'wudu-once',
    title: 'One complete wash',
    subtitle: 'Sahih al-Bukhari 157',
    url: 'https://sunnah.com/bukhari:157',
  ),
  GuideSource(
    id: 'wudu-head',
    title: 'Wiping from front to back and returning',
    subtitle: 'Sahih al-Bukhari 185',
    url: 'https://sunnah.com/bukhari:185',
  ),
  GuideSource(
    id: 'wudu-ears',
    title: 'Wiping the ears',
    subtitle: 'Sunan Abi Dawud 135',
    url: 'https://sunnah.com/abudawud:135',
  ),
  GuideSource(
    id: 'wudu-beard',
    title: 'Washing the beard',
    subtitle: 'Ustadh Tabraze Azam, SeekersGuidance',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/what-is-the-proper-way-to-wash-ones-beard-during-wudu/',
  ),
  GuideSource(
    id: 'wudu-heels',
    title: 'Washing the heels completely',
    subtitle: 'Sahih al-Bukhari 60',
    url: 'https://sunnah.com/bukhari:60',
  ),
  GuideSource(
    id: 'wudu-testimony',
    title: 'Remembrance after wudu',
    subtitle: 'Sahih Muslim 234a',
    url: 'https://sunnah.com/muslim:234a',
  ),
  GuideSource(
    id: 'wudu-doubt',
    title: 'Certainty and doubt about wudu',
    subtitle: 'Sahih Muslim 362',
    url: 'https://sunnah.com/muslim:362',
  ),
  GuideSource(
    id: 'wudu-touch-hanafi',
    title: 'Touching another person: Hanafi ruling',
    subtitle: 'Darul Iftaa Chicago, fatwa 206',
    url: 'https://daruliftaa.us/fatwa/206/',
  ),
  GuideSource(
    id: 'wudu-touch-shafii',
    title: 'Touching a spouse: Shafi‘i ruling',
    subtitle: 'Jordan Iftaa Department, fatwa 4044',
    url: 'https://aliftaa.jo/QuestionPrintEn.aspx?QuestionId=4044',
  ),
  GuideSource(
    id: 'wudu-nullifiers',
    title: 'Events that require fresh wudu',
    subtitle: 'Shaykh Faraz Rabbani, SeekersGuidance, Hanafi answer',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/could-you-please-list-all-the-nullifiers-of-ablution-according-to-the-hanafi-school/',
  ),
];
