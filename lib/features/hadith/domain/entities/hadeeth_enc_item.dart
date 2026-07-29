import 'package:equatable/equatable.dart';

import 'hadith_item.dart';

class HadeethEncLanguage extends Equatable {
  const HadeethEncLanguage({required this.code, required this.nativeName});

  factory HadeethEncLanguage.fromJson(Map<dynamic, dynamic> json) {
    return HadeethEncLanguage(
      code: _string(json['code']),
      nativeName: _string(json['native'] ?? json['nativeName']),
    );
  }

  final String code;
  final String nativeName;

  Map<String, Object> toJson() => {'code': code, 'nativeName': nativeName};

  @override
  List<Object> get props => [code, nativeName];
}

class HadeethEncItem extends Equatable {
  const HadeethEncItem({
    required this.id,
    required this.languageCode,
    required this.title,
    required this.titleArabic,
    required this.hadithText,
    required this.hadithTextArabic,
    required this.explanation,
    required this.explanationArabic,
    required this.benefits,
    required this.benefitsArabic,
    required this.grade,
    required this.gradeArabic,
    required this.attribution,
    required this.attributionArabic,
    required this.link,
  });

  factory HadeethEncItem.fromJson(Map<dynamic, dynamic> json) {
    return HadeethEncItem(
      id: _string(json['id']),
      languageCode: _string(json['languageCode'] ?? json['lang']),
      title: _string(json['title']),
      titleArabic: _string(json['titleArabic'] ?? json['title_ar']),
      hadithText: _string(json['hadithText'] ?? json['hadith_text']),
      hadithTextArabic: _string(
        json['hadithTextArabic'] ?? json['hadith_text_ar'],
      ),
      explanation: _string(json['explanation']),
      explanationArabic: _string(
        json['explanationArabic'] ?? json['explanation_ar'],
      ),
      benefits: _stringList(json['benefits']),
      benefitsArabic: _stringList(
        json['benefitsArabic'] ?? json['benefits_ar'],
      ),
      grade: _string(json['grade']),
      gradeArabic: _string(json['gradeArabic'] ?? json['grade_ar']),
      attribution: _string(json['attribution'] ?? json['takhrij']),
      attributionArabic: _string(
        json['attributionArabic'] ?? json['takhrij_ar'],
      ),
      link: _string(json['link']),
    );
  }

  final String id;
  final String languageCode;
  final String title;
  final String titleArabic;
  final String hadithText;
  final String hadithTextArabic;
  final String explanation;
  final String explanationArabic;
  final List<String> benefits;
  final List<String> benefitsArabic;
  final String grade;
  final String gradeArabic;
  final String attribution;
  final String attributionArabic;
  final String link;

  HadithItem toHadithItem() {
    return HadithItem(
      id: 'hadeethenc:$languageCode:$id',
      bookId: 'hadeethenc',
      chapterId: 'hadeethenc',
      hadithNumber: id,
      arabic: hadithTextArabic,
      translation: hadithText,
      grade: grade,
      reference: 'HadeethEnc $id',
      sourceId: 'hadeethenc',
      collectionName: 'HadeethEnc',
      cleanReference: link,
    );
  }

  Map<String, Object> toJson() {
    return {
      'id': id,
      'languageCode': languageCode,
      'title': title,
      'titleArabic': titleArabic,
      'hadithText': hadithText,
      'hadithTextArabic': hadithTextArabic,
      'explanation': explanation,
      'explanationArabic': explanationArabic,
      'benefits': benefits,
      'benefitsArabic': benefitsArabic,
      'grade': grade,
      'gradeArabic': gradeArabic,
      'attribution': attribution,
      'attributionArabic': attributionArabic,
      'link': link,
    };
  }

  @override
  List<Object> get props => [
    id,
    languageCode,
    title,
    titleArabic,
    hadithText,
    hadithTextArabic,
    explanation,
    explanationArabic,
    benefits,
    benefitsArabic,
    grade,
    gradeArabic,
    attribution,
    attributionArabic,
    link,
  ];
}

class HadeethEncImportResult extends Equatable {
  const HadeethEncImportResult({
    required this.languageCode,
    required this.version,
    required this.items,
  });

  final String languageCode;
  final String version;
  final List<HadeethEncItem> items;

  @override
  List<Object> get props => [languageCode, version, items];
}

String _string(Object? value) => value?.toString().trim() ?? '';

List<String> _stringList(Object? value) {
  if (value is List) {
    return [
      for (final item in value)
        if (_string(item).isNotEmpty) _string(item),
    ];
  }
  return _string(value)
      .split(RegExp(r'\\n|\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}
