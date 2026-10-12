enum HomeTile {
  tasbieh,
  qibla,
  bookmarks,
  fasting,
  prayerJournal,
  duas,
  divineNames,
  hifz,
  notes,
  mosques,
  islamicCalendar,
  todayReadingGoal,
  dailyAyah;

  static const defaults = [
    tasbieh,
    qibla,
    bookmarks,
    notes,
    todayReadingGoal,
    dailyAyah,
  ];

  static List<HomeTile> fromIds(List<String>? ids) {
    if (ids == null) return List.of(defaults);
    final byName = {for (final tile in values) tile.name: tile};
    // Preserve the full goal tile's position when retiring the old shortcut.
    final normalizedIds = ids.contains('todayReadingGoal')
        ? ids.where((id) => id != 'readingGoal')
        : ids.map((id) => id == 'readingGoal' ? 'todayReadingGoal' : id);
    return [
      for (final id in normalizedIds.toSet())
        if (byName[id] != null) byName[id]!,
    ];
  }
}
