import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';
import 'premium_surface.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? Theme.of(context).colorScheme.primary;
    final sub = QuranTheme.subText(context);

    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 108),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: QuranTheme.softFill(context, effectiveAccent),
                borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
              ),
              child: Icon(icon, color: effectiveAccent, size: 21),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: sub, height: 1.22),
            ),
          ],
        ),
      ),
    );
  }
}
