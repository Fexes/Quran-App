import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../../prayer_times/data/services/adhan_prayer_calculation_service.dart';
import '../../../prayer_tracking/data/stores/prayer_tracking_store.dart';
import 'prayer_alert_notification_service.dart';

const prayerAlertRenewalTask = 'tech.coreinfinite.quran.prayer-alert-renewal';
bool get supportsPrayerAlertRenewal => Platform.isIOS || Platform.isAndroid;
Future<void>? _initialization;

Future<void> ensurePrayerAlertRenewal() async {
  if (!supportsPrayerAlertRenewal) return;
  await (_initialization ??= Workmanager().initialize(
    prayerAlertTaskDispatcher,
  ));
  await Workmanager().registerPeriodicTask(
    prayerAlertRenewalTask,
    prayerAlertRenewalTask,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> cancelPrayerAlertRenewal() async {
  if (!supportsPrayerAlertRenewal) return;
  await (_initialization ??= Workmanager().initialize(
    prayerAlertTaskDispatcher,
  ));
  await Workmanager().cancelByUniqueName(prayerAlertRenewalTask);
}

// The background engine never opens Hive beside the UI engine. A minimal
// snapshot and cross-engine lock prevent stale alerts reappearing after erase.
Future<T> withPrayerAlertSnapshot<T>(
  Future<T> Function(File snapshot) action,
) async {
  final directory = await getApplicationSupportDirectory();
  final lock = File('${directory.path}/prayer_alerts.lock');
  final deadline = DateTime.now().add(const Duration(seconds: 35));
  while (true) {
    try {
      await lock.create(exclusive: true);
      break;
    } on FileSystemException {
      if (!await lock.exists()) continue;
      final modified = await lock.lastModified();
      if (DateTime.now().difference(modified) > const Duration(minutes: 2)) {
        await lock.delete();
        continue;
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const FileSystemException('Prayer alert update is still running');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  try {
    return await action(File('${directory.path}/prayer_alerts.json'));
  } finally {
    if (await lock.exists()) await lock.delete();
  }
}

@pragma('vm:entry-point')
void prayerAlertTaskDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != prayerAlertRenewalTask &&
        task != Workmanager.iOSBackgroundTask) {
      return true;
    }
    try {
      return await withPrayerAlertSnapshot((file) async {
        if (!await file.exists()) return true;
        final snapshot = jsonDecode(await file.readAsString()) as Map;
        final settings = SettingsStore.memory(
          Map<String, Object?>.from(snapshot['settings'] as Map),
        );
        final tracking = PrayerTrackingStore.memory(
          Map<String, Object?>.from(snapshot['tracking'] as Map),
        );
        await PrayerAlertNotificationService(
          settingsStore: settings,
          prayerTimesRepository: PrayerTimesRepositoryImpl(
            settingsStore: settings,
            calculationService: AdhanPrayerCalculationService(),
          ),
          prayerTrackingStore: tracking,
          managesBackgroundRenewal: false,
        ).syncUpcomingAlerts();
        return true;
      });
    } catch (_) {
      return false;
    }
  });
}
