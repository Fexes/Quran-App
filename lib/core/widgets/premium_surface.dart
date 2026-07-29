import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';

enum PremiumSurfaceShadowStyle { regular, subtle, none }

class PremiumSurfaceShadowScope extends InheritedWidget {
  const PremiumSurfaceShadowScope({
    super.key,
    required this.style,
    required super.child,
  });

  final PremiumSurfaceShadowStyle style;

  static PremiumSurfaceShadowStyle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PremiumSurfaceShadowScope>()
        ?.style;
  }

  @override
  bool updateShouldNotify(PremiumSurfaceShadowScope oldWidget) {
    return style != oldWidget.style;
  }
}

class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = QuranTheme.radiusCard,
    this.color,
    this.borderColor,
    this.prominent = false,
    this.clipBehavior = Clip.antiAlias,
    this.width,
    this.height,
    this.shadowStyle,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool prominent;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final PremiumSurfaceShadowStyle? shadowStyle;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);
    final effectiveBorder = borderColor ?? QuranTheme.outline(context);
    final effectiveShadowStyle =
        shadowStyle ??
        PremiumSurfaceShadowScope.maybeOf(context) ??
        PremiumSurfaceShadowStyle.regular;
    final shadows = switch (effectiveShadowStyle) {
      PremiumSurfaceShadowStyle.regular => QuranTheme.premiumShadow(
        context,
        prominent: prominent,
      ),
      PremiumSurfaceShadowStyle.subtle => QuranTheme.premiumShadow(
        context,
        prominent: prominent,
        compact: true,
      ),
      PremiumSurfaceShadowStyle.none => const <BoxShadow>[],
    };

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? QuranTheme.surface(context),
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder),
        boxShadow: shadows,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(
            alpha: borderColor == null
                ? (QuranTheme.isDark(context) ? 0.06 : 0.46)
                : (QuranTheme.isDark(context) ? 0.04 : 0.18),
          ),
        ),
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
      ),
    );
  }
}
