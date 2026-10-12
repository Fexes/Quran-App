import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/home_tile.dart';

class HomeTileImage extends StatelessWidget {
  const HomeTileImage({super.key, required this.tile, this.width, this.height})
    : assert(tile != HomeTile.dailyAyah);

  final HomeTile tile;
  final double? width;
  final double? height;

  static String assetFor(HomeTile tile) => switch (tile) {
    HomeTile.tasbieh => 'assets/images/companions/tasbieh.jpg',
    HomeTile.duas => 'assets/images/companions/duas.jpg',
    HomeTile.divineNames => 'assets/images/companions/divine-names.jpg',
    HomeTile.qibla => 'assets/images/companions/qibla.jpg',
    HomeTile.fasting => 'assets/images/companions/fasting.jpg',
    HomeTile.prayerJournal => 'assets/images/companions/journal.jpg',
    HomeTile.notes => 'assets/images/companions/notes.jpg',
    HomeTile.islamicCalendar => 'assets/images/companions/calendar.jpg',
    HomeTile.mosques => 'assets/images/companions/mosques.jpg',
    HomeTile.bookmarks => 'assets/images/companions/bookmarks.jpg',
    HomeTile.todayReadingGoal =>
      'assets/images/companions/today-reading-goal.jpg',
    HomeTile.hifz => 'assets/images/companions/memorization.jpg',
    HomeTile.dailyAyah => throw ArgumentError('Verse of the Day has no image'),
  };

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Ink(
          decoration: BoxDecoration(
            color: QuranTheme.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              opacity: 0.86,
              image: ResizeImage(AssetImage(assetFor(tile)), width: 600),
              fit: BoxFit.cover,
              alignment: tile == HomeTile.islamicCalendar
                  ? Alignment.center
                  : const Alignment(0, 0.4),
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
