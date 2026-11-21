class LearningGuide {
  const LearningGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.coverDescription,
    required this.chapters,
    required this.sources,
    this.questions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String coverImage;
  final String coverDescription;
  final List<GuideChapter> chapters;
  final List<GuideSource> sources;
  final List<GuideGuidance> questions;

  int get readMinutes =>
      chapters.fold(0, (total, chapter) => total + chapter.readMinutes);
}

class GuideSource {
  const GuideSource({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String id;
  final String title;
  final String subtitle;
  final String url;
}

class GuideGuidance {
  const GuideGuidance(this.title, this.body);

  final String title;
  final String body;
}

class GuideSupplication {
  const GuideSupplication({
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.context,
    required this.sourceId,
  });

  final String title;
  final String arabic;
  final String transliteration;
  final String meaning;
  final String context;
  final String sourceId;
}

class GuideChapter {
  const GuideChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.imageDescription,
    required this.readMinutes,
    required this.category,
    required this.introduction,
    required this.steps,
    required this.sourceIds,
    this.notes = const [],
    this.supplications = const [],
    this.reminder,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String imageDescription;
  final int readMinutes;
  final String category;
  final String introduction;
  final List<GuideGuidance> steps;
  final List<GuideGuidance> notes;
  final List<GuideSupplication> supplications;
  final List<String> sourceIds;
  final String? reminder;
}
