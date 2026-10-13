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
import '../../../../core/widgets/animated_expansion.dart';
import '../../../prayer/data/datasources/offline_prayer_city_data_source.dart';
import '../../../prayer/data/services/prayer_alert_notification_service.dart';
import '../../../prayer/domain/entities/prayer_alert_settings.dart';
import '../../../prayer_times/domain/entities/daily_prayer_times.dart';
import '../../../prayer_times/domain/entities/prayer_calculation_settings.dart';
import '../../../prayer_times/domain/entities/prayer_location.dart';
import '../../../prayer_times/domain/entities/prayer_time_entry.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_translation.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran/domain/repositories/quran_translation_repository.dart';
import '../../../quran/presentation/widgets/quran_translation_download_sheet.dart';
import '../../../quran/presentation/widgets/quran_reading_preferences.dart';
import '../../../quran_audio/domain/services/quran_translation_audio_selector.dart';
import '../../../quran_audio/presentation/cubit/quran_audio_cubit.dart';
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
  late final QuranRepository _quranRepository;
  late final OfflinePrayerCityDataSource _cityDataSource;
  late Future<List<QuranTranslationLanguage>> _translationLanguagesFuture;
  Future<DailyPrayerTimes>? _previewFuture;

  late int _step;
  late PrayerLocation _location;
  late PrayerCalculationMethod _method;
  late PrayerAsrMadhab _madhab;
  late bool _locationConfirmed;
  bool _enableNotifications = false;
  late PrayerAlertSettings _alertSettings;
  bool _notificationPermissionGranted = false;
  bool _movingForward = true;
  bool _leaving = false;
  QuranTranslationResource? _selectedTranslation;
  bool _translationSkipped = false;
  int? _preparedTranslationId;
  QuranAudioReciter? _selectedReciter;
  QuranAudioReciter? _selectedTranslationVoice;
  List<QuranAudioReciter> _reciters = const [];
  bool _loadingReadingPreferences = true;
  bool _readingPreferencesLoadFailed = false;
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
    _quranRepository = getIt<QuranRepository>();
    _cityDataSource = getIt<OfflinePrayerCityDataSource>();
    _step = widget.editMode ? 0 : _store.onboardingStep;
    _location = PrayerLocation(
      name: _store.prayerLocationName,
      latitude: _store.prayerLatitude,
      longitude: _store.prayerLongitude,
      timeZone: _store.prayerTimeZone,
      usesDeviceLocation: _store.prayerLocationUsesDevice,
    );
    _method = _methodFromName(_store.prayerMethod);
    _madhab = _madhabFromName(_store.prayerAsrMadhab);
    _locationConfirmed = widget.editMode || _store.onboardingLocationConfirmed;
    _enableNotifications = _store.prayerAlertEnabledPrayerNames.isNotEmpty;
    _alertSettings = PrayerAlertSettings.fromStored(
      enabledPrayerNames: _store.prayerAlertEnabledPrayerNames,
      notifyAtPrayerTime: _store.prayerAlertAtPrayerTime,
      notifyBeforePrayer: _store.prayerAlertBeforePrayer,
      beforeMinutes: _store.prayerAlertBeforeMinutes,
      includeSunrise: _store.prayerAlertIncludeSunrise,
    );
    if (_alertSettings.enabledPrayerNames.isEmpty) {
      _alertSettings = _alertSettings.withAllCorePrayers(true);
    }
    _translationLanguagesFuture = _loadTranslationLanguages();
    if (!widget.editMode) {
      unawaited(_store.setOnboardingStep(_step));
      unawaited(_suggestScript());
    }
  }

  Future<List<QuranTranslationLanguage>> _loadTranslationLanguages() async {
    _readingPreferencesLoadFailed = false;
    try {
      final selected = await _translationRepository.selectedTranslation();
      List<QuranAudioReciter> reciters;
      String? savedReciterId;
      try {
        reciters = await _quranRepository.getAudioReciters();
        savedReciterId = await _quranRepository.getSelectedAudioReciterId();
      } catch (_) {
        reciters = const [];
      }
      final arabicReciters = reciters.where((item) => !item.isTranslation);
      final selectedReciter = arabicReciters
          .where((item) => item.id == savedReciterId)
          .firstOrNull;
      if (mounted) {
        setState(() {
          _reciters = reciters;
          if (_step > 1 &&
              !_translationSkipped &&
              _selectedTranslation == null) {
            _selectedTranslation = selected;
            _preparedTranslationId = selected?.id;
            _translationSkipped =
                selected == null && !_store.quranTranslationVisible;
          }
          _selectedReciter = selectedReciter ?? arabicReciters.firstOrNull;
          _selectedTranslationVoice = _preferredTranslationVoice(
            _selectedTranslation,
          );
        });
      }
      final languages = await _translationRepository.translationLanguages();
      return languages;
    } catch (_) {
      if (mounted) setState(() => _readingPreferencesLoadFailed = true);
      return const [];
    } finally {
      if (mounted) setState(() => _loadingReadingPreferences = false);
    }
  }

  QuranAudioReciter? _preferredTranslationVoice(
    QuranTranslationResource? translation,
  ) {
    return preferredQuranTranslationVoice(
      quranCompatibleTranslationAudioReciters(
        reciters: _reciters,
        selectedTranslation: translation,
      ),
      preferredId: _store.translationVoiceForLanguage(
        translation?.resolvedLanguageCode ?? '',
      ),
      legacyId: _store.audioTranslationReciterId,
    );
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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
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
            if (_step == 1)
              TextButton(
                onPressed: _saving ? null : _skipTranslation,
                child: const Text('Skip'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: (_step + 1) / _stepCount),
                      duration: reducedMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(999),
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    fit: StackFit.expand,
                    children: [...previousChildren, ?currentChild],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      textDirection: Directionality.of(context),
                      position: animation.drive(
                        Tween<Offset>(
                          begin: Offset(_movingForward ? 0.06 : -0.06, 0),
                          end: Offset.zero,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _stepContent(),
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
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      0 => _languageStep(),
      1 => _translationStep(),
      2 => _locationStep(),
      3 => _calculationStep(),
      4 => _scriptAndNotificationsStep(),
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
      icon: Icons.menu_book_rounded,
      title: 'Reading and listening',
      description:
          'Choose your translation language and reciter. We choose the translation for you, with matching audio where available.',
      child: FutureBuilder<List<QuranTranslationLanguage>>(
        future: _translationLanguagesFuture,
        builder: (context, snapshot) {
          if (_loadingReadingPreferences) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_readingPreferencesLoadFailed) ...[
                const Text(
                  'Your translation choices could not be loaded. You can keep your current choice or try again.',
                ),
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _loadingReadingPreferences = true;
                          _translationLanguagesFuture =
                              _loadTranslationLanguages();
                        }),
                  icon: const AppIcon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 12),
              ],
              QuranReadingPreferences(
                translation: _selectedTranslation,
                requireLanguageSelection: true,
                arabicReciterFirst: true,
                reciterId: _selectedReciter?.id,
                translationVoiceId: _selectedTranslationVoice?.id,
                enabled: !_saving,
                onTranslationChanged: (translation) => setState(() {
                  _selectedTranslation = translation;
                  _translationSkipped = false;
                  _preparedTranslationId = null;
                  _selectedTranslationVoice = _preferredTranslationVoice(
                    translation,
                  );
                  _message = null;
                }),
                onReciterChanged: (reciter) => setState(() {
                  _selectedReciter = reciter;
                  _message = null;
                }),
                onTranslationVoiceChanged: (voice) => setState(() {
                  _selectedTranslationVoice = voice;
                }),
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

  Widget _scriptAndNotificationsStep() {
    return _StepPanel(
      icon: Icons.tune_rounded,
      title: 'Personalize your journey',
      description: 'Choose your Arabic script and prayer reminders.',
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
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enableNotifications,
            onChanged: _saving
                ? null
                : (value) {
                    setState(() => _enableNotifications = value);
                  },
            secondary: const AppIcon(Icons.notifications_rounded),
            title: const Text('Prayer notifications'),
            subtitle: const Text(
              'Choose the prayers and reminder times below.',
            ),
          ),
          AnimatedExpansion(
            expanded: _enableNotifications,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 24),
                for (final prayer in PrayerAlertSettings.corePrayerNames)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_prayerName(prayer)),
                    value: _alertSettings.isEnabledFor(prayer),
                    onChanged: _saving
                        ? null
                        : (enabled) => setState(() {
                            _alertSettings = _alertSettings.withPrayer(
                              prayer,
                              enabled,
                            );
                          }),
                  ),
                const Divider(height: 24),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('At prayer time'),
                  value: _alertSettings.notifyAtPrayerTime,
                  onChanged: _saving
                      ? null
                      : (enabled) => setState(() {
                          _alertSettings = _alertSettings.copyWith(
                            notifyAtPrayerTime: enabled,
                          );
                        }),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Before prayer'),
                  value: _alertSettings.notifyBeforePrayer,
                  onChanged: _saving
                      ? null
                      : (enabled) => setState(() {
                          _alertSettings = _alertSettings.copyWith(
                            notifyBeforePrayer: enabled,
                          );
                        }),
                ),
                AnimatedExpansion(
                  expanded: _alertSettings.notifyBeforePrayer,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final minutes in [5, 10, 15, 30])
                          ChoiceChip(
                            label: Text('$minutes min'),
                            selected: _alertSettings.beforeMinutes == minutes,
                            onSelected: _saving
                                ? null
                                : (_) => setState(() {
                                    _alertSettings = _alertSettings.copyWith(
                                      beforeMinutes: minutes,
                                    );
                                  }),
                          ),
                      ],
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
          _SummaryRow(
            label: 'Translation',
            value: _selectedTranslation?.displayEndonym ?? 'Off',
          ),
          _SummaryRow(
            label: 'Reciter',
            value: _selectedReciter?.name ?? 'Default reciter',
          ),
          if (_selectedTranslationVoice != null)
            _SummaryRow(
              label: 'Translation voice',
              value: _selectedTranslationVoice!.name,
            ),
          _SummaryRow(label: 'Arabic script', value: _script.label),
          _SummaryRow(
            label: 'Notifications',
            value: _enableNotifications && _notificationPermissionGranted
                ? '${_alertSettings.activePrayerCount} prayers enabled'
                : 'Off',
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

  bool get _canContinue =>
      (_step != 2 || _locationConfirmed) &&
      (_step != 1 || _selectedTranslation != null) &&
      ((_step != 1 && _step != _stepCount - 1) ||
          _translationSkipped ||
          !_loadingReadingPreferences);

  Future<bool> _ensureTranslationDownloaded(
    QuranTranslationResource resource,
  ) async {
    if (_preparedTranslationId == resource.id &&
        await _translationRepository.hasFullTranslation(resource.id)) {
      return true;
    }
    if (!mounted) return false;
    final result = await showModalBottomSheet<bool>(
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
        showContinueWhileDownloading: _step != 1,
      ),
    );
    final quranReady =
        result == true ||
        await _translationRepository.hasFullTranslation(resource.id);
    if (quranReady) _preparedTranslationId = resource.id;
    return quranReady;
  }

  Future<bool> _prepareSelectedTranslation() async {
    final resource = _selectedTranslation;
    if (resource == null) return true;
    return _ensureTranslationDownloaded(resource);
  }

  Future<void> _saveReadingPreferences() async {
    final translation = _selectedTranslation;
    await _store.setQuranTranslationVisible(translation != null);
    await _store.setLibraryTranslationEnabled(translation != null);
    await _store.setHadithLanguageCode(translation?.resolvedLanguageCode ?? '');
    await _store.setAzkarLanguageCode(translation?.resolvedLanguageCode ?? '');
    if (translation == null) await _store.setAudioPlayTranslationEnabled(false);
    await _store.setAudioMeaningLanguageCode(
      translation?.resolvedLanguageCode ?? '',
    );
    await _store.setAudioTranslationReciterId(
      _selectedTranslationVoice?.id ?? '',
      languageCode: translation?.resolvedLanguageCode,
    );
    final previous = await _translationRepository.selectedTranslation();
    if (previous?.id != translation?.id) {
      await _translationRepository.setSelectedTranslation(translation?.id);
    }
    final reciter = _selectedReciter;
    if (reciter != null) {
      await _quranRepository.saveSelectedAudioReciterId(reciter.id);
    }
  }

  void _skipTranslation() {
    if (_saving || _leaving || _step != 1) return;
    setState(() {
      _selectedTranslation = null;
      _selectedTranslationVoice = null;
      _translationSkipped = true;
      _preparedTranslationId = null;
    });
    unawaited(_continue(skipTranslation: true));
  }

  Future<void> _continue({bool skipTranslation = false}) async {
    if (_saving || _leaving) return;
    if (_step == 1 && !skipTranslation && !_canContinue) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      // Quran text is required; optional downloads must not block setup.
      if ((_step == 1 || _step == _stepCount - 1) &&
          !await _prepareSelectedTranslation()) {
        return;
      }
      if (!mounted) return;
      if (_step == 1 && !widget.editMode) {
        await _saveReadingPreferences();
        await _store.setContentLocaleSuggestionApplied(true);
      }
      if (!mounted) return;
      if (_step >= 4 &&
          _enableNotifications &&
          _alertSettings.schedulesAnything &&
          !_notificationPermissionGranted) {
        if (getIt.isRegistered<PrayerAlertNotificationService>()) {
          final allowed = await getIt<PrayerAlertNotificationService>()
              .requestPermissions();
          if (!mounted) return;
          setState(() {
            _notificationPermissionGranted = allowed;
            if (!allowed) {
              _enableNotifications = false;
              _message =
                  'Notifications were not allowed. You can enable them later in Settings.';
            }
          });
        }
      }
      if (!mounted) return;
      if (_step == 4) {
        final alerts = _enableNotifications && _notificationPermissionGranted
            ? _alertSettings
            : PrayerAlertSettings.disabled();
        await _store.setPrayerAlertSettings(
          enabledPrayerNames: alerts.toStoredPrayerNames(),
          notifyAtPrayerTime: alerts.notifyAtPrayerTime,
          notifyBeforePrayer: alerts.notifyBeforePrayer,
          beforeMinutes: alerts.beforeMinutes,
          includeSunrise: alerts.includeSunrise,
        );
      }
      if (!mounted) return;
      if (_step < _stepCount - 1) {
        _previewFuture = null;
        final next = _step + 1;
        if (!widget.editMode) {
          await _store.setOnboardingStep(next);
        }
        if (mounted) {
          setState(() {
            _movingForward = true;
            _step = next;
          });
        }
        return;
      }
      await _finish();
    } catch (error, stack) {
      debugPrint('Onboarding setup failed: $error\n$stack');
      _leaving = false;
      if (mounted) {
        setState(() => _message = 'Could not prepare setup. Please try again.');
      }
    } finally {
      if (mounted && !_leaving) setState(() => _saving = false);
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
    setState(() {
      _movingForward = false;
      _step = previous;
    });
  }

  Future<void> _finish() async {
    _scriptLookupRevision++;
    final themeCubit = context.read<QuranThemeCubit>();
    final audioCubit = context.read<QuranAudioCubit>();
    final router = GoRouter.of(context);
    await _prayerRepository.saveLocation(_location);
    await _prayerRepository.saveSettings(
      PrayerCalculationSettings(method: _method, asrMadhab: _madhab),
    );
    await _saveReadingPreferences();
    if (!mounted) return;
    final reciter = _selectedReciter;
    if (reciter != null) await audioCubit.changeReciter(reciter.id);
    await audioCubit.synchronizeTranslationSelection();
    await themeCubit.setQuranArabicScript(
      _script,
      automatic: !_scriptChosenManually,
    );
    await _store.setContentLocaleSuggestionApplied(true);
    await _store.setOnboardingLocationConfirmed(true);

    if (getIt.isRegistered<PrayerAlertNotificationService>()) {
      await getIt<PrayerAlertNotificationService>().saveSettings(
        _enableNotifications && _notificationPermissionGranted
            ? _alertSettings
            : PrayerAlertSettings.disabled(),
      );
    }

    await _store.completeOnboarding();
    if (!mounted) {
      return;
    }
    _leaving = true;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) router.go(AppRoutes.shell);
  }

  static String _prayerName(PrayerTimeName prayer) => switch (prayer) {
    PrayerTimeName.fajr => 'Fajr',
    PrayerTimeName.sunrise => 'Sunrise',
    PrayerTimeName.dhuhr => 'Dhuhr',
    PrayerTimeName.asr => 'Asr',
    PrayerTimeName.maghrib => 'Maghrib',
    PrayerTimeName.isha => 'Isha',
  };

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
      if (!mounted) {
        return;
      }
      _applyScriptSuggestion(nearest?.countryCode, 'location');
      setState(() {
        _location = PrayerLocation(
          name: nearest?.name ?? 'Current location',
          latitude: position.latitude,
          longitude: position.longitude,
          timeZone: nearest?.timeZone ?? _location.timeZone,
          usesDeviceLocation: true,
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
