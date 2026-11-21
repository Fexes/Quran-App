import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_page_app_bar.dart';
import '../../domain/learning_guide.dart';
import '../widgets/guide_widgets.dart';
import '../widgets/glossary_text.dart';
import 'guide_reader_page.dart';

class GuideOverviewPage extends StatelessWidget {
  const GuideOverviewPage({super.key, required this.guide});

  final LearningGuide guide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppPageAppBar(title: Text('${guide.title} guide')),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlossaryText(
                      guide.description,
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${guide.chapters.length} chapters · English · Offline',
                      style: textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                      ),
                    ),
                  ],
                ),
              ),
              for (final (index, chapter) in guide.chapters.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChapterTile(
                    chapter: chapter,
                    index: index,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => GuideReaderPage(
                          guide: guide,
                          initialChapter: index,
                        ),
                      ),
                    ),
                  ),
                ),
              if (guide.questions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                  child: Text('Common questions', style: textTheme.titleLarge),
                ),
                for (final question in guide.questions)
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                    title: Text(question.title, style: textTheme.titleSmall),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GlossaryText(
                          question.body,
                          style: textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 18),
              GuideSourcesButton(sources: guide.sources),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.index,
    required this.onTap,
  });

  final GuideChapter chapter;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          'Chapter ${index + 1}. ${chapter.title}. ${chapter.readMinutes} minute read.',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: QuranTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    chapter.image,
                    width: 82,
                    height: 123,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: textTheme.labelSmall?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(chapter.title, style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${chapter.readMinutes} min read',
                        style: textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
