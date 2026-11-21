import '../domain/learning_guide.dart';

const prayerMistakesGuide = LearningGuide(
  id: 'prayer-mistakes',
  title: 'Prayer mistakes',
  description:
      'Correct an omission, understand sujud al-sahw, and handle doubt.',
  coverImage: 'assets/images/learn/prayer_prostration_faceless_mat.webp',
  coverDescription:
      'A worshipper seen from behind in prostration on a prayer mat.',
  chapters: _prayerMistakesChapters,
  sources: _prayerMistakesSources,
  questions: [
    GuideGuidance(
      'Should I do sujud al-sahw after every prayer?',
      'No. It has specific causes. Do not add it routinely because something might have gone wrong. A wandering thought or forgetting a Sunnah such as saying Amin does not itself require it in Hanafi law.',
    ),
    GuideGuidance(
      'Does it replace a missed rak‘ah?',
      'No. It cannot replace an unperformed obligatory rak‘ah, bowing, or prostration. First complete or correctly repair the prayer, then perform sujud al-sahw when required by your school.',
    ),
    GuideGuidance(
      'What if I am following an imam?',
      'In Hanafi law, a follower does not independently perform sujud al-sahw for a personal accidental omission of a wajib while following. Follow the imam’s sujud al-sahw. Mistakes while completing missed units alone have their own ruling.',
    ),
  ],
);

const _prayerMistakesChapters = <GuideChapter>[
  GuideChapter(
    id: 'mistakes-identify',
    title: 'Identify the omission',
    subtitle: 'Not every mistake has the same repair',
    image: 'assets/images/learn/prayer_seated_faceless_mat.webp',
    imageDescription: 'A worshipper seated for tashahhud, viewed from behind.',
    readMinutes: 2,
    category: 'Hanafi examples',
    introduction:
        'Sujud al-sahw means two prostrations for forgetfulness. The following examples use Hanafi rules for a person praying alone. They do not replace missing pillars of prayer.',
    steps: [
      GuideGuidance(
        'A missed pillar must be supplied',
        'Bowing and prostrating are obligatory actions. If you accidentally prostrate before bowing and remember there, stand up, bow, rise, and perform the prostrations in their proper order. Finish with sujud al-sahw.',
      ),
      GuideGuidance(
        'A whole incomplete unit is different',
        'If you entirely omit the bowing or both prostrations and advance beyond that unit, it cannot count as a complete rak‘ah. Supply a complete replacement unit. A single missed prostration can instead be supplied when remembered, with sujud al-sahw at the end.',
      ),
      GuideGuidance(
        'A forgotten wajib needs correction',
        'For example, if you forget the first sitting of an obligatory prayer and have already stood fully upright, continue without returning to sit, then perform sujud al-sahw. If you remember while still closer to sitting, return and recite tashahhud.',
      ),
      GuideGuidance(
        'An omitted Sunnah does not require it',
        'Forgetting Amin after al-Fatiha does not require sujud al-sahw in Hanafi law. Continue the prayer. Do not classify every small hesitation or imperfect moment as a major omission.',
      ),
    ],
    notes: [
      GuideGuidance(
        'These are bounded examples',
        'If you remember a missed pillar only after ending the prayer, or you deliberately omitted an act, the ruling changes. Identify exactly what happened and when; do not apply the accidental-omission method automatically.',
      ),
    ],
    sourceIds: [
      'mistakes-pillars',
      'mistakes-amin',
      'mistakes-delay',
      'mistakes-first-sitting',
    ],
  ),
  GuideChapter(
    id: 'mistakes-hanafi',
    title: 'Two prostrations for forgetfulness',
    subtitle: 'The Hanafi sequence',
    image: 'assets/images/learn/prayer_prostration_faceless_mat.webp',
    imageDescription:
        'A rear view of a worshipper performing a full prostration.',
    readMinutes: 2,
    category: 'Hanafi method',
    introduction:
        'Use this sequence when Hanafi sujud al-sahw is due. It comes after one salam, followed by a renewed final sitting.',
    steps: [
      GuideGuidance(
        'Recite the final tashahhud',
        'At the end of the prayer, sit and recite the tashahhud. In the method taught here, stop before the blessings on the Prophet at this first sitting.',
      ),
      GuideGuidance(
        'Give one salam to the right',
        'Say the usual closing salam to the right only. Remain engaged in the prayer and proceed to the prostrations.',
      ),
      GuideGuidance(
        'Prostrate twice',
        'Say Allahu akbar and prostrate as in the prayer. Sit between the two prostrations, then prostrate again. Use the usual prostration remembrance; there is no need to invent a special formula.',
      ),
      GuideGuidance(
        'Sit again and finish',
        'Recite the tashahhud again, then the blessings on the Prophet and your closing supplication. End with the usual salam to the right and left.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Behind the imam',
        'Remain with the imam for his correction. A latecomer still follows the imam’s corrective prostrations before standing to complete missed units; the latecomer does not end their own prayer with the imam’s salam.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'In each prostration',
        arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
        transliteration: 'Subhana rabbiyal-a‘la.',
        meaning: 'Glory be to my Lord, the Most High.',
        context:
            'The usual remembrance in prostration. The wording is not unique to sujud al-sahw.',
        sourceId: 'mistakes-remembrance',
      ),
    ],
    sourceIds: [
      'mistakes-hanafi-method',
      'mistakes-follower',
      'mistakes-remembrance',
      'mistakes-latecomer',
    ],
  ),
  GuideChapter(
    id: 'mistakes-doubts',
    title: 'Timing and doubt differ',
    subtitle: 'A Shafi‘i example and a calmer approach',
    image: 'assets/images/learn/prayer_seated_faceless_mat.webp',
    imageDescription:
        'A rear view of a worshipper sitting at the end of prayer.',
    readMinutes: 2,
    category: 'Recognized differences',
    introduction:
        'Do not assume that every school puts sujud al-sahw on the same side of the salam. The causes, legal status, and handling of doubts also differ.',
    steps: [
      GuideGuidance(
        'Shafi‘i timing',
        'In the Shafi‘i school, the usual place is after the final tashahhud and its closing recitations, before the salam. Make two prostrations with a sitting between them, return to sitting, then give salam. It is normally Sunnah, while following the imam’s prostrations is obligatory.',
      ),
      GuideGuidance(
        'Shafi‘i example: three or four?',
        'For an ordinary doubt about whether you have prayed three or four rak‘ahs, count three, complete one more, and perform sujud al-sahw before salam. This example does not apply to persistent obsessive doubt.',
      ),
      GuideGuidance(
        'Hanafi doubt rules are different',
        'Hanafi guidance distinguishes a first isolated doubt from recurring uncertainty and considers a strong inclination about the count. Do not import the Shafi‘i “always take the lower number” example into every Hanafi situation.',
      ),
      GuideGuidance(
        'Do not reopen a prayer for a suspicion',
        'Learn the rule for a real, identified mistake. Repeated “what if” thoughts are not a reason to repeat prayers or add corrective prostrations every time. Continue using the certainty you already have.',
      ),
    ],
    sourceIds: [
      'mistakes-shafii',
      'mistakes-shafii-doubt',
      'mistakes-hanafi-doubt',
      'mistakes-no-preventive',
    ],
    reminder:
        'Use one learned method consistently. Before and after salam can both be correct in their proper context.',
  ),
];

const _prayerMistakesSources = <GuideSource>[
  GuideSource(
    id: 'mistakes-pillars',
    title: 'Correcting a missed obligatory action',
    subtitle: 'Ustadha Sulma Badrudduja · Hanafi worked examples',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/forgetting-to-perform-an-obgligatory-action-of-the-prayer/',
  ),
  GuideSource(
    id: 'mistakes-amin',
    title: 'Forgetting Amin and unnecessary sujud al-sahw',
    subtitle: 'Shaykh Faraz Rabbani · distinguishing Sunnah and wajib',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/is-the-prayer-invalid-if-one-performs-an-unnecessary-forgetfulness-prostration/',
  ),
  GuideSource(
    id: 'mistakes-delay',
    title: 'Avoiding misgivings about delay in prayer',
    subtitle: 'Shaykh Yusuf Weltch · meaningful delay and certainty',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/how-can-i-avoid-having-misgivings-about-delaying-a-necessary-act-of-prayer/',
  ),
  GuideSource(
    id: 'mistakes-hanafi-method',
    title: 'How to perform the forgetfulness prostration',
    subtitle: 'Shaykh Faraz Rabbani · complete Hanafi sequence',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/how-to-perform-the-forgetfulness-prostration/',
  ),
  GuideSource(
    id: 'mistakes-follower',
    title: 'Tashahhud and a follower’s mistakes',
    subtitle: 'Shaykh Faraz A. Khan · Hanafi congregation rules',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/reciting-the-tashahhud-before-the-forgetfulness-prostration-forgetting-a-necessary-wajib-act-behind-the-imam/',
  ),
  GuideSource(
    id: 'mistakes-remembrance',
    title: 'Sahih Muslim 772',
    subtitle: 'The remembrance recited in prostration',
    url: 'https://sunnah.com/muslim:772',
  ),
  GuideSource(
    id: 'mistakes-latecomer',
    title: 'A latecomer and the imam’s correction',
    subtitle: 'Ustadh Tabraze Azam · Hanafi latecomer rules',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/latecomer-imam-performing-prostrations-forgetfulness/',
  ),
  GuideSource(
    id: 'mistakes-shafii',
    title: 'Rulings of sujud al-sahw',
    subtitle: 'Dr. Nidal Sultan · Jordan Iftaa, Shafi‘i jurisprudence',
    url: 'https://www.aliftaa.jo/article-en/5953/Article.aspx?ArticleId=6011',
  ),
  GuideSource(
    id: 'mistakes-shafii-doubt',
    title: 'Doubt about the number of rak‘ahs',
    subtitle: 'Jordan Iftaa · Shafi‘i rule and obsessive doubt exception',
    url: 'https://www.aliftaa.jo/QuestionPrintEn.aspx?QuestionId=4431',
  ),
  GuideSource(
    id: 'mistakes-hanafi-doubt',
    title: 'Doubts in prayer',
    subtitle: 'Ustadh Salman Younas · Hanafi distinctions',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/doubts-in-prayer-making-up-such-prayers/',
  ),
  GuideSource(
    id: 'mistakes-no-preventive',
    title: 'Do not add sujud al-sahw just in case',
    subtitle: 'Shaykh Faraz Rabbani · its specific causes',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/can-the-forgetfulness-prostration-be-done-in-every-prayer-just-to-be-sure-it-is-valid/',
  ),
  GuideSource(
    id: 'mistakes-first-sitting',
    title: 'Forgetting the first sitting',
    subtitle: 'Dawat-e-Islami · Method of Salah (Hanafi), printed page 97',
    url:
        'https://data2.dawateislami.net/Data/Books/Download/en/pdf/2006/71-1.pdf',
  ),
];
