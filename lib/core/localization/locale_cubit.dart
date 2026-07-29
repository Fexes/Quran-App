import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/settings_store.dart';
import 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({required SettingsStore settingsStore})
    : _settingsStore = settingsStore,
      super(_stateFor(_normalize(settingsStore.localeCode)));

  static const supportedLanguageCodes = ['system', 'en', 'ur', 'ar'];

  final SettingsStore _settingsStore;

  Future<void> setLocale(String languageCode) async {
    final next = _normalize(languageCode);
    emit(_stateFor(next));
    await _settingsStore.setLocaleCode(next);
  }

  static String _normalize(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (supportedLanguageCodes.contains(normalized)) {
      return normalized;
    }
    return 'en';
  }

  static LocaleState _stateFor(String preference) {
    return LocaleState(
      locale: Locale(preference == 'system' ? 'en' : preference),
      followSystem: preference == 'system',
    );
  }
}
