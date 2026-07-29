import '../../../../core/search/search_text_normalizer.dart';
import '../entities/hadith_item.dart';

class HadithAuthenticityPolicy {
  const HadithAuthenticityPolicy._();

  static const _trustedUngradedBooks = {'bukhari', 'muslim', 'nawawi', 'qudsi'};

  static bool shouldShow(HadithItem hadith) {
    return hasNarrationChain(hadith) && hasAcceptedAuthenticity(hadith);
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
    final grades = _gradeTexts(hadith).toList(growable: false);
    if (grades.isEmpty) {
      return _trustedUngradedBooks.contains(hadith.bookId) ||
          _trustedUngradedBooks.contains(hadith.bookSlug);
    }

    if (grades.any(_isRejectedGrade)) {
      return false;
    }
    return grades.any(_isAcceptedGrade);
  }

  static Iterable<String> _gradeTexts(HadithItem hadith) sync* {
    for (final grade in hadith.grades) {
      if (grade is Map) {
        final value = grade['grade'];
        if (value != null) {
          yield value.toString();
        }
        continue;
      }
      final value = grade?.toString();
      if (value != null && value.trim().isNotEmpty) {
        yield value;
      }
    }

    if (hadith.grades.isEmpty && hadith.grade.trim().isNotEmpty) {
      yield hadith.grade;
    }
  }

  static bool _isAcceptedGrade(String grade) {
    final normalized = SearchTextNormalizer.normalize(grade);
    return _acceptedGradeMarkers.any(normalized.contains);
  }

  static bool _isRejectedGrade(String grade) {
    final normalized = SearchTextNormalizer.normalize(grade);
    return _rejectedGradeMarkers.any(normalized.contains);
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

  static const _acceptedGradeMarkers = [
    'sahih',
    'hasan',
    'authentic',
    'agreed upon',
  ];

  static const _rejectedGradeMarkers = [
    'daif',
    'daeef',
    'weak',
    'very daif',
    'mawdu',
    'munkar',
    'shadh',
    'batil',
    'fabricated',
    'not authentic',
  ];
}
