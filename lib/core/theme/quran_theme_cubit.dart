import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/settings_store.dart';
import 'quran_theme.dart';
import 'quran_theme_state.dart';

class QuranThemeCubit extends Cubit<QuranThemeState> {
  QuranThemeCubit({required SettingsStore settingsStore})
    : _settingsStore = settingsStore,
      super(
        QuranThemeState(
          mode: QuranTheme.modeFromName(settingsStore.themeMode),
          presetId: settingsStore.themePresetId,
          fontScale: settingsStore.fontScale,
          fontWeightScale: settingsStore.fontWeightScale,
          quranArabicFontScale: settingsStore.quranArabicFontScale,
          quranTranslationFontScale: settingsStore.quranTranslationFontScale,
        ),
      ) {
    _normalizeInitialPreset();
  }

  final SettingsStore _settingsStore;

  QuranThemePreset get selectedPreset => QuranTheme.presetById(state.presetId);

  Future<void> setPreset(String presetId) async {
    final preset = QuranTheme.presetById(presetId);
    emit(state.copyWith(mode: preset.mode, presetId: preset.id));
    await _settingsStore.setThemeMode(preset.mode.name);
    await _settingsStore.setThemePresetId(preset.id);
  }

  Future<void> setFontScale(double value) async {
    final next = value.clamp(0.88, 1.28).toDouble();
    emit(state.copyWith(fontScale: next));
    await _settingsStore.setFontScale(next);
  }

  Future<void> setFontWeightScale(double value) async {
    final next = value.clamp(0.72, 1.08).toDouble();
    emit(state.copyWith(fontWeightScale: next));
    await _settingsStore.setFontWeightScale(next);
  }

  Future<void> setQuranArabicFontScale(double value) async {
    final next = value.clamp(0.82, 1.42).toDouble();
    if (next == state.quranArabicFontScale) {
      return;
    }
    emit(state.copyWith(quranArabicFontScale: next));
    await _settingsStore.setQuranArabicFontScale(next);
  }

  Future<void> setQuranTranslationFontScale(double value) async {
    final next = value.clamp(0.82, 1.42).toDouble();
    if (next == state.quranTranslationFontScale) {
      return;
    }
    emit(state.copyWith(quranTranslationFontScale: next));
    await _settingsStore.setQuranTranslationFontScale(next);
  }

  void _normalizeInitialPreset() {
    final preset = QuranTheme.presetById(state.presetId);
    if (preset.id != state.presetId || preset.mode != state.mode) {
      emit(state.copyWith(mode: preset.mode, presetId: preset.id));
    }
  }
}
