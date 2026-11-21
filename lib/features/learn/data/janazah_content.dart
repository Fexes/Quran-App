import '../domain/learning_guide.dart';

const janazahGuide = LearningGuide(
  id: 'janazah',
  title: 'Janazah prayer',
  description: 'A standing prayer for the deceased, step by step.',
  coverImage: 'assets/images/learn/janazah_faceless.webp',
  coverDescription: 'A respectful congregation standing for a funeral prayer.',
  chapters: [
    GuideChapter(
      id: 'janazah-prepare',
      title: 'Stand with intention',
      subtitle: 'A prayer for the deceased',
      image: 'assets/images/learn/janazah_faceless.webp',
      imageDescription:
          'Worshippers standing quietly in rows at a funeral prayer.',
      readMinutes: 1,
      category: 'Prepare',
      introduction:
          'Janazah is a communal obligation. It has four takbirs and is performed standing, with no bowing, prostration, or seated tashahhud.',
      steps: [
        GuideGuidance(
          'Prepare as for prayer',
          'Have wudu, the required purity and covering, and face the qiblah. Stand behind the imam if able, with the prepared deceased in front of the congregation.',
        ),
        GuideGuidance(
          'Know this example',
          'The sequence below follows the Shafi‘i method for an adult deceased person. Other schools differ in the first recitation, raising the hands, and the closing salam. Follow your own school when praying with an imam.',
        ),
        GuideGuidance(
          'Intend and follow',
          'Intend to offer the funeral prayer for the deceased, following this imam. You do not need to know or say the person’s name. Follow each takbir after the imam and recite the words quietly yourself.',
        ),
      ],
      sourceIds: ['janazah-method', 'janazah-four'],
    ),
    GuideChapter(
      id: 'janazah-first',
      title: 'The first two takbirs',
      subtitle: 'Al-Fatihah and blessings',
      image: 'assets/images/learn/janazah_faceless.webp',
      imageDescription:
          'Worshippers standing behind an imam before a fully covered funeral bier.',
      readMinutes: 2,
      category: 'Remain standing',
      introduction:
          'In this Shafi‘i example, raise your hands with each takbir, then fold them. The Arabic recitations are available below.',
      steps: [
        GuideGuidance(
          'First takbir',
          'Say “Allahu akbar” after the imam. Recite Al-Fatihah quietly, including Bismillah. Do not add the ordinary opening praise in this example.',
        ),
        GuideGuidance(
          'Second takbir',
          'After the imam’s next takbir, say “Allahu akbar,” then send blessings on the Prophet. The complete established wording below may be used.',
        ),
      ],
      supplications: [
        GuideSupplication(
          title: 'Al-Fatihah',
          arabic:
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ\nالرَّحْمَٰنِ الرَّحِيمِ\nمَالِكِ يَوْمِ الدِّينِ\nإِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ\nاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nصِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
          transliteration:
              'Bismillahir-Rahmanir-Rahim.\nAl-hamdu lillahi Rabbil-‘alamin.\nAr-Rahmanir-Rahim.\nMaliki yawmid-din.\nIyyaka na‘budu wa iyyaka nasta‘in.\nIhdinas-siratal-mustaqim.\nSiratal-ladhina an‘amta ‘alayhim, ghayril-maghdubi ‘alayhim wa lad-dallin.',
          meaning:
              'In Allah’s name, the All-Merciful, the Especially Merciful. Praise belongs to Allah, Lord of all worlds, the All-Merciful, the Especially Merciful, Master of the Day of Recompense. You alone we worship, and You alone we ask for help. Guide us on the straight path: the path of those You have favored, not those who have incurred anger, nor those who are astray.',
          context: 'After the first takbir in this example.',
          sourceId: 'janazah-fatihah',
        ),
        GuideSupplication(
          title: 'Blessings on the Prophet',
          arabic:
              'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
          transliteration:
              'Allahumma salli ‘ala Muhammadin wa ‘ala ali Muhammad, kama sallayta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka Hamidun Majid. Allahumma barik ‘ala Muhammadin wa ‘ala ali Muhammad, kama barakta ‘ala Ibrahima wa ‘ala ali Ibrahim, innaka Hamidun Majid.',
          meaning:
              'O Allah, bestow Your favor on Muhammad and the family of Muhammad, as You bestowed Your favor on Ibrahim and the family of Ibrahim. You are Praiseworthy, Glorious. O Allah, bless Muhammad and the family of Muhammad, as You blessed Ibrahim and the family of Ibrahim. You are Praiseworthy, Glorious.',
          context:
              'After the second takbir. The shorter “Allahumma salli ‘ala Muhammad” meets the minimum in the Shafi‘i method.',
          sourceId: 'janazah-salawat',
        ),
      ],
      sourceIds: [
        'janazah-method',
        'janazah-fatihah',
        'janazah-fatihah-report',
        'janazah-salawat',
      ],
    ),
    GuideChapter(
      id: 'janazah-finish',
      title: 'Pray for them and close',
      subtitle: 'The third and fourth takbirs',
      image: 'assets/images/learn/janazah_faceless.webp',
      imageDescription:
          'A funeral congregation remaining in a standing posture.',
      readMinutes: 2,
      category: 'Complete the prayer',
      introduction:
          'The central request is mercy and forgiveness for the person who has died. Keep standing throughout.',
      steps: [
        GuideGuidance(
          'Third takbir',
          'Say “Allahu akbar” after the imam, then make dua specifically for the deceased. The short authentic excerpt below is sufficient as a request for an adult man; the second version adapts the pronouns for an adult woman.',
        ),
        GuideGuidance(
          'Fourth takbir',
          'Say “Allahu akbar” after the imam. Pause briefly. Further supplication is recommended in this method; it is also permissible to remain silent before closing.',
        ),
        GuideGuidance(
          'Close with salam',
          'In this Shafi‘i example, give salam to the right, then to the left, after the imam. The first salam fulfils the required close; the second is recommended. Remain respectful and follow the organizers’ directions afterward.',
        ),
      ],
      supplications: [
        GuideSupplication(
          title: 'For an adult man',
          arabic:
              'اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ',
          transliteration:
              'Allahumma-ghfir lahu, warhamhu, wa ‘afihi, wa‘fu ‘anhu.',
          meaning:
              'O Allah, forgive him, have mercy on him, grant him well-being, and pardon him.',
          context:
              'The opening of the longer funeral dua in Sahih Muslim, after the third takbir.',
          sourceId: 'janazah-dua',
        ),
        GuideSupplication(
          title: 'For an adult woman',
          arabic:
              'اللَّهُمَّ اغْفِرْ لَهَا وَارْحَمْهَا وَعَافِهَا وَاعْفُ عَنْهَا',
          transliteration:
              'Allahumma-ghfir laha, warhamha, wa ‘afiha, wa‘fu ‘anha.',
          meaning:
              'O Allah, forgive her, have mercy on her, grant her well-being, and pardon her.',
          context:
              'The same request with feminine pronouns, not a separate quoted narration.',
          sourceId: 'janazah-dua',
        ),
        GuideSupplication(
          title: 'The closing salam',
          arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
          transliteration: 'As-salamu ‘alaykum wa rahmatullah.',
          meaning: 'Peace be upon you, and Allah’s mercy.',
          context: 'At the end of the standing prayer.',
          sourceId: 'janazah-method',
        ),
      ],
      notes: [
        GuideGuidance(
          'Children, several deceased people, or late arrival',
          'These situations require adapted intentions, supplications, or completion rules. Ask the imam which wording or steps to use; do not assume every adult singular wording fits every funeral.',
        ),
      ],
      sourceIds: ['janazah-method', 'janazah-dua', 'janazah-salam'],
    ),
  ],
  sources: [
    GuideSource(
      id: 'janazah-method',
      title: 'The Shafi‘i funeral prayer',
      subtitle: 'Jordan Iftaa Department, fatwa 3619',
      url: 'https://www.aliftaa.jo/QuestionPrintEn.aspx?QuestionId=3619',
    ),
    GuideSource(
      id: 'janazah-salam',
      title: 'The closing salam across schools',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 3094',
      url:
          'https://www.dar-alifta.org/ar/fatwa/details/12565/حكم-التسليمة-الثانية-في-صلاة-الجنازة',
    ),
    GuideSource(
      id: 'janazah-four',
      title: 'Four takbirs',
      subtitle: 'Sahih al-Bukhari 1333',
      url: 'https://sunnah.com/bukhari:1333',
    ),
    GuideSource(
      id: 'janazah-fatihah',
      title: 'Al-Fatihah',
      subtitle: 'Quran 1:1–7',
      url: 'https://quran.com/1',
    ),
    GuideSource(
      id: 'janazah-fatihah-report',
      title: 'Al-Fatihah at the funeral prayer',
      subtitle: 'Sahih al-Bukhari 1335',
      url: 'https://sunnah.com/bukhari:1335',
    ),
    GuideSource(
      id: 'janazah-salawat',
      title: 'Blessings on the Prophet',
      subtitle: 'Sahih al-Bukhari 3370',
      url: 'https://sunnah.com/bukhari:3370',
    ),
    GuideSource(
      id: 'janazah-dua',
      title: 'Supplication for the deceased',
      subtitle: 'Sahih Muslim 963a–b',
      url: 'https://sunnah.com/muslim:963a',
    ),
  ],
  questions: [
    GuideGuidance(
      'Do I bow or sit down?',
      'No. The funeral prayer uses a standing sequence of takbirs and recitations. Someone unable to stand follows the ruling for their ability.',
    ),
    GuideGuidance(
      'Must every Muslim attend?',
      'It is a communal obligation. When fulfilled by sufficient members of the community, the obligation is discharged from the others. Attending remains a valuable act of support and worship.',
    ),
  ],
);
