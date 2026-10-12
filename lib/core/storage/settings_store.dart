import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class SettingsStore {
  SettingsStore._box(this._box, {required bool isFreshInstall})
    : _memory = null,
      _isFreshInstall = isFreshInstall;

  SettingsStore.memory([Map<String, Object?>? values])
    : _box = null,
      _memory = Map<String, Object?>.from(values ?? const {}),
      _isFreshInstall = false;

  final Box<dynamic>? _box;
  final Map<String, Object?>? _memory;
  final bool _isFreshInstall;

  static const _themeModeKey = 'theme_mode';
  static const _themePresetIdKey = 'theme_preset_id';
  static const _fontScaleKey = 'font_scale';
  static const _fontWeightScaleKey = 'font_weight_scale';
  static const _quranArabicFontScaleKey = 'quran_arabic_font_scale';
  static const _quranArabicScriptKey = 'quran_arabic_script';
  static const _quranTranslationFontScaleKey = 'quran_translation_font_scale';
  static const _quranTranslationVisibleKey = 'quran_translation_visible';
  static const _libraryTranslationEnabledKey = 'library_translation_enabled';
  static const _libraryTransliterationEnabledKey =
      'library_transliteration_enabled';
  static const _libraryHadithExplanationEnabledKey =
      'library_hadith_explanation_enabled';
  static const _localeCodeKey = 'locale_code';
  static const _tafsirLanguageNameKey = 'tafsir_language_name';
  static const _tafsirResourceIdKey = 'tafsir_resource_id';
  static const _wordMeaningLanguageCodeKey = 'word_meaning_language_code';
  static const _audioMeaningLanguageCodeKey = 'audio_meaning_language_code';
  static const _hadithLanguageCodeKey = 'hadith_language_code';
  static const _azkarLanguageCodeKey = 'azkar_language_code';
  static const _contentLocaleSuggestionAppliedKey =
      'content_locale_suggestion_applied';
  static const _onboardingStartedKey = 'onboarding_started';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _onboardingStepKey = 'onboarding_step';
  static const _onboardingLocationConfirmedKey =
      'onboarding_location_confirmed';
  static const _readingIntentKey = 'reading_intent';
  static const _prayerMethodKey = 'prayer_method';
  static const _prayerAsrMadhabKey = 'prayer_asr_madhab';
  static const _prayerLocationNameKey = 'prayer_location_name';
  static const _prayerLatitudeKey = 'prayer_latitude';
  static const _prayerLongitudeKey = 'prayer_longitude';
  static const _prayerTimeZoneKey = 'prayer_timezone';
  static const _prayerAlertEnabledPrayerNamesKey =
      'prayer_alert_enabled_prayer_names';
  static const _prayerAlertAtPrayerTimeKey = 'prayer_alert_at_prayer_time';
  static const _prayerAlertBeforePrayerKey = 'prayer_alert_before_prayer';
  static const _prayerAlertBeforeMinutesKey = 'prayer_alert_before_minutes';
  static const _prayerAlertIncludeSunriseKey = 'prayer_alert_include_sunrise';
  static const _audioAutoCachePlayedAyahsKey = 'audio_auto_cache_played_ayahs';
  static const _audioWifiOnlyLargeDownloadsKey =
      'audio_wifi_only_large_downloads';
  static const _audioPlayTranslationEnabledKey =
      'audio_play_translation_enabled';
  static const _audioTranslationReciterIdKey = 'audio_translation_reciter_id';
  static const _audioRestoreStateKey = 'audio_restore_state';
  static const _interlinearTranslationSkipVersionKey =
      'interlinear_translation_skip_version';
  static const _tasbiehCountKey = 'tasbieh_count';
  static const _tasbiehTargetKey = 'tasbieh_target';
  static const _tasbiehUpdatedAtKey = 'tasbieh_updated_at';
  static const _homeTileIdsKey = 'home_tile_ids';
  static const _homeCompanionTileIdsKey = 'home_companion_tile_ids';

  static Future<SettingsStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(AppConstants.settingsBoxName);
    return SettingsStore._box(box, isFreshInstall: box.isEmpty);
  }

  String get themeMode => _readString(_themeModeKey, 'light');
  List<String>? get homeTileIds {
    if (_read(_homeCompanionTileIdsKey) is List) {
      return _readStringList(_homeCompanionTileIdsKey, const []);
    }
    if (_read(_homeTileIdsKey) is! List) return null;
    // These cards were always visible below the legacy shortcut list.
    return {
      ..._readStringList(_homeTileIdsKey, const []),
      'todayReadingGoal',
      'dailyAyah',
    }.toList(growable: false);
  }

  Future<void> setHomeTileIds(List<String> ids) =>
      _write(_homeCompanionTileIdsKey, ids.toSet().toList(growable: false));
  String? get lastVerseShareBackgroundImage =>
      _readOptionalString('verse_share_background_image');
  Future<void> setLastVerseShareBackgroundImage(String assetPath) =>
      _write('verse_share_background_image', assetPath);
  String get themePresetId => _readString(_themePresetIdKey, 'white-glass');
  double get fontScale => _readDouble(_fontScaleKey, 1.0);
  double get fontWeightScale => _readDouble(_fontWeightScaleKey, 0.88);
  double get quranArabicFontScale => _readDouble(_quranArabicFontScaleKey, 1.0);
  String get quranArabicScript => _readString(_quranArabicScriptKey, 'uthmani');
  bool get hasManualArabicScript => _readBool(
    'quran_arabic_script_manual',
    _read(_quranArabicScriptKey) != null,
  );
  double get quranTranslationFontScale =>
      _readDouble(_quranTranslationFontScaleKey, 1.0);
  bool get quranTranslationVisible =>
      _readBool(_quranTranslationVisibleKey, true);
  bool get libraryTranslationEnabled =>
      _readBool(_libraryTranslationEnabledKey, true);
  bool get libraryTransliterationEnabled =>
      _readBool(_libraryTransliterationEnabledKey, true);
  bool get libraryHadithExplanationEnabled =>
      _readBool(_libraryHadithExplanationEnabledKey, false);
  String get localeCode => _readString(_localeCodeKey, 'en');
  String get tafsirLanguageName =>
      _readString(_tafsirLanguageNameKey, 'english');
  int? get tafsirResourceId {
    final value = _read(_tafsirResourceIdKey);
    return value is int && value > 0 ? value : null;
  }

  String get wordMeaningLanguageCode =>
      _readString(_wordMeaningLanguageCodeKey, 'en');
  String? get audioMeaningLanguageCodeOrNull =>
      _readOptionalString(_audioMeaningLanguageCodeKey);
  String get audioMeaningLanguageCode => audioMeaningLanguageCodeOrNull ?? 'en';
  String? get hadithLanguageCodeOrNull =>
      _readOptionalString(_hadithLanguageCodeKey);
  String get hadithLanguageCode => hadithLanguageCodeOrNull ?? 'en';
  String? get azkarLanguageCodeOrNull =>
      _readOptionalString(_azkarLanguageCodeKey);
  String get azkarLanguageCode => azkarLanguageCodeOrNull ?? 'en';
  bool get contentLocaleSuggestionApplied =>
      _readBool(_contentLocaleSuggestionAppliedKey, false);
  bool get onboardingComplete => _readBool(_onboardingCompleteKey, false);
  bool get onboardingStarted => _readBool(_onboardingStartedKey, false);
  int get onboardingStep => _readInt(_onboardingStepKey, 0).clamp(0, 5);
  bool get onboardingLocationConfirmed =>
      _readBool(_onboardingLocationConfirmedKey, false);
  String get readingIntent => _readString(_readingIntentKey, 'read');

  bool get shouldShowOnboarding {
    if (onboardingComplete) {
      return false;
    }
    return _isFreshInstall || onboardingStarted;
  }

  String get prayerMethod => _readString(_prayerMethodKey, 'karachi');
  String get prayerAsrMadhab => _readString(_prayerAsrMadhabKey, 'hanafi');
  String get prayerLocationName =>
      _readString(_prayerLocationNameKey, 'Karachi');
  double get prayerLatitude => _readDouble(_prayerLatitudeKey, 24.8607);
  double get prayerLongitude => _readDouble(_prayerLongitudeKey, 67.0011);
  String get prayerTimeZone => _readString(_prayerTimeZoneKey, 'Asia/Karachi');
  List<String> get prayerAlertEnabledPrayerNames =>
      _readStringList(_prayerAlertEnabledPrayerNamesKey, const []);
  bool get prayerAlertAtPrayerTime =>
      _readBool(_prayerAlertAtPrayerTimeKey, true);
  bool get prayerAlertBeforePrayer =>
      _readBool(_prayerAlertBeforePrayerKey, false);
  int get prayerAlertBeforeMinutes =>
      _readInt(_prayerAlertBeforeMinutesKey, 10);
  bool get prayerAlertIncludeSunrise =>
      _readBool(_prayerAlertIncludeSunriseKey, false);
  bool get audioAutoCachePlayedAyahs =>
      _readBool(_audioAutoCachePlayedAyahsKey, true);
  bool get audioWifiOnlyLargeDownloads =>
      _readBool(_audioWifiOnlyLargeDownloadsKey, true);
  bool get audioPlayTranslationEnabled =>
      _readBool(_audioPlayTranslationEnabledKey, false);
  String get audioTranslationReciterId =>
      _readString(_audioTranslationReciterIdKey, '');
  String translationVoiceForLanguage(String languageCode) =>
      _readString('translation_voice:${languageCode.toLowerCase()}', '');
  Map<String, Object?> get audioRestoreState =>
      _readStringObjectMap(_audioRestoreStateKey);
  String get interlinearTranslationSkipVersion =>
      _readString(_interlinearTranslationSkipVersionKey, '');
  int get tasbiehCount => _readInt(_tasbiehCountKey, 0).clamp(0, 999999);
  int get tasbiehTarget => _readInt(_tasbiehTargetKey, 33).clamp(1, 999999);
  DateTime? get tasbiehUpdatedAt {
    final raw = _read(_tasbiehUpdatedAtKey);
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Future<void> setThemeMode(String value) => _write(_themeModeKey, value);
  Future<void> setThemePresetId(String value) =>
      _write(_themePresetIdKey, value);
  Future<void> setFontScale(double value) => _write(_fontScaleKey, value);
  Future<void> setFontWeightScale(double value) =>
      _write(_fontWeightScaleKey, value);
  Future<void> setQuranArabicFontScale(double value) =>
      _write(_quranArabicFontScaleKey, value);
  Future<void> setQuranArabicScript(
    String value, {
    bool automatic = false,
  }) async {
    await _write(_quranArabicScriptKey, value);
    await _write('quran_arabic_script_manual', !automatic);
  }

  Future<void> setQuranTranslationFontScale(double value) =>
      _write(_quranTranslationFontScaleKey, value);
  Future<void> setQuranTranslationVisible(bool value) =>
      _write(_quranTranslationVisibleKey, value);
  Future<void> setLibraryTranslationEnabled(bool value) =>
      _write(_libraryTranslationEnabledKey, value);
  Future<void> setLibraryTransliterationEnabled(bool value) =>
      _write(_libraryTransliterationEnabledKey, value);
  Future<void> setLibraryHadithExplanationEnabled(bool value) =>
      _write(_libraryHadithExplanationEnabledKey, value);
  Future<void> setLocaleCode(String value) => _write(_localeCodeKey, value);
  Future<void> setTafsirPreference({
    required String languageName,
    int? resourceId,
  }) async {
    await _write(_tafsirLanguageNameKey, languageName);
    if (resourceId == null) {
      await _delete(_tafsirResourceIdKey);
    } else {
      await _write(_tafsirResourceIdKey, resourceId);
    }
  }

  Future<void> setWordMeaningLanguageCode(String value) =>
      _write(_wordMeaningLanguageCodeKey, value);
  Future<void> setAudioMeaningLanguageCode(String value) async {
    final code = value.trim().toLowerCase();
    final previous = audioMeaningLanguageCodeOrNull;
    if (previous == code) return;
    if (previous != null && audioTranslationReciterId.isNotEmpty) {
      await _write('translation_voice:$previous', audioTranslationReciterId);
    }
    await _write(_audioMeaningLanguageCodeKey, code);
    final saved = translationVoiceForLanguage(code);
    await _write(
      _audioTranslationReciterIdKey,
      code.isEmpty
          ? ''
          : saved.isNotEmpty
          ? saved
          : previous == null
          ? audioTranslationReciterId
          : '',
    );
  }

  Future<void> setHadithLanguageCode(String value) =>
      _write(_hadithLanguageCodeKey, value);
  Future<void> setAzkarLanguageCode(String value) =>
      _write(_azkarLanguageCodeKey, value);
  Future<void> setContentLocaleSuggestionApplied(bool value) =>
      _write(_contentLocaleSuggestionAppliedKey, value);
  Future<void> setOnboardingStep(int value) async {
    await _write(_onboardingStartedKey, true);
    await _write(_onboardingCompleteKey, false);
    await _write(_onboardingStepKey, value.clamp(0, 5));
  }

  Future<void> setOnboardingLocationConfirmed(bool value) =>
      _write(_onboardingLocationConfirmedKey, value);

  Future<void> setReadingIntent(String value) =>
      _write(_readingIntentKey, value);

  Future<void> completeOnboarding() async {
    await _write(_onboardingStartedKey, true);
    await _write(_onboardingCompleteKey, true);
    await _write(_onboardingStepKey, 5);
  }

  Map<String, Object?> exportSnapshot() {
    return {for (final key in _keys()) key: _read(key)};
  }

  Future<void> restoreSnapshot(
    Map<String, Object?> values, {
    required bool replace,
  }) async {
    if (replace) {
      await _clear();
    }
    for (final entry in values.entries) {
      if (entry.value != null) {
        await _write(entry.key, entry.value!);
      }
    }
  }

  Future<void> clearAll() => _clear();

  Future<void> setPrayerMethod(String value) => _write(_prayerMethodKey, value);
  Future<void> setPrayerAsrMadhab(String value) =>
      _write(_prayerAsrMadhabKey, value);
  Future<void> setPrayerLocation({
    required String name,
    required double latitude,
    required double longitude,
    required String timeZone,
  }) async {
    await _write(_prayerLocationNameKey, name);
    await _write(_prayerLatitudeKey, latitude);
    await _write(_prayerLongitudeKey, longitude);
    await _write(_prayerTimeZoneKey, timeZone);
  }

  Future<void> setPrayerAlertSettings({
    required List<String> enabledPrayerNames,
    required bool notifyAtPrayerTime,
    required bool notifyBeforePrayer,
    required int beforeMinutes,
    required bool includeSunrise,
  }) async {
    await _write(_prayerAlertEnabledPrayerNamesKey, enabledPrayerNames);
    await _write(_prayerAlertAtPrayerTimeKey, notifyAtPrayerTime);
    await _write(_prayerAlertBeforePrayerKey, notifyBeforePrayer);
    await _write(_prayerAlertBeforeMinutesKey, beforeMinutes);
    await _write(_prayerAlertIncludeSunriseKey, includeSunrise);
  }

  Future<void> setAudioAutoCachePlayedAyahs(bool value) =>
      _write(_audioAutoCachePlayedAyahsKey, value);

  Future<void> setAudioWifiOnlyLargeDownloads(bool value) =>
      _write(_audioWifiOnlyLargeDownloadsKey, value);

  Future<void> setAudioPlayTranslationEnabled(bool value) =>
      _write(_audioPlayTranslationEnabledKey, value);

  Future<void> setAudioTranslationReciterId(
    String value, {
    String? languageCode,
  }) async {
    await _write(_audioTranslationReciterIdKey, value);
    final code = languageCode ?? audioMeaningLanguageCodeOrNull;
    if (code != null && value.isNotEmpty) {
      await _write('translation_voice:${code.toLowerCase()}', value);
    }
  }

  Future<void> setAudioRestoreState(Map<String, Object?> value) =>
      _write(_audioRestoreStateKey, value);

  Future<void> clearAudioRestoreState() => _delete(_audioRestoreStateKey);

  Future<void> setInterlinearTranslationSkipVersion(String value) =>
      _write(_interlinearTranslationSkipVersionKey, value);

  Future<void> setTasbiehState({
    required int count,
    required int target,
    required DateTime updatedAt,
  }) async {
    await _write(_tasbiehCountKey, count.clamp(0, 999999));
    await _write(_tasbiehTargetKey, target.clamp(1, 999999));
    await _write(_tasbiehUpdatedAtKey, updatedAt.toIso8601String());
  }

  String _readString(String key, String fallback) {
    final value = _read(key);
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  String? _readOptionalString(String key) {
    final value = _read(key);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  double _readDouble(String key, double fallback) {
    final value = _read(key);
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return fallback;
  }

  int _readInt(String key, int fallback) {
    final value = _read(key);
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return fallback;
  }

  bool _readBool(String key, bool fallback) {
    final value = _read(key);
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  List<String> _readStringList(String key, List<String> fallback) {
    final value = _read(key);
    if (value is List) {
      return [
        for (final item in value)
          if (item is String && item.trim().isNotEmpty) item,
      ];
    }
    return fallback;
  }

  Map<String, Object?> _readStringObjectMap(String key) {
    final value = _read(key);
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    }
    return const {};
  }

  Object? _read(String key) {
    final box = _box;
    if (box != null) {
      return box.get(key);
    }
    return _memory?[key];
  }

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) {
      await box.put(key, value);
      return;
    }
    _memory?[key] = value;
  }

  Future<void> _delete(String key) async {
    final box = _box;
    if (box != null) {
      await box.delete(key);
      return;
    }
    _memory?.remove(key);
  }

  Iterable<String> _keys() {
    final box = _box;
    if (box != null) {
      return box.keys.whereType<String>();
    }
    return _memory?.keys ?? const [];
  }

  Future<void> _clear() async {
    final box = _box;
    if (box != null) {
      await box.clear();
    } else {
      _memory?.clear();
    }
  }
}
