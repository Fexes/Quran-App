import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/locale_state.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../prayer/data/datasources/offline_prayer_city_data_source.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../../prayer/domain/entities/prayer_alert_settings.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.editMode = false});

  final bool editMode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _stepCount = 6;

  late final SettingsStore _store;
  late final PrayerTimesRepository _prayerRepository;
  late final QuranTranslationRepository _translationRepository;
  late final OfflinePrayerCityDataSource _cityDataSource;
  late Future<List<QuranTranslationLanguage>> _translationLanguagesFuture;

  late int _step;
  late PrayerLocation _location;
  late PrayerCalculationMethod _method;
  late PrayerAsrMadhab _madhab;
  late bool _locationConfirmed;
  late String _readingIntent;
  bool _enableNotifications = false;
  int _selectedTranslationId = 0;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsStore>();
    _prayerRepository = getIt<PrayerTimesRepository>();
    _translationRepository = getIt<QuranTranslationRepository>();
    _cityDataSource = getIt<OfflinePrayerCityDataSource>();
    _step = widget.editMode ? 0 : _store.onboardingStep;
    _location = PrayerLocation(
      name: _store.prayerLocationName,
      latitude: _store.prayerLatitude,
      longitude: _store.prayerLongitude,
      timeZone: _store.prayerTimeZone,
    );
    _method = _methodFromName(_store.prayerMethod);
    _madhab = _madhabFromName(_store.prayerAsrMadhab);
    _locationConfirmed = widget.editMode || _store.onboardingLocationConfirmed;
    _readingIntent = _store.readingIntent;
    _enableNotifications = _store.prayerAlertEnabledPrayerNames.isNotEmpty;
    _translationLanguagesFuture = _loadTranslationLanguages();
    if (!widget.editMode) {
      unawaited(_store.setOnboardingStep(_step));
    }
  }

  Future<List<QuranTranslationLanguage>> _loadTranslationLanguages() async {
    final selected = await _translationRepository.selectedTranslation();
    final languages = await _translationRepository.translationLanguages();
    var suggestedId = selected?.id ?? 0;
    if (selected == null && !_store.contentLocaleSuggestionApplied) {
      final deviceLanguage = WidgetsBinding
          .instance
          .platformDispatcher
          .locale
          .languageCode
          .toLowerCase();
      for (final language in languages) {
        for (final resource in language.availableResources) {
          if (resource.resolvedLanguageCode == deviceLanguage) {
            suggestedId = resource.id;
            break;
          }
        }
        if (suggestedId != 0) {
          break;
        }
      }
    }
    if (mounted && suggestedId != 0) {
      setState(() => _selectedTranslationId = suggestedId);
    }
    return languages;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0 || widget.editMode
            ? IconButton(
                tooltip: 'Back',
                onPressed: _saving ? null : _back,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(widget.editMode ? 'Setup preferences' : 'Welcome'),
        actions: [
          if (widget.editMode)
            TextButton(
              onPressed: _saving ? null : () => context.pop(),
              child: const Text('Close'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Step ${_step + 1} of $_stepCount',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${(((_step + 1) / _stepCount) * 100).round()}%',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: QuranTheme.subText(context, 0.68),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / _stepCount,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(999),
                    color: primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _stepContent(),
                  ),
                ),
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving || !_canContinue ? null : _continue,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _step == _stepCount - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _step == _stepCount - 1 ? 'Finish setup' : 'Continue',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      0 => _languageStep(),
      1 => _translationStep(),
      2 => _locationStep(),
      3 => _calculationStep(),
      4 => _intentAndNotificationsStep(),
      _ => _previewStep(),
    };
  }

  Widget _languageStep() {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) => _StepCard(
        icon: Icons.language_rounded,
        title: 'Choose app language',
        description:
            'This controls menus and buttons only. Quran, tafsir, Hadith, and Azkar keep separate language choices.',
        child: DropdownButtonFormField<String>(
          initialValue: state.preferenceCode,
          decoration: const InputDecoration(labelText: 'Interface language'),
          items: const [
            DropdownMenuItem(value: 'system', child: Text('System language')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ur', child: Text('اردو')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<LocaleCubit>().setLocale(value);
            }
          },
        ),
      ),
    );
  }

  Widget _translationStep() {
    return _StepCard(
      icon: Icons.translate_rounded,
      title: 'Choose Quran translation',
      description:
          'The Arabic Quran remains unchanged. Downloaded editions show their translator and source in the reader.',
      child: FutureBuilder<List<QuranTranslationLanguage>>(
        future: _translationLanguagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final resources = [
            for (final language in snapshot.data!)
              ...language.availableResources,
          ];
          final ids = resources.map((item) => item.id).toSet();
          final selectedId = ids.contains(_selectedTranslationId)
              ? _selectedTranslationId
              : 0;
          QuranTranslationResource? selected;
          for (final resource in resources) {
            if (resource.id == selectedId) {
              selected = resource;
              break;
            }
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Edition'),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Bundled English default'),
                  ),
                  for (final resource in resources)
                    DropdownMenuItem(
                      value: resource.id,
                      child: Text(
                        '${resource.displayEndonym} • ${resource.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTranslationId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                selected == null
                    ? 'Preview: bundled English translation is available offline.'
                    : 'Preview: ${selected.displayEndonym} by ${selected.translator}. '
                          'Source ${selected.sourceUrl}. Download is requested when first opened.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _locationStep() {
    return _StepCard(
      icon: Icons.location_on_rounded,
      title: 'Set prayer location',
      description:
          'Prayer times need an accurate city or location. You can search manually without granting location permission.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PremiumSurface(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  _locationConfirmed
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: _locationConfirmed
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationConfirmed
                            ? _location.name
                            : 'No location confirmed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _locationConfirmed
                            ? _location.timeZone
                            : 'Choose a city or use current location.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _chooseCity,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search city'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _useCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Use current location'),
          ),
        ],
      ),
    );
  }

  Widget _calculationStep() {
    return _StepCard(
      icon: Icons.schedule_rounded,
      title: 'Prayer calculation',
      description:
          'Choose the method used by your mosque or local authority. You can change this later.',
      child: Column(
        children: [
          DropdownButtonFormField<PrayerCalculationMethod>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Method'),
            items: const [
              DropdownMenuItem(
                value: PrayerCalculationMethod.karachi,
                child: Text('University of Islamic Sciences, Karachi'),
              ),
              DropdownMenuItem(
                value: PrayerCalculationMethod.muslimWorldLeague,
                child: Text('Muslim World League'),
              ),
              DropdownMenuItem(
                value: PrayerCalculationMethod.ummAlQura,
                child: Text('Umm al-Qura, Makkah'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _method = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PrayerAsrMadhab>(
            initialValue: _madhab,
            decoration: const InputDecoration(labelText: 'Asr calculation'),
            items: const [
              DropdownMenuItem(
                value: PrayerAsrMadhab.hanafi,
                child: Text('Hanafi'),
              ),
              DropdownMenuItem(
                value: PrayerAsrMadhab.shafi,
                child: Text('Standard (Shafi, Maliki, Hanbali)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _madhab = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _intentAndNotificationsStep() {
    return _StepCard(
      icon: Icons.track_changes_rounded,
      title: 'Personalize your journey',
      description:
          'Your reading intent stays private on this device. Notification permission is requested only after you finish setup.',
      child: Column(
        children: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'read', label: Text('Read')),
              ButtonSegment(value: 'memorize', label: Text('Memorize')),
              ButtonSegment(value: 'both', label: Text('Both')),
            ],
            selected: {_readingIntent},
            onSelectionChanged: (values) {
              setState(() => _readingIntent = values.first);
            },
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enableNotifications,
            onChanged: (value) {
              setState(() => _enableNotifications = value);
            },
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('Prayer notifications'),
            subtitle: const Text(
              'Remind me at the five daily prayer times. The system prompt appears after this explanation.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewStep() {
    final settings = PrayerCalculationSettings(
      method: _method,
      asrMadhab: _madhab,
    );
    return _StepCard(
      icon: Icons.auto_awesome_rounded,
      title: 'Your setup preview',
      description:
          'Review the calculated prayer times and selections before continuing to Home.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(label: 'Location', value: _location.name),
          _SummaryRow(label: 'Method', value: _methodLabel(_method)),
          _SummaryRow(label: 'Asr', value: _madhabLabel(_madhab)),
          _SummaryRow(label: 'Reading', value: _readingIntentLabel()),
          _SummaryRow(
            label: 'Notifications',
            value: _enableNotifications ? 'Requested on finish' : 'Off',
          ),
          const SizedBox(height: 14),
          FutureBuilder<DailyPrayerTimes>(
            future: _prayerRepository.getDailyPrayerTimes(
              date: DateTime.now(),
              location: _location,
              settings: settings,
            ),
            builder: (context, snapshot) {
              final daily = snapshot.data;
              if (daily == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in daily.entries)
                    Chip(
                      label: Text(
                        '${entry.displayName} ${TimeOfDay.fromDateTime(entry.time).format(context)}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool get _canContinue => _step != 2 || _locationConfirmed;

  Future<void> _continue() async {
    setState(() => _message = null);
    if (_step < _stepCount - 1) {
      final next = _step + 1;
      if (!widget.editMode) {
        await _store.setOnboardingStep(next);
      }
      if (mounted) {
        setState(() => _step = next);
      }
      return;
    }
    await _finish();
  }

  void _back() {
    if (_step == 0) {
      if (widget.editMode) {
        context.pop();
      }
      return;
    }
    final previous = _step - 1;
    if (!widget.editMode) {
      unawaited(_store.setOnboardingStep(previous));
    }
    setState(() => _step = previous);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await _prayerRepository.saveLocation(_location);
      await _prayerRepository.saveSettings(
        PrayerCalculationSettings(method: _method, asrMadhab: _madhab),
      );
      await _translationRepository.setSelectedTranslation(
        _selectedTranslationId == 0 ? null : _selectedTranslationId,
      );
      await _store.setReadingIntent(_readingIntent);
      await _store.setContentLocaleSuggestionApplied(true);
      await _store.setOnboardingLocationConfirmed(true);

      if (_enableNotifications &&
          getIt.isRegistered<PrayerAlertNotificationService>()) {
        final service = getIt<PrayerAlertNotificationService>();
        final allowed = await service.requestPermissions();
        if (allowed) {
          await service.saveSettings(
            PrayerAlertSettings.disabled().withAllCorePrayers(true),
          );
        } else {
          await service.saveSettings(PrayerAlertSettings.disabled());
        }
      } else if (getIt.isRegistered<PrayerAlertNotificationService>()) {
        await getIt<PrayerAlertNotificationService>().saveSettings(
          PrayerAlertSettings.disabled(),
        );
      }

      await _store.completeOnboarding();
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.shell);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Could not save setup. Please try again.';
        });
      }
    }
  }

  String _readingIntentLabel() {
    return switch (_readingIntent) {
      'memorize' => 'Memorize',
      'both' => 'Read and memorize',
      _ => 'Read',
    };
  }

  Future<void> _chooseCity() async {
    final city = await showModalBottomSheet<OfflinePrayerCity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _OnboardingCityPicker(cityDataSource: _cityDataSource),
    );
    if (city == null) {
      return;
    }
    setState(() {
      _location = city.toPrayerLocation();
      _locationConfirmed = true;
      _message = null;
    });
    await _store.setOnboardingLocationConfirmed(true);
  }

  Future<void> _useCurrentLocation() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use current location?'),
        content: const Text(
          'Location is used to calculate prayer times and find the nearest offline city and time zone. You can choose a city manually instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose city'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) {
      if (proceed == false) {
        await _chooseCity();
      }
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _saving = false;
            _message =
                'Location was not allowed. Search for your city instead.';
          });
          await _chooseCity();
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final nearest = await _cityDataSource.nearest(
        position.latitude,
        position.longitude,
      );
      final next = nearest?.toPrayerLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _location =
            next ??
            PrayerLocation(
              name: 'Current location',
              latitude: position.latitude,
              longitude: position.longitude,
              timeZone: _location.timeZone,
            );
        _locationConfirmed = true;
      });
      await _store.setOnboardingLocationConfirmed(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Could not read location. Search for your city instead.';
        });
      }
    }
  }

  PrayerCalculationMethod _methodFromName(String value) {
    return PrayerCalculationMethod.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PrayerCalculationMethod.karachi,
    );
  }

  PrayerAsrMadhab _madhabFromName(String value) {
    return PrayerAsrMadhab.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PrayerAsrMadhab.hanafi,
    );
  }

  String _methodLabel(PrayerCalculationMethod method) {
    return switch (method) {
      PrayerCalculationMethod.karachi => 'Karachi',
      PrayerCalculationMethod.muslimWorldLeague => 'Muslim World League',
      PrayerCalculationMethod.ummAlQura => 'Umm al-Qura',
    };
  }

  String _madhabLabel(PrayerAsrMadhab madhab) {
    return madhab == PrayerAsrMadhab.hanafi ? 'Hanafi' : 'Standard';
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(18),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.72),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 106,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCityPicker extends StatefulWidget {
  const _OnboardingCityPicker({required this.cityDataSource});

  final OfflinePrayerCityDataSource cityDataSource;

  @override
  State<_OnboardingCityPicker> createState() => _OnboardingCityPickerState();
}

class _OnboardingCityPickerState extends State<_OnboardingCityPicker> {
  final _controller = TextEditingController();
  List<OfflinePrayerCity> _cities = const [];
  bool _loading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final requestId = ++_requestId;
    setState(() => _loading = true);
    final cities = await widget.cityDataSource.search(value);
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() {
      _cities = cities;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose prayer city',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search city or country',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _cities.length,
                      itemBuilder: (context, index) {
                        final city = _cities[index];
                        return ListTile(
                          title: Text(city.name),
                          subtitle: Text(city.subtitle),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
