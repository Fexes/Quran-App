import 'learning_guide.dart';

class GuideTerm {
  const GuideTerm({
    required this.id,
    required this.title,
    required this.aliases,
    required this.definition,
    this.details = const [],
    this.sources = const [],
  });

  final String id;
  final String title;
  final List<String> aliases;
  final String definition;
  final List<GuideGuidance> details;
  final List<GuideSource> sources;

  bool get hasDetails => details.isNotEmpty;
}
