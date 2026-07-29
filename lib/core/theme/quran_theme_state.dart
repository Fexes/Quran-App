import 'package:equatable/equatable.dart';

enum QuranThemeMode { light, dark, black }

class QuranThemeState extends Equatable {
  const QuranThemeState({
    required this.mode,
    required this.presetId,
    required this.fontScale,
    required this.fontWeightScale,
    required this.quranArabicFontScale,
    required this.quranTranslationFontScale,
  });

  final QuranThemeMode mode;
  final String presetId;
  final double fontScale;
  final double fontWeightScale;
  final double quranArabicFontScale;
  final double quranTranslationFontScale;

  QuranThemeState copyWith({
    QuranThemeMode? mode,
    String? presetId,
    double? fontScale,
    double? fontWeightScale,
    double? quranArabicFontScale,
    double? quranTranslationFontScale,
  }) {
    return QuranThemeState(
      mode: mode ?? this.mode,
      presetId: presetId ?? this.presetId,
      fontScale: fontScale ?? this.fontScale,
      fontWeightScale: fontWeightScale ?? this.fontWeightScale,
      quranArabicFontScale: quranArabicFontScale ?? this.quranArabicFontScale,
      quranTranslationFontScale:
          quranTranslationFontScale ?? this.quranTranslationFontScale,
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
  ];
}
