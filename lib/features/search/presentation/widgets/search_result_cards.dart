part of '../pages/offline_search_page.dart';

class _PassageTile extends StatefulWidget {
  const _PassageTile({
    required this.passage,
    this.query = '',
    this.openSource = true,
  });
  final OfflineSearchPassage passage;
  final String query;
  final bool openSource;

  @override
  State<_PassageTile> createState() => _PassageTileState();
}

class _PassageTileState extends State<_PassageTile> {
  int _translationIndex = 0;
  String? _locale;
  bool _expanded = false;
  final _excerpts = <String, String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _selectPreferredTranslation(locale);
    }
  }

  @override
  void didUpdateWidget(covariant _PassageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passage != widget.passage ||
        oldWidget.query != widget.query) {
      _selectPreferredTranslation(_locale ?? 'en');
      _excerpts.clear();
      _expanded = false;
    }
  }

  void _selectPreferredTranslation(String locale) {
    final passage = widget.passage;
    final translations = passage.translations;
    final matchedLanguage = passage.language.toLowerCase();
    final matchedEdition = translations.indexWhere(
      (item) =>
          item.language.toLowerCase() == matchedLanguage &&
          passage.sourceLabel.isNotEmpty &&
          item.source == passage.sourceLabel,
    );
    final matched = translations.indexWhere(
      (item) => item.language.toLowerCase() == matchedLanguage,
    );
    final preferred = translations.indexWhere(
      (item) => item.language.split(RegExp('[-_]')).first == locale,
    );
    final english = translations.indexWhere((item) => item.language == 'en');
    _translationIndex = matchedEdition >= 0
        ? matchedEdition
        : matched >= 0
        ? matched
        : preferred >= 0
        ? preferred
        : english >= 0
        ? english
        : 0;
  }

  String _text(String value) => widget.passage.isUserContent
      ? value
      : SearchTextNormalizer.cleanVisibleText(value);

  String _excerpt(String text) => !widget.openSource || _expanded
      ? text
      : _excerpts.putIfAbsent(
          text,
          () => searchResultExcerpt(text, widget.query),
        );

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final translation = passage.translations.isEmpty
        ? null
        : passage.translations[_translationIndex];
    final body = _text(passage.body);
    final translationText = translation == null ? '' : _text(translation.text);
    final showBody =
        body.isNotEmpty &&
        body != _text(passage.arabic) &&
        body != translationText;
    final canExpand =
        passage.arabic.length > 240 ||
        (showBody && body.length > 420) ||
        translationText.length > 420;
    final dailyAyah =
        passage.sourceLabel == 'Daily ayah widget' ||
        passage.metadata['cardType'] == 'dailyAyah';
    final hadithIdParts = passage.canonicalId.split(':');
    final grading = passage.kind == 'hadith'
        ? HadithGrading.fromGrades(
            grades: passage.grades.map(
              (grade) => {'grader': grade.grader, 'grade': grade.grade},
            ),
            bookId:
                passage.metadata['bookId'] ??
                (hadithIdParts.first == 'hadith' && hadithIdParts.length >= 3
                    ? hadithIdParts[1]
                    : hadithIdParts.first == 'hadeethenc'
                    ? 'hadeethenc'
                    : ''),
            sourceId: passage.metadata['sourceId'] ?? passage.sourceLabel,
            reference: passage.reference,
            sourceUrl: passage.metadata['sourceUrl'] ?? '',
          )
        : null;
    return PremiumSurface(
      onTap: widget.openSource ? () => _openPassage(context, passage) : null,
      padding: EdgeInsets.zero,
      borderColor: dailyAyah ? primary.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResultIcon(
                  icon: dailyAyah
                      ? Icons.wb_sunny_outlined
                      : _kindIcon(passage.kind),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyAyah
                            ? 'TODAY’S AYAH'
                            : _kindLabel(passage.kind).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        passage.reference.isEmpty
                            ? passage.title
                            : passage.reference,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (passage.title.isNotEmpty &&
                          passage.reference.isNotEmpty &&
                          passage.title != passage.reference) ...[
                        const SizedBox(height: 3),
                        Text(
                          passage.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: QuranTheme.subText(context),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.openSource) ...[
                  const SizedBox(width: 8),
                  AppIcon(
                    Icons.north_east_rounded,
                    size: 17,
                    color: QuranTheme.subText(context),
                  ),
                ],
              ],
            ),
          ),
          if (grading != null &&
              (!widget.openSource || grading.requiresCaution))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: HadithGradingPanel(
                grading: grading,
                compact: widget.openSource,
              ),
            ),
          if (passage.arabic.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: QuranTheme.softFill(context),
              child: Text(
                passage.arabic,
                maxLines: !widget.openSource || _expanded ? null : 3,
                overflow: !widget.openSource || _expanded
                    ? null
                    : TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1.8,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBody)
                  QuranTranslationText(
                    text: _excerpt(body),
                    languageCode: passage.language,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                if (translation != null) ...[
                  if (showBody) const SizedBox(height: 12),
                  QuranTranslationText(
                    text: _excerpt(translationText),
                    languageCode: translation.language,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIcon(
                        Icons.translate_rounded,
                        size: 14,
                        color: QuranTheme.subText(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          [
                            _languageLabel(translation.language),
                            if (passage.kind != 'hadith' &&
                                translation.source.isNotEmpty)
                              _sourceDisplayLabel(translation.source),
                          ].join(' · '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: QuranTheme.subText(context),
                            height: 1.4,
                          ),
                        ),
                      ),
                      // A result card keeps the edition selected by retrieval,
                      // so its excerpt and reader destination agree. Other
                      // translations remain selectable in full source detail.
                      if (!widget.openSource && passage.translations.length > 1)
                        PopupMenuButton<int>(
                          tooltip: 'Change translation',
                          initialValue: _translationIndex,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(maxWidth: 300),
                          onSelected: (value) =>
                              setState(() => _translationIndex = value),
                          itemBuilder: (_) => [
                            for (
                              var i = 0;
                              i < passage.translations.length;
                              i++
                            )
                              PopupMenuItem(
                                value: i,
                                child: Text(
                                  _translationLabel(passage.translations, i),
                                ),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10,
                              bottom: 8,
                            ),
                            child: Text(
                              'Change',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else if (passage.kind != 'hadith' &&
                    passage.sourceLabel.isNotEmpty) ...[
                  if (showBody) const SizedBox(height: 10),
                  Text(
                    _sourceDisplayLabel(passage.sourceLabel),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
                ],
                if (widget.openSource) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (canExpand)
                        TextButton(
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 38),
                            alignment: AlignmentDirectional.centerStart,
                          ),
                          child: Text(_expanded ? 'Show less' : 'Read more'),
                        )
                      else if (passage.kind == 'hadith')
                        Text(
                          passage.canonicalId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: QuranTheme.subText(context, 0.5),
                            fontSize: 10,
                          ),
                        ),
                      Text(
                        'Open ${passage.kind == 'surah' ? 'surah' : 'source'}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultIcon extends StatelessWidget {
  const _ResultIcon({required this.icon, this.size = 36});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: QuranTheme.softFill(context),
      borderRadius: BorderRadius.circular(11),
    ),
    alignment: Alignment.center,
    child: AppIcon(
      icon,
      size: size * 0.52,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _PrayerResultCard extends StatelessWidget {
  const _PrayerResultCard({required this.passages});
  final List<OfflineSearchPassage> passages;

  static String _name(OfflineSearchPassage passage) =>
      passage.metadata['prayerName'] ??
      passage.title.replaceFirst('Next prayer • ', '').split(' • ').first;
  static String _time(OfflineSearchPassage passage) =>
      passage.metadata['displayTime'] ?? passage.title.split(' • ').last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final first = passages.first;
    final single = passages.length == 1;
    final next =
        first.metadata['isNext'] == 'true' ||
        first.title.startsWith('Next prayer');
    return PremiumSurface(
      onTap: () => _openPassage(context, first),
      borderColor: primary.withValues(alpha: 0.3),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            color: QuranTheme.softFill(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(Icons.schedule_rounded, size: 17, color: primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        next ? 'NEXT PRAYER' : 'PRAYER TIMES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    AppIcon(Icons.north_east_rounded, size: 17, color: primary),
                  ],
                ),
                if (single) ...[
                  const SizedBox(height: 20),
                  Text(
                    _name(first),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _time(first),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                      color: primary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Text(
                    first.metadata['location'] ?? 'Your prayer schedule',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: QuranTheme.subText(context),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        [
                          if (single && first.metadata['location'] != null)
                            first.metadata['location']!,
                          if (first.metadata['date'] != null)
                            _friendlyDate(context, first.metadata['date']!),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!single)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < passages.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          AppIcon(
                            _prayerIcon(passages[i]),
                            size: 20,
                            color: primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _name(passages[i]),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _time(passages[i]),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < passages.length - 1)
                      Divider(height: 1, color: QuranTheme.outline(context)),
                  ],
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(
                  Icons.tune_rounded,
                  size: 15,
                  color: QuranTheme.subText(context),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    [
                      if ((first.metadata['timeZone'] ?? '').isNotEmpty)
                        first.metadata['timeZone']!,
                      first.sourceLabel.isEmpty
                          ? 'Your prayer settings'
                          : first.sourceLabel,
                    ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: QuranTheme.subText(context),
                      height: 1.4,
                    ),
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

IconData _prayerIcon(OfflineSearchPassage passage) =>
    switch (passage.metadata['prayerKey']) {
      'fajr' || 'sunrise' => Icons.wb_twilight_rounded,
      'dhuhr' || 'asr' => Icons.wb_sunny_outlined,
      _ => Icons.nights_stay_outlined,
    };

class _CalendarResultCard extends StatelessWidget {
  const _CalendarResultCard({required this.passage});
  final OfflineSearchPassage passage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(passage.metadata['date'] ?? '');
    final hijriDay = passage.metadata['hijriDay'];
    final hijriMonth =
        passage.metadata['hijriMonthName'] ?? passage.metadata['hijriMonth'];
    final hijriYear = passage.metadata['hijriYear'];
    final hijri = hijriDay != null && hijriMonth != null && hijriYear != null
        ? '$hijriDay $hijriMonth $hijriYear AH'
        : passage.body
              .split('\n')
              .where((line) => line.startsWith('Hijri:'))
              .firstOrNull;
    return PremiumSurface(
      onTap: () => _openPassage(context, passage),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: QuranTheme.softFill(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  date == null
                      ? 'DATE'
                      : const [
                          'JAN',
                          'FEB',
                          'MAR',
                          'APR',
                          'MAY',
                          'JUN',
                          'JUL',
                          'AUG',
                          'SEP',
                          'OCT',
                          'NOV',
                          'DEC',
                        ][date.month - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  date == null ? '–' : '${date.day}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Islamic calendar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (hijri != null)
                  Text(
                    hijri,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _friendlyDate(
                    context,
                    passage.metadata['date'] ?? passage.reference,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Open calendar',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          AppIcon(
            Icons.north_east_rounded,
            size: 17,
            color: QuranTheme.subText(context),
          ),
        ],
      ),
    );
  }
}

String _friendlyDate(BuildContext context, String value) {
  final date = DateTime.tryParse(value);
  return date == null
      ? value
      : MaterialLocalizations.of(context).formatMediumDate(date);
}

class _ToolResultCard extends StatelessWidget {
  const _ToolResultCard({required this.passage});
  final OfflineSearchPassage passage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final widgetEnabled =
        passage.metadata['widgetEnabled'] == 'true' ||
        passage.body.contains('Home widget: enabled');
    final homeWidget =
        passage.metadata['widgetId'] != null ||
        passage.body.contains('Home widget:');
    final body = SearchTextNormalizer.cleanVisibleText(
      passage.body.replaceAll(RegExp(r'Home widget: [^\n]*'), '').trim(),
    );
    final count = int.tryParse(passage.metadata['count'] ?? '');
    final target = int.tryParse(passage.metadata['target'] ?? '');
    return PremiumSurface(
      onTap: () => _openPassage(context, passage),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultIcon(icon: _toolIcon(passage), size: 46),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passage.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(Icons.north_east_rounded, size: 17, color: primary),
            ],
          ),
          if (count != null && target != null && target > 0) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '$count',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ $target',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (count / target).clamp(0, 1),
                minHeight: 5,
              ),
            ),
          ],
          if (homeWidget) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                AppIcon(
                  widgetEnabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.widgets_outlined,
                  size: 15,
                  color: primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widgetEnabled
                        ? 'On your home screen'
                        : 'Available as a home widget',
                    style: theme.textTheme.labelSmall?.copyWith(color: primary),
                  ),
                ),
                Text(
                  'Open',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

IconData _toolIcon(OfflineSearchPassage passage) {
  final id = passage.metadata['featureId'] ?? passage.canonicalId;
  if (id.contains('calendar')) return Icons.calendar_month_outlined;
  if (id.contains('qibla')) return Icons.explore_outlined;
  if (id.contains('tasbieh') || id.contains('tasbih')) {
    return Icons.radio_button_checked_rounded;
  }
  if (id.contains('download')) return Icons.download_for_offline_outlined;
  if (id.contains('translation') || id.contains('language')) {
    return Icons.translate_rounded;
  }
  if (id.contains('note')) return Icons.edit_note_rounded;
  if (id.contains('bookmark')) return Icons.bookmarks_outlined;
  if (id.contains('hifz')) return Icons.psychology_outlined;
  if (id.contains('goal')) return Icons.track_changes_rounded;
  if (id.contains('fast') || id.contains('ramadan')) {
    return Icons.dark_mode_outlined;
  }
  if (id.contains('zakat')) return Icons.calculate_outlined;
  if (id.contains('mosque')) return Icons.mosque_outlined;
  if (id.contains('prayer') || id.contains('journal')) {
    return Icons.schedule_rounded;
  }
  if (id.contains('settings')) return Icons.tune_rounded;
  if (id.contains('quran') || id.contains('ayah')) {
    return Icons.menu_book_rounded;
  }
  if (id.contains('dua')) return Icons.favorite_outline_rounded;
  return Icons.apps_rounded;
}

class _PersonalResultCard extends StatelessWidget {
  const _PersonalResultCard({required this.passage, required this.query});
  final OfflineSearchPassage passage;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final text = searchResultExcerpt(passage.body, query, maxCharacters: 300);
    return PremiumSurface(
      onTap: () => _openPassage(context, passage),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIcon(_kindIcon(passage.kind), size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passage.kind == 'notes' ? 'YOUR NOTE' : 'YOUR CONTENT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              AppIcon(
                Icons.north_east_rounded,
                size: 17,
                color: QuranTheme.subText(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            passage.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            QuranTranslationText(
              text: text,
              languageCode: passage.language,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (passage.reference.isNotEmpty)
                Expanded(
                  child: Text(
                    passage.reference,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
                )
              else
                const Spacer(),
              Text(
                passage.kind == 'notes' ? 'Open note' : 'View',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              AppIcon(Icons.arrow_forward_rounded, size: 15, color: primary),
            ],
          ),
        ],
      ),
    );
  }
}
