import 'package:equatable/equatable.dart';

import '../constants/quran_arabic_script.dart';

enum QuranThemeMode { light, dark }

class QuranThemeState extends Equatable {
  const QuranThemeState({
    required this.mode,
    required this.presetId,
    required this.fontScale,
    required this.fontWeightScale,
    required this.quranArabicFontScale,
    required this.quranTranslationFontScale,
    this.quranArabicScript = QuranArabicScript.uthmani,
  });

  final QuranThemeMode mode;
  final String presetId;
  final double fontScale;
  final double fontWeightScale;
  final double quranArabicFontScale;
  final double quranTranslationFontScale;
  final QuranArabicScript quranArabicScript;

  QuranThemeState copyWith({
    QuranThemeMode? mode,
    String? presetId,
    double? fontScale,
    double? fontWeightScale,
    double? quranArabicFontScale,
    double? quranTranslationFontScale,
    QuranArabicScript? quranArabicScript,
  }) {
    return QuranThemeState(
      mode: mode ?? this.mode,
      presetId: presetId ?? this.presetId,
      fontScale: fontScale ?? this.fontScale,
      fontWeightScale: fontWeightScale ?? this.fontWeightScale,
      quranArabicFontScale: quranArabicFontScale ?? this.quranArabicFontScale,
      quranTranslationFontScale:
          quranTranslationFontScale ?? this.quranTranslationFontScale,
      quranArabicScript: quranArabicScript ?? this.quranArabicScript,
    );
  }

  @override
  List<Object> get props => [
    mode,
    presetId,
    fontScale,
    fontWeightScale,
    quranArabicFontScale,
    quranTranslationFontScale,
    quranArabicScript,
  ];
}
