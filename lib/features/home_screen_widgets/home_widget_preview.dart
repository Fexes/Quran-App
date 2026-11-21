import 'package:flutter/material.dart';

import 'home_widget_content.dart';

class HomeWidgetPreview extends StatelessWidget {
  const HomeWidgetPreview({
    super.key,
    required this.kind,
    required this.content,
    required this.size,
    required this.dark,
  });

  final HomeWidgetKind kind;
  final HomeWidgetContent content;
  final HomeWidgetSize size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final medium = size == HomeWidgetSize.medium;
    final paper =
        kind == HomeWidgetKind.ayah ||
        kind == HomeWidgetKind.reading ||
        kind == HomeWidgetKind.goal;
    final ink = paper && !dark ? const Color(0xff213831) : Colors.white;
    final secondary = paper && !dark
        ? const Color(0xff43564a)
        : const Color(0xfff2e9dc);
    final labelColor = kind == HomeWidgetKind.ayah ? secondary : Colors.white;
    final hasPrayerTime =
        kind == HomeWidgetKind.prayer && content.detail.isNotEmpty;
    final metric =
        (kind == HomeWidgetKind.hifz || kind == HomeWidgetKind.goal) &&
        RegExp(r'^\d').hasMatch(content.heading);
    final artwork = switch (kind) {
      HomeWidgetKind.prayer => 'prayer_${content.prayerPhase ?? 'dhuhr'}',
      _ when paper && dark => '${kind.id}_dark',
      HomeWidgetKind.fasting when rtl => 'fasting_rtl',
      _ => kind.id,
    };
    final mediumPrayer = medium && kind == HomeWidgetKind.prayer;
    final footer = content.arabic.isNotEmpty ? content.heading : content.footer;

    Text line(
      String text,
      double points,
      Color color, {
      int lines = 1,
      FontWeight weight = FontWeight.normal,
      double height = 1.18,
    }) => Text(
      text,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: points,
        height: height,
        color: color,
        fontWeight: weight,
      ),
    );

    return Container(
      width: medium ? 350 : 166,
      constraints: BoxConstraints(minHeight: medium ? 158 : 166),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: paper && !dark
            ? const Color(0xffe8e2d1)
            : const Color(0xff23372f),
        borderRadius: BorderRadius.circular(19),
        image: DecorationImage(
          image: AssetImage(
            'assets/widgets/drawable-nodpi/widget_$artwork.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(kind.icon, color: labelColor, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: line(
                    content.label,
                    11,
                    labelColor,
                    lines: 2,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: kind == HomeWidgetKind.fasting ? .65 : 1,
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (content.arabic.isNotEmpty)
                    Text(
                      content.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontFamily: 'UthmanicHafs',
                        fontSize: 22,
                        height: 1.45,
                      ),
                    )
                  else
                    line(
                      content.heading,
                      metric
                          ? 30
                          : hasPrayerTime
                          ? 18
                          : 21,
                      ink,
                      lines: 2,
                      weight: FontWeight.w600,
                    ),
                  if (content.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    line(
                      content.detail,
                      hasPrayerTime ? (mediumPrayer ? 32 : 28) : 13,
                      hasPrayerTime ? ink : secondary,
                      lines: content.arabic.isEmpty ? 2 : 1,
                      weight: hasPrayerTime
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ],
                  if (content.progress case final value?) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      color: dark
                          ? const Color(0xffafdcc7)
                          : const Color(0xff357363),
                      backgroundColor: ink.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    if (mediumPrayer)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: line(
                              footer,
                              13,
                              secondary,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      line(footer, 11, secondary, weight: FontWeight.w600),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
