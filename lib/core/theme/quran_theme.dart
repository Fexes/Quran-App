import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/quran_arabic_script.dart';
import 'quran_theme_state.dart';

@immutable
class QuranThemePreset {
  const QuranThemePreset({
    required this.id,
    required this.name,
    required this.mode,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.text,
  });

  final String id;
  final String name;
  final QuranThemeMode mode;
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color text;
}

@immutable
class QuranSemanticColors extends ThemeExtension<QuranSemanticColors> {
  const QuranSemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accentSoft,
    required this.wordHighlight,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accentSoft;
  final Color wordHighlight;

  @override
  QuranSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? accentSoft,
    Color? wordHighlight,
  }) {
    return QuranSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      accentSoft: accentSoft ?? this.accentSoft,
      wordHighlight: wordHighlight ?? this.wordHighlight,
    );
  }

  @override
  QuranSemanticColors lerp(
    ThemeExtension<QuranSemanticColors>? other,
    double t,
  ) {
    if (other is! QuranSemanticColors) {
      return this;
    }

    return QuranSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      info: Color.lerp(info, other.info, t) ?? info,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      wordHighlight:
          Color.lerp(wordHighlight, other.wordHighlight, t) ?? wordHighlight,
    );
  }
}

class QuranTheme {
  const QuranTheme._();

  static const double radiusCard = 12;
  static const double radiusControl = 12;
  static const double radiusDock = 20;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  static const presets = [
    QuranThemePreset(
      id: 'white-glass',
      name: 'Light',
      mode: QuranThemeMode.light,
      primary: Color(0xFF202323),
      onPrimary: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceVariant: Color(0xFFF3F3F3),
      outline: Color(0xFFE7E7E7),
      text: Color(0xFF202323),
    ),
    QuranThemePreset(
      id: 'dark-minbar',
      name: 'Dark',
      mode: QuranThemeMode.dark,
      primary: Color(0xFFF3F3F3),
      onPrimary: Color(0xFF171717),
      background: Color(0xFF141414),
      surface: Color(0xFF191919),
      surfaceVariant: Color(0xFF252525),
      outline: Color(0xFF363636),
      text: Color(0xFFF3F3F3),
    ),
  ];

  static QuranThemePreset presetById(String id) {
    // Restore retired dark presets without changing the user's brightness.
    if (id == 'black-gold') return presets.last;
    return presets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => presets.first,
    );
  }

  static QuranThemeMode modeFromName(String value) {
    if (value == 'black') return QuranThemeMode.dark;
    return QuranThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => QuranThemeMode.light,
    );
  }

  static FontWeight weight(FontWeight weight, double fontWeightScale) {
    final scaled = (_weightToInt(weight) * fontWeightScale).round();
    return _intToWeight(scaled.clamp(100, 900));
  }

  static ThemeData buildTheme({
    required QuranThemePreset preset,
    required double fontWeightScale,
    QuranArabicScript arabicScript = QuranArabicScript.uthmani,
  }) {
    final brightness = preset.mode == QuranThemeMode.light
        ? Brightness.light
        : Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: preset.primary,
          brightness: brightness,
        ).copyWith(
          primary: preset.primary,
          onPrimary: preset.onPrimary,
          secondary: preset.primary,
          onSecondary: preset.onPrimary,
          secondaryContainer: preset.surfaceVariant,
          onSecondaryContainer: preset.text,
          surface: preset.surface,
          surfaceContainerHighest: preset.surfaceVariant,
          outline: preset.outline,
          onSurface: preset.text,
          error: brightness == Brightness.dark
              ? const Color(0xFFFF8A8A)
              : const Color(0xFFDC2626),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: preset.background,
      fontFamily: 'Manrope',
      fontFamilyFallback: [
        if (arabicScript.fontFamily != null) arabicScript.fontFamily!,
        'NotoSansArabic',
      ],
      visualDensity: VisualDensity.standard,
    );

    final textTheme = _scaleTextWeights(
      base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 22,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      fontWeightScale,
    ).apply(bodyColor: preset.text, displayColor: preset.text);
    final cardShadowColor = brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.32)
        : Colors.black.withValues(alpha: 0.10);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusControl),
      borderSide: BorderSide(color: preset.outline),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: preset.background,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: preset.text,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: weight(FontWeight.w600, fontWeightScale),
          letterSpacing: 0,
        ),
        systemOverlayStyle: systemUiOverlayStyle(preset.mode),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: preset.surface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minVerticalPadding: 10,
        iconColor: preset.text.withValues(alpha: 0.68),
        textColor: preset.text,
        selectedColor: preset.primary,
        selectedTileColor: preset.primary.withValues(
          alpha: brightness == Brightness.dark ? 0.18 : 0.09,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      dividerTheme: DividerThemeData(color: preset.outline, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: preset.primary, width: 1.3),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.3),
        ),
        labelStyle: TextStyle(color: preset.text.withValues(alpha: 0.68)),
        hintStyle: TextStyle(color: preset.text.withValues(alpha: 0.44)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          textStyle: TextStyle(
            fontWeight: weight(FontWeight.w500, fontWeightScale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          side: BorderSide(color: preset.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusControl),
          ),
          side: BorderSide(color: preset.outline),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: preset.surface,
        selectedColor: scheme.secondaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0),
        side: BorderSide(color: preset.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: preset.surface,
        modalBackgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
        elevation: brightness == Brightness.dark ? 0 : 10,
        shadowColor: cardShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
          side: BorderSide(color: preset.outline),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: preset.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: preset.primary,
        thumbColor: preset.primary,
      ),
      extensions: [
        QuranSemanticColors(
          success: brightness == Brightness.dark
              ? const Color(0xFF4ADE80)
              : const Color(0xFF16A34A),
          warning: brightness == Brightness.dark
              ? const Color(0xFFFBBF24)
              : const Color(0xFFD97706),
          error: scheme.error,
          info: brightness == Brightness.dark
              ? const Color(0xFF38BDF8)
              : const Color(0xFF0284C7),
          accentSoft: preset.primary.withValues(
            alpha: brightness == Brightness.dark ? 0.20 : 0.11,
          ),
          wordHighlight: _wordHighlightFor(preset, brightness),
        ),
      ],
    );
  }

  static Color _wordHighlightFor(
    QuranThemePreset preset,
    Brightness brightness,
  ) {
    if (preset.id == 'white-glass') {
      return const Color(0xFF8A5A00);
    }
    if (brightness == Brightness.dark) {
      return const Color(0xFFFFD166);
    }
    return preset.primary;
  }

  static SystemUiOverlayStyle systemUiOverlayStyle(QuranThemeMode mode) {
    final dark = mode != QuranThemeMode.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color surfaceVariant(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  static Color outline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color text(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color subText(BuildContext context, [double opacity = 0.68]) {
    return text(context).withValues(alpha: opacity);
  }

  static Color quranTextNormal(BuildContext context) {
    return text(context).withValues(alpha: isDark(context) ? 0.80 : 0.76);
  }

  static Color quranTextSelected(BuildContext context) {
    return isDark(context) ? const Color(0xFFF8FAFC) : Colors.black;
  }

  static QuranSemanticColors semantic(BuildContext context) {
    return Theme.of(context).extension<QuranSemanticColors>() ??
        const QuranSemanticColors(
          success: Color(0xFF16A34A),
          warning: Color(0xFFD97706),
          error: Color(0xFFDC2626),
          info: Color(0xFF0284C7),
          accentSoft: Color(0x1A0F766E),
          wordHighlight: Color(0xFF8A5A00),
        );
  }

  static Color wordHighlight(BuildContext context) {
    return semantic(context).wordHighlight;
  }

  static TextStyle translationStyle(TextStyle? style, String? languageCode) {
    final base = style ?? const TextStyle();
    final language = languageCode?.toLowerCase().split(RegExp('[-_]')).first;
    if (language != 'ur' && language != 'urdu') return base;
    return base.copyWith(
      fontFamily: 'NotoNastaliqUrdu',
      fontFamilyFallback: const ['NotoSansArabic'],
      height: math.max(base.height ?? 1, 2.15),
      letterSpacing: 0,
    );
  }

  static Color wordHighlighterFill(BuildContext context) {
    return wordHighlight(
      context,
    ).withValues(alpha: isDark(context) ? 0.24 : 0.16);
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color softFill(BuildContext context, [Color? color]) {
    final effective = color ?? Theme.of(context).colorScheme.primary;
    return effective.withValues(alpha: isDark(context) ? 0.18 : 0.10);
  }

  static Color glassTint(BuildContext context) {
    return surface(context).withValues(alpha: isDark(context) ? 0.76 : 0.88);
  }

  static Color glassBorder(BuildContext context) {
    return Colors.white.withValues(alpha: isDark(context) ? 0.18 : 0.72);
  }

  static List<BoxShadow> premiumShadow(
    BuildContext context, {
    bool prominent = false,
    bool compact = false,
  }) {
    if (isDark(context) && !prominent) {
      return const <BoxShadow>[];
    }

    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.26),
          blurRadius: 30,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
      ];
    }

    if (compact) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: prominent ? 0.09 : 0.025),
          blurRadius: prominent ? 22 : 10,
          spreadRadius: prominent ? -4 : -2,
          offset: Offset(0, prominent ? 8 : 4),
        ),
      ];
    }

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: prominent ? 0.10 : 0.03),
        blurRadius: prominent ? 26 : 12,
        spreadRadius: prominent ? -5 : -2,
        offset: Offset(0, prominent ? 12 : 4),
      ),
    ];
  }

  static List<BoxShadow> modalSheetShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark(context) ? 0.28 : 0.10),
        blurRadius: 28,
        spreadRadius: -5,
        offset: const Offset(0, -8),
      ),
    ];
  }

  static TextTheme _scaleTextWeights(
    TextTheme textTheme,
    double fontWeightScale,
  ) {
    return textTheme.copyWith(
      displayLarge: _scaleWeight(textTheme.displayLarge, fontWeightScale),
      displayMedium: _scaleWeight(textTheme.displayMedium, fontWeightScale),
      displaySmall: _scaleWeight(textTheme.displaySmall, fontWeightScale),
      headlineLarge: _scaleWeight(textTheme.headlineLarge, fontWeightScale),
      headlineMedium: _scaleWeight(textTheme.headlineMedium, fontWeightScale),
      headlineSmall: _scaleWeight(textTheme.headlineSmall, fontWeightScale),
      titleLarge: _scaleWeight(textTheme.titleLarge, fontWeightScale),
      titleMedium: _scaleWeight(textTheme.titleMedium, fontWeightScale),
      titleSmall: _scaleWeight(textTheme.titleSmall, fontWeightScale),
      bodyLarge: _scaleWeight(textTheme.bodyLarge, fontWeightScale),
      bodyMedium: _scaleWeight(textTheme.bodyMedium, fontWeightScale),
      bodySmall: _scaleWeight(textTheme.bodySmall, fontWeightScale),
      labelLarge: _scaleWeight(textTheme.labelLarge, fontWeightScale),
      labelMedium: _scaleWeight(textTheme.labelMedium, fontWeightScale),
      labelSmall: _scaleWeight(textTheme.labelSmall, fontWeightScale),
    );
  }

  static TextStyle? _scaleWeight(TextStyle? style, double fontWeightScale) {
    if (style == null) {
      return null;
    }
    return style.copyWith(
      fontWeight: weight(style.fontWeight ?? FontWeight.w400, fontWeightScale),
      letterSpacing: 0,
    );
  }

  static int _weightToInt(FontWeight weight) {
    if (weight == FontWeight.w100) return 100;
    if (weight == FontWeight.w200) return 200;
    if (weight == FontWeight.w300) return 300;
    if (weight == FontWeight.w400) return 400;
    if (weight == FontWeight.w500) return 500;
    if (weight == FontWeight.w600) return 600;
    if (weight == FontWeight.w700) return 700;
    if (weight == FontWeight.w800) return 800;
    if (weight == FontWeight.w900) return 900;
    return 400;
  }

  static FontWeight _intToWeight(int value) {
    final rounded = (math.max(100, math.min(900, value)) / 100).round() * 100;
    return switch (rounded) {
      100 => FontWeight.w100,
      200 => FontWeight.w200,
      300 => FontWeight.w300,
      400 => FontWeight.w400,
      500 => FontWeight.w500,
      600 => FontWeight.w600,
      700 => FontWeight.w700,
      800 => FontWeight.w800,
      _ => FontWeight.w900,
    };
  }
}
