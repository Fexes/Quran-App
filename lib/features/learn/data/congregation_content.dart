import '../domain/learning_guide.dart';

const congregationGuide = LearningGuide(
  id: 'congregation',
  title: 'Congregational prayer',
  description:
      'Follow the imam, join calmly, and complete the units you missed.',
  coverImage: 'assets/images/learn/congregation_faceless.webp',
  coverDescription: 'Worshippers praying in aligned rows behind an imam.',
  chapters: _congregationChapters,
  sources: _congregationSources,
  questions: [
    GuideGuidance(
      'Do I wait for the next rak‘ah?',
      'No. Join the imam in the posture you find him in after making your opening takbir correctly. A prostration or final sitting alone does not count as a caught rak‘ah, but you still join the congregation.',
    ),
    GuideGuidance(
      'Should I run to catch the bowing?',
      'No. Approach calmly, even if you will miss the unit. Pray what you catch and complete what remains.',
    ),
    GuideGuidance(
      'Is recitation behind the imam the same in every school?',
      'No. Hanafis do not recite Qur’an behind the imam in either quiet or audible prayers. Shafi‘is normally recite al-Fatiha themselves, with a concession for a genuine latecomer. Other personal remembrances remain part of the prayer.',
    ),
  ],
);

const _congregationChapters = <GuideChapter>[
  GuideChapter(
    id: 'congregation-follow',
    title: 'Follow the imam',
    subtitle: 'One congregation, calm movements',
    image: 'assets/images/learn/congregation_faceless.webp',
    imageDescription: 'A congregation arranged in prayer rows.',
    readMinutes: 2,
    category: 'Praying together',
    introduction:
        'Join the appropriate row, face the qibla, and intend the prayer while following the imam. Begin your own prayer with its opening takbir.',
    steps: [
      GuideGuidance(
        'Keep the rows orderly',
        'Stand in line with those beside you and close reasonable gaps without pushing. Allow room for everyone to bow and prostrate comfortably.',
      ),
      GuideGuidance(
        'Follow the movement',
        'Do not bow, prostrate, or rise ahead of the imam. Move after him and settle into each posture. The imam’s voice guides the congregation; it does not replace your own opening takbir or personal remembrances.',
      ),
      GuideGuidance(
        'Recitation: Hanafi practice',
        'Do not recite al-Fatiha or another surah behind the imam, whether the prayer is quiet or audible. Listen when he recites aloud. Say your own movement takbirs, bowing and prostration remembrances, and sitting recitations quietly.',
      ),
      GuideGuidance(
        'Recitation: Shafi‘i practice',
        'Normally recite al-Fatiha yourself in each unit, quietly. Prefer the imam’s pause after al-Fatiha or his later recitation; if that will not leave enough time, recite while he reads al-Fatiha. A genuine latecomer has a specific exception.',
      ),
    ],
    supplications: [
      GuideSupplication(
        title: 'After the imam rises from bowing',
        arabic: 'رَبَّنَا لَكَ الْحَمْدُ',
        transliteration: 'Rabbana lakal-hamd.',
        meaning: 'Our Lord, to You belongs all praise.',
        context:
            'Say this when the imam says “Sami‘allahu liman hamidah.” This short form is established in the hadith.',
        sourceId: 'congregation-follow-hadith',
      ),
    ],
    sourceIds: [
      'congregation-follow-hadith',
      'congregation-hanafi-recitation',
      'congregation-shafii-recitation',
    ],
  ),
  GuideChapter(
    id: 'congregation-join',
    title: 'Join even when you are late',
    subtitle: 'Opening takbir, then the imam’s posture',
    image: 'assets/images/learn/congregation_faceless.webp',
    imageDescription: 'Worshippers following their imam during prayer.',
    readMinutes: 2,
    category: 'Joining late',
    introduction:
        'Walk calmly. Do not wait outside the prayer just because the imam has already bowed or prostrated.',
    steps: [
      GuideGuidance(
        'Start while standing, if able',
        'Face the qibla, intend to join, and complete Allahu akbar while upright. Do not begin that opening takbir only after bending down. Then move to the posture the imam is in.',
      ),
      GuideGuidance(
        'Count a unit caught in bowing',
        'In the Hanafi method here, reaching the bowing posture while the imam is still bowing counts as catching that rak‘ah. If you arrive after the bowing, join him but count that unit as missed.',
      ),
      GuideGuidance(
        'If joining in prostration or sitting',
        'After the opening takbir, join the prostration or sitting. Those actions alone do not count as a complete rak‘ah. Continue following and make up the missing units when the imam finishes.',
      ),
      GuideGuidance(
        'Do not end an incomplete prayer',
        'If units remain, do not give the closing salam with the imam. In Hanafi practice, remain for any sujud al-sahw he performs, then stand to complete your prayer after he has finished.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Shafi‘i latecomer exception',
        'If you join with genuinely too little standing time to recite al-Fatiha, begin it and follow the imam into bowing when he bows. To count the unit, attain stillness in bowing before he leaves it. This exception does not cover deliberately delaying recitation.',
      ),
    ],
    sourceIds: [
      'congregation-calm',
      'congregation-catch',
      'congregation-shafii-detail',
      'congregation-finish',
    ],
    reminder:
        'If you missed every bowing, complete the full number of units after the imam finishes.',
  ),
  GuideChapter(
    id: 'congregation-complete',
    title: 'Complete the missed units',
    subtitle: 'Worked Hanafi examples',
    image: 'assets/images/learn/congregation_complete.webp',
    imageDescription:
        'A latecomer completing missed units while the congregation remains seated.',
    readMinutes: 2,
    category: 'After the imam finishes',
    introduction:
        'These examples are for ordinary obligatory prayers in Hanafi practice. They explain both recitation and where to sit. Other schools treat the order of a latecomer’s units differently.',
    steps: [
      GuideGuidance(
        'Caught one of Fajr’s two units',
        'After the imam finishes, stand for one rak‘ah. Recite al-Fatiha and a surah, complete its bowing and prostrations, then make your final sitting and salam.',
      ),
      GuideGuidance(
        'Caught the last two of a four-unit prayer',
        'Stand and pray two more units. Recite al-Fatiha and a surah in each. After the second, sit for the full final recitations and end with salam.',
      ),
      GuideGuidance(
        'Caught only the last of four',
        'Pray one unit with al-Fatiha and a surah, then sit for tashahhud. Pray another with al-Fatiha and a surah, then one with al-Fatiha alone. Make the final sitting and salam.',
      ),
      GuideGuidance(
        'Caught only Maghrib’s last unit',
        'Pray one unit with al-Fatiha and a surah, then sit for tashahhud. Stand for one more with al-Fatiha and a surah, then make the full final sitting and salam.',
      ),
    ],
    notes: [
      GuideGuidance(
        'Recite without disturbing others',
        'When completing the missed units, you are responsible for their recitation. Keep your voice low enough not to disturb people who are still praying.',
      ),
      GuideGuidance(
        'Friday prayer has additional rules',
        'Do not use these ordinary-prayer examples to decide whether you caught Jumu‘ah. The schools have distinct conditions for catching Friday prayer.',
      ),
    ],
    sourceIds: [
      'congregation-makeup',
      'congregation-calm',
      'congregation-sittings',
    ],
  ),
];

const _congregationSources = <GuideSource>[
  GuideSource(
    id: 'congregation-follow-hadith',
    title: 'Sahih al-Bukhari 722',
    subtitle:
        'Following the imam, straight rows, and the response after bowing',
    url: 'https://sunnah.com/bukhari:722',
  ),
  GuideSource(
    id: 'congregation-calm',
    title: 'Sahih al-Bukhari 636',
    subtitle: 'Approach calmly and complete what you missed',
    url: 'https://sunnah.com/bukhari:636',
  ),
  GuideSource(
    id: 'congregation-hanafi-recitation',
    title: 'A follower’s recitations',
    subtitle: 'Sidi Waseem Hussain · Hanafi practice',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/follower-reciting-behind-the-imam/',
  ),
  GuideSource(
    id: 'congregation-shafii-recitation',
    title: 'Reciting al-Fatiha with the imam',
    subtitle: 'Ustadha Shazia Ahmad · Shafi‘i practice',
    url:
        'https://seekersguidance.org/answers/shafii-fiqh/can-i-recite-the-fatiha-during-the-imams-fatiha-in-the-shafii-school/',
  ),
  GuideSource(
    id: 'congregation-catch',
    title: 'When has a latecomer caught a rak‘ah?',
    subtitle: 'Ustadha Naielah Ackbarali · Hanafi opening and bowing',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/a-latecomers-prayer-when-is-one-considered-to-have-missed-a-cycle-rakat/',
  ),
  GuideSource(
    id: 'congregation-shafii-detail',
    title: 'The follower and al-Fatiha',
    subtitle: 'Shaykh Muhammad Afifi al-Akiti · Shafi‘i latecomer distinctions',
    url:
        'https://seekersguidance.org/answers/shafii-fiqh/follower-reciting-al-fatiha-in-the-shafii-school/',
  ),
  GuideSource(
    id: 'congregation-finish',
    title: 'Following the imam’s corrective prostrations',
    subtitle: 'Ustadh Tabraze Azam · Hanafi latecomer rules',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/latecomer-imam-performing-prostrations-forgetfulness/',
  ),
  GuideSource(
    id: 'congregation-makeup',
    title: 'Latecomer recitation in prayer',
    subtitle: 'Ustadh Tabraze Azam · Hanafi recitation and sitting order',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/latecomer-recitation-in-prayer/',
  ),
  GuideSource(
    id: 'congregation-sittings',
    title: 'A latecomer’s recitation and sitting order',
    subtitle: 'Shaykh Faraz Rabbani · Hanafi worked examples',
    url:
        'https://seekersguidance.org/answers/hanafi-fiqh/the-rulings-related-to-a-latecomer-a-note-on-the-durr-al-mukhtar/',
  ),
];
