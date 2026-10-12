import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/premium_surface.dart';

class QuranBrowseTile extends StatelessWidget {
  const QuranBrowseTile({
    super.key,
    required this.number,
    required this.title,
    required this.details,
    required this.onTap,
    this.arabicTitle,
  });

  final int number;
  final String title;
  final String? arabicTitle;
  final List<String> details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      label: ['$number. $title', ?arabicTitle, ...details].join(', '),
      child: PremiumSurface(
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: Colors.transparent,
        shadowStyle: PremiumSurfaceShadowStyle.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: QuranTheme.surfaceVariant(
                    context,
                  ).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  number.toString().padLeft(2, '0'),
                  textScaler: TextScaler.noScaling,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: QuranTheme.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 2,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      if (arabicTitle != null)
                        Text(
                          arabicTitle!,
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 23,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0,
                            color: QuranTheme.text(context),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: QuranTheme.outline(context),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          details.join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.6,
                            letterSpacing: 0,
                            color: QuranTheme.subText(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ExcludeSemantics(
                        child: AppIcon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: QuranTheme.subText(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
