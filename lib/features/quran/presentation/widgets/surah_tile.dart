import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../domain/entities/quran_surah.dart';

class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.surah, required this.onTap});

  final QuranSurah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context, primary),
              borderRadius: BorderRadius.circular(QuranTheme.radiusControl),
            ),
            child: Text(
              surah.number.toString(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah.englishName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${surah.revelationType} • ${surah.ayahCount} ayahs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            surah.arabicName,
            textDirection: TextDirection.rtl,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
