import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/quran_arabic_script.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/localization/locale_state.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../prayer/data/datasources/offline_prayer_city_data_source.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../../prayer/domain/entities/prayer_alert_settings.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/quran_translation_download_sheet.dart';
import '../../../quran/presentation/widgets/quran_translation_picker.dart';
import '../../data/ip_country_lookup.dart';

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
  Future<DailyPrayerTimes>? _previewFuture;

  late int _step;
  late PrayerLocation _location;
  late PrayerCalculationMethod _method;
  late PrayerAsrMadhab _madhab;
  late bool _locationConfirmed;
  late String _readingIntent;
  bool _enableNotifications = false;
  int _selectedTranslationId = 0;
  bool _saving = false;
  late QuranArabicScript _script;
  late bool _scriptChosenManually;
  int _scriptLookupRevision = 0;
  String? _scriptSuggestionSource;
  String? _message;

  @override
  void initState() {
    super.initState();
    _store = getIt<SettingsStore>();
    _script = QuranArabicScript.values.firstWhere(
      (script) => script.name == _store.quranArabicScript,
      orElse: () => QuranArabicScript.uthmani,
    );
    _scriptChosenManually = _store.hasManualArabicScript;
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
      unawaited(_suggestScript());
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
        if (language.defaultResource.resolvedLanguageCode == deviceLanguage) {
          suggestedId = language.defaultResource.id;
          break;
        }
      }
    }
    if (mounted && suggestedId != 0) {
      setState(() => _selectedTranslationId = suggestedId);
    }
    return languages;
  }

  Future<void> _suggestScript() async {
    if (_scriptChosenManually) return;
    final revision = ++_scriptLookupRevision;
    String? country;
    var source = 'prayer location';
    try {
      if (_locationConfirmed) {
        country = (await _cityDataSource.nearest(
          _location.latitude,
          _location.longitude,
        ))?.countryCode;
      }
    } catch (_) {
      // An unavailable offline city lookup must not hold up setup.
    }
    if (!mounted ||
        revision != _scriptLookupRevision ||
        _scriptChosenManually) {
      return;
    }
    if (country == null) {
      source = 'IP country';
      country = await lookupIpCountry();
    }
    if (!mounted ||
        revision != _scriptLookupRevision ||
        _scriptChosenManually) {
      return;
    }
    _applyScriptSuggestion(country, source);
  }

  void _applyScriptSuggestion(String? country, String source) {
    if (!mounted || _scriptChosenManually || country == null) return;
    setState(() {
      _script = QuranArabicScript.forCountry(country);
      _scriptSuggestionSource = '$source: $country';
    });
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
                icon: const AppIcon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(widget.editMode ? 'Setup preferences' : 'Welcome'),
        flexibleSpace: const ArchitecturalBackdrop(),
        actions: [
          if (widget.editMode)
            IconButton(
              tooltip: 'Close',
              onPressed: _saving ? null : () => context.pop(),
              icon: const AppIcon(Icons.close_rounded),
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
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / _stepCount,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(999),
                    color: primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
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
                      : AppIcon(
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
      builder: (context, state) => _StepPanel(
        icon: Icons.language_rounded,
        title: 'Choose app language',
        description:
            'This controls menus and buttons only. Quran, tafsir, Hadith, and Azkar keep separate language choices.',
        child: DropdownButtonFormField<String>(
          initialValue: state.preferenceCode,
          isExpanded: true,
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
    return _StepPanel(
      icon: Icons.translate_rounded,
      title: 'Choose Quran translation',
      description:
          'The Arabic Quran remains unchanged. Downloaded editions show their translator and source in the reader.',
      child: FutureBuilder<List<QuranTranslationLanguage>>(
        future: _translationLanguagesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                const Text('Translation editions could not be loaded.'),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _translationLanguagesFuture = _loadTranslationLanguages();
                  }),
                  icon: const AppIcon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            );
          }
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(Icons.translate_rounded),
                title: Text(selected?.displayEndonym ?? 'Bundled English'),
                subtitle: Text(selected?.name ?? 'Default edition'),
                trailing: const AppIcon(Icons.chevron_right_rounded),
                onTap: _saving ? null : () => _chooseTranslation(selected),
              ),
              if (selected != null)
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _selectedTranslationId = 0),
                  child: const Text('Use bundled English'),
                ),
              const SizedBox(height: 12),
              Text(
                selected == null
                    ? 'Preview: bundled English translation is available offline.'
                    : 'Preview: ${selected.displayEndonym} by ${selected.translator}. '
                          'Source ${selected.sourceUrl}.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: QuranTheme.subText(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _locationStep() {
    return _StepPanel(
      icon: Icons.location_on_rounded,
      title: 'Set prayer location',
      description:
          'Choose a city or use your location for prayer times. Coordinates stay on your device.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                AppIcon(
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
                          fontWeight: FontWeight.w600,
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
            onPressed: _saving ? null : _chooseCity,
            icon: const AppIcon(Icons.search_rounded),
            label: const Text('Search city'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _useCurrentLocation,
            icon: const AppIcon(Icons.my_location_rounded),
            label: const Text('Use current location'),
          ),
        ],
      ),
    );
  }

  Widget _calculationStep() {
    return _StepPanel(
      icon: Icons.schedule_rounded,
      title: 'Prayer calculation',
      description:
          'Choose the method used by your mosque or local authority. You can change this later.',
      child: Column(
        children: [
          DropdownButtonFormField<PrayerCalculationMethod>(
            initialValue: _method,
            isExpanded: true,
            itemHeight: null,
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
            isExpanded: true,
            itemHeight: null,
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
    return _StepPanel(
      icon: Icons.track_changes_rounded,
      title: 'Personalize your journey',
      description:
          'Your reading intent stays private on this device. Notification permission is requested only after you finish setup.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Arabic script', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<QuranArabicScript>(
            segments: [
              for (final script in QuranArabicScript.values)
                ButtonSegment(value: script, label: Text(script.label)),
            ],
            selected: {_script},
            onSelectionChanged: (selection) => setState(() {
              _script = selection.first;
              _scriptChosenManually = true;
              _scriptSuggestionSource = null;
              _scriptLookupRevision++;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _scriptChosenManually
                ? 'Your selection'
                : _scriptSuggestionSource == null
                ? 'Automatic default: prayer location, then approximate IP country (country.is).'
                : 'Suggested from $_scriptSuggestionSource',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
          ),
          const SizedBox(height: 20),
          Text('Reading intent', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
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
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enableNotifications,
            onChanged: (value) {
              setState(() => _enableNotifications = value);
            },
            secondary: const AppIcon(Icons.notifications_rounded),
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
    return _StepPanel(
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
          _SummaryRow(label: 'Arabic script', value: _script.label),
          _SummaryRow(
            label: 'Notifications',
            value: _enableNotifications ? 'Requested on finish' : 'Off',
          ),
          const SizedBox(height: 14),
          FutureBuilder<DailyPrayerTimes>(
            future: _previewFuture ??= _prayerRepository.getDailyPrayerTimes(
              date: DateTime.now(),
              location: _location,
              settings: settings,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(() => _previewFuture = null),
                  icon: const AppIcon(Icons.refresh_rounded),
                  label: const Text('Retry prayer preview'),
                );
              }
              final daily = snapshot.data;
              if (daily == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: [
                  for (final entry in daily.entries)
                    _SummaryRow(
                      label: entry.displayName,
                      value: TimeOfDay.fromDateTime(entry.time).format(context),
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

  Future<void> _chooseTranslation(QuranTranslationResource? selected) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final resource = await showModalBottomSheet<QuranTranslationResource>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => QuranTranslationPicker(
          repository: _translationRepository,
          currentResource: selected,
        ),
      );
      if (resource != null &&
          mounted &&
          await _ensureTranslationDownloaded(resource) &&
          mounted) {
        setState(() => _selectedTranslationId = resource.id);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not prepare translation. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _ensureTranslationDownloaded(
    QuranTranslationResource resource,
  ) async {
    final available = await _translationRepository.hasFullTranslation(
      resource.id,
    );
    if (!mounted) return false;
    if (available) return true;
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QuranTranslationDownloadSheet(
            repository: _translationRepository,
            resource: resource,
            activateOnComplete: false,
          ),
        ) ==
        true;
  }

  Future<bool> _prepareSelectedTranslation() async {
    List<QuranTranslationLanguage> languages;
    try {
      languages = await _translationLanguagesFuture;
    } catch (_) {
      // Bundled English remains usable if the catalog is unavailable.
      if (_selectedTranslationId == 0) return true;
      rethrow;
    }
    if (!mounted) return false;
    if (_selectedTranslationId == 0) return true;
    for (final language in languages) {
      for (final resource in language.availableResources) {
        if (resource.id == _selectedTranslationId) {
          return _ensureTranslationDownloaded(resource);
        }
      }
    }
    throw StateError('Selected translation is unavailable.');
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      // Suggested and restored choices must be ready too, even without a picker tap.
      if ((_step == 1 || _step == _stepCount - 1) &&
          !await _prepareSelectedTranslation()) {
        return;
      }
      if (!mounted) return;
      if (_step < _stepCount - 1) {
        _previewFuture = null;
        final next = _step + 1;
        if (!widget.editMode) {
          await _store.setOnboardingStep(next);
        }
        if (mounted) setState(() => _step = next);
        return;
      }
      await _finish();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not prepare setup. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    _scriptLookupRevision++;
    final themeCubit = context.read<QuranThemeCubit>();
    try {
      await _prayerRepository.saveLocation(_location);
      await _prayerRepository.saveSettings(
        PrayerCalculationSettings(method: _method, asrMadhab: _madhab),
      );
      await _translationRepository.setSelectedTranslation(
        _selectedTranslationId == 0 ? null : _selectedTranslationId,
      );
      await _store.setReadingIntent(_readingIntent);
      await themeCubit.setQuranArabicScript(
        _script,
        automatic: !_scriptChosenManually,
      );
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
    if (city == null || !mounted) {
      return;
    }
    _scriptLookupRevision++;
    _applyScriptSuggestion(city.countryCode, 'selected city');
    setState(() {
      _location = city.toPrayerLocation();
      _locationConfirmed = true;
      _message = null;
      _saving = true;
    });
    try {
      if (!widget.editMode) {
        await _prayerRepository.saveLocation(_location);
        await _store.setOnboardingLocationConfirmed(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not save location. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
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
      if (proceed == false && mounted) {
        await _chooseCity();
      }
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    _scriptLookupRevision++;
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
      _applyScriptSuggestion(nearest?.countryCode, 'location');
      setState(() {
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
      if (!widget.editMode) {
        await _prayerRepository.saveLocation(_location);
        await _store.setOnboardingLocationConfirmed(true);
      }
      if (mounted) setState(() => _saving = false);
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

class _StepPanel extends StatelessWidget {
  const _StepPanel({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            const Positioned.fill(
              child: ArchitecturalBackdrop(prominent: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Row(
                children: [
                  AppIcon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.72),
              height: 1.45,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ],
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
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context, 0.66),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
  bool _failed = false;

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
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final cities = await widget.cityDataSource.search(value);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _cities = cities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Choose prayer city',
      scrollableChild: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search city or country',
              prefixIcon: AppIcon(Icons.search_rounded),
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _failed
                ? TextButton.icon(
                    onPressed: () => _search(_controller.text),
                    icon: const AppIcon(Icons.refresh_rounded),
                    label: const Text('Cities could not be loaded. Retry'),
                  )
                : _cities.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No cities found'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _cities.length,
                    itemBuilder: (context, index) {
                      final city = _cities[index];
                      return ListTile(
                        title: Text(city.name),
                        subtitle: Text(city.subtitle),
                        trailing: const AppIcon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
