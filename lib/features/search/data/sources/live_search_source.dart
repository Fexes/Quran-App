import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/search/offline_search_normalizer.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../prayer/data/datasources/offline_prayer_city_data_source.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../domain/entities/offline_search_result.dart';

/// Time-dependent answers are recalculated for each submitted query. They are
/// never embedded, persisted as facts, or obtained from a remote AI service.
class LiveSearchSource {
  LiveSearchSource({
    required this.prayerTimes,
    required this.settings,
    this.cities,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final PrayerTimesRepository prayerTimes;
  final SettingsStore settings;
  final OfflinePrayerCityDataSource? cities;

  static bool supportsQuery(String query) {
    final text = OfflineSearchNormalizer.keyword(query);
    return !_congregationQuery(text) &&
        (_timingIntent(text) || _calendarIntent(text));
  }

  static bool _congregationQuery(String text) => RegExp(
    r'\b(jummah|jumuah|jumu ah|congregation|jamaat)\b|جمعہ|الجمعة|جماعت',
  ).hasMatch(text);

  Future<List<OfflineSearchHit>> search(
    String query,
    OfflineSearchFilter filter,
  ) async {
    if (filter != OfflineSearchFilter.all &&
        filter != OfflineSearchFilter.timings) {
      return const [];
    }
    final text = OfflineSearchNormalizer.reference(query);
    final intentText = OfflineSearchNormalizer.keyword(query);
    if (_congregationQuery(intentText)) {
      return const [];
    }
    final timing = _timingIntent(intentText);
    final calendar = _calendarIntent(intentText);
    final scheduleDate =
        filter == OfflineSearchFilter.timings &&
        RegExp(
          r'^(today|tomorrow|yesterday|\d{4}-\d{2}-\d{2})$',
        ).hasMatch(text);
    if (!timing && !calendar && !scheduleDate) {
      return const [];
    }
    // An explicit location suppresses the repository's device-location refresh.
    var location = PrayerLocation(
      name: settings.prayerLocationName,
      latitude: settings.prayerLatitude,
      longitude: settings.prayerLongitude,
      timeZone: settings.prayerTimeZone,
      usesDeviceLocation: settings.prayerLocationUsesDevice,
    );
    final requestedCity = _requestedCity(text);
    if (requestedCity != null) {
      final matches = await _resolveCity(requestedCity);
      if (matches.length != 1) {
        return [
          _hit(
            'live:choose-city',
            'Choose a city for prayer times',
            matches.isEmpty
                ? 'No exact offline city match for "$requestedCity". Select a city in Prayer Times or search using its English name and country.'
                : 'More than one city matches "$requestedCity":\n${matches.map((city) => '${city.name}, ${city.countryName}').join('\n')}\nInclude the country in your search or select a city in Prayer Times.',
            requestedCity,
            {'requestedCity': requestedCity, 'category': 'chooseCity'},
            sourceLabel: 'Offline city catalog',
          ),
        ];
      }
      location = matches.single.toPrayerLocation();
    }
    final now = _clock();
    var daily = await prayerTimes.getDailyPrayerTimes(
      date: now,
      location: location,
    );
    // The normal prayer calculator initializes the app's timezone database.
    final zone = tz.getLocation(location.timeZone);
    final localNow = tz.TZDateTime.from(now, zone);
    final nextMidnight = tz.TZDateTime(
      zone,
      localNow.year,
      localNow.month,
      localNow.day + 1,
    );
    var date = tz.TZDateTime(
      zone,
      localNow.year,
      localNow.month,
      localNow.day,
      12,
    );
    final explicit = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b').firstMatch(text);
    if (explicit != null) {
      final year = int.parse(explicit[1]!);
      final month = int.parse(explicit[2]!);
      final day = int.parse(explicit[3]!);
      final requested = tz.TZDateTime(zone, year, month, day, 12);
      if (requested.year != year ||
          requested.month != month ||
          requested.day != day) {
        return const [];
      }
      date = requested;
    } else if (RegExp(r'\btomorrow\b|غدا|غداً|آنے والا کل').hasMatch(text)) {
      date = tz.TZDateTime(
        zone,
        localNow.year,
        localNow.month,
        localNow.day + 1,
        12,
      );
    } else if (RegExp(r'\byesterday\b|أمس|گزشتہ کل').hasMatch(text)) {
      date = tz.TZDateTime(
        zone,
        localNow.year,
        localNow.month,
        localNow.day - 1,
        12,
      );
    }
    daily = await prayerTimes.getDailyPrayerTimes(
      date: date,
      location: location,
    );
    final reference =
        '${_date(date)} • ${location.name} • ${location.timeZone}';
    if (calendar && !timing) {
      final hijri = HijriCalendarConfig.fromGregorian(date);
      return [
        _hit(
          'live:calendar',
          'Calendar • ${_date(date)}',
          'Gregorian: ${_date(date)}\nHijri: ${hijri.hDay}/${hijri.hMonth}/${hijri.hYear}',
          reference,
          {
            'date': _date(date),
            'category': 'calendar',
            'location': location.name,
            'hijriDay': '${hijri.hDay}',
            'hijriMonth': '${hijri.hMonth}',
            'hijriMonthName': hijri.getLongMonthName(),
            'hijriYear': '${hijri.hYear}',
            'refreshAt': nextMidnight.toUtc().toIso8601String(),
            'timeZone': location.timeZone,
            'calculatedAt': now.toIso8601String(),
          },
          sourceLabel: requestedCity == null
              ? 'Your saved prayer settings'
              : 'Your prayer settings • Offline city catalog',
        ),
      ];
    }
    final next = RegExp(r'\bnext\b|اگلی|اگلا|القادمة|التالي').hasMatch(text);
    final selected = <PrayerTimeEntry>[];
    if (next && explicit == null && _date(date) == _date(localNow)) {
      final nextEntry =
          daily.entries
              .where(
                (entry) =>
                    entry.name != PrayerTimeName.sunrise &&
                    entry.time.isAfter(now),
              )
              .firstOrNull ??
          daily.nextDayFajr;
      if (nextEntry != null) selected.add(nextEntry);
    } else {
      final requested = _requestedPrayers(text);
      selected.addAll(
        daily.entries.where(
          (entry) => requested.isEmpty || requested.contains(entry.name),
        ),
      );
    }
    return [
      for (final entry in selected)
        _hit(
          'live:prayer:${entry.name.name}:${_date(entry.time)}',
          '${next ? 'Next prayer • ' : ''}${_prayerName(entry)} • ${_time(entry.time)}',
          '${_prayerName(entry)}: ${_time(entry.time)}\n${_date(entry.time)} • ${location.name}\n${location.timeZone}\nCalculation: ${daily.settings.method.name}; Asr: ${daily.settings.asrMadhab.name}.',
          '${_date(entry.time)} • ${location.name} • ${location.timeZone}',
          {
            'date': _date(entry.time),
            'time': entry.time.toUtc().toIso8601String(),
            'timeZone': location.timeZone,
            'location': location.name,
            'category': 'prayer',
            'prayerName': _prayerName(entry),
            'prayerKey': entry.name.name,
            'displayTime': _time(entry.time),
            'isNext': '$next',
            'calculationMethod': daily.settings.method.name,
            'asrMethod': daily.settings.asrMadhab.name,
            'refreshAt':
                (next && entry.time.isBefore(nextMidnight)
                        ? entry.time
                        : nextMidnight)
                    .toUtc()
                    .toIso8601String(),
            'calculatedAt': now.toIso8601String(),
          },
          sourceLabel: requestedCity == null
              ? 'Your saved prayer settings'
              : 'Your prayer settings • Offline city catalog',
        ),
    ];
  }

  /// Only explicit city clauses override the saved location. Date words remain
  /// in the full query for the calendar parser and are excluded from city names.
  static String? _requestedCity(String text) {
    final withoutDateClause = text.replaceAll(
      RegExp(r'\bfor\s+(today|tomorrow|yesterday|\d{4}-\d{2}-\d{2})\b'),
      ' ',
    );
    final clauses = RegExp(r'\b(?:in|for)\s+').allMatches(withoutDateClause);
    if (clauses.isEmpty) return null;
    final city = withoutDateClause
        .substring(clauses.last.end)
        .replaceAll(
          RegExp(
            r'\b(today|tomorrow|yesterday|please)\b|\b\d{4}-\d{2}-\d{2}\b|آنے والا کل|گزشتہ کل|غداً|غدا|أمس|آج',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[?؟.!]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (city.isEmpty ||
        {'my city', 'my location', 'here', 'now'}.contains(city) ||
        _requestedPrayers(city).isNotEmpty) {
      return null;
    }
    return city;
  }

  Future<List<OfflinePrayerCity>> _resolveCity(String requested) async {
    final catalog = cities;
    if (catalog == null) return const [];
    final pieces = requested.split(',').map((part) => part.trim()).toList();
    var name = pieces.first;
    String? country = pieces.length > 1 ? pieces.skip(1).join(' ') : null;
    const countryAliases = {
      'uk': 'gb',
      'united kingdom': 'gb',
      'great britain': 'gb',
      'usa': 'us',
      'united states': 'us',
      'pakistan': 'pk',
      'canada': 'ca',
    };
    if (country == null) {
      for (final suffix in countryAliases.keys) {
        if (name.endsWith(' $suffix')) {
          country = suffix;
          name = name.substring(0, name.length - suffix.length).trim();
          break;
        }
      }
    }
    name =
        const {
          'کراچی': 'karachi',
          'كراتشي': 'karachi',
          'لندن': 'london',
          'لاہور': 'lahore',
          'اسلام آباد': 'islamabad',
          'دبي': 'dubai',
          'دبئی': 'dubai',
          'مکہ': 'makkah',
          'مكة': 'makkah',
        }[name] ??
        name;
    // The catalog's ASCII normalizer turns unknown native-script names into an
    // empty featured-city query. Never allow that to silently choose a city.
    if (!RegExp(r'[a-z0-9]').hasMatch(name)) return const [];
    final normalized = name.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    final countryFilter = countryAliases[country] ?? country;
    final candidates = await catalog.search(name, limit: 100);
    return candidates.where((city) {
      final exact =
          city.normalizedName == normalized ||
          city.normalizedAsciiName == normalized;
      return exact &&
          (countryFilter == null ||
              city.normalizedCountry == countryFilter ||
              city.normalizedCountryCode == countryFilter);
    }).toList();
  }

  static bool _timingIntent(String text) {
    if (_pattern(
      r'\b(dua|supplication|hadith|quran|meaning|importance|benefits|why|how|allowed|permissible|forbidden|ruling|miss|missed|combine|combining|travelling|traveling|sick|sunnah|best|preferred|preferable|proper|correct|duha|ishraq|tahajjud|witr|taraweeh|eid|janazah)\b|دعاء|دعا|حدیث|حديث|قران|فضائل|قضا|حکم|کیوں|لماذا|يجوز|افضل|بہترین|ضحی|ضحى|اشراق|تہجد|وتر|تراويح|عيد|عید|جناز',
    ).hasMatch(text)) {
      return false;
    }
    final prayers = _requestedPrayers(text);
    final timeWords = _pattern(
      r'\b(time|times|timing|timings|next|today|tomorrow|kab|waqt|baje|schedule)\b|\bwhen\s+(is|are|does|will)\b|وقت|اوقات|كب|بجے|موعد|متي|اگلي|القادمة',
    ).hasMatch(text);
    final prayerWords = _pattern(
      r'\b(prayer|prayers|namaz|salah|salat)\b|نماز|الصلاة|صلاة',
    ).hasMatch(text);
    final fastingTime = _pattern(
      r'\b(iftar|sehri|suhoor|sehar|break my fast|break the fast|stop eating)\b|افطار|إفطار|سحری|سحور',
    ).hasMatch(text);
    return (timeWords && (prayerWords || prayers.isNotEmpty)) ||
        RegExp(r'^timings?\s+(in|for)\b').hasMatch(text) ||
        (fastingTime &&
            (timeWords || text.trim().split(RegExp(r'\s+')).length == 1)) ||
        (prayers.isNotEmpty && text.trim().split(RegExp(r'\s+')).length == 1);
  }

  static bool _calendarIntent(String text) {
    if (_pattern(
      r'\b(quran|hadith|ruling|meaning|judgment|judgement|revelation|birth|death|battle|history|historical|why|how|explain)\b|قران|حديث|حدیث|حکم|قیامت|نزول|کیوں|کیسے|لماذا|كيف',
    ).hasMatch(text)) {
      return false;
    }
    return _pattern(
      r'\b(calendar|hijri)\b|\b(today s date|todays date|date today|current date|what is the date|what date is it)\b|^(date|islamic date)$|تاريخ اليوم|تاريخ هجري|اج.*تاريخ|ہجري.*تاريخ|تقويم',
    ).hasMatch(text);
  }

  // A calculated Friday Dhuhr is not a mosque's Jumuah congregation time.
  static String _prayerName(PrayerTimeEntry entry) =>
      entry.name == PrayerTimeName.dhuhr ? 'Dhuhr' : entry.displayName;

  static RegExp _pattern(String pattern) => RegExp(
    pattern
        .replaceAll('ی', 'ي')
        .replaceAll('ک', 'ك')
        .replaceAll('آ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('ى', 'ي'),
  );

  static Set<PrayerTimeName> _requestedPrayers(String text) {
    final normalized = OfflineSearchNormalizer.keyword(text);
    return {
      if (_pattern(
        r'\b(fajr|fajar|sehri|suhoor|sehar|stop eating)\b|فجر|سحری|سحور',
      ).hasMatch(normalized))
        PrayerTimeName.fajr,
      if (_pattern(r'\b(sunrise|sun rise)\b|طلوع|شروق').hasMatch(normalized))
        PrayerTimeName.sunrise,
      if (_pattern(r'\b(dhuhr|zuhr|zohar)\b|ظهر|ظہر').hasMatch(normalized))
        PrayerTimeName.dhuhr,
      if (_pattern(r'\basr\b|عصر').hasMatch(normalized)) PrayerTimeName.asr,
      if (_pattern(
        r'\b(maghrib|magrib|iftar|sunset|break my fast|break the fast)\b|مغرب|افطار|إفطار',
      ).hasMatch(normalized))
        PrayerTimeName.maghrib,
      if (_pattern(r'\b(isha|ishaa)\b|عشاء|عشا').hasMatch(normalized))
        PrayerTimeName.isha,
    };
  }

  static OfflineSearchHit _hit(
    String id,
    String title,
    String body,
    String reference,
    Map<String, String> metadata, {
    String sourceLabel = 'Your saved prayer settings',
  }) => OfflineSearchHit(
    score: 1,
    passage: OfflineSearchPassage(
      canonicalId: id,
      kind: 'timings',
      reference: reference,
      title: title,
      arabic: '',
      translations: const [],
      grades: const [],
      body: body,
      route: '/?tab=prayer',
      sourceLabel: sourceLabel,
      metadata: metadata,
    ),
  );
  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
