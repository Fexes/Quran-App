import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/learning_guide.dart';
import 'glossary_text.dart';

export 'guide_sources.dart';

class GuideIllustration extends StatelessWidget {
  const GuideIllustration({
    super.key,
    required this.chapter,
    this.showTitle = true,
    this.onTap,
    this.label,
  });

  final GuideChapter chapter;
  final bool showTitle;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            chapter.image,
            fit: showTitle ? BoxFit.cover : BoxFit.contain,
            alignment: showTitle ? const Alignment(0, -0.25) : Alignment.center,
            semanticLabel: chapter.imageDescription,
          ),
          if (showTitle)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 0.65, 1],
                  colors: [
                    Colors.transparent,
                    Color(0x3320252E),
                    Color(0xE620252E),
                  ],
                ),
              ),
            ),
          if (showTitle)
            Positioned(
              top: 18,
              right: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9111418),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_stories_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      if (label != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          label!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (showTitle)
            Positioned(
              left: 22,
              right: 22,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${chapter.readMinutes} min read',
                    style: const TextStyle(
                      color: Color(0xFFE1E2E4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Read ${chapter.title}, ${chapter.readMinutes} minutes',
      onTap: onTap,
      excludeSemantics: true,
      child: content,
    );
  }
}

class GuideGuidanceCard extends StatelessWidget {
  const GuideGuidanceCard({super.key, required this.guidance, this.number});

  final GuideGuidance guidance;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final numberDiameter = (MediaQuery.textScalerOf(context).scale(13) + 16)
        .clamp(30.0, double.infinity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (number != null) ...[
            Container(
              width: numberDiameter,
              height: numberDiameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: QuranTheme.surfaceVariant(context),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlossaryText(
                  guidance.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                GlossaryText(
                  guidance.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.82),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
