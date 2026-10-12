import 'package:flutter/material.dart';

import '../../domain/entities/quran_surah.dart';
import 'quran_browse_tile.dart';

class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.surah, required this.onTap});

  final QuranSurah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => QuranBrowseTile(
    number: surah.number,
    title: surah.englishName,
    arabicTitle: surah.arabicName,
    details: [surah.revelationType, '${surah.ayahCount} ayahs'],
    onTap: onTap,
  );
}
