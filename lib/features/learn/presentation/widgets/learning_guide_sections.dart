import 'package:flutter/material.dart';

import '../../data/learning_guide_catalog.dart';
import '../pages/guide_overview_page.dart';
import 'learning_guide_grid.dart';

class LearningGuideSectionView extends StatelessWidget {
  const LearningGuideSectionView({super.key, required this.index});

  static int get sectionCount => learningGuideSections.length;
  final int index;

  @override
  Widget build(BuildContext context) {
    final section = learningGuideSections[index];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
              child: _SectionHeading(
                title: section.title,
                count: section.guides.length,
              ),
            ),
            LearningGuideGrid(
              guides: section.guides,
              sectionIndex: index,
              onGuideTap: (guide) => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => GuideOverviewPage(guide: guide),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
    final guideCount = Text(
      '$count guides',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(20) > 25) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [heading, const SizedBox(height: 4), guideCount],
      );
    }
    return Row(
      children: [
        Expanded(child: heading),
        const SizedBox(width: 12),
        guideCount,
      ],
    );
  }
}
