import '../domain/learning_guide.dart';
import 'congregation_content.dart';
import 'eid_content.dart';
import 'fasting_content.dart';
import 'ghusl_content.dart';
import 'hajj_content.dart';
import 'janazah_content.dart';
import 'jumuah_content.dart';
import 'prayer_content.dart';
import 'prayer_mistakes_content.dart';
import 'tayammum_content.dart';
import 'travel_illness_content.dart';
import 'umrah_content.dart';
import 'wudu_content.dart';
import 'zakat_content.dart';

class LearningGuideSection {
  const LearningGuideSection({required this.title, required this.guides});

  final String title;
  final List<LearningGuide> guides;
}

const learningGuideSections = [
  LearningGuideSection(
    title: 'Purification',
    guides: [wuduGuide, ghuslGuide, tayammumGuide],
  ),
  LearningGuideSection(
    title: 'Prayer',
    guides: [
      prayerGuide,
      congregationGuide,
      prayerMistakesGuide,
      travelIllnessGuide,
      jumuahGuide,
      eidGuide,
      janazahGuide,
    ],
  ),
  LearningGuideSection(
    title: 'Fasting & giving',
    guides: [fastingGuide, zakatGuide],
  ),
  LearningGuideSection(title: 'Pilgrimage', guides: [umrahGuide, hajjGuide]),
];

Iterable<LearningGuide> get allLearningGuides =>
    learningGuideSections.expand((section) => section.guides);
