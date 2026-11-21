import '../domain/learning_guide.dart';

const eidGuide = LearningGuide(
  id: 'eid',
  title: 'Eid prayer',
  description: 'Two prayer units, extra takbirs, and a shared celebration.',
  coverImage: 'assets/images/learn/eid_faceless.webp',
  coverDescription: 'Worshippers gathering for Eid in warm morning light.',
  chapters: [
    GuideChapter(
      id: 'eid-prepare',
      title: 'Begin the Eid morning',
      subtitle: 'Prepare and join the gathering',
      image: 'assets/images/learn/eid_faceless.webp',
      imageDescription: 'A congregation gathering outdoors for Eid prayer.',
      readMinutes: 2,
      category: 'Prepare',
      introduction:
          'Eid al-Fitr follows Ramadan; Eid al-Adha falls on 10 Dhul-Hijjah. Both have a two-unit prayer, with extra takbirs and a sermon afterward.',
      steps: [
        GuideGuidance(
          'Prepare for prayer',
          'Wash, wear clean modest clothes, and have wudu. Check the announced prayer time. Eid prayer is offered after the sun has risen sufficiently and before the midday zenith, not at the instant of sunrise.',
        ),
        GuideGuidance(
          'For Eid al-Fitr',
          'Arrange zakat al-fitr before the prayer. Eating an odd number of dates before leaving is a reported Sunnah. Fasting on either Eid day is prohibited.',
        ),
        GuideGuidance(
          'Join and remember Allah',
          'Go to the congregation calmly and recite takbir. There is no adhan or iqamah for Eid. Learn which extra-takbir pattern the imam uses and follow him.',
        ),
      ],
      supplications: [
        GuideSupplication(
          title: 'A familiar Eid takbir',
          arabic:
              'اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ',
          transliteration:
              'Allahu akbar, Allahu akbar. La ilaha illa Allah. Wallahu akbar, Allahu akbar, wa lillahi al-hamd.',
          meaning:
              'Allah is greater, Allah is greater. There is no deity except Allah. Allah is greater, Allah is greater, and all praise belongs to Allah.',
          context:
              'An established form of Eid remembrance. Other recognized wordings exist; this is not the only valid formula.',
          sourceId: 'eid-takbir-words',
        ),
      ],
      sourceIds: [
        'eid-hanafi',
        'eid-shafii',
        'eid-dates',
        'eid-fitr',
        'eid-no-fast',
        'eid-takbir-words',
      ],
    ),
    GuideChapter(
      id: 'eid-pray',
      title: 'Follow the two units',
      subtitle: 'Two recognized takbir patterns',
      image: 'assets/images/learn/eid_faceless.webp',
      imageDescription:
          'Worshippers standing in aligned rows for outdoor Eid prayer.',
      readMinutes: 3,
      category: 'Pray with the imam',
      introduction:
          'Intend the Eid prayer and follow the imam. The extra takbirs are in addition to the ordinary opening and movement takbirs. Do not combine the patterns below.',
      steps: [
        GuideGuidance(
          'Hanafi: first rak‘ah',
          'Begin with the opening takbir and opening praise. Say three extra takbirs before recitation, raising the hands with each. Let them fall after the first two; fold them after the third. The imam recites, then leads the usual bow, upright standing, and two prostrations.',
        ),
        GuideGuidance(
          'Hanafi: second rak‘ah',
          'Rise for the second unit. The imam recites first, then everyone says three extra takbirs, raising and lowering the hands each time. The next ordinary takbir takes you into bowing. Complete the unit normally.',
        ),
        GuideGuidance(
          'Shafi‘i alternative: seven, then five',
          'In the first unit, make seven extra takbirs after the opening takbir and opening supplication, before recitation. In the second, make five extra takbirs after rising, before recitation. The opening and rising takbirs are not included in those numbers.',
        ),
        GuideGuidance(
          'Finish, then listen',
          'After the second unit’s two prostrations, sit for tashahhud and the final recitations, then give salam after the imam. Remain for the Eid sermon, which follows the prayer.',
        ),
      ],
      notes: [
        GuideGuidance(
          'Other schools and late arrival',
          'Maliki and Hanbali counts are described differently, including whether the opening takbir is counted. Follow the congregation’s imam. If you join late, the completion rules depend on your school.',
        ),
        GuideGuidance(
          'Its legal status',
          'Eid prayer is wajib for those meeting its conditions in Hanafi law, an emphasized Sunnah in Shafi‘i and Maliki law, and a communal obligation in Hanbali law. Rules for praying it alone or at home also differ.',
        ),
      ],
      sourceIds: ['eid-hanafi', 'eid-shafii', 'eid-sermon', 'eid-status'],
    ),
  ],
  sources: [
    GuideSource(
      id: 'eid-hanafi',
      title: 'The Hanafi Eid prayer',
      subtitle: 'Darul Iftaa Mahmudiyyah, Eid Guidelines, pp. 1–2',
      url:
          'https://daruliftaa.net/wp-content/uploads/2020/05/Eid-Guidelines.pdf',
    ),
    GuideSource(
      id: 'eid-shafii',
      title: 'Seven and five extra takbirs',
      subtitle: 'Jordan Iftaa Department, article 3481, Shafi‘i method',
      url: 'https://www.aliftaa.jo/Article.aspx?ArticleId=3481',
    ),
    GuideSource(
      id: 'eid-dates',
      title: 'Dates before Eid al-Fitr',
      subtitle: 'Sahih al-Bukhari 953',
      url: 'https://sunnah.com/bukhari:953',
    ),
    GuideSource(
      id: 'eid-fitr',
      title: 'Zakat al-fitr before prayer',
      subtitle: 'Sahih al-Bukhari 1503',
      url: 'https://sunnah.com/bukhari:1503',
    ),
    GuideSource(
      id: 'eid-no-fast',
      title: 'No fasting on the two Eids',
      subtitle: 'Sahih al-Bukhari 1991–1992',
      url: 'https://sunnah.com/bukhari:1991',
    ),
    GuideSource(
      id: 'eid-takbir-words',
      title: 'Recognized Eid takbir wordings',
      subtitle: 'Egypt’s Dar Al-Ifta, fatwa 7547',
      url:
          'https://dar-alifta.org/ar/fatwa/details/20500/أقوال-العلماء-في-صيغة-التكبير-لصلاة-العيد-وما-عليه-الفتوى',
    ),
    GuideSource(
      id: 'eid-sermon',
      title: 'The sermon follows the prayer',
      subtitle: 'Sahih al-Bukhari 962',
      url: 'https://sunnah.com/bukhari:962',
    ),
    GuideSource(
      id: 'eid-status',
      title: 'Eid prayer across the schools',
      subtitle: 'British Board of Scholars & Imams, Eid guidance, pp. 5–7',
      url:
          'https://www.bbsi.org.uk/wp-content/uploads/2020/05/BBSI0G8-Guidance-for-Eid.pdf',
    ),
  ],
  questions: [
    GuideGuidance(
      'Does a different takbir count invalidate the prayer?',
      'Recognized schools use different methods. Follow your imam rather than interrupting the congregation over the count.',
    ),
    GuideGuidance(
      'Does Eid replace Jumu‘ah on a Friday?',
      'Schools differ on the concession when both occur on one day. Do not assume Jumu‘ah is cancelled. Follow your mosque’s guidance and the ruling applicable to you.',
    ),
  ],
);
