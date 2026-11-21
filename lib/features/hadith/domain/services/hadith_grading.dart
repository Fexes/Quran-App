import '../entities/hadith_item.dart';

enum HadithGradeKind { sahih, hasan, weak, fabricated, critical, unknown }

enum HadithGradingStatus {
  sahih,
  hasan,
  weak,
  fabricated,
  differing,
  scoped,
  critical,
  unverified,
  collection,
}

class HadithGradeAssessment {
  const HadithGradeAssessment({
    required this.grader,
    required this.grade,
    required this.kind,
    required this.scoped,
  });

  final String grader;
  final String grade;
  final HadithGradeKind kind;
  final bool scoped;

  String get attributedText => grader.isEmpty ? grade : '$grader: $grade';
}

/// Summarizes recorded assessments, without independently authenticating a report.
/// Unknown wording and chain-only judgments never establish a whole-report grade.
class HadithGrading {
  const HadithGrading._({
    required this.assessments,
    required this.status,
    required this.bookId,
    required this.sourceId,
    required this.reference,
    required this.sourceUrl,
  });

  factory HadithGrading.fromHadith(HadithItem item) => HadithGrading.fromGrades(
    grades: item.grades,
    fallbackGrade: item.grade,
    bookId: item.bookSlug.isEmpty ? item.bookId : item.bookSlug,
    sourceId: item.sourceId,
    reference: item.cleanReference.isEmpty
        ? item.reference
        : item.cleanReference,
  );

  factory HadithGrading.fromGrades({
    required Iterable<Object?> grades,
    String fallbackGrade = '',
    String bookId = '',
    String sourceId = '',
    String reference = '',
    String sourceUrl = '',
  }) {
    final assessments = <HadithGradeAssessment>[];
    for (final entry in grades) {
      final grader = entry is Map
          ? (entry['grader'] ?? entry['name'] ?? '').toString().trim()
          : '';
      final text = entry is Map
          ? (entry['grade'] ?? '').toString().trim()
          : entry?.toString().trim() ?? '';
      _append(assessments, text, grader);
    }
    if (assessments.isEmpty) _append(assessments, fallbackGrade, '');
    return HadithGrading._(
      assessments: List.unmodifiable(assessments),
      status: _status(assessments, bookId, sourceId),
      bookId: bookId,
      sourceId: sourceId,
      reference: reference,
      sourceUrl: _sourceUrl(
        bookId,
        sourceId,
        sourceUrl.isEmpty ? reference : sourceUrl,
      ),
    );
  }

  final List<HadithGradeAssessment> assessments;
  final HadithGradingStatus status;
  final String bookId;
  final String sourceId;
  final String reference;
  final Uri? sourceUrl;

  // Imported data contains no independently reviewed, primary-source verdicts.
  bool get independentlyVerified => false;

  bool get requiresCaution => switch (status) {
    HadithGradingStatus.sahih ||
    HadithGradingStatus.hasan ||
    HadithGradingStatus.collection => false,
    _ => true,
  };

  bool get isSuitableForDaily => !requiresCaution;

  String get summaryLabel => labelFor('en');

  String labelFor(String code) {
    final labels = switch (code) {
      'ur' => const [
        'درج شدہ حکم: صحیح',
        'درج شدہ حکم: حسن',
        'درج شدہ حکم: ضعیف',
        'درج شدہ حکم: موضوع',
        'احکام میں اختلاف',
        'سند یا مخصوص روایت کا حکم',
        'قابلِ توجہ حکم',
        'انفرادی درجے کی تصدیق نہیں',
        'صحیح مجموعے میں شامل',
      ],
      'ar' => const [
        'الحكم المنقول: صحيح',
        'الحكم المنقول: حسن',
        'الحكم المنقول: ضعيف',
        'الحكم المنقول: موضوع',
        'أحكام مختلفة',
        'حكم على الإسناد أو رواية مقيّدة',
        'حكم يحتاج إلى انتباه',
        'درجة الحديث غير متحقّق منها',
        'ضمن مجموعة صحيحة',
      ],
      _ => const [
        'Sahih reported',
        'Hasan / accepted grades reported',
        'Reported weak (Da‘if)',
        'Reported fabricated (Mawdu‘)',
        'Grades differ',
        'Chain / report assessment',
        'Critical assessment reported',
        'Individual grade not verified',
        'Sahih collection',
      ],
    };
    return labels[status.index];
  }

  String explanationFor(String code) {
    final explanations = switch (code) {
      'ur' => const [
        'ذیل میں درج ماخذ کے مطابق یہ روایت صحیح ہے۔ اصل ماخذ سے آزادانہ تصدیق ابھی باقی ہے۔',
        'ذیل میں درج ماخذ کے مطابق یہ روایت حسن یا صحیح ہے۔ اصل ماخذ سے آزادانہ تصدیق ابھی باقی ہے۔',
        'تمام واضح، منسوب اور پوری روایت سے متعلق درج شدہ احکام اسے ضعیف کہتے ہیں۔ یہ نقل شدہ احکام ہیں، آزادانہ تصدیق ابھی باقی ہے۔',
        'ذیل کے درج شدہ احکام اس روایت کو موضوع کہتے ہیں۔ اصل ماخذ سے آزادانہ تصدیق ابھی باقی ہے۔',
        'درج شدہ احکام مختلف ہیں۔ ہر عالم کا اصل حکم الگ دیکھیں۔',
        'یہ حکم سند، موقوف، مقطوع یا مخصوص روایت سے متعلق ہے؛ اسے پوری مرفوع روایت کا حتمی حکم نہ سمجھیں۔',
        'اصل حکم ذیل میں محفوظ ہے۔ اسے خودکار طور پر صحیح، ضعیف یا موضوع قرار نہیں دیا گیا۔',
        'انفرادی حکم دستیاب نہیں یا اس کی عبارت یا نسبت واضح نہیں۔ اس سے ضعف ثابت نہیں ہوتا۔',
        'یہ صحیح بخاری یا صحیح مسلم میں شامل ہے۔ اس ریکارڈ میں الگ انفرادی حکم فراہم نہیں کیا گیا۔',
      ],
      'ar' => const [
        'تصحّح الأحكام المنقولة أدناه هذه الرواية. التحقّق المستقل من المصدر الأصلي لم يكتمل.',
        'تحسّن الأحكام المنقولة أدناه هذه الرواية أو تصحّحها. التحقّق المستقل من المصدر الأصلي لم يكتمل.',
        'الأحكام المنقولة الواضحة والمنسوبة على الرواية كاملة تضعّفها. التحقّق المستقل من المصدر الأصلي لم يكتمل.',
        'الأحكام المنقولة أدناه تصف هذه الرواية بالوضع. التحقّق المستقل من المصدر الأصلي لم يكتمل.',
        'تختلف الأحكام المنقولة. راجع حكم كل محدّث بلفظه.',
        'الحكم يخصّ إسنادًا أو أثرًا موقوفًا أو مقطوعًا أو رواية مقيّدة، ولا يُعمّم على الحديث المرفوع كاملًا.',
        'حُفظ الحكم الأصلي أدناه دون تحويله آليًا إلى صحيح أو ضعيف أو موضوع.',
        'الحكم الفردي غير متاح أو لفظه أو نسبته غير واضحين. هذا لا يثبت ضعف الحديث.',
        'هذا الحديث ضمن صحيح البخاري أو صحيح مسلم. لا يتضمن هذا السجل حكمًا فرديًا منفصلًا.',
      ],
      _ => const [
        'The recorded assessments below grade this narration Sahih. Independent verification against the original source is pending.',
        'The recorded assessments below grade this narration Hasan or Sahih. Independent verification against the original source is pending.',
        'The clear, attributed, whole-report assessments recorded here grade this narration weak. These are reported judgments; independent source verification is pending.',
        'The recorded assessments below describe this narration as fabricated. Independent verification against the original source is pending.',
        'The recorded assessments differ. Each scholar’s original judgment is preserved below.',
        'These judgments concern a chain, companion report, successor report, or qualified narration. They do not establish a final grade for the whole prophetic narration.',
        'The original assessment is preserved below without automatically converting it to Sahih, weak, or fabricated.',
        'An individual grade is missing, unattributed, or not safely understood. This does not establish that the narration is weak.',
        'Included in Sahih al-Bukhari or Sahih Muslim. This record does not provide a separate individual grading assessment.',
      ],
    };
    return explanations[status.index];
  }

  String get sourceLabel => switch (sourceId) {
    'hadeethenc' => 'HadeethEnc',
    'ummah_library_hadith' => 'Ummah Library / Hadith API',
    'fawaz_hadith_api' => 'Hadith API',
    _ => 'Recorded source assessments',
  };

  String get shareSummary => [
    summaryLabel,
    explanationFor('en'),
    for (final assessment in assessments) assessment.attributedText,
    'Source: $sourceLabel',
    if (sourceUrl != null) sourceUrl.toString(),
  ].join('\n');

  static void _append(
    List<HadithGradeAssessment> output,
    String text,
    String name,
  ) {
    for (final part in text.split(RegExp(r'[;؛]'))) {
      var grade = part.trim();
      if (grade.isEmpty) continue;
      var grader = name;
      final colon = grade.indexOf(':');
      if (grader.isEmpty && colon > 0) {
        grader = grade.substring(0, colon).trim();
        grade = grade.substring(colon + 1).trim();
      }
      if (grade.isEmpty) continue;
      final normalized = _normalize(grade);
      output.add(
        HadithGradeAssessment(
          grader: grader,
          grade: grade,
          kind: _kind(normalized),
          scoped: _scope.hasMatch(normalized),
        ),
      );
    }
  }

  static HadithGradingStatus _status(
    List<HadithGradeAssessment> values,
    String book,
    String source,
  ) {
    if (values.isEmpty) {
      return {'bukhari', 'muslim'}.contains(book) &&
              {'ummah_library_hadith', 'fawaz_hadith_api'}.contains(source)
          ? HadithGradingStatus.collection
          : HadithGradingStatus.unverified;
    }
    final positive = values.any(
      (v) => v.kind == HadithGradeKind.sahih || v.kind == HadithGradeKind.hasan,
    );
    final negative = values.any(
      (v) =>
          v.kind == HadithGradeKind.weak ||
          v.kind == HadithGradeKind.fabricated ||
          v.kind == HadithGradeKind.critical,
    );
    if (positive && negative) return HadithGradingStatus.differing;
    if (!{
      'ummah_library_hadith',
      'fawaz_hadith_api',
      'hadeethenc',
    }.contains(source)) {
      return HadithGradingStatus.unverified;
    }
    if (values.any(
      (v) =>
          v.kind == HadithGradeKind.unknown ||
          (!_knownGraders.contains(_graderKey(v.grader)) &&
              !(source == 'hadeethenc' &&
                  v.grader.isEmpty &&
                  (v.kind == HadithGradeKind.sahih ||
                      v.kind == HadithGradeKind.hasan))),
    )) {
      return HadithGradingStatus.unverified;
    }
    if (values.any((v) => v.scoped)) return HadithGradingStatus.scoped;
    final kinds = values.map((v) => v.kind).toSet();
    if (kinds.every((k) => k == HadithGradeKind.sahih)) {
      return HadithGradingStatus.sahih;
    }
    if (!negative && positive) return HadithGradingStatus.hasan;
    if (kinds.every((k) => k == HadithGradeKind.weak)) {
      return HadithGradingStatus.weak;
    }
    if (kinds.every((k) => k == HadithGradeKind.fabricated)) {
      return HadithGradingStatus.fabricated;
    }
    if (kinds.length > 1) return HadithGradingStatus.differing;
    return HadithGradingStatus.critical;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(
        RegExp(r'[\u0610-\u061a\u064b-\u065f\u0670\u06d6-\u06ed]'),
        '',
      )
      .replaceAll(RegExp('[‘’ʿʾ\u0027ـ]'), '')
      .replaceAll(RegExp(r'[\[\]]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final _scope = RegExp(
    r'\b(isnaad|isnad|sanad|chain|narrators|mauquf|mawquf|muquf|maqtu|mursal|matn)\b|إسناد|اسناد|سند|رجاله|موقوف|مقطوع|متن',
  );

  static String _graderKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  static const _knownGraders = {
    'abughuddah',
    'alalbani',
    'zubairalizai',
    'ahmadmuhammadshakir',
    'basharawadmaarouf',
    'muhammadfouadabdalbaqi',
    'shuaibalarnaut',
    'salimalhilali',
    'muhammadmuhyialdinabdulhamid',
  };

  static HadithGradeKind _kind(String text) {
    final unscoped = text
        .replaceAll(_scope, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (const {
      'daif',
      'daeef',
      'dhaif',
      'zaif',
      'weak',
      'very daif',
      'very weak',
      'daif munkar',
      'munkar daif',
      'ضعيف',
      'ضعيف جدا',
    }.contains(unscoped)) {
      return HadithGradeKind.weak;
    }
    if (const {'mawdu', 'mawdoo', 'fabricated', 'موضوع'}.contains(unscoped)) {
      return HadithGradeKind.fabricated;
    }
    if (const {
      'munkar',
      'shadh',
      'batil',
      'منكر',
      'شاذ',
      'باطل',
    }.contains(unscoped)) {
      return HadithGradeKind.critical;
    }
    if (const {
      'hasan',
      'hasan sahih',
      'hasan lighairihi',
      'حسن',
      'حسن صحيح',
      'حسن لغيره',
    }.contains(unscoped)) {
      return HadithGradeKind.hasan;
    }
    if (const {
      'sahih',
      'sahih hadith',
      'sahih matn',
      'sahih mutawatir',
      'sahih lighairihi',
      'sahih - agreed upon',
      'sahih - bukhari and muslim',
      'sahih agreed upon',
      'صحيح',
      'صحيح لغيره',
      'متفق عليه',
    }.contains(unscoped)) {
      return HadithGradeKind.sahih;
    }
    if (RegExp(
      r'^sahih (?:bukhari|muslim)(?: \([0-9٠-٩۰-۹ ,،after]+\))?(?: sahih (?:bukhari|muslim)(?: \([0-9٠-٩۰-۹ ,،after]+\))?)*$',
    ).hasMatch(unscoped)) {
      return HadithGradeKind.sahih;
    }
    return HadithGradeKind.unknown;
  }

  static Uri? _sourceUrl(String book, String source, String reference) {
    if (source == 'hadeethenc') {
      final link = Uri.tryParse(reference);
      return link?.scheme == 'https' && link?.host == 'hadeethenc.com'
          ? link
          : Uri.parse('https://hadeethenc.com/en/home');
    }
    if (source == 'ummah_library_hadith' || source == 'fawaz_hadith_api') {
      return Uri.parse('https://github.com/fawazahmed0/hadith-api');
    }
    return null;
  }
}
