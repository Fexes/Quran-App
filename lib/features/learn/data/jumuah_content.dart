import '../domain/learning_guide.dart';

const jumuahGuide = LearningGuide(
  id: 'jumuah',
  title: 'Jumu‘ah',
  description: 'Prepare for Friday, listen, and pray together.',
  coverImage: 'assets/images/learn/jumuah_faceless.webp',
  coverDescription: 'Worshippers gathered in a mosque for Friday prayer.',
  chapters: [
    GuideChapter(
      id: 'jumuah-prepare',
      title: 'Arrive with care',
      subtitle: 'Before the Friday sermon',
      image: 'assets/images/learn/jumuah_faceless.webp',
      imageDescription: 'A mosque congregation gathering for Friday worship.',
      readMinutes: 2,
      category: 'Prepare',
      introduction:
          'Jumu‘ah is the Friday congregational prayer with a sermon and two required prayer units. When validly attended, it takes the place of Dhuhr.',
      steps: [
        GuideGuidance(
          'Know whether you must attend',
          'It is generally obligatory for an adult Muslim man who is resident and able, without a valid excuse. Women, travellers, and people with qualifying illness have exemptions. Those who validly attend do not also owe Dhuhr for that time.',
        ),
        GuideGuidance(
          'Wash and dress cleanly',
          'Take the emphasized Friday bath, attend to cleanliness, wear clean modest clothes, and have wudu. The Friday bath’s precise legal classification differs between scholars.',
        ),
        GuideGuidance(
          'Go early and settle quietly',
          'Check the mosque’s sermon time, leave enough time to arrive, and silence your phone. Do not push between seated people or obstruct others. Offer your pre-sermon prayers according to your school.',
        ),
      ],
      notes: [
        GuideGuidance(
          'If you cannot attend',
          'Pray the ordinary Dhuhr prayer according to your circumstances. Two units alone at home, or following an online broadcast, do not replace a valid Jumu‘ah congregation.',
        ),
      ],
      sourceIds: [
        'jumuah-quran',
        'jumuah-rules',
        'jumuah-exemptions',
        'jumuah-broadcast',
        'jumuah-cleanliness',
      ],
    ),
    GuideChapter(
      id: 'jumuah-pray',
      title: 'Listen, then pray',
      subtitle: 'The khutbah and two rak‘ahs',
      image: 'assets/images/learn/jumuah_prayer.webp',
      imageDescription:
          'A Friday congregation standing behind the imam in a mosque.',
      readMinutes: 2,
      category: 'In the congregation',
      introduction:
          'The khutbah comes before the prayer. Follow the imam calmly, without moving ahead of him.',
      steps: [
        GuideGuidance(
          'Listen to the khutbah',
          'Listen quietly through the sermon and its brief sitting interval. Avoid conversation and phone use. Even telling someone else to be quiet interrupts the attention due to the sermon.',
        ),
        GuideGuidance(
          'Join the two-unit prayer',
          'After the iqamah, intend Jumu‘ah behind the imam and begin after his opening takbir. The imam recites aloud. Follow your school’s rules for your own recitation behind him.',
        ),
        GuideGuidance(
          'Complete both units',
          'In each rak‘ah follow the imam through standing, bowing, standing upright, and two prostrations with a sitting between. After the second, remain seated for tashahhud and the final recitations, then close with salam after him.',
        ),
        GuideGuidance(
          'Continue your Friday worship',
          'Offer the prayers after Jumu‘ah according to your school. Their number and arrangement have recognized differences; they are separate from the two required units.',
        ),
      ],
      notes: [
        GuideGuidance(
          'If you arrive late',
          'Join a prayer still in progress, then ask how to complete it if unsure. Schools differ over how much must be caught for it to count as Jumu‘ah. If the congregation has finished and you cannot attend another valid one, pray Dhuhr.',
        ),
      ],
      sourceIds: [
        'jumuah-listen',
        'jumuah-rules',
        'jumuah-two',
        'jumuah-follow',
        'jumuah-postures',
      ],
    ),
  ],
  sources: [
    GuideSource(
      id: 'jumuah-quran',
      title: 'The Friday call',
      subtitle: 'Quran 62:9–10',
      url: 'https://quran.com/62/9-10',
    ),
    GuideSource(
      id: 'jumuah-rules',
      title: 'Friday prayer and its conditions',
      subtitle: 'SeekersGuidance, edited from Ashraf Ali al-Thanawi',
      url:
          'https://seekersguidance.org/answers/hanafi-fiqh/the-rulings-related-to-friday-prayer/',
    ),
    GuideSource(
      id: 'jumuah-broadcast',
      title: 'Attendance and a remote broadcast',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 4997',
      url:
          'https://www.dar-alifta.org/ar/Fatwa/Details/15339/حكم-صلاة-الجمعة-خلف-التلفاز',
    ),
    GuideSource(
      id: 'jumuah-exemptions',
      title: 'Travel and Friday prayer',
      subtitle: 'Egypt’s Dar Al-Ifta, research 128',
      url:
          'https://www.dar-alifta.org/ar/fatwaresearch/details/128/الإمامة-والخطابة-للجمعة-في-السفر',
    ),
    GuideSource(
      id: 'jumuah-cleanliness',
      title: 'Cleanliness and consideration',
      subtitle: 'Sahih al-Bukhari 883',
      url: 'https://sunnah.com/bukhari:883',
    ),
    GuideSource(
      id: 'jumuah-listen',
      title: 'Listening during the sermon',
      subtitle: 'Sahih al-Bukhari 934',
      url: 'https://sunnah.com/bukhari:934',
    ),
    GuideSource(
      id: 'jumuah-two',
      title: 'Two complete prayer units',
      subtitle: 'Islamweb, fatwa 142059',
      url:
          'https://www.islamweb.net/en/fatwa/142059/why-friday-prayer-is-only-two-rakahs',
    ),
    GuideSource(
      id: 'jumuah-follow',
      title: 'Following the imam',
      subtitle: 'Sahih al-Bukhari 722',
      url: 'https://sunnah.com/bukhari:722',
    ),
    GuideSource(
      id: 'jumuah-postures',
      title: 'Prayer postures and sittings',
      subtitle: 'Sahih Muslim 498',
      url: 'https://sunnah.com/muslim:498',
    ),
  ],
  questions: [
    GuideGuidance(
      'Is the Friday sermon after the prayer?',
      'No. Jumu‘ah has its sermon before the prayer. The Eid prayer has its sermon afterward.',
    ),
    GuideGuidance(
      'What if I enter during the sermon?',
      'Enter quietly. Schools differ on praying two brief greeting rak‘ahs at this point; follow the guidance for your school without disturbing listeners.',
    ),
  ],
);
