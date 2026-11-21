import '../domain/guide_term.dart';
import '../domain/learning_guide.dart';
import 'additional_guide_terms.dart';

const guideTerms = <GuideTerm>[
  GuideTerm(
    id: 'salah',
    title: 'Salah',
    aliases: ['salah', 'salat'],
    definition:
        'The prescribed Islamic prayer, with recitation and a sequence of standing, bowing, prostrating, and sitting.',
    details: [
      GuideGuidance(
        'Five daily prayers',
        'The daily fard prayers are Fajr, Dhuhr, Asr, Maghrib, and Isha. Each has an appointed time and number of rak‘ahs.',
      ),
      GuideGuidance(
        'A complete prayer',
        'Begin with intention and the opening takbir. Complete each posture calmly, then end with the closing salam. The Prayer guide walks through two rak‘ahs offered alone.',
      ),
      GuideGuidance(
        'According to ability',
        'Someone unable to stand may pray sitting; someone unable to sit may pray on their side. Further adaptations depend on the person’s circumstances.',
      ),
    ],
    sources: [_prayerTimes, _prayerSequence, _prayerAbility],
  ),
  GuideTerm(
    id: 'wudu',
    title: 'Wudu',
    aliases: ['wudu', 'wudhu', 'ablution'],
    definition:
        'Ritual purification that includes washing the face, arms, and feet, and wiping the head before prayer.',
    details: [
      GuideGuidance(
        'The main sequence',
        'With intention, wash the hands, rinse the mouth and nose, wash the face and arms through the elbows, wipe the head and ears, then wash the feet through the ankles.',
      ),
      GuideGuidance(
        'Coverage before repetition',
        'One complete wash fulfils the washing requirement. Three washes are recommended. The Wudu guide uses one complete head wipe, not three head washes.',
      ),
      GuideGuidance(
        'When it ends',
        'Passing urine, stool, or wind ends wudu. Some other causes, including kinds of touch and sleep, have school-specific rules. Mere doubt does not cancel known wudu.',
      ),
    ],
    sources: [_purification, _wuduSequence, _wuduOnce, _wuduDoubt],
  ),
  GuideTerm(
    id: 'ghusl',
    title: 'Ghusl',
    aliases: ['ghusl', 'ritual bath'],
    definition:
        'A full ritual bath for purification from major ritual impurity. Wudu alone does not replace it when it is required.',
    details: [
      GuideGuidance(
        'When it is needed',
        'Common causes include intercourse, ejaculation, and the end of menstruation or postnatal bleeding. Bathing before entering ihram is recommended, which is a different reason for bathing.',
      ),
      GuideGuidance(
        'What it involves',
        'Intend purification and make water reach the entire body and hair roots. Rinse the mouth and nose gently. Remove barriers to water. A shower can be used; a bathtub is not required.',
      ),
      GuideGuidance(
        'Learn the details for your school',
        'Schools classify intention, mouth and nose rinsing, rubbing, and continuity differently. Hair arrangements and unusual bleeding can need individual guidance. The prophetic method also includes washing the hands and performing wudu before washing the body.',
      ),
    ],
    sources: [_purification, _ghuslMethod, _ghuslDetails],
  ),
  GuideTerm(
    id: 'tayammum',
    title: 'Tayammum',
    aliases: ['tayammum', 'dry ablution'],
    definition:
        'Ritual purification using clean earth in circumstances where water is unavailable or cannot lawfully be used.',
    details: [
      GuideGuidance(
        'A permitted alternative',
        'The Quran provides tayammum when the conditions for using it are met. It can take the place of wudu or ghusl in those circumstances; it is not a general shortcut when water is usable.',
      ),
      GuideGuidance(
        'The basic action',
        'It involves intention and wiping the face and hands using a permitted clean earth material. The Prophet demonstrated it to ‘Ammar after he could not find water.',
      ),
      GuideGuidance(
        'Details differ',
        'Schools differ about suitable materials, the extent of the arms to wipe, and related conditions. Learn the method and eligibility for your school before relying on it.',
      ),
    ],
    sources: [_purification, _tayammumReport, _tayammumDetails],
  ),
  GuideTerm(
    id: 'rakah',
    title: 'Rak‘ah',
    aliases: [
      'rak‘ah',
      'rak‘ahs',
      'rak’ah',
      'rak’ahs',
      "rak'ah",
      "rak'ahs",
      'rakah',
      'rakahs',
    ],
    definition:
        'One unit of prayer: standing and recitation, one bow, an upright pause, then two prostrations with a sitting between them.',
    details: [
      GuideGuidance(
        'Count complete units',
        'Both prostrations belong to one rak‘ah. A bow alone, or a single prostration, is not a complete rak‘ah.',
      ),
      GuideGuidance(
        'Different prayer lengths',
        'Fajr has two fard rak‘ahs; Maghrib has three; Dhuhr, Asr, and Isha ordinarily have four. Travel and Friday prayer have separate rules.',
      ),
    ],
    sources: [_prayerSequence, _prayerCounts],
  ),
  GuideTerm(
    id: 'qiblah',
    title: 'Qiblah',
    aliases: ['qiblah', 'qibla'],
    definition:
        'The direction of the Kaaba in Makkah, which Muslims face for prayer.',
    sources: [_qiblah],
  ),
  GuideTerm(
    id: 'fard',
    title: 'Fard',
    aliases: ['fard', 'fardh'],
    definition:
        'An obligatory religious duty. “Fard rak‘ahs” means the required units of a prayer, separate from additional prayers.',
    details: [
      GuideGuidance(
        'How the guide uses it',
        'The five daily prayer counts in the guide refer to their fard units. Additional Sunnah prayers and Witr are not included in those numbers.',
      ),
      GuideGuidance(
        'Fard and wajib',
        'Hanafi law distinguishes fard from wajib according to the strength of the evidence and their legal effects. Both require observance. Other schools often use the two terms interchangeably.',
      ),
    ],
    sources: [_legalCategories, _prayerCounts],
  ),
  GuideTerm(
    id: 'wajib',
    title: 'Wajib',
    aliases: ['wajib'],
    definition:
        'A required act. In Hanafi law it is a distinct category from fard, but it is still required, not merely optional.',
    sources: [_legalCategories],
  ),
  GuideTerm(
    id: 'sunnah',
    title: 'Sunnah',
    aliases: ['Sunnah', 'Sunna'],
    definition:
        'The Prophet’s teaching and practice. In instructions about a particular act, “Sunnah” often means recommended practice rather than a condition of validity.',
    details: [
      GuideGuidance(
        'Meaning depends on context',
        'Sunnah can refer broadly to the Prophet’s way, or more narrowly to a legal category of recommended acts. Do not assume that every act established in the Sunnah is optional.',
      ),
      GuideGuidance(
        'Levels of emphasis',
        'Some recommended practices are especially emphasized. Schools can also classify the same act differently, as with the prayer after tawaf. Follow the qualification given with the instruction.',
      ),
    ],
    sources: [_sunnahCategory, _tawafPrayer],
  ),
  GuideTerm(
    id: 'sunni-schools',
    title: 'Sunni schools of law',
    aliases: [
      'Sunni',
      'Hanafi',
      'Hanafis',
      'Maliki',
      'Malikis',
      'Shafi‘i',
      'Shafi’i',
      "Shafi'i",
      'Hanbali',
      'Hanbalis',
      'madhhab',
      'madhhabs',
    ],
    definition:
        'Hanafi, Maliki, Shafi‘i, and Hanbali are four established schools of Islamic law within the Sunni tradition. They share core worship while differing on some details.',
    details: [
      GuideGuidance(
        'What a school provides',
        'A school, or madhhab, is a developed method for understanding religious evidence and applying it to worship and daily life. Its rulings are taught through generations of scholarship.',
      ),
      GuideGuidance(
        'Why this matters here',
        'Hand positions, some purification rules, and the classification of particular acts can differ. A difference from an illustration does not by itself make someone’s worship invalid.',
      ),
      GuideGuidance(
        'Learning a consistent method',
        'Learn from a qualified teacher who can explain the rulings relevant to you. These guides mention important differences without trying to decide every individual case.',
      ),
    ],
    sources: [_schools],
  ),
  GuideTerm(
    id: 'imam',
    title: 'Imam',
    aliases: ['imam'],
    definition:
        'In these guides, the person leading a congregational prayer. Those praying behind the imam follow rather than move ahead.',
    sources: [_imam],
  ),
  GuideTerm(
    id: 'fajr',
    title: 'Fajr',
    aliases: ['Fajr'],
    definition:
        'The dawn prayer, offered before sunrise. Its required prayer has two units.',
    sources: [_dailyTimes, _prayerCounts],
  ),
  GuideTerm(
    id: 'dhuhr',
    title: 'Dhuhr',
    aliases: ['Dhuhr', 'Zuhr'],
    definition:
        'The midday prayer, after the sun has passed its highest point. Its required prayer ordinarily has four units for someone not travelling.',
    sources: [_dailyTimes, _prayerCounts],
  ),
  GuideTerm(
    id: 'asr',
    title: 'Asr',
    aliases: ['Asr'],
    definition:
        'The afternoon prayer. Its required prayer ordinarily has four units for someone not travelling.',
    sources: [_dailyTimes, _prayerCounts],
  ),
  GuideTerm(
    id: 'maghrib',
    title: 'Maghrib',
    aliases: ['Maghrib'],
    definition: 'The prayer after sunset. Its required prayer has three units.',
    sources: [_dailyTimes, _prayerCounts],
  ),
  GuideTerm(
    id: 'isha',
    title: 'Isha',
    aliases: ['Isha'],
    definition:
        'The night prayer, after the evening twilight. Its required prayer ordinarily has four units for someone not travelling.',
    sources: [_dailyTimes, _prayerCounts],
  ),
  GuideTerm(
    id: 'witr',
    title: 'Witr',
    aliases: ['Witr'],
    definition:
        'A prayer with an odd number of prayer units, offered after the night prayer and before dawn. It is separate from the night prayer’s four required units.',
    details: [
      GuideGuidance(
        'Its status',
        'Witr is wajib in the Hanafi school and an emphasized Sunnah in the other three schools. It should not simply be described as optional for everyone.',
      ),
      GuideGuidance(
        'Its method',
        'Hanafis pray three connected rak‘ahs. Other recognized methods differ in the number and arrangement of units and the special supplication. Learn the form used in your school.',
      ),
    ],
    sources: [_witrReport, _witrDetails, _witrStatus],
  ),
  GuideTerm(
    id: 'jumuah',
    title: 'Jumu‘ah',
    aliases: ['Jumu‘ah', 'Jumu’ah', "Jumu'ah", 'Jumuah'],
    definition:
        'The Friday congregational prayer, with a sermon and two rak‘ahs, which takes the place of Dhuhr for those who attend it validly.',
    details: [
      GuideGuidance(
        'A congregation with a sermon',
        'Jumu‘ah is not simply two rak‘ahs prayed alone at home. It has a sermon, congregational conditions, and an appointed time.',
      ),
      GuideGuidance(
        'Who must attend',
        'Attendance requirements and exemptions depend on circumstances such as residence, travel, and ability. Someone not attending Jumu‘ah ordinarily prays Dhuhr instead; ask about your own situation.',
      ),
    ],
    sources: [_friday, _prayerCounts],
  ),
  GuideTerm(
    id: 'takbir',
    title: 'Takbir',
    aliases: ['takbir', 'Allahu akbar'],
    definition:
        'Saying “Allahu akbar,” meaning “Allah is greater.” The opening takbir begins salah; it is also said at many transitions.',
    sources: [_transitions],
  ),
  GuideTerm(
    id: 'bismillah',
    title: 'Bismillah',
    aliases: ['Bismillah'],
    definition:
        '“In the name of Allah.” The full phrase at the start of Al-Fatihah also names Allah as the All-Merciful, the Especially Merciful.',
    sources: [_fatihah],
  ),
  GuideTerm(
    id: 'amin',
    title: 'Amin',
    aliases: ['Amin', 'Ameen'],
    definition:
        'An appeal meaning “O Allah, answer.” It is said after Al-Fatihah and is not one of the surah’s verses.',
    sources: [_amin],
  ),
  GuideTerm(
    id: 'surah',
    title: 'Surah',
    aliases: ['surah', 'surahs'],
    definition:
        'A chapter of the Quran. Al-Fatihah and Al-Ikhlas are two examples.',
    sources: [_fatihah, _ikhlas],
  ),
  GuideTerm(
    id: 'al-fatihah',
    title: 'Al-Fatihah',
    aliases: ['Al-Fatihah', 'Al-Fatiha'],
    definition:
        'The opening chapter of the Quran, a prayer of praise and a request for guidance. It is recited while standing in salah.',
    details: [
      GuideGuidance(
        'In the Prayer guide',
        'Recite all of Al-Fatihah in each rak‘ah of the example offered alone. Its complete Arabic, transliteration, and meaning are in the standing chapter.',
      ),
      GuideGuidance(
        'Behind an imam',
        'Rules for a follower’s recitation differ by school. Do not apply the praying-alone example to every congregational situation without learning that distinction.',
      ),
    ],
    sources: [_fatihah, _fatihahPrayer],
  ),
  GuideTerm(
    id: 'al-ikhlas',
    title: 'Al-Ikhlas',
    aliases: ['Al-Ikhlas'],
    definition:
        'Chapter 112 of the Quran, affirming Allah’s oneness and uniqueness. It is a short surah used as an example in the Prayer guide.',
    sources: [_ikhlas],
  ),
  GuideTerm(
    id: 'al-kafirun',
    title: 'Al-Kafirun',
    aliases: ['Al-Kafirun'],
    definition:
        'Chapter 109 of the Quran. Reciting it after Al-Fatihah in the first of the two rak‘ahs after tawaf is recommended.',
    sources: [_kafirun, _jabir],
  ),
  GuideTerm(
    id: 'ruku',
    title: 'Ruku‘',
    aliases: ['ruku‘', 'ruku’', "ruku'", 'ruku'],
    definition:
        'The bowing posture in salah. Each rak‘ah includes one bow, followed by standing fully upright before prostration.',
    sources: [_prayerSequence],
  ),
  GuideTerm(
    id: 'sajdah',
    title: 'Sajdah',
    aliases: [
      'sajdah',
      'sajdahs',
      'sujud',
      'sujood',
      'prostration',
      'prostrations',
    ],
    definition:
        'A prostration in prayer. Each rak‘ah includes two, with an upright sitting between them.',
    details: [
      GuideGuidance(
        'The contact points',
        'In the standard posture, the forehead and nose, both hands, both knees, and toes of both feet touch the ground.',
      ),
      GuideGuidance(
        'Two, with a pause between',
        'Settle in the first prostration, rise and sit calmly, then make the second. Body positioning has recognized school differences and adaptations for inability.',
      ),
    ],
    sources: [_prostration, _prayerSequence],
  ),
  GuideTerm(
    id: 'tashahhud',
    title: 'Tashahhud',
    aliases: ['tashahhud', 'At-Tahiyyat'],
    definition:
        'The seated recitation that includes greetings of honor and the testimony of faith. The version in the guide begins “At-tahiyyatu lillah.”',
    details: [
      GuideGuidance(
        'When to recite it',
        'Recite it in the sitting after two rak‘ahs, and again in the final sitting of a longer prayer. In a two-rak‘ah prayer, these are the same sitting.',
      ),
      GuideGuidance(
        'The final sitting continues',
        'In the guide’s final sitting, follow tashahhud with blessings on the Prophet, then an optional dua, and close with salam. Several authentic tashahhud wordings exist.',
      ),
    ],
    sources: [_tashahhud, _prayerPostures, _salawat],
  ),
  GuideTerm(
    id: 'salawat',
    title: 'Blessings on the Prophet',
    aliases: ['blessings on the Prophet', 'salawat'],
    definition:
        'A prayer asking Allah to bestow His favor and blessings on the Prophet Muhammad. The final sitting includes an established form of this prayer.',
    sources: [_salawat],
  ),
  GuideTerm(
    id: 'salam',
    title: 'Salam',
    aliases: ['salam', 'taslim'],
    definition:
        'The closing greeting of salah. In this guide, say “As-salamu ‘alaykum wa rahmatullah” while turning right, then repeat it to the left.',
    sources: [_salam],
  ),
  GuideTerm(
    id: 'dua',
    title: 'Dua',
    aliases: ['dua', 'duas', 'du‘a', 'du’a', 'supplication', 'supplications'],
    definition:
        'Calling upon Allah in prayer, such as asking for forgiveness, guidance, or help. It can be a transmitted supplication or a personal request.',
    details: [
      GuideGuidance(
        'In the pilgrimage rites',
        'You may make personal dua during tawaf and sa’i. There is no prescribed separate dua for every numbered circuit or length.',
      ),
      GuideGuidance(
        'Inside salah',
        'Salah has its own recitations and rules for supplication. The Prayer guide includes an authentic Arabic dua before salam; do not assume every freedom outside salah applies inside it.',
      ),
    ],
    sources: [_duaInTawaf, _finalDua],
  ),
  GuideTerm(
    id: 'dhikr',
    title: 'Dhikr',
    aliases: ['dhikr'],
    definition:
        'Remembering Allah, including words of praise, glorification, and affirmation of His oneness. The Safa and Marwah remembrance is one example.',
    sources: [_jabir],
  ),
  GuideTerm(
    id: 'umrah',
    title: 'Umrah',
    aliases: ['Umrah'],
    definition:
        'Pilgrimage worship in Makkah involving ihram, tawaf, sa’i, and shaving or shortening the hair to leave ihram.',
    details: [
      GuideGuidance(
        'The order',
        'Enter ihram, complete seven circuits of tawaf, walk seven lengths between Safa and Marwah, then shave or shorten the hair as appropriate.',
      ),
      GuideGuidance(
        'Distinct from Hajj',
        'Standing at Arafat, staying at Muzdalifah, and stoning the Jamarat belong to Hajj. They are not steps of this Umrah.',
      ),
      GuideGuidance(
        'Travel arrangements',
        'Access and booking requirements can change. Check official Nusuk information before departure rather than relying on a saved rule.',
      ),
    ],
    sources: [_nusukJourney, _nusukPlanning],
  ),
  GuideTerm(
    id: 'ihram',
    title: 'Ihram',
    aliases: ['ihram'],
    definition:
        'The sacred state entered to perform Hajj or Umrah, with specific restrictions. Wearing the garments alone does not begin that state.',
    details: [
      GuideGuidance(
        'Entering it',
        'Prepare before the route’s miqat, intend Umrah, and recite talbiyah. The miqat is not simply the airport where you arrive.',
      ),
      GuideGuidance(
        'Garments and restrictions',
        'Men use an izar and rida; women wear modest clothing with the head covered. Perfume, deliberate hair removal, and other specified acts are restricted. Clothing and face-covering details differ by school.',
      ),
      GuideGuidance(
        'Leaving it',
        'In the Umrah described here, complete tawaf and sa’i, then the haircut. Finishing the walking alone does not lift the restrictions.',
      ),
    ],
    sources: [_miqat, _ihramClothing, _umrahRulings],
  ),
  GuideTerm(
    id: 'miqat',
    title: 'Miqat',
    aliases: ['miqat', 'mawaqit'],
    definition:
        'A designated boundary for entering ihram when approaching Makkah for Hajj or Umrah. The relevant boundary depends on your route.',
    details: [
      GuideGuidance(
        'For an arriving pilgrim',
        'If travelling with the intention of Umrah, enter ihram at or before your route’s miqat. Air travellers should prepare before the flight reaches that boundary.',
      ),
      GuideGuidance(
        'Different starting circumstances',
        'People already within the boundaries, including those already in Makkah, have further rules. If you crossed without ihram or are starting from Makkah, ask a qualified guide about the correct starting point.',
      ),
    ],
    sources: [_miqat],
  ),
  GuideTerm(
    id: 'talbiyah',
    title: 'Talbiyah',
    aliases: ['talbiyah'],
    definition:
        'The pilgrimage recitation beginning “Labbayka Allahumma labbayk,” expressing a response to Allah’s call and affirming that He has no partner.',
    details: [
      GuideGuidance(
        'Its meaning',
        'The words declare readiness to respond to Allah and attribute praise, blessing, and sovereignty to Him alone.',
      ),
      GuideGuidance(
        'In this Umrah',
        'Recite it when entering ihram and continue during the journey until beginning tawaf. The Ihram chapter includes its full Arabic and meaning.',
      ),
    ],
    sources: [_talbiyah, _nusukJourney],
  ),
  GuideTerm(
    id: 'tawaf',
    title: 'Tawaf',
    aliases: ['tawaf'],
    definition:
        'Worship by making seven complete circuits around the Kaaba, counterclockwise with the Kaaba on your left.',
    details: [
      GuideGuidance(
        'Start and count',
        'Begin aligned with the Black Stone. Returning to that point completes one circuit. Pass outside the Hijr rather than through its enclosed area.',
      ),
      GuideGuidance(
        'Purity and safety',
        'Perform tawaf with wudu and appropriate covering. Schools differ on the legal classification of purity and on how to resume after it breaks. Touching the Black Stone is not required; avoid pushing.',
      ),
      GuideGuidance(
        'Remembrance and the prayer afterward',
        'Make dua or remember Allah without a fixed formula for each numbered circuit. Include the two rak‘ahs afterward, in a safe place clear of walking routes.',
      ),
    ],
    sources: [_tawafRules, _tawafPurity, _blackStone, _tawafPrayer],
  ),
  GuideTerm(
    id: 'sai',
    title: 'Sa’i',
    aliases: ['sa’i', 'sa‘i', "sa'i", 'sai'],
    definition:
        'Seven one-way journeys between Safa and Marwah after tawaf, starting at Safa and ending at Marwah.',
    details: [
      GuideGuidance(
        'Each direction counts once',
        'Safa to Marwah is one length. The return to Safa is the second. After the seventh length you are at Marwah, not back at Safa.',
      ),
      GuideGuidance(
        'Walking and remembrance',
        'Walk the full route and make dua. Men who are able run only between the green markers when safe; women walk throughout. Climbing the rocks is not required.',
      ),
      GuideGuidance(
        'Before leaving ihram',
        'Completing sa’i does not itself end ihram. The haircut follows. Wudu is recommended for sa’i, but is not a condition of its validity.',
      ),
    ],
    sources: [_jabir, _haramainGuide, _umrahRulings],
  ),
  GuideTerm(
    id: 'kaaba',
    title: 'Kaaba',
    aliases: ['Kaaba', 'Ka‘bah', 'Ka’bah', "Ka'bah"],
    definition:
        'The sacred House at the center of the Grand Mosque in Makkah. Muslims face its direction in prayer and worship Allah by making tawaf around it.',
    sources: [_qiblah, _sacredHouse],
  ),
  GuideTerm(
    id: 'maqam-ibrahim',
    title: 'Maqam Ibrahim',
    aliases: ['Maqam Ibrahim'],
    definition:
        'The stone on which the Prophet Ibrahim stood while building the Kaaba, now preserved nearby. The Quran associates this station with prayer.',
    details: [
      GuideGuidance(
        'After tawaf',
        'Pray the two rak‘ahs behind it when there is safe space. If the area is busy, pray elsewhere in the mosque without blocking the tawaf route.',
      ),
      GuideGuidance(
        'What it is not',
        'It is not Ibrahim’s tomb. Prayer is offered to Allah; reaching or touching the structure is not a step required for Umrah.',
      ),
    ],
    sources: [_maqam, _buildingKaaba, _haramainGuide],
  ),
  GuideTerm(
    id: 'hijr',
    title: 'Hijr',
    aliases: ['Hijr'],
    definition:
        'The area beside the Kaaba enclosed by a low semicircular wall. It contains part of the original Kaaba’s footprint; tawaf passes outside the enclosure.',
    sources: [_tawafRules, _hijr],
  ),
  GuideTerm(
    id: 'black-stone',
    title: 'Black Stone',
    aliases: ['Black Stone'],
    definition:
        'The stone set in one corner of the Kaaba. Alignment with it marks the start and completion of each tawaf circuit.',
    details: [
      GuideGuidance(
        'A marker for tawaf',
        'When aligned with it, say “Allahu akbar.” Touching or kissing it is a reported practice, but is not required to complete tawaf.',
      ),
      GuideGuidance(
        'Keep moving safely',
        'Gesture from a distance when you cannot reach it safely. Do not push or stop the moving crowd to get closer.',
      ),
    ],
    sources: [_blackStone, _tawafRules],
  ),
  GuideTerm(
    id: 'yemeni-corner',
    title: 'Yemeni Corner',
    aliases: ['Yemeni Corner'],
    definition:
        'The corner of the Kaaba encountered before the Black Stone when making tawaf. The guide’s “Rabbana atina” dua is reported between these two corners.',
    sources: [_corners],
  ),
  GuideTerm(
    id: 'zamzam',
    title: 'Zamzam',
    aliases: ['Zamzam'],
    definition:
        'Water from the historic well in Makkah near the Kaaba. Pilgrims may drink it; drinking it is not a condition for completing Umrah.',
    sources: [_buildingKaaba, _jabir, _nusukJourney],
  ),
  GuideTerm(
    id: 'safa',
    title: 'Safa',
    aliases: ['Safa', 'Al-Safa'],
    definition:
        'The starting point of sa’i. Walk from Safa to Marwah for the first length, then continue alternating directions.',
    sources: [_safaMarwah, _jabir],
  ),
  GuideTerm(
    id: 'marwah',
    title: 'Marwah',
    aliases: ['Marwah', 'Marwa', 'Al-Marwah'],
    definition:
        'The other endpoint of sa’i. Beginning at Safa, you reach Marwah at the end of lengths one, three, five, and seven.',
    sources: [_safaMarwah, _jabir],
  ),
  GuideTerm(
    id: 'haram',
    title: 'The Haram boundary',
    aliases: ['Haram boundary', 'Haram'],
    definition:
        'Here, the sacred precinct around Makkah with defined boundaries. It is larger than the Grand Mosque itself.',
    details: [
      GuideGuidance(
        'A sacred area',
        'The Haram has particular religious protections and boundaries. “Inside the Haram” does not simply mean inside the mosque building.',
      ),
      GuideGuidance(
        'The Umrah haircut',
        'The guide advises arranging the haircut within this boundary because that location is required in Hanafi practice. Confirm whether your accommodation is inside it before relying on a hotel haircut.',
      ),
    ],
    sources: [_haramSanctity, _haircutLocation],
  ),
  GuideTerm(
    id: 'izar',
    title: 'Izar',
    aliases: ['izar'],
    definition: 'The lower wrap worn around the waist by a man in ihram.',
    sources: [_ihramClothing],
  ),
  GuideTerm(
    id: 'rida',
    title: 'Rida',
    aliases: ['rida'],
    definition:
        'The upper cloth worn over the body by a man in ihram. Both shoulders are covered for prayer.',
    sources: [_shoulderWrap],
  ),
  GuideTerm(
    id: 'niqab',
    title: 'Niqab',
    aliases: ['niqab'],
    definition:
        'A fitted face veil. In ihram, women do not wear a fitted niqab; draping fabric over the face is a separate issue with school-specific details.',
    sources: [_ihramClothing, _womenFace],
  ),
  GuideTerm(
    id: 'hajj',
    title: 'Hajj',
    aliases: ['Hajj'],
    definition:
        'The pilgrimage performed at its appointed time each year, with rites that include Arafat. Its sequence differs from Umrah.',
    details: [
      GuideGuidance(
        'Its obligation',
        'Hajj is a duty for those who meet its conditions and have the ability to undertake it. Personal eligibility and travel arrangements need their own guidance.',
      ),
      GuideGuidance(
        'Different rites',
        'Arafat, Muzdalifah, and the Jamarat are part of Hajj. Adding them to an Umrah itinerary does not make them Umrah rites.',
      ),
    ],
    sources: [_hajjDuty, _jabir],
  ),
  GuideTerm(
    id: 'arafat',
    title: 'Arafat',
    aliases: ['Arafat'],
    definition:
        'The plain where pilgrims stand and make supplication on the ninth of Dhul-Hijjah during Hajj. Visiting it is not an Umrah rite.',
    sources: [_jabir],
  ),
  GuideTerm(
    id: 'muzdalifah',
    title: 'Muzdalifah',
    aliases: ['Muzdalifah'],
    definition:
        'A place visited after Arafat in the Hajj sequence. Staying there belongs to Hajj, not to the steps of Umrah.',
    sources: [_jabir],
  ),
  GuideTerm(
    id: 'jamarat',
    title: 'Jamarat',
    aliases: ['Jamarat'],
    definition:
        'The designated stoning sites in Mina used during Hajj. Stoning them is not part of Umrah.',
    sources: [_jabir],
  ),
  GuideTerm(
    id: 'makkah',
    title: 'Makkah',
    aliases: ['Makkah', 'Mecca'],
    definition:
        'The city in Saudi Arabia containing the Kaaba and the Grand Mosque, where Umrah is performed.',
    sources: [_nusukJourney],
  ),
  GuideTerm(
    id: 'madinah',
    title: 'Madinah',
    aliases: ['Madinah', 'Medina'],
    definition:
        'The city of the Prophet’s Mosque. Visiting Madinah is separate from the rites needed to complete Umrah.',
    sources: [_madinah, _madinahVisit],
  ),
  GuideTerm(
    id: 'nusuk',
    title: 'Nusuk',
    aliases: ['Nusuk'],
    definition:
        'Saudi Arabia’s official pilgrimage platform. Use its current information for Umrah services, bookings, and access arrangements.',
    sources: [_nusukPlanning],
  ),
  ...additionalGuideTerms,
];

const _purification = GuideSource(
  id: 'quran-5-6',
  title: 'Purification for worship',
  subtitle: 'Quran 5:6',
  url: 'https://quran.com/5/6',
);
const _prayerTimes = GuideSource(
  id: 'quran-4-103',
  title: 'The appointed prayer times',
  subtitle: 'Quran 4:103',
  url: 'https://quran.com/4/103',
);
const _prayerSequence = GuideSource(
  id: 'bukhari-757',
  title: 'Completing the prayer postures',
  subtitle: 'Sahih al-Bukhari 757',
  url: 'https://sunnah.com/bukhari:757',
);
const _prayerAbility = GuideSource(
  id: 'bukhari-1117',
  title: 'Prayer according to ability',
  subtitle: 'Sahih al-Bukhari 1117',
  url: 'https://sunnah.com/bukhari:1117',
);
const _wuduSequence = GuideSource(
  id: 'bukhari-159',
  title: 'The wudu sequence',
  subtitle: 'Sahih al-Bukhari 159',
  url: 'https://sunnah.com/bukhari:159',
);
const _wuduOnce = GuideSource(
  id: 'bukhari-157',
  title: 'One complete wash',
  subtitle: 'Sahih al-Bukhari 157',
  url: 'https://sunnah.com/bukhari:157',
);
const _wuduDoubt = GuideSource(
  id: 'muslim-362',
  title: 'Certainty and doubt',
  subtitle: 'Sahih Muslim 362',
  url: 'https://sunnah.com/muslim:362',
);
const _ghuslMethod = GuideSource(
  id: 'bukhari-248',
  title: 'The prophetic bath',
  subtitle: 'Sahih al-Bukhari 248',
  url: 'https://sunnah.com/bukhari:248',
);
const _ghuslDetails = GuideSource(
  id: 'ghusl-details',
  title: 'Ghusl: causes and method',
  subtitle: 'Faraz Rabbani, SeekersGuidance, Hanafi answer',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/the-ritual-bath-ghusl-obligatory-recommended-and-disliked-acts/',
);
const _tayammumReport = GuideSource(
  id: 'bukhari-347',
  title: 'The teaching given to ‘Ammar',
  subtitle: 'Sahih al-Bukhari 347',
  url: 'https://sunnah.com/bukhari:347',
);
const _tayammumDetails = GuideSource(
  id: 'tayammum-details',
  title: 'A school-specific tayammum method',
  subtitle: 'Tabraze Azam, SeekersGuidance, Hanafi answer',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/how-to-make-dry-ablution-tayammum/',
);
const _prayerCounts = GuideSource(
  id: 'prayer-counts',
  title: 'Daily fard counts',
  subtitle: 'Ebrahim Noor, Prayers in Salah, 3rd ed., p. 28',
  url:
      'https://islamicportal.co.uk/wp-content/uploads/2018/01/Prayers-in-%E1%B9%A2alah-3rd-Edition.pdf',
);
const _qiblah = GuideSource(
  id: 'quran-2-144',
  title: 'The direction of prayer',
  subtitle: 'Quran 2:144',
  url: 'https://quran.com/2/144',
);
const _legalCategories = GuideSource(
  id: 'fard-wajib',
  title: 'Fard and wajib in Hanafi law',
  subtitle: 'Faraz Rabbani, SeekersGuidance',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/how-do-the-hanafis-distinguish-between-fard-wajib-and-and-when-denial-becomes-disbelief/',
);
const _sunnahCategory = GuideSource(
  id: 'sunnah-category',
  title: 'Emphasized Sunnah',
  subtitle: 'Egypt’s Dar Al-Ifta, fatwa 6881',
  url:
      'https://www.dar-alifta.org/ar/fatwa/details/17521/بيان-المراد-بمصطلح-سنة-الـهُدى-عند-السادة-الأحناف',
);
const _schools = GuideSource(
  id: 'sunni-schools',
  title: 'The Sunni schools of law',
  subtitle: 'Egypt’s Dar Al-Ifta, fatwa 5916',
  url:
      'https://www.dar-alifta.org/en/fatwa/details/5916/am-i-obliged-to-follow-only-one-of-the-four-sunni-legal-schools-of-jurisprudence',
);
const _imam = GuideSource(
  id: 'bukhari-722',
  title: 'Following the imam',
  subtitle: 'Sahih al-Bukhari 722',
  url: 'https://sunnah.com/bukhari:722',
);
const _dailyTimes = GuideSource(
  id: 'muslim-612',
  title: 'The five daily prayer times',
  subtitle: 'Sahih Muslim 612d',
  url: 'https://sunnah.com/muslim:612d',
);
const _witrReport = GuideSource(
  id: 'bukhari-998',
  title: 'Witr and the night prayer',
  subtitle: 'Sahih al-Bukhari 998',
  url: 'https://sunnah.com/bukhari:998',
);
const _witrDetails = GuideSource(
  id: 'witr-details',
  title: 'The Hanafi method of Witr',
  subtitle: 'Faraz Rabbani, SeekersGuidance',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/details-regarding-witr-confirmed-sunna-and-non-confirmed-sunna-prayers/',
);
const _witrStatus = GuideSource(
  id: 'witr-status',
  title: 'The status of Witr across schools',
  subtitle: 'Yusuf Badat, Mathabah Institute',
  url: 'https://mathabah.org/the-status-of-witr-prayer/',
);
const _friday = GuideSource(
  id: 'quran-62-9',
  title: 'The Friday call to prayer',
  subtitle: 'Quran 62:9',
  url: 'https://quran.com/62/9',
);
const _transitions = GuideSource(
  id: 'bukhari-789',
  title: 'Takbir in prayer',
  subtitle: 'Sahih al-Bukhari 789',
  url: 'https://sunnah.com/bukhari:789',
);
const _fatihah = GuideSource(
  id: 'quran-1',
  title: 'Al-Fatihah',
  subtitle: 'Quran 1',
  url: 'https://quran.com/1',
);
const _ikhlas = GuideSource(
  id: 'quran-112',
  title: 'Al-Ikhlas',
  subtitle: 'Quran 112',
  url: 'https://quran.com/112',
);
const _kafirun = GuideSource(
  id: 'quran-109',
  title: 'Al-Kafirun',
  subtitle: 'Quran 109',
  url: 'https://quran.com/109',
);
const _amin = GuideSource(
  id: 'amin',
  title: 'Amin after Al-Fatihah',
  subtitle: 'Egypt’s Dar Al-Ifta',
  url:
      'https://www.dar-alifta.org/ar/fatwa/details/18478/حكم-التأمين-بعد-قراءة-سورة-الفاتحة-في-الصلاة',
);
const _fatihahPrayer = GuideSource(
  id: 'bukhari-756',
  title: 'Al-Fatihah in prayer',
  subtitle: 'Sahih al-Bukhari 756',
  url: 'https://sunnah.com/bukhari:756',
);
const _prostration = GuideSource(
  id: 'bukhari-812',
  title: 'Prostration contact points',
  subtitle: 'Sahih al-Bukhari 812',
  url: 'https://sunnah.com/bukhari:812',
);
const _tashahhud = GuideSource(
  id: 'bukhari-831',
  title: 'The seated testimony',
  subtitle: 'Sahih al-Bukhari 831',
  url: 'https://sunnah.com/bukhari:831',
);
const _prayerPostures = GuideSource(
  id: 'muslim-498',
  title: 'The prayer’s postures and sittings',
  subtitle: 'Sahih Muslim 498',
  url: 'https://sunnah.com/muslim:498',
);
const _salawat = GuideSource(
  id: 'bukhari-3370',
  title: 'Blessings on the Prophet',
  subtitle: 'Sahih al-Bukhari 3370',
  url: 'https://sunnah.com/bukhari:3370',
);
const _salam = GuideSource(
  id: 'abudawud-996',
  title: 'The closing salam',
  subtitle: 'Sunan Abi Dawud 996',
  url: 'https://sunnah.com/abudawud:996',
);
const _finalDua = GuideSource(
  id: 'bukhari-834',
  title: 'A supplication before salam',
  subtitle: 'Sahih al-Bukhari 834',
  url: 'https://sunnah.com/bukhari:834',
);
const _duaInTawaf = GuideSource(
  id: 'dua-in-tawaf',
  title: 'Dua during tawaf',
  subtitle: 'Ibn Baz, fatwa 15716',
  url: 'https://binbaz.org.sa/fatwas/15716/الدعاء-في-الطواف',
);
const _umrahRulings = GuideSource(
  id: 'umrah-rulings',
  title: 'Umrah rites',
  subtitle: 'Egypt’s Dar Al-Ifta',
  url:
      'https://www.dar-alifta.org/en/article/details/103/the-umrah-rulings-and-rites',
);
const _nusukPlanning = GuideSource(
  id: 'nusuk',
  title: 'Official Umrah information',
  subtitle: 'Nusuk',
  url: 'https://www.nusuk.sa/umrah',
);
const _nusukJourney = GuideSource(
  id: 'nusuk-journey',
  title: 'The Umrah journey',
  subtitle: 'Nusuk, Ministry of Hajj and Umrah',
  url: 'https://umrah.nusuk.sa/Journey',
);
const _miqat = GuideSource(
  id: 'bukhari-1524',
  title: 'The pilgrimage boundaries',
  subtitle: 'Sahih al-Bukhari 1524',
  url: 'https://sunnah.com/bukhari:1524',
);
const _ihramClothing = GuideSource(
  id: 'bukhari-1838',
  title: 'Clothing in ihram',
  subtitle: 'Sahih al-Bukhari 1838',
  url: 'https://sunnah.com/bukhari:1838',
);
const _talbiyah = GuideSource(
  id: 'bukhari-1549',
  title: 'The Prophet’s talbiyah',
  subtitle: 'Sahih al-Bukhari 1549',
  url: 'https://sunnah.com/bukhari:1549',
);
const _tawafRules = GuideSource(
  id: 'tawaf-rules',
  title: 'Tawaf and its route',
  subtitle: 'Egypt’s Dar Al-Ifta, fatwa 8258',
  url: 'https://dar-alifta.org/ar/fatwa/details/20651/بيان-واجبات-الطواف',
);
const _tawafPurity = GuideSource(
  id: 'tawaf-purity',
  title: 'Purity during tawaf',
  subtitle: 'Egypt’s Dar Al-Ifta research',
  url:
      'https://www.dar-alifta.org/ar/FatwaResearch/details/185/انتقاض-الوضوء-أثناء-الطواف',
);
const _tawafPrayer = GuideSource(
  id: 'tawaf-prayer',
  title: 'Two rak‘ahs after tawaf',
  subtitle: 'Islamweb, fatwa 121305',
  url:
      'https://www.islamweb.net/en/fatwa/121305/ruling-of-two-rakahs-after-tawaaf',
);
const _jabir = GuideSource(
  id: 'muslim-1218',
  title: 'Jabir’s account of the pilgrimage',
  subtitle: 'Sahih Muslim 1218a',
  url: 'https://sunnah.com/muslim:1218a',
);
const _haramainGuide = GuideSource(
  id: 'haramain-guide',
  title: 'Pilgrimage guidance',
  subtitle: 'Presidency of Religious Affairs at the Two Holy Mosques',
  url: 'https://risala.prh.gov.sa/en/contents/114',
);
const _sacredHouse = GuideSource(
  id: 'quran-5-97',
  title: 'The Kaaba, the sacred House',
  subtitle: 'Quran 5:97',
  url: 'https://quran.com/5/97',
);
const _maqam = GuideSource(
  id: 'quran-2-125',
  title: 'The station of Ibrahim',
  subtitle: 'Quran 2:125',
  url: 'https://quran.com/2/125',
);
const _hijr = GuideSource(
  id: 'abudawud-2028',
  title: 'The Hijr and the House',
  subtitle: 'Sunan Abi Dawud 2028',
  url: 'https://sunnah.com/abudawud:2028',
);
const _buildingKaaba = GuideSource(
  id: 'bukhari-3364',
  title: 'Zamzam and the building of the Kaaba',
  subtitle: 'Sahih al-Bukhari 3364',
  url: 'https://sunnah.com/bukhari:3364',
);
const _blackStone = GuideSource(
  id: 'bukhari-1613',
  title: 'Gesturing toward the Black Stone',
  subtitle: 'Sahih al-Bukhari 1613',
  url: 'https://sunnah.com/bukhari:1613',
);
const _corners = GuideSource(
  id: 'abudawud-1892',
  title: 'The dua between the corners',
  subtitle: 'Sunan Abi Dawud 1892',
  url: 'https://sunnah.com/abudawud:1892',
);
const _safaMarwah = GuideSource(
  id: 'quran-2-158',
  title: 'Safa and Marwah',
  subtitle: 'Quran 2:158',
  url: 'https://quran.com/2/158',
);
const _haramSanctity = GuideSource(
  id: 'bukhari-1834',
  title: 'Makkah’s sacred precinct',
  subtitle: 'Sahih al-Bukhari 1834',
  url: 'https://sunnah.com/bukhari:1834',
);
const _haircutLocation = GuideSource(
  id: 'haircut-location',
  title: 'The haircut within the Haram',
  subtitle: 'Yusuf Shabbir, Islamic Portal, Hanafi answer',
  url: 'https://islamicportal.co.uk/does-hair-have-to-be-shaved-in-haram/',
);
const _shoulderWrap = GuideSource(
  id: 'abudawud-1883',
  title: 'The upper wrap during tawaf',
  subtitle: 'Sunan Abi Dawud 1883',
  url: 'https://sunnah.com/abudawud:1883',
);
const _womenFace = GuideSource(
  id: 'women-face',
  title: 'Face covering in ihram',
  subtitle: 'Jordan Iftaa Department, fatwa 1259',
  url: 'https://aliftaa.jo/QuestionPrintEn.aspx?QuestionId=1259',
);
const _hajjDuty = GuideSource(
  id: 'quran-3-97',
  title: 'Hajj and the ability to undertake it',
  subtitle: 'Quran 3:97',
  url: 'https://quran.com/3/97',
);
const _madinah = GuideSource(
  id: 'nusuk-madinah',
  title: 'Madinah and the Prophet’s Mosque',
  subtitle: 'Nusuk',
  url: 'https://umrah.nusuk.sa/MakkahAndMadinah',
);
const _madinahVisit = GuideSource(
  id: 'madinah-visit',
  title: 'Visiting Madinah and pilgrimage',
  subtitle: 'Presidency of Religious Affairs, visiting guide, p. 12',
  url: 'https://risala.prh.gov.sa/storage/contents/250/en400.pdf',
);
