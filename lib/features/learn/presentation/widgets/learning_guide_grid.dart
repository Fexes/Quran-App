import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../domain/learning_guide.dart';

class LearningGuideGrid extends StatelessWidget {
  const LearningGuideGrid({
    super.key,
    required this.guides,
    required this.onGuideTap,
    this.sectionIndex = 0,
  });

  final List<LearningGuide> guides;
  final ValueChanged<LearningGuide> onGuideTap;
  final int sectionIndex;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = MediaQuery.textScalerOf(context).scale(20) / 20;
        final compactWidth = (width - _gap) * 5 / 11;
        final stackCards =
            width < 320 ||
            scale > 1.25 ||
            !_titlesFit(context, compactWidth - 28);

        Widget tile(
          int index, {
          double? height,
          bool featured = false,
          bool compact = false,
        }) {
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: Semantics(
              sortKey: OrdinalSortKey(index.toDouble()),
              child: _GuideMosaicTile(
                guide: guides[index],
                height: height,
                featured: featured,
                compact: compact,
                compactTitleSize: compact
                    ? _compactTitleSize(
                        context,
                        guides[index].title,
                        compactWidth - 28,
                      )
                    : null,
                onTap: () => onGuideTap(guides[index]),
              ),
            ),
          );
        }

        if (stackCards) {
          return FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < guides.length; index++) ...[
                  if (index > 0) const SizedBox(height: _gap),
                  tile(index, featured: true),
                ],
              ],
            ),
          );
        }

        final unit = (width * 0.51).clamp(174.0, 198.0) + (scale - 1) * 70;
        final bands = <Widget>[];
        var cursor = 0;
        if (guides.length >= 3) {
          if (width >= 680) {
            final height = (width * 0.36).clamp(280.0, 350.0);
            bands.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: tile(0, height: height, featured: true),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(flex: 4, child: tile(1, height: height)),
                  const SizedBox(width: _gap),
                  Expanded(flex: 4, child: tile(2, height: height)),
                ],
              ),
            );
          } else {
            bands.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: tile(0, height: unit * 2 + _gap, featured: true),
                  ),
                  const SizedBox(width: _gap),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tile(1, height: unit, compact: true),
                        const SizedBox(height: _gap),
                        tile(2, height: unit, compact: true),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          cursor = 3;
        }

        while (cursor < guides.length) {
          if (bands.isNotEmpty) bands.add(const SizedBox(height: _gap));
          final first = cursor;
          if (first + 1 == guides.length) {
            bands.add(tile(first, height: unit + 58, featured: true));
            cursor++;
            continue;
          }
          final pairOnly = guides.length == 2;
          final reverseWidths = (sectionIndex + first) % 2 == 1;
          final height = unit + (pairOnly ? 74 : 34);
          bands.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: reverseWidths ? 5 : 6,
                  child: tile(first, height: height, featured: pairOnly),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  flex: reverseWidths ? 6 : 5,
                  child: tile(first + 1, height: height),
                ),
              ],
            ),
          );
          cursor += 2;
        }
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: bands,
          ),
        );
      },
    );
  }

  double _compactTitleSize(BuildContext context, String title, double width) {
    var widestWord = 0.0;
    for (final word in title.split(' ')) {
      final painter = TextPainter(
        text: TextSpan(
          text: word,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (painter.width > widestWord) widestWord = painter.width;
      painter.dispose();
    }
    return widestWord > width ? (20 * width / widestWord).clamp(16, 20) : 20;
  }

  bool _titlesFit(BuildContext context, double width) {
    final theme = Theme.of(context);
    for (final guide in guides) {
      final painter = TextPainter(
        text: TextSpan(
          text: guide.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 3,
      )..layout(maxWidth: width);
      final fits = !painter.didExceedMaxLines;
      painter.dispose();
      if (!fits) return false;
    }
    return true;
  }
}

class _GuideMosaicTile extends StatelessWidget {
  const _GuideMosaicTile({
    required this.guide,
    required this.onTap,
    required this.height,
    required this.featured,
    required this.compact,
    this.compactTitleSize,
  });
  final LearningGuide guide;
  final VoidCallback onTap;
  final double? height;
  final bool featured;
  final bool compact;
  final double? compactTitleSize;

  @override
  Widget build(BuildContext context) {
    final naturalHeight = height == null;
    final padding = compact ? 14.0 : 18.0;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontSize: featured ? 28 : (compact ? compactTitleSize ?? 20 : 23),
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    );
    final content = Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (naturalHeight) const SizedBox(height: 112),
          Text(guide.title, style: titleStyle),
          if (featured && !compact) ...[
            const SizedBox(height: 8),
            Text(
              guide.description,
              maxLines: naturalHeight ? null : 3,
              overflow: naturalHeight ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE6E7E8),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${guide.chapters.length} chapters',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFD8DBDF),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label:
          '${guide.title}. ${guide.description} ${guide.chapters.length} chapters.',
      onTap: onTap,
      excludeSemantics: true,
      child: Container(
        height: height,
        constraints: naturalHeight
            ? const BoxConstraints(minHeight: 260)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D20252E),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Positioned.fill(child: _GuideCover(guide: guide)),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.05, 0.38, 0.72, 1],
                      colors: [
                        Color(0x0520252E),
                        Color(0x0A20252E),
                        Color(0x9920252E),
                        Color(0xF020252E),
                      ],
                    ),
                  ),
                ),
              ),
              content,
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCover extends StatelessWidget {
  const _GuideCover({required this.guide});
  final LearningGuide guide;

  @override
  Widget build(BuildContext context) {
    final preservePose = switch (guide.id) {
      'prayer' || 'prayer-mistakes' || 'travel-illness' => true,
      _ => false,
    };
    return ColoredBox(
      color: const Color(0xFFE5DED2),
      child: Image.asset(
        guide.coverImage,
        fit: preservePose ? BoxFit.contain : BoxFit.cover,
        alignment: preservePose
            ? Alignment.topCenter
            : const Alignment(0, -0.3),
        excludeFromSemantics: true,
      ),
    );
  }
}
