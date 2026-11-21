import '../../../../core/search/search_text_normalizer.dart';
import '../entities/hadith_item.dart';
import 'hadith_grading.dart';

class HadithAuthenticityPolicy {
  const HadithAuthenticityPolicy._();

  static bool shouldShow(HadithItem hadith) {
    return hadith.arabic.trim().isNotEmpty ||
        hadith.translation.trim().isNotEmpty;
  }

  static bool hasNarrationChain(HadithItem hadith) {
    final arabic = hadith.arabic;
    if (_arabicChainMarkers.any(arabic.contains)) {
      return true;
    }

    final translation = SearchTextNormalizer.normalize(hadith.translation);
    return _englishChainMarkers.any(translation.contains);
  }

  static bool hasAcceptedAuthenticity(HadithItem hadith) {
    return HadithGrading.fromHadith(hadith).isSuitableForDaily;
  }

  static const _arabicChainMarkers = [
    'حَدَّثَنَا',
    'حَدَّثَنَا',
    'حدثنا',
    'حَدَّثَنِي',
    'حَدَّثَنِي',
    'حدثني',
    'أَخْبَرَنَا',
    'أَخْبَرَنِي',
    'اخبرنا',
    'اخبرني',
    'عَنْ',
    'عَنِ',
    'عن ',
  ];

  static const _englishChainMarkers = [
    'narrated',
    'reported',
    'authority of',
    'transmitted',
  ];
}
