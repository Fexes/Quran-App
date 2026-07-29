import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/storage/settings_store.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_tracking/data/stores/prayer_tracking_store.dart';
import '../../../prayer_tracking/domain/entities/prayer_tracking_models.dart';
import '../../domain/entities/prayer_alert_settings.dart';

class PrayerAlertNotificationService {
  PrayerAlertNotificationService({
    required SettingsStore settingsStore,
    required PrayerTimesRepository prayerTimesRepository,
    PrayerTrackingStore? prayerTrackingStore,
    FlutterLocalNotificationsPlugin? notifications,
  }) : _settingsStore = settingsStore,
       _prayerTimesRepository = prayerTimesRepository,
       _prayerTrackingStore = prayerTrackingStore,
       _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final SettingsStore _settingsStore;
  final PrayerTimesRepository _prayerTimesRepository;
  final PrayerTrackingStore? _prayerTrackingStore;
  final FlutterLocalNotificationsPlugin _notifications;

  static const _channelId = 'prayer_alerts';
  static const _channelName = 'Prayer alerts';
  static const _channelDescription = 'Prayer time and reminder alerts';
  static const _androidNotificationIcon = 'ic_stat_prayer';
  static const _baseNotificationId = 910000;
  static const _scheduledDays = 5;
  static var _timeZonesInitialized = false;

  var _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    _ensureTimeZonesInitialized();
    const androidSettings = AndroidInitializationSettings(
      _androidNotificationIcon,
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    try {
      await _notifications.initialize(settings: settings);
    } on PlatformException catch (error) {
      if (error.code != 'invalid_icon') {
        rethrow;
      }
      debugPrint(
        'Prayer alerts unavailable because Android drawable '
        '$_androidNotificationIcon is missing from the installed APK. '
        'Reinstall the app using a fresh native build.',
      );
      return false;
    }
    _initialized = true;
    return true;
  }

  PrayerAlertSettings loadSettings() {
    return PrayerAlertSettings.fromStored(
      enabledPrayerNames: _settingsStore.prayerAlertEnabledPrayerNames,
      notifyAtPrayerTime: _settingsStore.prayerAlertAtPrayerTime,
      notifyBeforePrayer: _settingsStore.prayerAlertBeforePrayer,
      beforeMinutes: _settingsStore.prayerAlertBeforeMinutes,
      includeSunrise: _settingsStore.prayerAlertIncludeSunrise,
    );
  }

  Future<void> saveSettings(PrayerAlertSettings settings) async {
    await _settingsStore.setPrayerAlertSettings(
      enabledPrayerNames: settings.toStoredPrayerNames(),
      notifyAtPrayerTime: settings.notifyAtPrayerTime,
      notifyBeforePrayer: settings.notifyBeforePrayer,
      beforeMinutes: settings.beforeMinutes,
      includeSunrise: settings.includeSunrise,
    );
    await syncUpcomingAlerts(settings: settings);
  }

  Future<bool> requestPermissions() async {
    if (!await initialize()) {
      return false;
    }
    var allowed = true;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidAllowed = await android?.requestNotificationsPermission();
    if (androidAllowed == false) {
      allowed = false;
    }
    await android?.requestExactAlarmsPermission();

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosAllowed = await ios?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
    if (iosAllowed == false) {
      allowed = false;
    }

    final macOS = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macAllowed = await macOS?.requestPermissions(
      alert: true,
      badge: false,
      sound: true,
    );
    if (macAllowed == false) {
      allowed = false;
    }
    return allowed;
  }

  Future<void> syncUpcomingAlerts({PrayerAlertSettings? settings}) async {
    if (!await initialize()) {
      return;
    }
    final nextSettings = settings ?? loadSettings();
    await cancelScheduledAlerts();
    if (!nextSettings.schedulesAnything) {
      return;
    }
    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _scheduledDays; dayOffset++) {
      final dailyTimes = await _prayerTimesRepository.getDailyPrayerTimes(
        date: now.add(Duration(days: dayOffset)),
      );
      await _scheduleDailyAlerts(
        dailyTimes: dailyTimes,
        settings: nextSettings,
        dayOffset: dayOffset,
      );
    }
  }

  Future<void> cancelScheduledAlerts() async {
    if (!await initialize()) {
      return;
    }
    for (var dayOffset = 0; dayOffset < _scheduledDays; dayOffset++) {
      for (final name in PrayerTimeName.values) {
        for (var type = 0; type < 2; type++) {
          await _notifications.cancel(
            id: _notificationId(dayOffset, name, type),
          );
        }
      }
    }
  }

  Future<void> _scheduleDailyAlerts({
    required DailyPrayerTimes dailyTimes,
    required PrayerAlertSettings settings,
    required int dayOffset,
  }) async {
    if (_prayerTrackingStore?.suppressesRemindersFor(
          worshipDateKey(dailyTimes.date),
        ) ==
        true) {
      return;
    }
    final timeZone = _timeZone(dailyTimes.location.timeZone);
    for (final entry in dailyTimes.entries) {
      if (!settings.isEnabledFor(entry.name)) {
        continue;
      }
      if (settings.notifyAtPrayerTime) {
        await _scheduleEntryAlert(
          id: _notificationId(dayOffset, entry.name, 0),
          entry: entry,
          dailyTimes: dailyTimes,
          timeZone: timeZone,
          scheduledAt: entry.time,
          beforeMinutes: null,
        );
      }
      if (settings.notifyBeforePrayer) {
        await _scheduleEntryAlert(
          id: _notificationId(dayOffset, entry.name, 1),
          entry: entry,
          dailyTimes: dailyTimes,
          timeZone: timeZone,
          scheduledAt: entry.time.subtract(
            Duration(minutes: settings.beforeMinutes),
          ),
          beforeMinutes: settings.beforeMinutes,
        );
      }
    }
  }

  Future<void> _scheduleEntryAlert({
    required int id,
    required PrayerTimeEntry entry,
    required DailyPrayerTimes dailyTimes,
    required tz.Location timeZone,
    required DateTime scheduledAt,
    required int? beforeMinutes,
  }) async {
    final scheduledDate = tz.TZDateTime.from(scheduledAt, timeZone);
    if (!scheduledDate.isAfter(tz.TZDateTime.now(timeZone))) {
      return;
    }
    final isSunrise = entry.name == PrayerTimeName.sunrise;
    final title = beforeMinutes == null
        ? isSunrise
              ? 'Sunrise reminder'
              : '${entry.displayName} prayer'
        : isSunrise
        ? 'Sunrise soon'
        : '${entry.displayName} soon';
    final body = beforeMinutes == null
        ? isSunrise
              ? 'Sunrise is now in ${dailyTimes.location.name}.'
              : 'It is time for ${entry.displayName} in ${dailyTimes.location.name}.'
        : isSunrise
        ? 'Sunrise begins in $beforeMinutes minutes.'
        : '${entry.displayName} begins in $beforeMinutes minutes.';
    await _zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: 'prayer:${entry.name}',
      scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required AndroidScheduleMode scheduleMode,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted' ||
          scheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        rethrow;
      }
      await _zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: _androidNotificationIcon,
        ticker: 'Prayer alert',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  int _notificationId(int dayOffset, PrayerTimeName name, int type) {
    return _baseNotificationId + (dayOffset * 100) + (name.index * 10) + type;
  }

  tz.Location _timeZone(String timeZone) {
    _ensureTimeZonesInitialized();
    try {
      return tz.getLocation(timeZone);
    } catch (_) {
      return tz.getLocation('Etc/UTC');
    }
  }

  void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) {
      return;
    }
    timezone_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
}
