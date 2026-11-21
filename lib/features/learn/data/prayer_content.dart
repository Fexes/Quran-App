import '../domain/learning_guide.dart';

const prayerGuide = LearningGuide(
  id: 'prayer',
  title: 'Prayer',
  description: 'Learn salah, from the first takbir to the final salam.',
  coverImage: 'assets/images/learn/prayer_standing_faceless_mat.webp',
  coverDescription:
      'A worshipper seen directly from behind, standing on a prayer rug in a quiet mosque.',
  chapters: _prayerChapters,
  sources: _prayerSources,
  questions: [
    GuideGuidance(
      'How many rak‘ahs do I pray?',
      'The daily fard prayers are Fajr 2, Dhuhr 4, Asr 4, Maghrib 3, and Isha 4. These counts are for a resident, without travel concessions. Sunnah prayers and Witr are separate; Witr is wajib in the Hanafi school. Jumu‘ah has its own congregational requirements.',
    ),
    GuideGuidance(
      'What changes in a congregation?',
      'Follow the imam and do not move ahead of him. Reciting Al-Fatihah behind an imam differs by school. This guide teaches praying alone; learn the congregational details from your teacher.',
    ),
    GuideGuidance(
      'Do women follow the same sequence?',
      'Yes, the rak‘ahs, recitations, bowing, and prostrations follow the same sequence. Some schools teach a more compact posture for women. The illustrations show one example, not every accepted posture.',
    ),
    GuideGuidance(
      'What if I cannot stand?',
      'Pray standing if able. If unable, pray sitting; if unable to sit, pray on your side. Learn any further adaptations for your circumstances from a qualified teacher.',
    ),
  ],
);

const _prayerChapters = <GuideChapter>[
  GuideChapter(
    id: 'prayer-prepare',
    title: 'Prepare for prayer',
    subtitle: 'Time, purity, direction, intention',
    image: 'assets/images/learn/prayer_standing_faceless_mat.webp',
    imageDescription:
        'A rear view of a worshipper standing on a prayer rug, ready for prayer.',
    readMinutes: 2,
    category: 'Before you begin',
    introduction:
        'Follow a complete two-rak‘ah prayer offered alone. A rak‘ah is one cycle of standing, bowing, and two prostrations.',
    steps: [
      GuideGuidance(
        'Check the time and your purity',
        'Pray the obligatory prayer within its time. Have valid wudu, and ghusl when required. Remove ritual impurities from your body, clothes, and place of prayer.',
      ),
      GuideGuidance(
        'Dress for prayer',
        'Wear clothing that is opaque and remains covering when you bow. Men should cover the torso and from the navel through the knees. Women cover the hair and body, with the face and hands ordinarily uncovered; covering the feet avoids a difference between schools.',
      ),
      GuideGuidance(
        'Face the qiblah and intend',
        'Face the direction of the Ka‘bah. Know in your heart which prayer you are offering for Allah. No spoken intention formula is required. Stand if able.',
      ),
      GuideGuidance(
        'Know the fard count',
        'Fajr: 2 rak‘ahs. Dhuhr: 4. Asr: 4. Maghrib: 3. Isha: 4. These are the ordinary resident fard counts, separate from Sunnah prayers and Witr. The final chapter explains how to continue to three or four.',
      ),
    ],
    notes: [
      GuideGuidance(
        'A shared Sunni sequence',
        'Schools differ on some postures and on whether particular details are obligatory or recommended. Follow your school consistently. Use a teacher to learn pronunciation and any personal exceptions.',
      ),
    ],
    sourceIds: [
      'prayer-times',
      'prayer-qiblah',
      'prayer-purity',
      'prayer-covering',
      'prayer-men-covering',
      'prayer-intention',
      'prayer-ability',
      'prayer-counts',
      'prayer-imam',
    ],
    reminder: 'Move calmly and let each posture settle.',
  ),
  GuideChapter(
    id: 'prayer-stand',
    title: 'Stand and recite',
    subtitle: 'Begin with Allahu akbar',
    image: 'assets/images/learn/prayer_standing_faceless_mat.webp',
    imageDescription:
        'A worshipper seen from behind, standing in the recitation posture.',
    readMinutes: 3,
    category: 'In each rak‘ah',
    introduction:
        'Begin the prayer with the opening takbir, then recite while standing.',
    steps: [
      GuideGuidance(
        'Begin the prayer',
        'Say “Allahu akbar.” Raise your hands as you do so. A reported form is to raise them to shoulder level. In this example, rest the right hand over the left afterward.',
      ),
      GuideGuidance(
        'Recite Al-Fatihah',
        'You may first say an established opening supplication. Seek refuge in Allah before reciting, then read Bismillah and all of Al-Fatihah below. Say “Amin” afterward, meaning “O Allah, answer.” Amin is not part of the surah.',
      ),
      GuideGuidance(
        'Add a short surah',
        'In each of these first two rak‘ahs, recite another surah after Al-Fatihah. Al-Ikhlas is included below as an example. Recite the Arabic with your tongue, not only in your thoughts.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Recognized differences',
        'Hand placement, raising the hands at later transitions, and saying Amin aloud differ between schools. Some Malikis pray with their arms at their sides. These differences do not make the illustrated posture the only valid form.',
      ),
      GuideGuidance(
        'Learning the recitation',
        'Transliteration is a pronunciation aid; the English meaning is for understanding. Learn the Arabic with a teacher. If you cannot yet recite it, seek the beginner concession appropriate to you rather than delaying prayer.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'The opening takbir',
        arabic: 'اللَّهُ أَكْبَرُ',
        transliteration: 'Allahu akbar.',
        meaning: 'Allah is greater.',
        context:
            'Begin the prayer with these words. Also say them during the transitions described in the next chapters.',
        sourceId: 'prayer-transitions',
      ),
      GuideSupplication(
        title: 'Seeking refuge',
        arabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
        transliteration: 'A‘udhu billahi min ash-shaytan ir-rajim.',
        meaning: 'I seek Allah’s protection from the rejected Satan.',
        context:
            'Before beginning Quran recitation. This is separate from Al-Fatihah.',
        sourceId: 'prayer-refuge',
      ),
      GuideSupplication(
        title: 'Al-Fatihah',
        arabic:
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ\nالرَّحْمَٰنِ الرَّحِيمِ\nمَالِكِ يَوْمِ الدِّينِ\nإِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ\nاهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ\nصِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
        transliteration:
            'Bismillahir-Rahmanir-Rahim.\nAl-hamdu lillahi Rabbil-‘alamin.\nAr-Rahmanir-Rahim.\nMaliki yawmid-din.\nIyyaka na‘budu wa iyyaka nasta‘in.\nIhdinas-siratal-mustaqim.\nSiratal-ladhina an‘amta ‘alayhim, ghayril-maghdubi ‘alayhim wa lad-dallin.',
        meaning:
            'In Allah’s name, the All-Merciful, the Especially Merciful. Praise belongs to Allah, Lord of all worlds, the All-Merciful, the Especially Merciful, Master of the Day of Recompense. You alone we worship, and You alone we ask for help. Guide us on the straight path: the path of those You have favored, not those who have incurred anger, nor those who are astray.',
        context: 'Recite in every rak‘ah of this example, then say Amin.',
        sourceId: 'prayer-fatihah',
      ),
      GuideSupplication(
        title: 'A short surah: Al-Ikhlas',
        arabic:
            'قُلْ هُوَ اللَّهُ أَحَدٌ\nاللَّهُ الصَّمَدُ\nلَمْ يَلِدْ وَلَمْ يُولَدْ\nوَلَمْ يَكُنْ لَهُ كُفُوًا أَحَدٌ',
        transliteration:
            'Qul huwallahu ahad.\nAllahus-samad.\nLam yalid wa lam yulad.\nWa lam yakul-lahu kufuwan ahad.',
        meaning:
            'Say: He is Allah, One. Allah, the One on whom all depend. He neither begets nor was begotten. And none is equal to Him.',
        context:
            'One option after Al-Fatihah in the first two rak‘ahs. Other Quran passages may be recited.',
        sourceId: 'prayer-ikhlas',
      ),
    ],
    sourceIds: [
      'prayer-hands',
      'prayer-hand-differences',
      'prayer-amin',
      'prayer-fatihah-duty',
      'prayer-recitation',
      'prayer-fatihah',
      'prayer-ikhlas',
      'prayer-refuge',
    ],
  ),
  GuideChapter(
    id: 'prayer-bow',
    title: 'Bow, then stand upright',
    subtitle: 'Ruku‘ and the standing pause',
    image: 'assets/images/learn/prayer_bowing_faceless_mat.webp',
    imageDescription:
        'A rear view of a worshipper bowing, with the hands resting beside the knees.',
    readMinutes: 2,
    category: 'In each rak‘ah',
    introduction:
        'Finish reciting before you bow. Give both the bow and the upright standing their own calm pause.',
    steps: [
      GuideGuidance(
        'Bow for ruku‘',
        'Say “Allahu akbar” as you bow. Place your hands on your knees. A reported posture keeps the back and head level. Settle, then say “Subhana Rabbiyal-‘Azim.” Saying it three times is a customary recommended practice.',
      ),
      GuideGuidance(
        'Rise all the way',
        'While rising, say “Sami‘allahu liman hamidah.” Once fully upright, say “Rabbana wa lakal-hamd.” These instructions are for someone praying alone.',
      ),
      GuideGuidance(
        'Pause before prostrating',
        'Stand straight and let your body settle. Do not turn the standing into a quick movement directly from bowing to the floor.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Posture details',
        'Some schools recommend a more compact bow for women. Follow the posture taught in your school while completing the bow and upright pause.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'In bowing',
        arabic: 'سُبْحَانَ رَبِّيَ الْعَظِيمِ',
        transliteration: 'Subhana Rabbiyal-‘Azim.',
        meaning: 'Glory be to my Lord, the Magnificent.',
        context:
            'Say while settled in ruku‘. Three repetitions are recommended, not a universal condition of validity.',
        sourceId: 'prayer-bow-dhikr',
      ),
      GuideSupplication(
        title: 'As you rise',
        arabic: 'سَمِعَ اللَّهُ لِمَنْ حَمِدَهُ',
        transliteration: 'Sami‘allahu liman hamidah.',
        meaning: 'Allah hears the one who praises Him.',
        context: 'When rising from ruku‘ in this prayer offered alone.',
        sourceId: 'prayer-hands',
      ),
      GuideSupplication(
        title: 'Once standing',
        arabic: 'رَبَّنَا وَلَكَ الْحَمْدُ',
        transliteration: 'Rabbana wa lakal-hamd.',
        meaning: 'Our Lord, all praise belongs to You.',
        context: 'After you have stood upright.',
        sourceId: 'prayer-hands',
      ),
    ],
    sourceIds: [
      'prayer-calm',
      'prayer-postures',
      'prayer-bow-dhikr',
      'prayer-hands',
      'prayer-women',
      'prayer-counts',
    ],
  ),
  GuideChapter(
    id: 'prayer-prostrate',
    title: 'Prostrate twice',
    subtitle: 'Two sajdahs with a sitting between',
    image: 'assets/images/learn/prayer_prostration_faceless_mat.webp',
    imageDescription:
        'A worshipper in prostration viewed from behind, with the face naturally hidden.',
    readMinutes: 2,
    category: 'In each rak‘ah',
    introduction:
        'Every rak‘ah includes two prostrations. Sit calmly between them.',
    steps: [
      GuideGuidance(
        'Make the first sajdah',
        'Say “Allahu akbar” as you lower yourself. Place your forehead and nose, both palms, both knees, and the toes of both feet on the ground. Settle and say “Subhana Rabbiyal-A‘la.” Three repetitions are recommended.',
      ),
      GuideGuidance(
        'Sit between the two',
        'Say “Allahu akbar” as you rise to sit. Pause upright and say “Rabbighfir li.” Sitting on the left foot with the right foot upright is one reported posture; sitting details differ by school and ability.',
      ),
      GuideGuidance(
        'Make the second sajdah',
        'Say “Allahu akbar” and prostrate again with the same contact points. Pause and repeat the prostration remembrance.',
      ),
      GuideGuidance(
        'Complete the second rak‘ah',
        'After the first rak‘ah, say “Allahu akbar” and rise. Repeat Al-Fatihah, another surah, bowing, standing upright, and both prostrations with the sitting between. After the second rak‘ah’s second sajdah, say “Allahu akbar” and sit for tashahhud.',
      ),
    ],
    notes: [
      GuideGuidance(
        'A complete cycle',
        'One rak‘ah has one bow, an upright pause, two prostrations, and a sitting between them. Do not omit the second prostration or the sitting.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'In prostration',
        arabic: 'سُبْحَانَ رَبِّيَ الْأَعْلَى',
        transliteration: 'Subhana Rabbiyal-A‘la.',
        meaning: 'Glory be to my Lord, the Most High.',
        context: 'Say while settled in each sajdah.',
        sourceId: 'prayer-bow-dhikr',
      ),
      GuideSupplication(
        title: 'Between the two prostrations',
        arabic: 'رَبِّ اغْفِرْ لِي',
        transliteration: 'Rabbighfir li.',
        meaning: 'My Lord, forgive me.',
        context:
            'While sitting between the two sajdahs. The report also records repeating it.',
        sourceId: 'prayer-sitting-dua',
      ),
    ],
    sourceIds: [
      'prayer-prostration',
      'prayer-calm',
      'prayer-postures',
      'prayer-transitions',
      'prayer-bow-dhikr',
      'prayer-sitting-dua',
      'prayer-women',
    ],
    reminder: 'Pause in each position before moving to the next.',
  ),
  GuideChapter(
    id: 'prayer-finish',
    title: 'Sit and finish',
    subtitle: 'Tashahhud, blessings, and salam',
    image: 'assets/images/learn/prayer_seated_faceless_mat.webp',
    imageDescription:
        'A rear view of a worshipper seated for the final recitation of prayer.',
    readMinutes: 3,
    category: 'After the second rak‘ah',
    introduction:
        'For this two-rak‘ah prayer, the sitting after the second sajdah of rak‘ah two is the final sitting.',
    steps: [
      GuideGuidance(
        'Recite the tashahhud',
        'Sit calmly, with your hands resting on your thighs or knees. Recite At-Tahiyyat below. Pointing the right index finger is a Sunnah; its timing and movement differ between schools.',
      ),
      GuideGuidance(
        'Send blessings and make dua',
        'In the final sitting, follow the tashahhud with the blessings on the Prophet below. You may then add the authentic supplication for forgiveness.',
      ),
      GuideGuidance(
        'End with the salam',
        'Turn your head to the right and say “As-salamu ‘alaykum wa rahmatullah,” then turn to the left and repeat it. This completes the two-rak‘ah prayer.',
      ),
    ],
    notes: [
      GuideGuidance(
        'For three or four rak‘ahs',
        'After rak‘ah two, recite the tashahhud, then stand with “Allahu akbar” instead of ending with salam. Pray a third rak‘ah, reciting Al-Fatihah, then completing the bow, upright pause, and both sajdahs. For Maghrib, sit and finish here. For Dhuhr, Asr, or Isha, stand for a fourth rak‘ah, then sit and finish. In these later fard rak‘ahs, recite Al-Fatihah without adding another surah.',
      ),
      GuideGuidance(
        'Final sitting every time',
        'Use the full final sequence after the last rak‘ah: tashahhud, blessings, optional dua, and salam. Recognized schools differ on the legal classification of some recitations and on the sitting posture.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'Tashahhud: At-Tahiyyat',
        arabic:
            'التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ، السَّلَامُ عَلَيْكَ أَيُّهَا النَّبِيُّ وَرَحْمَةُ اللَّهِ وَبَرَكَاتُهُ، السَّلَامُ عَلَيْنَا وَعَلَى عِبَادِ اللَّهِ الصَّالِحِينَ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا اللَّهُ، وَأَشْهَدُ أَنَّ مُحَمَّدًا عَبْدُهُ وَرَسُولُهُ',
        transliteration:
            'At-tahiyyatu lillahi was-salawatu wat-tayyibat. As-salamu ‘alayka ayyuhan-nabiyyu wa rahmatullahi wa barakatuh. As-salamu ‘alayna wa ‘ala ‘ibadillahis-salihin. Ashhadu an la ilaha illallah, wa ashhadu anna Muhammadan ‘abduhu wa rasuluh.',
        meaning:
            'All greetings of honor, prayers, and good things belong to Allah. Peace be upon you, O Prophet, and Allah’s mercy and blessings. Peace be upon us and Allah’s righteous servants. I testify that no deity is worthy of worship except Allah, and that Muhammad is His servant and messenger.',
        context:
            'Recite while seated after two rak‘ahs and in the final sitting. This is the wording reported by Ibn Mas‘ud; other authentic versions exist.',
        sourceId: 'prayer-tashahhud',
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
            'After the tashahhud in the final sitting. This is one authentic wording.',
        sourceId: 'prayer-salawat',
      ),
      GuideSupplication(
        title: 'A dua before salam',
        arabic:
            'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي، إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
        transliteration:
            'Allahumma inni zalamtu nafsi zulman kathira, wa la yaghfirudh-dhunuba illa Anta, faghfir li maghfiratan min ‘indika, warhamni, innaka Antal-Ghafurur-Rahim.',
        meaning:
            'O Allah, I have greatly wronged myself, and no one forgives sins except You. Grant me forgiveness from You and have mercy on me. You are the Ever-Forgiving, the Especially Merciful.',
        context:
            'An optional authentic supplication after the final recitations, before salam.',
        sourceId: 'prayer-final-dua',
      ),
      GuideSupplication(
        title: 'The closing salam',
        arabic: 'السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللَّهِ',
        transliteration: 'As-salamu ‘alaykum wa rahmatullah.',
        meaning: 'Peace be upon you, and Allah’s mercy.',
        context:
            'Say once turning to the right, then once turning to the left.',
        sourceId: 'prayer-salam',
      ),
    ],
    sourceIds: [
      'prayer-tashahhud',
      'prayer-salawat',
      'prayer-final-dua',
      'prayer-salam',
      'prayer-finger',
      'prayer-recitation',
      'prayer-counts',
    ],
  ),
];

const _prayerSources = <GuideSource>[
  GuideSource(
    id: 'prayer-times',
    title: 'Prayer at its appointed times',
    subtitle: 'Quran 4:103',
    url: 'https://quran.com/4/103',
  ),
  GuideSource(
    id: 'prayer-qiblah',
    title: 'Facing the qiblah',
    subtitle: 'Quran 2:144',
    url: 'https://quran.com/2/144',
  ),
  GuideSource(
    id: 'prayer-purity',
    title: 'Purification for prayer',
    subtitle: 'Quran 5:6',
    url: 'https://quran.com/5/6',
  ),
  GuideSource(
    id: 'prayer-covering',
    title: 'Covering during prayer',
    subtitle: 'Egypt’s Dar Al-Ifta: A woman praying while wearing the niqab',
    url:
        'https://www.dar-alifta.org/en/fatwa/details/24050/a-woman-praying-while-wearing-the-niqab',
  ),
  GuideSource(
    id: 'prayer-men-covering',
    title: 'Men’s clothing during prayer',
    subtitle: 'Jordan Iftaa Department, fatwa 3072',
    url: 'https://www.aliftaa.jo/research-fatwas/3072/Questions2.aspx?Id=109',
  ),
  GuideSource(
    id: 'prayer-imam',
    title: 'Following the imam',
    subtitle: 'Sahih al-Bukhari 722',
    url: 'https://sunnah.com/bukhari:722',
  ),
  GuideSource(
    id: 'prayer-intention',
    title: 'Intention is in the heart',
    subtitle: 'Egypt’s Dar Al-Ifta, fatwa 2280',
    url:
        'https://dar-alifta.org/ar/fatwa/details/11652/حكم-الجهر-بالنية-عند-الصلاة',
  ),
  GuideSource(
    id: 'prayer-ability',
    title: 'Prayer according to ability',
    subtitle: 'Sahih al-Bukhari 1117',
    url: 'https://sunnah.com/bukhari:1117',
  ),
  GuideSource(
    id: 'prayer-counts',
    title: 'Daily counts and prayer sequence',
    subtitle: 'Ebrahim Noor, Prayers in Salah, 3rd ed., pp. 28–33',
    url:
        'https://islamicportal.co.uk/wp-content/uploads/2018/01/Prayers-in-%E1%B9%A2alah-3rd-Edition.pdf',
  ),
  GuideSource(
    id: 'prayer-hands',
    title: 'Opening and rising from bowing',
    subtitle: 'Sahih al-Bukhari 735',
    url: 'https://sunnah.com/bukhari:735',
  ),
  GuideSource(
    id: 'prayer-hand-differences',
    title: 'Accepted hand positions',
    subtitle: 'Egypt’s Dar Al-Ifta: Letting the hands rest at the sides',
    url:
        'https://dar-alifta.org/ar/fatwa/details/19034/حكم-إرسال-اليدين-في-الصلاة',
  ),
  GuideSource(
    id: 'prayer-amin',
    title: 'Saying Amin after Al-Fatihah',
    subtitle: 'Egypt’s Dar Al-Ifta: Amin after Al-Fatihah in prayer',
    url:
        'https://www.dar-alifta.org/ar/fatwa/details/18478/حكم-التأمين-بعد-قراءة-سورة-الفاتحة-في-الصلاة',
  ),
  GuideSource(
    id: 'prayer-refuge',
    title: 'Seeking refuge before recitation',
    subtitle: 'Quran 16:98',
    url: 'https://quran.com/16/98',
  ),
  GuideSource(
    id: 'prayer-fatihah',
    title: 'Al-Fatihah',
    subtitle: 'Quran 1:1–7',
    url: 'https://quran.com/1',
  ),
  GuideSource(
    id: 'prayer-ikhlas',
    title: 'Al-Ikhlas',
    subtitle: 'Quran 112:1–4',
    url: 'https://quran.com/112',
  ),
  GuideSource(
    id: 'prayer-fatihah-duty',
    title: 'Reciting Al-Fatihah',
    subtitle: 'Sahih al-Bukhari 756',
    url: 'https://sunnah.com/bukhari:756',
  ),
  GuideSource(
    id: 'prayer-recitation',
    title: 'Recitation in successive rak‘ahs',
    subtitle: 'Sahih al-Bukhari 776',
    url: 'https://sunnah.com/bukhari:776',
  ),
  GuideSource(
    id: 'prayer-transitions',
    title: 'Words between postures',
    subtitle: 'Sahih al-Bukhari 789',
    url: 'https://sunnah.com/bukhari:789',
  ),
  GuideSource(
    id: 'prayer-calm',
    title: 'Completing every posture calmly',
    subtitle: 'Sahih al-Bukhari 757',
    url: 'https://sunnah.com/bukhari:757',
  ),
  GuideSource(
    id: 'prayer-postures',
    title: 'Bowing, standing, and sitting',
    subtitle: 'Sahih Muslim 498',
    url: 'https://sunnah.com/muslim:498',
  ),
  GuideSource(
    id: 'prayer-bow-dhikr',
    title: 'Remembrance in bowing and prostration',
    subtitle: 'Sahih Muslim 772',
    url: 'https://sunnah.com/muslim:772',
  ),
  GuideSource(
    id: 'prayer-prostration',
    title: 'The seven points of prostration',
    subtitle: 'Sahih al-Bukhari 812',
    url: 'https://sunnah.com/bukhari:812',
  ),
  GuideSource(
    id: 'prayer-sitting-dua',
    title: 'Supplication between prostrations',
    subtitle: 'Sunan Abi Dawud 874',
    url: 'https://sunnah.com/abudawud:874',
  ),
  GuideSource(
    id: 'prayer-women',
    title: 'Posture details for women',
    subtitle: 'Shaykh Faraz Rabbani, SeekersGuidance, Hanafi answer',
    url:
        'https://seekersguidance.org/uncategorized/what-are-the-differences-between-the-prayer-of-a-man-and-a-woman-in-the-hanafi-school/',
  ),
  GuideSource(
    id: 'prayer-tashahhud',
    title: 'The tashahhud of Ibn Mas‘ud',
    subtitle: 'Sahih al-Bukhari 831',
    url: 'https://sunnah.com/bukhari:831',
  ),
  GuideSource(
    id: 'prayer-salawat',
    title: 'Blessings on the Prophet',
    subtitle: 'Sahih al-Bukhari 3370',
    url: 'https://sunnah.com/bukhari:3370',
  ),
  GuideSource(
    id: 'prayer-final-dua',
    title: 'Supplication before salam',
    subtitle: 'Sahih al-Bukhari 834',
    url: 'https://sunnah.com/bukhari:834',
  ),
  GuideSource(
    id: 'prayer-salam',
    title: 'Salam to the right and left',
    subtitle: 'Sunan Abi Dawud 996',
    url: 'https://sunnah.com/abudawud:996',
  ),
  GuideSource(
    id: 'prayer-finger',
    title: 'The index finger in tashahhud',
    subtitle: 'Egypt’s Dar Al-Ifta, fatwa 5833',
    url:
        'https://dar-alifta.org/ar/fatwa/details/16470/حكم-تحريك-الأصبع-في-التشهد-وكيفيته',
  ),
];
