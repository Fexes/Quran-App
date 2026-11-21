import '../domain/learning_guide.dart';

const hajjGuide = LearningGuide(
  id: 'hajj',
  title: 'Hajj',
  description: 'The Tamattu pilgrimage, in order from Umrah to farewell.',
  coverImage: 'assets/images/learn/hajj_arafat_faceless.webp',
  coverDescription:
      'Three pilgrims seen entirely from behind making dua on the open plain of Arafat.',
  chapters: [
    GuideChapter(
      id: 'hajj-tamattu',
      title: 'Prepare for Tamattu',
      subtitle: 'Umrah first, then Hajj',
      image: 'assets/images/learn/umrah_ihram_faceless.webp',
      imageDescription:
          'Straight rear view of a bareheaded pilgrim preparing in white ihram.',
      readMinutes: 2,
      category: 'Before 8 Dhul-Hijjah',
      introduction:
          'This guide follows Tamattu for a visiting pilgrim: Umrah during the Hajj months, release from ihram, then a new ihram for Hajj in the same year. It does not describe the different Qiran or Ifrad sequences.',
      steps: [
        GuideGuidance(
          'Arrange the journey',
          'Confirm eligibility, official access requirements, your authorized provider, transport, and a qualified group guide. Check current Nusuk information. Arrange the Tamattu hady through a reliable authorized service.',
        ),
        GuideGuidance(
          'Complete the Umrah',
          'Enter ihram for Umrah before crossing your route’s miqat. Complete seven tawaf circuits with the Kaaba on your left, the prayer afterward, and seven sa’i lengths from Safa to Marwah. Then shave or shorten the hair appropriately and leave ihram. The Umrah guide gives the full method.',
        ),
        GuideGuidance(
          'Understand the offering',
          'A qualifying visiting Tamattu pilgrim owes a hady. If genuinely unable to obtain it, Quran 2:196 gives three days of fasting during Hajj and seven after returning. Arrange the timing with your guide before the rites; do not substitute a general charity payment.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Choosing a form of Hajj',
          'Tamattu allows a break from ihram between Umrah and Hajj and normally requires a hady. Qiran keeps the two rites in one continuing ihram and also normally requires a hady. Ifrad is Hajj alone, without that offering merely for its form. Your circumstances determine the appropriate choice.',
        ),
      ],
      sourceIds: [
        'hajj-nusuk',
        'hajj-modes',
        'hajj-quran-offering',
        'hajj-jabir',
        'hajj-miqat',
      ],
    ),
    GuideChapter(
      id: 'hajj-arafat',
      title: 'Mina, then Arafat',
      subtitle: '8 and 9 Dhul-Hijjah',
      image: 'assets/images/learn/hajj_arafat_faceless.webp',
      imageDescription:
          'Three pilgrims seen entirely from behind making dua on the open plain of Arafat.',
      readMinutes: 2,
      category: 'The heart of Hajj',
      introduction:
          'Being within Arafat at its appointed time is indispensable to Hajj. You do not need to climb a hill, and “standing” does not mean you must remain on your feet.',
      steps: [
        GuideGuidance(
          '8th: enter ihram for Hajj',
          'From your accommodation in Makkah, prepare, intend Hajj, and recite talbiyah. The ihram restrictions resume. Go to Mina and spend the day and night there, offering the five prayers from Dhuhr through the following Fajr.',
        ),
        GuideGuidance(
          '9th: reach Arafat',
          'Travel to Arafat in the morning and confirm you are inside its marked boundary. Join the arranged Dhuhr and Asr prayers. Shortening and combining have conditions, so follow the qualified guide’s instructions for your status.',
        ),
        GuideGuidance(
          'Remain until sunset',
          'Spend the afternoon in dua, remembrance, and repentance. Face the qiblah when supplicating if convenient. Remain within Arafat until sunset, then depart calmly for Muzdalifah with your group.',
        ),
      ],
      supplications: [
        GuideSupplication(
          title: 'Talbiyah',
          arabic:
              'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
          transliteration:
              'Labbayka Allahumma labbayk. Labbayka la sharika laka labbayk. Inna al-hamda wa-n-ni‘mata laka wa-l-mulk. La sharika lak.',
          meaning:
              'Here I am, O Allah, responding to You. Here I am; You have no partner. All praise, blessing, and sovereignty belong to You. You have no partner.',
          context:
              'Repeat during the Hajj journey in ihram. In the sequence here, stop when beginning the stoning of Jamrat al-Aqabah on the 10th.',
          sourceId: 'hajj-talbiyah',
        ),
      ],
      reminder:
          'A missed Arafat cannot simply be replaced with an offering. Contact your qualified guide immediately if access or timing goes wrong.',
      sourceIds: [
        'hajj-jabir',
        'hajj-arafah-essential',
        'hajj-talbiyah',
        'hajj-talbiyah-end',
        'hajj-details',
      ],
    ),
    GuideChapter(
      id: 'hajj-tenth',
      title: 'Muzdalifah and the 10th',
      subtitle: 'Stoning, hady, and haircut',
      image: 'assets/images/learn/hajj_muzdalifah.webp',
      imageDescription:
          'Empty resting mats and travel belongings on the open plain of Muzdalifah at night.',
      readMinutes: 3,
      category: 'Night of the 10th and Eid day',
      introduction:
          'The usual order shown here is stoning, the offering, then the haircut. Keep to your group’s safe schedule and the legal timings explained by its guide.',
      steps: [
        GuideGuidance(
          'Spend the night at Muzdalifah',
          'After Arafat, offer Maghrib and Isha at Muzdalifah as arranged, and stay for the night. The normal sequence includes Fajr and remembrance there before leaving. Concessions for early departure and minimum stays differ by school and circumstance.',
        ),
        GuideGuidance(
          'Stone Jamrat al-Aqabah only',
          'On the 10th, throw seven small pebbles one at a time into the designated basin at the large Jamrah. Say “Allahu akbar” with each. Do not stone all three sites on this day, throw large objects, or push others.',
        ),
        GuideGuidance(
          'Complete the hady',
          'Arrange the required Tamattu offering and establish that it has been carried out before the haircut when following the Hanafi sequence. A booking receipt alone is not the slaughter; a reliable service’s confirmed schedule can be relevant.',
        ),
        GuideGuidance(
          'Shave or shorten the hair',
          'Men shave the head or shorten the hair across it; women trim the ends and do not shave. Ask your guide about the minimum cut for your school. With the stoning and haircut completed in this sequence, the first release from ihram is reached. Sexual intimacy remains restricted until the full release.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Order and concessions',
          'Schools differ on the order’s legal force and on the acts that establish each release from ihram. If the sequence changes, ask your guide before assuming a penalty or resuming restricted acts. Pebbles can be collected from a permitted place; Muzdalifah is not their only valid source.',
        ),
      ],
      sourceIds: [
        'hajj-jabir',
        'hajj-requirements',
        'hajj-sacrifice-confirmation',
        'hajj-order',
        'hajj-release',
      ],
    ),
    GuideChapter(
      id: 'hajj-ifadah',
      title: 'Tawaf and sa’i for Hajj',
      subtitle: 'The essential visit to the House',
      image: 'assets/images/learn/umrah_tawaf_faceless.webp',
      imageDescription:
          'An overhead view of counterclockwise tawaf around the Kaaba with no visible faces.',
      readMinutes: 2,
      category: 'From the 10th onward',
      introduction:
          'Tawaf al-ifadah is an essential Hajj rite. In Tamattu, the earlier Umrah tawaf and sa’i do not replace these Hajj rites.',
      steps: [
        GuideGuidance(
          'Complete tawaf al-ifadah',
          'Make seven circuits, starting at the Black Stone alignment, keeping the Kaaba to your left and passing outside the Hijr. Have wudu and proper covering. Pray the two rak‘ahs afterward where you can do so safely.',
        ),
        GuideGuidance(
          'Complete the Hajj sa’i',
          'Walk seven one-way lengths, starting at Safa and ending at Marwah. Men who are able run only between the green markers when safe; women walk throughout. Make dua without inventing a fixed formula for each length.',
        ),
        GuideGuidance(
          'Confirm full release',
          'With the stoning, haircut, tawaf al-ifadah, and this sa’i completed, the full release from ihram is attained in this sequence. Return to Mina for the remaining nights and stoning.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Schedule within the right window',
          'The 10th is the usual day, but timing and consequences of delay differ by school. Agree the plan with your guide, especially before postponing beyond the 12th.',
        ),
        GuideGuidance(
          'Menstruation needs a specific plan',
          'Menstruation does not prevent ihram or the stay at Arafat. Tawaf has separate purity rules. The exemption from farewell tawaf does not exempt you from tawaf al-ifadah; consult your guide if travel and bleeding overlap.',
        ),
      ],
      sourceIds: [
        'hajj-jabir',
        'hajj-details',
        'hajj-release',
        'hajj-menstruation',
        'hajj-farewell',
      ],
    ),
    GuideChapter(
      id: 'hajj-farewell',
      title: 'Finish the days of Mina',
      subtitle: '11–13 Dhul-Hijjah and departure',
      image: 'assets/images/learn/hajj_jamarat_faceless.webp',
      imageDescription:
          'The modern Jamarat wall and pebble basin in Mina, shown without people.',
      readMinutes: 2,
      category: 'Complete the journey',
      introduction:
          'The days of Tashriq follow Eid. Complete the remaining stoning and follow the Mina stay requirements of your school before the farewell visit to the Kaaba.',
      steps: [
        GuideGuidance(
          '11th and 12th: all three Jamarat',
          'Plan to spend the nights leading into the 11th and 12th in Mina, with the 13th if staying longer. Each day, stone the small Jamrah, then the middle, then Jamrat al-Aqabah: seven pebbles at each, one by one, with takbir. The usual time begins after the sun passes its zenith; follow the approved schedule and any qualified concession.',
        ),
        GuideGuidance(
          'Make dua away from the flow',
          'After the small and middle Jamarat, move clear of the crowd and make dua facing the qiblah if safe. Do not stop for this pause after Jamrat al-Aqabah.',
        ),
        GuideGuidance(
          'Leave on the 12th or stay for the 13th',
          'If taking the early departure, complete the 12th’s stoning and arrange to leave Mina before sunset. If sunset passes first, the majority require the extra night and 13th’s stoning; Hanafi law has a later dawn cutoff. Ask your guide before changing your plan.',
        ),
        GuideGuidance(
          'Perform farewell tawaf',
          'Before leaving Makkah, make seven circuits as tawaf al-wada‘ and pray afterward. There is no new sa’i for this farewell. Menstruating women are excused from farewell tawaf, provided the essential Hajj tawaf has been completed.',
        ),
      ],
      notes: [
        GuideGuidance(
          'The Mina nights differ by school',
          'The majority treat these overnight stays as obligatory, with recognized concessions. Hanafi law treats them as Sunnah. Follow your school and group plan; stoning remains a separate duty.',
        ),
        GuideGuidance(
          'Unable to stone or stay?',
          'Illness, disability, and other genuine obstacles have specific concessions, including deputizing for stoning in qualifying cases. Have the guide arrange the correct alternative; do not simply omit a rite.',
        ),
      ],
      sourceIds: [
        'hajj-mina-nights',
        'hajj-departure',
        'hajj-stoning-order',
        'hajj-stoning-time',
        'hajj-days',
        'hajj-requirements',
        'hajj-farewell',
        'hajj-details',
      ],
    ),
  ],
  sources: [
    GuideSource(
      id: 'hajj-nusuk',
      title: 'Official Hajj access and services',
      subtitle: 'Nusuk Hajj',
      url: 'https://hajj.nusuk.sa/',
    ),
    GuideSource(
      id: 'hajj-modes',
      title: 'Tamattu, Qiran, and Ifrad',
      subtitle: 'Nusuk, Hajj Rituals',
      url: 'https://hajj.nusuk.sa/nusuk/hajj-rituals',
    ),
    GuideSource(
      id: 'hajj-quran-offering',
      title: 'The offering and its fasting alternative',
      subtitle: 'Quran 2:196',
      url: 'https://quran.com/2/196',
    ),
    GuideSource(
      id: 'hajj-miqat',
      title: 'The entry boundaries',
      subtitle: 'Sahih al-Bukhari 1524',
      url: 'https://sunnah.com/bukhari:1524',
    ),
    GuideSource(
      id: 'hajj-jabir',
      title: 'Jabir’s account of the pilgrimage',
      subtitle: 'Sahih Muslim 1218a',
      url: 'https://sunnah.com/muslim:1218a',
    ),
    GuideSource(
      id: 'hajj-arafah-essential',
      title: 'The indispensable stay at Arafat',
      subtitle: 'Sunan Ibn Majah 3015, graded sahih',
      url: 'https://sunnah.com/ibnmajah:3015',
    ),
    GuideSource(
      id: 'hajj-talbiyah',
      title: 'The talbiyah',
      subtitle: 'Sahih al-Bukhari 1549',
      url: 'https://sunnah.com/bukhari:1549',
    ),
    GuideSource(
      id: 'hajj-talbiyah-end',
      title: 'Talbiyah until the first stoning',
      subtitle: 'Sahih al-Bukhari 1685',
      url: 'https://sunnah.com/bukhari:1685',
    ),
    GuideSource(
      id: 'hajj-details',
      title: 'The principal rites and their details',
      subtitle: 'Egypt’s Dar Al-Ifta, article 102',
      url:
          'https://www.dar-alifta.org/en/article/details/102/the-rites-of-hajj-in-detail',
    ),
    GuideSource(
      id: 'hajj-requirements',
      title: 'Stoning, offerings, and farewell',
      subtitle: 'Egypt’s Dar Al-Ifta, article 50',
      url:
          'https://www.dar-alifta.org/en/article/details/50/the-requirements-of-hajj',
    ),
    GuideSource(
      id: 'hajj-sacrifice-confirmation',
      title: 'Hady and the haircut order',
      subtitle: 'Ilyas Patel, SeekersGuidance, Hanafi answer',
      url:
          'https://seekersguidance.org/answers/hajj/can-i-exit-ihram-if-my-sacrifice-is-confirmed-online/',
    ),
    GuideSource(
      id: 'hajj-order',
      title: 'Changes to the order of rites',
      subtitle: 'Sahih al-Bukhari 83',
      url: 'https://sunnah.com/bukhari:83',
    ),
    GuideSource(
      id: 'hajj-release',
      title: 'The two releases from ihram',
      subtitle: 'Egypt’s Dar Al-Ifta, Hajj guidance',
      url: 'https://www.dar-alifta.org/ar/haj',
    ),
    GuideSource(
      id: 'hajj-menstruation',
      title: 'Menstruation and pilgrimage rites',
      subtitle: 'Sahih al-Bukhari 305',
      url: 'https://sunnah.com/bukhari:305',
    ),
    GuideSource(
      id: 'hajj-mina-nights',
      title: 'Mina nights and recognized concessions',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 6341',
      url:
          'https://dar-alifta.org/en/fatwa/details/6341/the-permissibility-for-women-and-the-weak-not-spending-the-night-at-mina',
    ),
    GuideSource(
      id: 'hajj-departure',
      title: 'The early-departure cutoff',
      subtitle: 'Al-Azhar, Hajj Guide, p. 77',
      url: 'https://azhar.eg/Portals/0/dalil_hajj_2019.pdf',
    ),
    GuideSource(
      id: 'hajj-stoning-order',
      title: 'The three Jamarat in order',
      subtitle: 'Sahih al-Bukhari 1751',
      url: 'https://sunnah.com/bukhari:1751',
    ),
    GuideSource(
      id: 'hajj-stoning-time',
      title: 'Stoning after the zenith',
      subtitle: 'Sahih al-Bukhari 1746',
      url: 'https://sunnah.com/bukhari:1746',
    ),
    GuideSource(
      id: 'hajj-days',
      title: 'Two days or three',
      subtitle: 'Quran 2:203',
      url: 'https://quran.com/2/203',
    ),
    GuideSource(
      id: 'hajj-farewell',
      title: 'Farewell tawaf and the exemption',
      subtitle: 'Sahih al-Bukhari 1755',
      url: 'https://sunnah.com/bukhari:1755',
    ),
  ],
  questions: [
    GuideGuidance(
      'Are all the steps legally identical?',
      'No. Schools distinguish essential rites, obligations, and recommended acts differently. Missing Arafat is not treated like missing a recommended practice. Seek a specific ruling for any omission.',
    ),
    GuideGuidance(
      'Must I visit Madinah to complete Hajj?',
      'No. Visiting the Prophet’s Mosque is separate from completing Hajj. Plan it separately from the required dates and rites.',
    ),
    GuideGuidance(
      'Do these dates change each year?',
      'The rites follow Dhul-Hijjah in the Islamic calendar. Their Gregorian dates and access arrangements change; confirm them with official channels and your provider.',
    ),
  ],
);
