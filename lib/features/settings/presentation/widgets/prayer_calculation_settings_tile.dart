import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';

class PrayerCalculationSettingsTile extends StatefulWidget {
  const PrayerCalculationSettingsTile({super.key});

  @override
  State<PrayerCalculationSettingsTile> createState() =>
      _PrayerCalculationSettingsTileState();
}

class _PrayerCalculationSettingsTileState
    extends State<PrayerCalculationSettingsTile> {
  @override
  Widget build(BuildContext context) {
    final store = getIt<SettingsStore>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const AppIcon(Icons.schedule_outlined),
      title: const Text('Prayer calculation'),
      subtitle: Text(store.prayerAsrMadhab == 'shafi' ? 'Shafi' : 'Hanafi'),
      trailing: const AppIcon(Icons.chevron_right_rounded),
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _PrayerCalculationSheet(),
        );
        if (mounted) setState(() {});
      },
    );
  }
}

class _PrayerCalculationSheet extends StatefulWidget {
  const _PrayerCalculationSheet();

  @override
  State<_PrayerCalculationSheet> createState() =>
      _PrayerCalculationSheetState();
}

class _PrayerCalculationSheetState extends State<_PrayerCalculationSheet> {
  late PrayerCalculationSettings _settings;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final store = getIt<SettingsStore>();
    _settings = PrayerCalculationSettings(
      method: PrayerCalculationMethod.values.firstWhere(
        (value) => value.name == store.prayerMethod,
        orElse: () => PrayerCalculationMethod.karachi,
      ),
      asrMadhab: PrayerAsrMadhab.values.firstWhere(
        (value) => value.name == store.prayerAsrMadhab,
        orElse: () => PrayerAsrMadhab.hanafi,
      ),
    );
  }

  Future<void> _save(PrayerCalculationSettings next) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await getIt<PrayerTimesRepository>().saveSettings(next);
      if (mounted) setState(() => _settings = next);
      if (getIt.isRegistered<PrayerAlertNotificationService>()) {
        await getIt<PrayerAlertNotificationService>().syncUpcomingAlerts();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not finish updating prayer times and alerts. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Prayer calculation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Asr method', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          SegmentedButton<PrayerAsrMadhab>(
            segments: const [
              ButtonSegment(
                value: PrayerAsrMadhab.hanafi,
                label: Text('Hanafi'),
              ),
              ButtonSegment(value: PrayerAsrMadhab.shafi, label: Text('Shafi')),
            ],
            selected: {_settings.asrMadhab},
            onSelectionChanged: _saving
                ? null
                : (values) => _save(
                    PrayerCalculationSettings(
                      method: _settings.method,
                      asrMadhab: values.first,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Calculation method'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PrayerCalculationMethod>(
                value: _settings.method,
                isExpanded: true,
                isDense: true,
                items: [
                  for (final method in PrayerCalculationMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(switch (method) {
                        PrayerCalculationMethod.karachi => 'Karachi',
                        PrayerCalculationMethod.muslimWorldLeague =>
                          'Muslim World League',
                        PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
                      }),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          _save(
                            PrayerCalculationSettings(
                              method: value,
                              asrMadhab: _settings.asrMadhab,
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
