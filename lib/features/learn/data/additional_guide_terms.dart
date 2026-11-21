import '../domain/guide_term.dart';
import '../domain/learning_guide.dart';

const additionalGuideTerms = <GuideTerm>[
  GuideTerm(
    id: 'janabah',
    title: 'Janabah',
    aliases: ['janabah', 'janaba', 'junub'],
    definition:
        'A state of major ritual impurity associated with intercourse or sexual discharge. It requires ghusl before prayer; it does not mean a person is physically dirty.',
    sources: [_purity, _ghusl],
  ),
  GuideTerm(
    id: 'nifas',
    title: 'Nifas',
    aliases: ['nifas', 'nifaas'],
    definition:
        'Bleeding associated with childbirth. It has particular rules for prayer, fasting, and purification; the limits and unusual cases differ by school.',
    sources: [_ghusl],
  ),
  GuideTerm(
    id: 'madhi',
    title: 'Madhi',
    aliases: ['madhi', 'madhy'],
    definition:
        'The thin fluid associated with sexual arousal before ejaculation. It has different purification rules from semen: wash the affected area and renew wudu, rather than treating it alone as a reason for ghusl.',
    sources: [_madhi],
  ),
  GuideTerm(
    id: 'pillar',
    title: 'Pillar',
    aliases: ['pillar', 'pillars', 'rukn', 'arkan'],
    definition:
        'Here, an essential component of an act of worship. In prayer, a missed pillar must be supplied or correctly repaired; two corrective prostrations alone do not replace it.',
    sources: [_missedPillar],
  ),
  GuideTerm(
    id: 'communal-obligation',
    title: 'Communal obligation',
    aliases: ['communal obligation', 'fard kifayah', 'fard al-kifayah'],
    definition:
        'A duty fulfilled on behalf of the community when enough qualified people perform it. Funeral prayer is an example; it need not be performed separately by every individual.',
    sources: [_funeralMethod],
  ),
  GuideTerm(
    id: 'zenith',
    title: 'Midday zenith',
    aliases: ['midday zenith', 'zenith'],
    definition:
        'In these prayer instructions, local solar noon: the sun’s highest daily position. Dhuhr begins after the sun has passed that point; it is not necessarily 12:00 on a clock.',
    sources: [_prayerTimes],
  ),
  GuideTerm(
    id: 'sujud-sahw',
    title: 'Sujud al-sahw',
    aliases: [
      'sujud al-sahw',
      'sujud al sahw',
      'sujud as-sahw',
      'sajdah al-sahw',
      'sajdah sahw',
      'sajdah-e-sahw',
      'prostrations of forgetfulness',
      'corrective prostrations',
    ],
    definition:
        'Two prostrations made to address certain mistakes or forgetfulness in prayer. They do not repair every kind of omission.',
    details: [
      GuideGuidance(
        'Identify what happened',
        'An omitted essential act may need to be completed, while another omission may call for these prostrations. Doubt about the number of prayer units has its own rules.',
      ),
      GuideGuidance(
        'Follow one method',
        'Recognized schools differ about the causes and whether the prostrations come before or after salam. The Prayer mistakes guide labels its worked method rather than treating one timing as universal.',
      ),
    ],
    sources: [_forgetfulness, _hanafiCorrection, _shafiiCorrection],
  ),
  GuideTerm(
    id: 'masbuq',
    title: 'Masbuq',
    aliases: ['masbuq', 'masbooq'],
    definition:
        'Someone who joins a congregational prayer after missing one or more prayer units. They follow the imam, then complete the units still owed.',
    sources: [_lateJoining],
  ),
  GuideTerm(
    id: 'qasr',
    title: 'Qasr',
    aliases: ['qasr'],
    definition:
        'Shortening an eligible four-unit obligatory prayer to two units during a qualifying journey. It is different from combining prayer times.',
    details: [
      GuideGuidance(
        'Which prayers change',
        'The shortening concerns the four required units of Dhuhr, Asr, and Isha. Fajr remains two and Maghrib remains three.',
      ),
      GuideGuidance(
        'Eligibility matters',
        'The journey, planned stay, and whether you follow a resident imam affect the ruling. Schools differ about these conditions; use the labeled examples in Travel & illness.',
      ),
    ],
    sources: [_travel, _travelRules],
  ),
  GuideTerm(
    id: 'jam',
    title: 'Jam‘',
    aliases: ['jam‘', 'jam’', "jam'", 'combining prayers'],
    definition:
        'Combining Dhuhr with Asr, or Maghrib with Isha, under permitted conditions. Combining changes when prayers are offered; shortening changes their length.',
    details: [
      GuideGuidance(
        'The permitted pairs',
        'Fajr is not combined with another prayer. An early combination uses the first prayer’s time; a delayed combination uses the second prayer’s time.',
      ),
      GuideGuidance(
        'School differences',
        'The schools differ about when a true combination is allowed. In ordinary Hanafi travel, prayers are kept within their own times, with specific Hajj exceptions. Travel & illness explains this distinction.',
      ),
    ],
    sources: [_combining, _combiningRules],
  ),
  GuideTerm(
    id: 'adhan',
    title: 'Adhan',
    aliases: ['adhan', 'adhaan', 'azan'],
    definition:
        'The call announcing the prayer. It is distinct from the iqamah, which announces that the congregational prayer is about to begin.',
    sources: [_prayerCall],
  ),
  GuideTerm(
    id: 'iqamah',
    title: 'Iqamah',
    aliases: ['iqamah', 'iqama', 'iqaamah'],
    definition:
        'The call immediately before the congregation begins its obligatory prayer. If you arrive then, approach calmly rather than running.',
    sources: [_lateJoining],
  ),
  GuideTerm(
    id: 'khutbah',
    title: 'Khutbah',
    aliases: ['khutbah', 'khutba', 'khutbas'],
    definition:
        'A religious sermon. For Jumu‘ah it comes before the prayer; for Eid it follows the prayer. Listen attentively during the Friday sermon.',
    sources: [_sermon, _eidSermon],
  ),
  GuideTerm(
    id: 'ramadan',
    title: 'Ramadan',
    aliases: ['Ramadan', 'Ramadhan'],
    definition:
        'The Islamic lunar month of obligatory fasting for those who meet its conditions. Its beginning and end follow the accepted local moon-sighting or calendar authority.',
    sources: [_fasting, _moon],
  ),
  GuideTerm(
    id: 'sawm',
    title: 'Sawm',
    aliases: ['sawm', 'siyam'],
    definition:
        'Fasting as worship: with intention, abstaining from food, drink, and other things that invalidate the fast from true dawn until sunset.',
    sources: [_fasting, _fastingHours],
  ),
  GuideTerm(
    id: 'suhoor',
    title: 'Suhoor',
    aliases: ['suhoor', 'suhur', 'sehri'],
    definition:
        'The meal eaten before true dawn in preparation for a fast. Eating must finish when the fasting time begins, rather than at sunrise.',
    sources: [_fastingHours, _predawnMeal],
  ),
  GuideTerm(
    id: 'iftar',
    title: 'Iftar',
    aliases: ['iftar', 'iftaar'],
    definition:
        'Breaking the fast after sunset. The term can refer to the first food or drink and to the meal that follows.',
    sources: [_fastingHours, _sunset],
  ),
  GuideTerm(
    id: 'qada',
    title: 'Qada',
    aliases: ['qada', 'qadha', 'qada’', 'qada‘', "qada'"],
    definition:
        'Making up an act of worship that is owed after its original time, such as a missed Ramadan fast. The method depends on the act and why it was missed.',
    sources: [_fasting],
  ),
  GuideTerm(
    id: 'fidyah',
    title: 'Fidyah',
    aliases: ['fidyah', 'fidya'],
    definition:
        'A prescribed compensation in particular circumstances. For fasting, it commonly involves feeding someone in need when a person is permanently unable to fast.',
    details: [
      GuideGuidance(
        'It has defined circumstances',
        'A temporary illness or a journey ordinarily leads to making up the fast later. Fidyah is not a payment that anyone can choose instead of fasting.',
      ),
      GuideGuidance(
        'The amount and reason matter',
        'Use current local scholarly guidance for the required food amount or permitted monetary equivalent. Pregnancy, nursing, and delayed make-up days involve school-specific details. Pilgrimage fidyah has a separate context.',
      ),
    ],
    sources: [_fasting, _pilgrimage],
  ),
  GuideTerm(
    id: 'kaffarah',
    title: 'Kaffarah',
    aliases: ['kaffarah', 'kaffara'],
    definition:
        'A prescribed expiation for certain violations. It is distinct from simply making up a missed fast and from fidyah for inability.',
    details: [
      GuideGuidance(
        'A specific ruling',
        'Deliberate intercourse during a Ramadan fast is an established example. Schools differ about other violations that also require kaffarah.',
      ),
      GuideGuidance(
        'It is not a fee to choose',
        'The form, sequence, and ability conditions must be established for the actual case. Use qualified guidance before deciding that a donation settles the matter.',
      ),
    ],
    sources: [_expiation],
  ),
  GuideTerm(
    id: 'zakat',
    title: 'Zakat',
    aliases: ['zakat', 'zakah'],
    definition:
        'The obligatory giving due on specified wealth when its conditions are met. It goes to eligible recipients and is distinct from general voluntary charity.',
    details: [
      GuideGuidance(
        'Work out the liability',
        'Identify the assets covered, the relevant minimum threshold, and any required lunar-year period. Savings, trade stock, crops, and livestock do not all share one calculation.',
      ),
      GuideGuidance(
        'Pay with the right intention',
        'Intend to discharge zakat and choose eligible recipients or a trusted agent. The Zakat guide gives a simple savings example and identifies cases needing a fuller calculation.',
      ),
    ],
    sources: [_zakatRules, _recipients],
  ),
  GuideTerm(
    id: 'nisab',
    title: 'Nisab',
    aliases: ['nisab', 'nisaab'],
    definition:
        'The minimum threshold of relevant wealth used to determine zakat liability. The threshold depends on the asset and the valuation method used.',
    details: [
      GuideGuidance(
        'A threshold, not the amount to donate',
        'For savings, the threshold is compared with eligible wealth. Once zakat is due, the calculation is not limited to only the amount above that threshold.',
      ),
      GuideGuidance(
        'Use one supported method',
        'Gold and silver benchmarks and their application to cash differ between authorities. The Zakat guide labels its convention. Use the corresponding current local value rather than a saved currency amount.',
      ),
    ],
    sources: [_zakatRules],
  ),
  GuideTerm(
    id: 'hawl',
    title: 'Hawl',
    aliases: ['hawl'],
    definition:
        'A complete Islamic lunar year used in the zakat rules for wealth such as savings. It is not a condition for every type of zakat, including crops.',
    sources: [_zakatRules, _harvest],
  ),
  GuideTerm(
    id: 'sadaqah',
    title: 'Sadaqah',
    aliases: ['sadaqah', 'sadaqa'],
    definition:
        'Charitable giving. In everyday use it often means voluntary charity; zakat is a particular obligatory form of giving with its own conditions.',
    sources: [_charityDifference],
  ),
  GuideTerm(
    id: 'zakat-fitr',
    title: 'Zakat al-fitr',
    aliases: [
      'zakat al-fitr',
      'zakat ul-fitr',
      'zakat al fitr',
      'sadaqat al-fitr',
      'fitrana',
    ],
    definition:
        'The prescribed giving associated with the end of Ramadan, distinct from annual zakat on wealth. Arrange it before the Eid prayer, using the method recognized by your school.',
    sources: [_fitr],
  ),
  GuideTerm(
    id: 'eid',
    title: 'Eid',
    aliases: [
      'Eid',
      'Eid al-Fitr',
      'Eid ul-Fitr',
      'Eid al-Adha',
      'Eid ul-Adha',
    ],
    definition:
        'An Islamic festival. Eid al-Fitr follows Ramadan; Eid al-Adha is on the tenth of Dhul-Hijjah. The festival prayer has two prayer units and additional takbirs.',
    sources: [_eidSermon, _eidPrayer],
  ),
  GuideTerm(
    id: 'janazah',
    title: 'Janazah',
    aliases: ['janazah', 'janaza', 'salat al-janazah'],
    definition:
        'The funeral and, in this guide, the prayer for a deceased Muslim. The funeral prayer is offered standing, with takbirs and supplication, without bowing or prostration.',
    details: [
      GuideGuidance(
        'The prayer’s purpose',
        'Worship is directed to Allah while asking Him to forgive and have mercy on the deceased. The prayer is distinct from washing, shrouding, carrying, and burying the body.',
      ),
      GuideGuidance(
        'Follow the taught method',
        'The Janazah guide gives a labeled adult example. Schools differ in some recitations and the closing salam, and the supplications for a child require separate guidance.',
      ),
    ],
    sources: [_funeral],
  ),
  GuideTerm(
    id: 'tamattu',
    title: 'Tamattu‘',
    aliases: ['Tamattu‘', 'Tamattu’', "Tamattu'", 'Tamattu'],
    definition:
        'A form of pilgrimage in which Umrah is completed during the Hajj months, ihram is left, and a new ihram is entered for Hajj in the same year.',
    details: [
      GuideGuidance(
        'Two entries into ihram',
        'Complete Umrah first, including the haircut. Later enter ihram specifically for Hajj. The Hajj guide follows this form, rather than the continuous ihram of Qiran.',
      ),
      GuideGuidance(
        'The offering',
        'For those to whom the requirement applies, Tamattu‘ includes a sacrificial offering. If it cannot be afforded, the Quran gives a fasting alternative with defined conditions.',
      ),
    ],
    sources: [_pilgrimage, _hajjModes],
  ),
  GuideTerm(
    id: 'qiran',
    title: 'Qiran',
    aliases: ['qiran'],
    definition:
        'A form of pilgrimage joining Hajj and Umrah in one continuous state of ihram. Its sequence differs from Tamattu‘, and an offering applies to those subject to it.',
    sources: [_hajjModes],
  ),
  GuideTerm(
    id: 'ifrad',
    title: 'Ifrad',
    aliases: ['ifrad'],
    definition:
        'Entering ihram for Hajj alone. The Tamattu‘ offering is not required merely for choosing Ifrad, though other reasons for an offering may arise.',
    sources: [_hajjModes],
  ),
  GuideTerm(
    id: 'mina',
    title: 'Mina',
    aliases: ['Mina'],
    definition:
        'The valley near Makkah associated with the pilgrims’ tent camps and the Jamarat. Its stays and stoning belong to Hajj.',
    sources: [_hajjSequence],
  ),
  GuideTerm(
    id: 'hady',
    title: 'Hady',
    aliases: ['hady', 'hadi'],
    definition:
        'A sacrificial offering associated with pilgrimage. It is distinct from the stoning rite and from an ordinary charitable donation.',
    sources: [_pilgrimage],
  ),
  GuideTerm(
    id: 'rami',
    title: 'Rami',
    aliases: ['rami'],
    definition:
        'The Hajj rite of throwing pebbles at the designated Jamarat. The number of sites, timing, and sequence depend on the day.',
    sources: [_hajjSequence],
  ),
  GuideTerm(
    id: 'tawaf-ifadah',
    title: 'Tawaf al-ifadah',
    aliases: ['Tawaf al-ifadah', 'Tawaf al ifadah', 'Tawaf al-ziyarah'],
    definition:
        'The essential Hajj tawaf performed after the standing at Arafat. It is distinct from the farewell tawaf and cannot simply be omitted.',
    sources: [_hajjSequence],
  ),
  GuideTerm(
    id: 'tawaf-wada',
    title: 'Tawaf al-wada‘',
    aliases: [
      'Tawaf al-wada‘',
      'Tawaf al-wada’',
      "Tawaf al-wada'",
      'Tawaf al-wada',
      'farewell tawaf',
    ],
    definition:
        'The farewell tawaf associated with leaving Makkah after Hajj. Exemptions apply in defined circumstances, including menstruation.',
    sources: [_farewell],
  ),
  GuideTerm(
    id: 'tashriq',
    title: 'Days of Tashriq',
    aliases: ['Days of Tashriq', 'Tashriq', 'Tashreeq', 'Ayyam al-Tashriq'],
    definition:
        'The eleventh, twelfth, and thirteenth days of Dhul-Hijjah, following Eid al-Adha. The Hajj guide explains the Mina stays and stoning during these days.',
    sources: [_hajjSequence, _rememberDays],
  ),
  GuideTerm(
    id: 'dhul-hijjah',
    title: 'Dhul-Hijjah',
    aliases: ['Dhul-Hijjah', 'Dhu al-Hijjah', 'Dhul Hijjah', 'Dhu al Hijjah'],
    definition:
        'The twelfth month of the Islamic lunar calendar, in which the main Hajj rites and Eid al-Adha take place.',
    sources: [_hajjModes],
  ),
];

const _purity = GuideSource(
  id: 'purity',
  title: 'Purification before worship',
  subtitle: 'Quran 5:6',
  url: 'https://quran.com/5/6',
);
const _ghusl = GuideSource(
  id: 'ghusl',
  title: 'The ritual bath and its causes',
  subtitle: 'Faraz Rabbani, SeekersGuidance, Hanafi answer',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/the-ritual-bath-ghusl-obligatory-recommended-and-disliked-acts/',
);
const _forgetfulness = GuideSource(
  id: 'forgetfulness',
  title: 'Two prostrations for forgetfulness',
  subtitle: 'Sahih al-Bukhari 1224',
  url: 'https://sunnah.com/bukhari:1224',
);
const _lateJoining = GuideSource(
  id: 'late-joining',
  title: 'Joining calmly and completing missed units',
  subtitle: 'Sahih al-Bukhari 636',
  url: 'https://sunnah.com/bukhari:636',
);
const _travel = GuideSource(
  id: 'travel',
  title: 'The concession of shortening prayer',
  subtitle: 'Sahih Muslim 686a',
  url: 'https://sunnah.com/muslim:686a',
);
const _combining = GuideSource(
  id: 'combining',
  title: 'Combining the two pairs of prayers',
  subtitle: 'Sahih Muslim 705a',
  url: 'https://sunnah.com/muslim:705a',
);
const _prayerCall = GuideSource(
  id: 'prayer-call',
  title: 'The call and leading prayer',
  subtitle: 'Sahih al-Bukhari 631',
  url: 'https://sunnah.com/bukhari:631',
);
const _sermon = GuideSource(
  id: 'sermon',
  title: 'Listening to the Friday sermon',
  subtitle: 'Sahih al-Bukhari 934',
  url: 'https://sunnah.com/bukhari:934',
);
const _eidSermon = GuideSource(
  id: 'eid-sermon',
  title: 'Eid prayer before the sermon',
  subtitle: 'Sahih al-Bukhari 956',
  url: 'https://sunnah.com/bukhari:956',
);
const _eidPrayer = GuideSource(
  id: 'eid-prayer',
  title: 'The two units of Eid prayer',
  subtitle: 'Sahih al-Bukhari 989',
  url: 'https://sunnah.com/bukhari:989',
);
const _fasting = GuideSource(
  id: 'fasting',
  title: 'Fasting and permitted exceptions',
  subtitle: 'Quran 2:183–185',
  url: 'https://quran.com/2/183-185',
);
const _fastingHours = GuideSource(
  id: 'fasting-hours',
  title: 'The daily boundaries of fasting',
  subtitle: 'Quran 2:187',
  url: 'https://quran.com/2/187',
);
const _moon = GuideSource(
  id: 'moon',
  title: 'Beginning and ending Ramadan',
  subtitle: 'Sahih al-Bukhari 1909',
  url: 'https://sunnah.com/bukhari:1909',
);
const _predawnMeal = GuideSource(
  id: 'predawn-meal',
  title: 'The pre-dawn meal',
  subtitle: 'Sahih al-Bukhari 1923',
  url: 'https://sunnah.com/bukhari:1923',
);
const _sunset = GuideSource(
  id: 'sunset',
  title: 'Breaking the fast after sunset',
  subtitle: 'Sahih al-Bukhari 1954',
  url: 'https://sunnah.com/bukhari:1954',
);
const _expiation = GuideSource(
  id: 'expiation',
  title: 'Expiation for intercourse during the fast',
  subtitle: 'Sahih al-Bukhari 1936',
  url: 'https://sunnah.com/bukhari:1936',
);
const _zakatRules = GuideSource(
  id: 'zakat-rules',
  title: 'Zakat, its threshold and lunar year',
  subtitle: 'Egypt’s Dar Al-Ifta, fatwa 4585',
  url:
      'https://www.dar-alifta.org/en/fatwa/details/4585/paying-zakat-on-wealth-in-monthly-installments',
);
const _recipients = GuideSource(
  id: 'recipients',
  title: 'The categories of zakat recipients',
  subtitle: 'Quran 9:60',
  url: 'https://quran.com/9/60',
);
const _harvest = GuideSource(
  id: 'harvest',
  title: 'The due at harvest',
  subtitle: 'Quran 6:141',
  url: 'https://quran.com/6/141',
);
const _fitr = GuideSource(
  id: 'fitr',
  title: 'Zakat al-fitr before the Eid prayer',
  subtitle: 'Sahih al-Bukhari 1503',
  url: 'https://sunnah.com/bukhari:1503',
);
const _funeral = GuideSource(
  id: 'funeral',
  title: 'The funeral prayer and four takbirs',
  subtitle: 'Sahih al-Bukhari 1333',
  url: 'https://sunnah.com/bukhari:1333',
);
const _pilgrimage = GuideSource(
  id: 'pilgrimage',
  title: 'Pilgrimage and offerings',
  subtitle: 'Quran 2:196',
  url: 'https://quran.com/2/196',
);
const _hajjModes = GuideSource(
  id: 'hajj-modes',
  title: 'The forms and rites of Hajj',
  subtitle: 'Official Nusuk Hajj guidance',
  url: 'https://hajj.nusuk.sa/nusuk/hajj-rituals',
);
const _hajjSequence = GuideSource(
  id: 'hajj-sequence',
  title: 'Jabir’s account of the pilgrimage',
  subtitle: 'Sahih Muslim 1218a',
  url: 'https://sunnah.com/muslim:1218a',
);
const _farewell = GuideSource(
  id: 'farewell',
  title: 'The final visit to the House',
  subtitle: 'Sahih al-Bukhari 1755',
  url: 'https://sunnah.com/bukhari:1755',
);
const _rememberDays = GuideSource(
  id: 'remember-days',
  title: 'Remembering Allah on the appointed days',
  subtitle: 'Quran 2:203',
  url: 'https://quran.com/2/203',
);
const _madhi = GuideSource(
  id: 'madhi',
  title: 'Cleaning and wudu after madhi',
  subtitle: 'Sahih al-Bukhari 269',
  url: 'https://sunnah.com/bukhari:269',
);
const _missedPillar = GuideSource(
  id: 'missed-pillar',
  title: 'Correcting a missed obligatory action',
  subtitle: 'Ustadha Sulma Badrudduja, Hanafi worked examples',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/forgetting-to-perform-an-obgligatory-action-of-the-prayer/',
);
const _funeralMethod = GuideSource(
  id: 'funeral-method',
  title: 'The funeral prayer and its obligation',
  subtitle: 'Jordan Iftaa Department, fatwa 3619',
  url: 'https://www.aliftaa.jo/QuestionPrintEn.aspx?QuestionId=3619',
);
const _prayerTimes = GuideSource(
  id: 'prayer-times',
  title: 'The beginning of the midday prayer',
  subtitle: 'Sahih Muslim 612d',
  url: 'https://sunnah.com/muslim:612d',
);
const _hanafiCorrection = GuideSource(
  id: 'hanafi-correction',
  title: 'The Hanafi forgetfulness prostration',
  subtitle: 'Shaykh Faraz Rabbani, SeekersGuidance',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/how-to-perform-the-forgetfulness-prostration/',
);
const _shafiiCorrection = GuideSource(
  id: 'shafii-correction',
  title: 'The Shafi‘i forgetfulness prostration',
  subtitle: 'Dr. Nidal Sultan, Jordan Iftaa, article 5953',
  url: 'https://www.aliftaa.jo/article-en/5953/Article.aspx?ArticleId=6011',
);
const _travelRules = GuideSource(
  id: 'travel-rules',
  title: 'Travel prayer counts and conditions',
  subtitle: 'Shaykh Faraz A. Khan, Hanafi guidance',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/the-basic-rulings-of-travel/',
);
const _combiningRules = GuideSource(
  id: 'combining-rules',
  title: 'Hanafi prayer times during travel',
  subtitle: 'Shaykh Faraz Rabbani, SeekersGuidance',
  url:
      'https://seekersguidance.org/answers/hanafi-fiqh/do-i-shorten-prayers-during-frequent-work-travel/',
);
const _charityDifference = GuideSource(
  id: 'charity-difference',
  title: 'Sadaqah and zakat',
  subtitle: 'Egypt’s Dar Al-Ifta, fatwa 7741',
  url:
      'https://www.dar-alifta.org/en/fatwa/details/7741/what-is-the-difference-between-sadaqah-and-zakat',
);
