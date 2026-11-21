import '../domain/learning_guide.dart';

const ghuslGuide = LearningGuide(
  id: 'ghusl',
  title: 'Ghusl',
  description: 'When a full ritual wash is needed, and how to complete it.',
  coverImage: 'assets/images/learn/ghusl_preparation.webp',
  coverDescription: 'A clean, private washing area prepared for ghusl.',
  chapters: _ghuslChapters,
  sources: _ghuslSources,
  questions: [
    GuideGuidance(
      'Can I use a shower?',
      'Yes. In the Hanafi method taught here, rinse the mouth and nose and let water flow over the entire body. A shower can accomplish this; soaking in a bath is not required.',
    ),
    GuideGuidance(
      'Do I have to say an intention aloud?',
      'No. Intend purification in your heart. No spoken formula is needed. Intention is Sunnah for ghusl in the Hanafi school and required in the Shafi‘i school, so include it as washing begins.',
    ),
    GuideGuidance(
      'Is every discharge a reason for ghusl?',
      'No. Madhi, the thin fluid associated with arousal before ejaculation, requires washing the affected area and making wudu, rather than ghusl. The causes of major impurity are different from ordinary wudu breakers.',
    ),
  ],
);

const _ghuslChapters = <GuideChapter>[
  GuideChapter(
    id: 'ghusl-when',
    title: 'Know when it is needed',
    subtitle: 'Major impurity and the end of bleeding',
    image: 'assets/images/learn/ghusl_preparation.webp',
    imageDescription: 'Water and washing supplies prepared in a private space.',
    readMinutes: 2,
    category: 'Before the wash',
    introduction:
        'Ghusl is a full ritual wash that removes major ritual impurity. This guide uses a Hanafi method and points out selected school differences.',
    steps: [
      GuideGuidance(
        'After intercourse',
        'Penetrative intercourse requires ghusl for both partners, even without ejaculation. Washing only the private parts or making wudu does not replace it.',
      ),
      GuideGuidance(
        'After ejaculation or a wet dream',
        'In the Hanafi school, ejaculation associated with sexual pleasure requires ghusl. A remembered sexual dream alone, without the relevant discharge, does not. This applies to women as well as men.',
      ),
      GuideGuidance(
        'After menstruation or postnatal bleeding',
        'Once the bleeding has ended under the rules of your cycle, perform ghusl before resuming prayer. Washing while the bleeding continues does not end the menstrual or postnatal state.',
      ),
      GuideGuidance(
        'Distinguish minor impurity',
        'Passing urine or wind requires wudu, not a full bath. Madhi requires cleaning the affected area and wudu. A feeling of arousal on its own does not require ghusl.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Irregular bleeding needs its own ruling',
        'Menstruation, postnatal bleeding, and irregular bleeding have different prayer rules. If bleeding stops and returns or differs from your usual cycle, record the dates and obtain a ruling for that pattern.',
      ),
    ],
    sourceIds: [
      'ghusl-causes',
      'ghusl-intercourse',
      'ghusl-dream',
      'ghusl-madhi',
    ],
    reminder:
        'A dream or suspicion alone is not a reason to keep repeating ghusl.',
  ),
  GuideChapter(
    id: 'ghusl-wash',
    title: 'Wash from head to toe',
    subtitle: 'A complete Hanafi method',
    image: 'assets/images/learn/ghusl_wash.webp',
    imageDescription:
        'An empty private shower with running water, a clean towel and washing supplies.',
    readMinutes: 2,
    category: 'The method',
    introduction:
        'Choose a private place and use clean, purifying water. A normal, thorough wash is enough; there is no need to scrub harshly.',
    steps: [
      GuideGuidance(
        'Prepare and begin',
        'Remove removable barriers that keep water off the skin, such as impermeable nail polish. Intend purification. Before undressing, say Bismillah. Wash your hands, private parts, and any impurity on the body.',
      ),
      GuideGuidance(
        'Make wudu',
        'Perform your usual wudu, including rinsing the mouth and nose. Let water reach the inside of the mouth and the soft inner part of the nostrils gently. Do not swallow water or draw it deeply into the nose while fasting.',
      ),
      GuideGuidance(
        'Wash the hair and scalp',
        'Work water through the hair to the roots. Pour water over the head three times as in the prophetic description. Water must reach the scalp; simply wiping the hair is not enough.',
      ),
      GuideGuidance(
        'Wash the whole body',
        'Wash the right side, then the left, and reach every area. Include behind the ears, under the arms, the navel, skin folds, between fingers and toes, and the feet. Let water flow over the skin rather than merely passing a damp hand over it.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Required coverage and Sunnah practice',
        'In Hanafi law, one complete wash of the mouth, nose, and entire body fulfils the essentials. The fuller sequence, beginning with wudu and washing three times, includes recommended practices. Avoid wasting water.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'Before beginning',
        arabic: 'بِسْمِ اللَّهِ',
        transliteration: 'Bismillah.',
        meaning: 'In the name of Allah.',
        context:
            'Recommended before undressing. This is not a spoken intention.',
        sourceId: 'ghusl-method',
      ),
    ],
    sourceIds: [
      'ghusl-prophetic',
      'ghusl-method',
      'ghusl-barriers',
      'ghusl-mouth',
    ],
  ),
  GuideChapter(
    id: 'ghusl-finish',
    title: 'Finish with confidence',
    subtitle: 'Hair, wudu, and school differences',
    image: 'assets/images/learn/ghusl_preparation.webp',
    imageDescription:
        'A calm washing area with clean water and a folded towel.',
    readMinutes: 2,
    category: 'After the wash',
    introduction:
        'Once the required areas have been washed, ghusl is complete. Its validity depends on purification, not on a special towel, soap, or long recitation.',
    steps: [
      GuideGuidance(
        'Make sure water reaches the roots',
        'In the Hanafi school, a woman may leave her hair braided if water reaches all the roots. If the braids prevent this, loosen them. This concession does not mean keeping the scalp dry.',
      ),
      GuideGuidance(
        'Know whether wudu is still needed',
        'A valid Hanafi ghusl that includes the mouth, nose, and whole body also removes minor impurity. If a wudu breaker occurs during or after ghusl, renew wudu before praying; the ghusl itself need not be repeated.',
      ),
      GuideGuidance(
        'Use one consistent method',
        'Mouth and nose rinsing are required in Hanafi ghusl and recommended in Shafi‘i ghusl. Intend purification and include both rinses in your routine. In Shafi‘i practice, have the intention present as the first part of the body is washed.',
      ),
    ],
    notes: [
      GuideGuidance(
        'If water cannot be used',
        'A valid reason such as harmful water use or genuine lack of water can permit tayammum. Needing ghusl does not exclude that concession. See the Tayammum guide for its conditions and method.',
      ),
    ],
    sourceIds: [
      'ghusl-method',
      'ghusl-braids',
      'ghusl-intention',
      'ghusl-nullifier',
      'ghusl-wudu',
      'ghusl-mouth',
      'ghusl-barriers',
    ],
    reminder:
        'Wash normally and move on. Do not keep checking imagined dry areas.',
  ),
];

const _ghuslSources = <GuideSource>[
  GuideSource(
    id: 'ghusl-causes',
    title: 'What makes ghusl necessary?',
    subtitle: 'Torab Torabi, checked by Faraz Rabbani · Hanafi guidance',
    url:
        'https://seekersguidance.org/answers/general-counsel/i-felt-a-moment-of-sexual-pleasure-without-ejaculating-do-i-need-to-perform-a-ritual-bath-ghusl/',
  ),
  GuideSource(
    id: 'ghusl-intercourse',
    title: 'Ghusl after intercourse',
    subtitle: 'Darul Iftaa Chicago · approved by Mufti Abrar Mirza',
    url: 'https://daruliftaa.us/fatwa/571/',
  ),
  GuideSource(
    id: 'ghusl-dream',
    title: 'Sahih al-Bukhari 282',
    subtitle: 'Wet dreams and the presence of discharge',
    url: 'https://sunnah.com/bukhari:282',
  ),
  GuideSource(
    id: 'ghusl-madhi',
    title: 'Sahih al-Bukhari 269',
    subtitle: 'Cleaning and wudu for madhi',
    url: 'https://sunnah.com/bukhari:269',
  ),
  GuideSource(
    id: 'ghusl-prophetic',
    title: 'Sahih al-Bukhari 248',
    subtitle: 'The Prophet’s washing sequence',
    url: 'https://sunnah.com/bukhari:248',
  ),
  GuideSource(
    id: 'ghusl-method',
    title: 'Ghusl: obligatory and recommended acts',
    subtitle: 'Shaykh Faraz Rabbani · Hanafi method and hair rules',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/the-ritual-bath-ghusl-obligatory-recommended-and-disliked-acts/',
  ),
  GuideSource(
    id: 'ghusl-mouth',
    title: 'Mouth and nose rinsing in ghusl',
    subtitle: 'Ustadha Shazia Ahmad · Hanafi and Shafi‘i distinction',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/is-it-obligatory-to-rinse-ones-mouth-and-nose-in-ghusl-and-wudu/',
  ),
  GuideSource(
    id: 'ghusl-braids',
    title: 'Sahih Muslim 330a',
    subtitle: 'Umm Salama’s question about braided hair',
    url: 'https://sunnah.com/muslim:330a',
  ),
  GuideSource(
    id: 'ghusl-wudu',
    title: 'Wudu after a ritual bath',
    subtitle: 'Egypt’s Dar Al-Ifta · Hanafi essentials and intention',
    url:
        'https://www.dar-alifta.org/en/fatwa/details/24353/performing-ablution-for-prayer-after-the-ritual-bath-for-major-ritual-impurity',
  ),
  GuideSource(
    id: 'ghusl-barriers',
    title: 'Water barriers and valid reasons for tayammum',
    subtitle: 'Egypt’s Dar Al-Ifta · Dr. Nazir Mohammad Ayyad',
    url:
        'https://dar-alifta.org/en/fatwa/details/21991/tayammum-while-wearing-makeup',
  ),
  GuideSource(
    id: 'ghusl-intention',
    title: 'The required intention for ghusl',
    subtitle: 'Shaykh Ahmed Al-Ahmad · Shafi‘i essentials',
    url:
        'https://seekersguidance.org/answers/purity-shafii-fiqh/what-are-the-things-that-require-ghusl-ritual-bath/',
  ),
  GuideSource(
    id: 'ghusl-nullifier',
    title: 'A wudu breaker during ghusl',
    subtitle: 'Shaykh Yusuf Weltch · purification questions',
    url:
        'https://seekersguidance.org/answers/purity/what-is-the-right-way-to-understand-the-concept-of-purity/',
  ),
];
