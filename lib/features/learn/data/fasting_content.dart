import '../domain/learning_guide.dart';

const fastingGuide = LearningGuide(
  id: 'fasting',
  title: 'Fasting',
  description: 'Ramadan, from the intention to breaking your fast.',
  coverImage: 'assets/images/learn/fasting.webp',
  coverDescription: 'Dates and water prepared for the evening meal.',
  chapters: [
    GuideChapter(
      id: 'fasting-prepare',
      title: 'Before dawn',
      subtitle: 'Intention and suhur',
      image: 'assets/images/learn/fasting_suhoor.webp',
      imageDescription: 'A simple suhur meal beside a window before dawn.',
      readMinutes: 2,
      category: 'Prepare',
      introduction:
          'Ramadan fasting is an obligation for an accountable adult Muslim who is able, with recognized exemptions. Each day runs from true dawn until sunset.',
      steps: [
        GuideGuidance(
          'Know your local times',
          'Follow a reliable local Ramadan timetable for Fajr and Maghrib, and your community’s established decision for the start of Ramadan. Fasting starts at dawn, not sunrise.',
        ),
        GuideGuidance(
          'Intend the fast',
          'Each night, intend in your heart to fast the next day of Ramadan for Allah. A spoken formula is not required. Doing this before dawn covers the stricter timing requirements.',
        ),
        GuideGuidance(
          'Eat suhur',
          'Have the recommended meal before dawn. Finish eating and drinking by the start of Fajr. Missing suhur does not itself invalidate a fast.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Intention differs by school',
          'Schools differ over repeating the intention each night and the latest valid time. A nightly intention before dawn is a straightforward shared practice, rather than a claim that every other method is invalid.',
        ),
      ],
      sourceIds: [
        'fasting-quran',
        'fasting-hours',
        'fasting-intention',
        'fasting-suhur',
        'fasting-book',
      ],
    ),
    GuideChapter(
      id: 'fasting-day',
      title: 'Keep the fast',
      subtitle: 'Dawn to sunset',
      image: 'assets/images/learn/fasting_day.webp',
      imageDescription:
          'An empty place setting and covered water carafe in daylight.',
      readMinutes: 2,
      category: 'During the day',
      introduction:
          'Keep the daily prayers and protect your speech and conduct as well as abstaining from food and drink.',
      steps: [
        GuideGuidance(
          'Abstain during the fasting hours',
          'Do not deliberately eat, drink, smoke, or have sexual intercourse. Deliberately causing ejaculation or vomiting can also invalidate the fast; their detailed rules differ by circumstance and school.',
        ),
        GuideGuidance(
          'If you forget',
          'Stop eating or drinking as soon as you remember, and continue fasting. The majority do not require a make-up day for genuine forgetfulness; Maliki practice does require making up an obligatory fast.',
        ),
        GuideGuidance(
          'Break the fast at sunset',
          'Once sunset is established, break your fast without unnecessary delay. Dates or water are a simple way to begin, then offer Maghrib. The dua below is reported after breaking the fast.',
        ),
      ],
      notes: [
        GuideGuidance(
          'An accident is not always a deliberate act',
          'A wet dream or vomiting that happens involuntarily does not itself invalidate fasting. Questions about medicines, treatments, or accidentally swallowing water need their own ruling; do not stop prescribed treatment on the basis of this brief guide.',
        ),
      ],
      supplications: [
        GuideSupplication(
          title: 'After breaking the fast',
          arabic:
              'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
          transliteration:
              'Dhahaba al-zama’u, wabtallati al-‘uruqu, wa thabata al-ajru in sha’a Allah.',
          meaning:
              'The thirst has gone, the veins are moistened, and the reward is established, if Allah wills.',
          context:
              'A recommended remembrance after iftar, not a condition for the fast to count.',
          sourceId: 'fasting-iftar-dua',
        ),
      ],
      sourceIds: [
        'fasting-hours',
        'fasting-conduct',
        'fasting-forget',
        'fasting-nullifiers',
        'fasting-book',
        'fasting-hasten',
        'fasting-iftar-dua',
        'fasting-wet-dream',
        'fasting-vomiting',
      ],
    ),
    GuideChapter(
      id: 'fasting-exemptions',
      title: 'When a day is missed',
      subtitle: 'Make-up fasts and exemptions',
      image: 'assets/images/learn/fasting_makeup.webp',
      imageDescription:
          'A paper calendar and notebook for recording missed fasting days.',
      readMinutes: 2,
      category: 'Know the distinction',
      introduction:
          'A missed day, an ongoing inability, and a deliberate violation are different situations. Record missed days so you can address them correctly.',
      steps: [
        GuideGuidance(
          'Temporary illness or travel',
          'A qualifying illness or journey can permit not fasting. Make up the missed days when able. The travel conditions and when the concession begins differ by school.',
        ),
        GuideGuidance(
          'Menstruation and postnatal bleeding',
          'Do not fast during these states. Make up the days afterward. If bleeding begins before sunset, that day also needs to be made up.',
        ),
        GuideGuidance(
          'Pregnancy, nursing, or lasting inability',
          'Where fasting poses a genuine concern for mother or child, obtain medical advice and a ruling for the circumstances. Pregnancy and nursing generally require make-up days, with additional fidyah in some school-specific cases. Lasting inability may require feeding a poor person for each day instead.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Fidyah is not a purchase of permission',
          'Someone able to make up a fast cannot generally replace it with a donation. Food quantities, payment in money, and inability to afford fidyah require the guidance of your school.',
        ),
        GuideGuidance(
          'Deliberately breaking Ramadan',
          'Repent and ask about making up the day and any kaffarah. Intercourse can entail a major expiation; Hanafi and Maliki rules also cover some deliberate eating or drinking. Conditions, who owes it, and its form differ, so do not assume every broken fast has the same remedy.',
        ),
      ],
      sourceIds: [
        'fasting-quran',
        'fasting-book',
        'fasting-menstruation',
        'fasting-nullifiers',
        'fasting-kaffarah',
        'fasting-eid',
        'fasting-tashriq',
      ],
    ),
  ],
  sources: [
    GuideSource(
      id: 'fasting-quran',
      title: 'Ramadan and exemptions',
      subtitle: 'Quran 2:183–185',
      url: 'https://quran.com/2/183-185',
    ),
    GuideSource(
      id: 'fasting-hours',
      title: 'The fasting hours',
      subtitle: 'Quran 2:187',
      url: 'https://quran.com/2/187',
    ),
    GuideSource(
      id: 'fasting-intention',
      title: 'Intention before dawn',
      subtitle: 'Sunan Abi Dawud 2454',
      url: 'https://sunnah.com/abudawud:2454',
    ),
    GuideSource(
      id: 'fasting-suhur',
      title: 'The blessing of suhur',
      subtitle: 'Sahih al-Bukhari 1923',
      url: 'https://sunnah.com/bukhari:1923',
    ),
    GuideSource(
      id: 'fasting-book',
      title: 'Fasting conditions and exemptions',
      subtitle: 'Egypt’s Dar Al-Ifta, The Book of Fasting, pp. 24–29',
      url:
          'https://www.dar-alifta.org/images/Languages/OnlineBooks/Thebookoffasting.pdf',
    ),
    GuideSource(
      id: 'fasting-conduct',
      title: 'Guarding speech and conduct',
      subtitle: 'Sahih al-Bukhari 1903',
      url: 'https://sunnah.com/bukhari:1903',
    ),
    GuideSource(
      id: 'fasting-forget',
      title: 'Eating forgetfully',
      subtitle: 'Sahih al-Bukhari 1933',
      url: 'https://sunnah.com/bukhari:1933',
    ),
    GuideSource(
      id: 'fasting-nullifiers',
      title: 'What invalidates a fast',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 6221',
      url:
          'https://dar-alifta.org/en/fatwa/details/6221/things-which-invalidate-the-fast',
    ),
    GuideSource(
      id: 'fasting-hasten',
      title: 'Breaking the fast promptly',
      subtitle: 'Sahih al-Bukhari 1957',
      url: 'https://sunnah.com/bukhari:1957',
    ),
    GuideSource(
      id: 'fasting-iftar-dua',
      title: 'The iftar remembrance',
      subtitle: 'Sunan Abi Dawud 2357, graded hasan',
      url: 'https://sunnah.com/abudawud:2357',
    ),
    GuideSource(
      id: 'fasting-menstruation',
      title: 'Making up missed fasts',
      subtitle: 'Sahih Muslim 335c',
      url: 'https://sunnah.com/muslim:335c',
    ),
    GuideSource(
      id: 'fasting-vomiting',
      title: 'Involuntary and deliberate vomiting',
      subtitle: 'Sunan Abi Dawud 2380',
      url: 'https://sunnah.com/abudawud:2380',
    ),
    GuideSource(
      id: 'fasting-wet-dream',
      title: 'Involuntary wet dreams',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 1220',
      url:
          'https://www.dar-alifta.org/en/fatwa/details/1220/wet-dreams-during-the-fasting-hours-of-ramadan',
    ),
    GuideSource(
      id: 'fasting-eid',
      title: 'No fasting on Eid',
      subtitle: 'Sahih al-Bukhari 1991–1992',
      url: 'https://sunnah.com/bukhari:1991',
    ),
    GuideSource(
      id: 'fasting-tashriq',
      title: 'The days of Tashriq',
      subtitle: 'Sahih al-Bukhari 1997–1998',
      url: 'https://sunnah.com/bukhari:1997',
    ),
    GuideSource(
      id: 'fasting-kaffarah',
      title: 'Expiation for intercourse',
      subtitle: 'Sahih al-Bukhari 1936',
      url: 'https://sunnah.com/bukhari:1936',
    ),
  ],
  questions: [
    GuideGuidance(
      'Must I say a special intention dua?',
      'No. Intention is the decision in your heart. Choosing to eat suhur because you will fast Ramadan is an expression of that intention.',
    ),
    GuideGuidance(
      'Does losing wudu break a fast?',
      'No. Fasting and wudu are separate. Renew wudu for prayer when needed.',
    ),
    GuideGuidance(
      'Can I fast on Eid?',
      'Fasting on Eid al-Fitr and Eid al-Adha is prohibited. The three days of Tashriq, 11–13 Dhul-Hijjah, also have a fasting prohibition with a specific pilgrimage exception; do not schedule ordinary make-up fasts then.',
    ),
  ],
);
