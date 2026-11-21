import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/di/injection.dart';
import '../../app/router/app_routes.dart';
import '../../core/search/local_search_revision.dart';
import '../../core/storage/settings_store.dart';
import '../../core/theme/quran_theme.dart';
import '../../core/theme/quran_theme_state.dart';
import '../hifz/domain/repositories/hifz_repository.dart';
import '../home/domain/entities/daily_ayah.dart';
import '../home/domain/services/daily_ayah_service.dart';
import '../prayer_times/domain/entities/daily_prayer_times.dart';
import '../prayer_times/domain/entities/prayer_banner_phase.dart';
import '../prayer_times/domain/entities/prayer_time_entry.dart';
import '../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../quran/domain/repositories/quran_repository.dart';
import '../quran/domain/repositories/quran_translation_repository.dart';
import '../reading_goals/domain/entities/reading_progress.dart';
import '../reading_goals/domain/repositories/reading_progress_repository.dart';
import 'home_widget_content.dart';

class HomeWidgetSnapshotService {
  static const prayerPath = '/widget-prayer';
  static const _days = 14;
  static const _azkarCategory = 'morning-and-evening';

  final _ayahCache = <(int, int, int), DailyAyah>{};
  String? _translationRevision;

  Future<HomeWidgetSnapshot> load() async {
    final now = DateTime.now();
    final settings = getIt<SettingsStore>();
    final translationRevision = LocalSearchRevision.forSource(
      'quran-translations',
    );
    if (translationRevision != _translationRevision) {
      _ayahCache.clear();
      _translationRevision = translationRevision;
    }
    final requestedLanguage = settings.localeCode == 'system'
        ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
        : settings.localeCode;
    final language = switch (requestedLanguage) {
      'ar' || 'ur' => requestedLanguage,
      _ => 'en',
    };
    await initializeDateFormatting(language);
    final dark =
        QuranTheme.presetById(settings.themePresetId).mode ==
        QuranThemeMode.dark;
    final timelines = {
      for (final kind in HomeWidgetKind.values) kind: <HomeWidgetEntry>[],
    };
    String t(String en, String ar, String ur) =>
        widgetText(language, en, ar, ur);
    void add(HomeWidgetKind kind, DateTime start, HomeWidgetContent content) {
      timelines[kind]!.add(HomeWidgetEntry(start, content));
    }

    const reading = HomeWidgetKind.reading;
    const goal = HomeWidgetKind.goal;
    const hifz = HomeWidgetKind.hifz;
    const ayah = HomeWidgetKind.ayah;
    const azkar = HomeWidgetKind.azkar;
    const fasting = HomeWidgetKind.fasting;
    const prayer = HomeWidgetKind.prayer;

    final quran = getIt<QuranRepository>();
    final prayers = getIt<PrayerTimesRepository>();
    final readingProgress = getIt<ReadingProgressRepository>();
    final translations = getIt<QuranTranslationRepository>();
    final lastRead = await quran.getLastRead();
    final surah = lastRead == null
        ? null
        : await quran.getSurah(lastRead.surahNumber);
    final readerPath = AppRoutes.quranReaderPath(
      lastRead?.surahNumber ?? 1,
      ayahNumber: lastRead?.ayahNumber,
    );
    final readContent = HomeWidgetContent(
      label: reading.label(language),
      heading: surah?.englishName ?? 'Al-Fatihah',
      detail: lastRead == null
          ? t('Start reading', 'ابدأ القراءة', 'مطالعہ شروع کریں')
          : t(
              'Ayah ${lastRead.ayahNumber}',
              'الآية ${lastRead.ayahNumber}',
              'آیت ${lastRead.ayahNumber}',
            ),
      footer: switch (lastRead?.page) {
        final page? => t('Page $page', 'الصفحة $page', 'صفحہ $page'),
        _ => '',
      },
      progress: lastRead == null || surah == null
          ? null
          : (lastRead.ayahNumber / surah.ayahCount).clamp(0.0, 1.0),
      path: readerPath,
    );
    add(reading, now, readContent);

    final memorization = await getIt<HifzRepository>().dashboard(now: now);
    final cards = memorization.cards.values;
    final localEnd = DateTime(now.year, now.month, now.day + _days);
    final futureReviews = [
      for (final card in cards)
        if (!card.isDue(now) && card.dueAt.isBefore(localEnd)) card.dueAt,
    ]..sort();
    const hour = Duration.millisecondsPerHour;
    final reviewTimes = {
      now,
      if (futureReviews.isNotEmpty) futureReviews.first,
      for (final due in futureReviews)
        DateTime.fromMillisecondsSinceEpoch(
          ((due.millisecondsSinceEpoch + hour - 1) ~/ hour) * hour,
        ),
    }.where((instant) => instant.isBefore(localEnd)).toList()..sort();
    for (final instant in reviewTimes) {
      final due = cards.where((card) => card.isDue(instant)).toList();
      final dueKeys = due.map((card) => card.verseKey).toSet();
      final review = memorization.collections
          .where((collection) => collection.verseKeys.any(dueKeys.contains))
          .firstOrNull;
      add(
        hifz,
        instant,
        HomeWidgetContent(
          label: hifz.label(language),
          heading: '${due.length}',
          detail: t('Due for review', 'للمراجعة', 'دہرائی کے لیے'),
          footer: review?.title ?? '',
          path: review == null
              ? AppRoutes.hifz
              : AppRoutes.hifzReviewPath(review.id),
        ),
      );
    }

    final firstPrayerDay = await _prayerDay(prayers, now);
    final zone = switch (firstPrayerDay?.entries.firstOrNull?.time) {
      final tz.TZDateTime day => day.location,
      _ => null,
    };
    final prayerNow = zone == null ? now : tz.TZDateTime.from(now, zone);
    DateTime prayerDate(int offset, [int hour = 0]) => zone == null
        ? DateTime(now.year, now.month, now.day + offset, hour)
        : tz.TZDateTime(
            zone,
            prayerNow.year,
            prayerNow.month,
            prayerNow.day + offset,
            hour,
          );

    final timesByDay = await Future.wait([
      Future.value(firstPrayerDay),
      for (var index = 1; index < _days; index++)
        _prayerDay(prayers, prayerDate(index, 12), reference: firstPrayerDay),
    ]);
    // Keep the numerator and target in reading order on RTL launchers.
    final goalSeparator = language == 'en' ? ' / ' : '\u200e / \u200e';
    final timeFormat = DateFormat.jm(language);
    final missingTimes = t(
      'Open Quran for prayer times',
      'افتح التطبيق لعرض أوقات الصلاة',
      'نماز کے اوقات کے لیے قرآن کھولیں',
    );
    final ayahs = <HomeWidgetEntry>[];
    final goals = <HomeWidgetEntry>[];

    for (var index = 0; index < _days; index++) {
      final start = prayerDate(index);
      final day = timesByDay[index];
      final entries = day?.entries ?? const <PrayerTimeEntry>[];
      final upcoming = [
        ...entries.where((entry) => entry.name != PrayerTimeName.sunrise),
        ?day?.nextDayFajr,
      ];
      final maghrib = entries
          .where((entry) => entry.name == PrayerTimeName.maghrib)
          .firstOrNull;
      final sunset = maghrib?.time.subtract(PrayerBannerPhase.sunsetWindow);
      final transitions = {
        start,
        if (sunset != null &&
            sunset.isAfter(start) &&
            sunset.isBefore(prayerDate(index + 1)))
          sunset,
        for (final entry in entries)
          if (entry.time.isAfter(start) &&
              entry.time.isBefore(prayerDate(index + 1)))
            entry.time,
      }.toList()..sort();
      for (final instant in transitions) {
        final next = upcoming
            .where((entry) => entry.time.isAfter(instant))
            .firstOrNull;
        final name = next == null ? missingTimes : _prayerName(next, language);
        final time = next == null ? '' : timeFormat.format(next.time);
        add(
          prayer,
          instant,
          HomeWidgetContent(
            label: prayer.label(language),
            heading: name,
            detail: time,
            footer: day?.location.name ?? '',
            prayerPhase: PrayerBannerPhase.at(
              entries: entries,
              now: instant,
            ).name,
            path: prayerPath,
          ),
        );
      }

      final fajr = entries
          .where((entry) => entry.name == PrayerTimeName.fajr)
          .firstOrNull;
      add(
        fasting,
        start,
        HomeWidgetContent(
          label: fasting.label(language),
          heading: t('Fasting times', 'أوقات الصيام', 'روزے کے اوقات'),
          detail: fajr == null || maghrib == null
              ? missingTimes
              : '${t('Sehri ends', 'نهاية السحور', 'سحری ختم')} ${timeFormat.format(fajr.time)}\n'
                    '${t('Iftar', 'الإفطار', 'افطار')} ${timeFormat.format(maghrib.time)}',
          footer: t('Fasting journal', 'سجل الصيام', 'روزوں کا ریکارڈ'),
          path: AppRoutes.ramadan,
          footerPath: AppRoutes.fastingJournalPath(date: start),
        ),
      );

      final morning = fajr?.time ?? prayerDate(index, 5);
      final evening = maghrib?.time ?? prayerDate(index, 18);
      HomeWidgetContent remembrance(bool morning) => HomeWidgetContent(
        label: azkar.label(language),
        heading: morning
            ? t('Morning Azkar', 'أذكار الصباح', 'صبح کے اذکار')
            : t('Evening Azkar', 'أذكار المساء', 'شام کے اذکار'),
        detail: t('Open collection', 'افتح المجموعة', 'مجموعہ کھولیں'),
        path: AppRoutes.azkarCategoryPath(
          _azkarCategory,
          itemId: 'azkar:$_azkarCategory:${morning ? 75 : 98}',
        ),
      );
      add(
        azkar,
        start,
        remembrance(!morning.isAfter(start) && evening.isAfter(start)),
      );
      if (morning.isAfter(start) && morning.isBefore(evening)) {
        add(azkar, morning, remembrance(true));
      }
      if (evening.isAfter(start) && evening.isBefore(prayerDate(index + 1))) {
        add(azkar, evening, remembrance(false));
      }

      final key = (start.year, start.month, start.day);
      final daily =
          _ayahCache[key] ??
          await const DailyAyahService().load(
            date: start,
            quranRepository: quran,
            translationRepository: translations,
          );
      if (_translationRevision == translationRevision) {
        _ayahCache[key] = daily;
      }
      ayahs.add(
        HomeWidgetEntry(
          start,
          HomeWidgetContent(
            label: ayah.label(language),
            heading: daily.reference,
            detail: daily.translation,
            arabic: daily.ayah.text,
            path: AppRoutes.quranReaderPath(
              daily.surah.number,
              ayahNumber: daily.ayah.number,
              translationResourceId: daily.translationResource?.id,
            ),
          ),
        ),
      );

      final localDate = DateTime(now.year, now.month, now.day + index);
      final dashboard = await readingProgress.dashboard(now: localDate);
      final target = dashboard.goal;
      final unit = switch (target.metric) {
        ReadingGoalMetric.verses => t('ayahs', 'آيات', 'آیات'),
        ReadingGoalMetric.pages => t('pages', 'صفحات', 'صفحات'),
        ReadingGoalMetric.minutes => t('minutes', 'دقائق', 'منٹ'),
      };
      goals.add(
        HomeWidgetEntry(
          localDate,
          HomeWidgetContent(
            label: goal.label(language),
            heading: target.enabled
                ? '${dashboard.todayValue}$goalSeparator${target.dailyTarget}'
                : t('Set a goal', 'اضبط هدفاً', 'ہدف مقرر کریں'),
            detail: target.enabled ? unit : '',
            progress: target.enabled ? dashboard.goalProgress : null,
            path: target.enabled ? readerPath : AppRoutes.readingGoals,
          ),
        ),
      );
    }
    _ayahCache.removeWhere(
      (_, daily) => daily.date.isBefore(
        DateTime(prayerNow.year, prayerNow.month, prayerNow.day - 1),
      ),
    );
    timelines[ayah]!.addAll(ayahs);
    timelines[goal]!.addAll(goals);
    timelines[azkar]!.sort((a, b) => a.start.compareTo(b.start));

    final expiresAt = prayerDate(_days);
    for (final kind in [prayer, ayah, azkar, fasting, goal, hifz]) {
      add(
        kind,
        kind == goal || kind == hifz ? localEnd : expiresAt,
        HomeWidgetContent(
          label: kind.label(language),
          heading: t(
            'Open Quran to refresh',
            'افتح التطبيق للتحديث',
            'تازہ کرنے کے لیے قرآن کھولیں',
          ),
          path: '/',
        ),
      );
    }
    return HomeWidgetSnapshot(language, dark, timelines);
  }

  Future<DailyPrayerTimes?> _prayerDay(
    PrayerTimesRepository repository,
    DateTime date, {
    DailyPrayerTimes? reference,
  }) async {
    try {
      return await repository.getDailyPrayerTimes(
        date: date,
        location: reference?.location,
        settings: reference?.settings,
      );
    } catch (_) {
      return null;
    }
  }

  String _prayerName(PrayerTimeEntry entry, String language) {
    final (arabic, urdu) = entry.isFridayDhuhr
        ? ('الجمعة', 'جمعہ')
        : switch (entry.name) {
            PrayerTimeName.fajr => ('الفجر', 'فجر'),
            PrayerTimeName.sunrise => ('الشروق', 'طلوع آفتاب'),
            PrayerTimeName.dhuhr => ('الظهر', 'ظہر'),
            PrayerTimeName.asr => ('العصر', 'عصر'),
            PrayerTimeName.maghrib => ('المغرب', 'مغرب'),
            PrayerTimeName.isha => ('العشاء', 'عشاء'),
          };
    return widgetText(language, entry.displayName, arabic, urdu);
  }
}
