import 'package:flutter/material.dart';

enum HomeWidgetKind {
  prayer(
    'prayer',
    Icons.mosque_outlined,
    'Next Prayer',
    'الصلاة التالية',
    'اگلی نماز',
  ),
  reading(
    'reading',
    Icons.menu_book_outlined,
    'Continue Reading',
    'متابعة القراءة',
    'مطالعہ جاری رکھیں',
  ),
  ayah(
    'ayah',
    Icons.auto_stories_outlined,
    'Ayah of the Day',
    'آية اليوم',
    'آج کی آیت',
  ),
  azkar(
    'azkar',
    Icons.wb_twilight_outlined,
    'Morning & Evening Azkar',
    'أذكار الصباح والمساء',
    'صبح و شام کے اذکار',
  ),
  fasting('fasting', Icons.nightlight_outlined, 'Fasting', 'الصيام', 'روزہ'),
  hifz(
    'hifz',
    Icons.school_outlined,
    'Hifz Review',
    'مراجعة الحفظ',
    'حفظ کی دہرائی',
  ),
  goal(
    'goal',
    Icons.track_changes_outlined,
    'Daily Reading Goal',
    'هدف القراءة اليومي',
    'روزانہ مطالعے کا ہدف',
  );

  const HomeWidgetKind(this.id, this.icon, this.en, this.ar, this.ur);

  final String id;
  final IconData icon;
  final String en;
  final String ar;
  final String ur;

  String label(String language) => widgetText(language, en, ar, ur);

  List<HomeWidgetSize> get sizes => switch (this) {
    prayer => const [HomeWidgetSize.small, HomeWidgetSize.medium],
    ayah || fasting => const [HomeWidgetSize.medium],
    _ => const [HomeWidgetSize.small],
  };
}

enum HomeWidgetSize { small, medium }

String widgetText(String language, String en, String ar, String ur) =>
    switch (language) {
      'ar' => ar,
      'ur' => ur,
      _ => en,
    };

class HomeWidgetContent {
  const HomeWidgetContent({
    required this.label,
    required this.heading,
    required this.path,
    this.detail = '',
    this.footer = '',
    this.arabic = '',
    this.footerPath,
    this.prayerPhase,
    this.progress,
  });

  final String label;
  final String heading;
  final String path;
  final String detail;
  final String footer;
  final String arabic;
  final String? footerPath;
  final String? prayerPhase;
  final double? progress;

  Map<String, Object?> toJson() => {
    'label': label,
    'heading': heading,
    'path': path,
    if (detail.isNotEmpty) 'detail': detail,
    if (footer.isNotEmpty) 'footer': footer,
    if (arabic.isNotEmpty) 'arabic': arabic,
    if (footerPath != null) 'footerPath': footerPath,
    if (prayerPhase != null) 'prayerPhase': prayerPhase,
    if (progress != null) 'progress': progress,
  };
}

class HomeWidgetEntry {
  const HomeWidgetEntry(this.start, this.content);

  final DateTime start;
  final HomeWidgetContent content;

  Map<String, Object?> toJson() => {
    'start': start.millisecondsSinceEpoch,
    ...content.toJson(),
  };
}

class HomeWidgetSnapshot {
  const HomeWidgetSnapshot(this.language, this.dark, this.timelines);

  final String language;
  final bool dark;
  final Map<HomeWidgetKind, List<HomeWidgetEntry>> timelines;

  HomeWidgetContent contentAt(HomeWidgetKind kind, DateTime now) =>
      timelines[kind]!
          .lastWhere(
            (entry) => !entry.start.isAfter(now),
            orElse: () => timelines[kind]!.first,
          )
          .content;

  Map<String, Object> toJson() => {
    'language': language,
    'dark': dark,
    'widgets': {
      for (final entry in timelines.entries)
        entry.key.id: [for (final item in entry.value) item.toJson()],
    },
  };
}
