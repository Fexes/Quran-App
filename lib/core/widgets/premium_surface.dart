import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';

enum PremiumSurfaceShadowStyle { regular, subtle, floating, none }

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
    this.borderWidth = 1,
    this.showBorder = true,
    this.prominent = false,
    this.clipBehavior = Clip.antiAlias,
    this.width,
    this.height,
    this.shadowStyle,
  }) : assert(borderWidth >= 0);

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;
  final bool prominent;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final PremiumSurfaceShadowStyle? shadowStyle;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final effectiveBorder = borderColor ?? QuranTheme.outline(context);
    final hasBorder =
        showBorder && (borderColor != null || prominent || onTap != null);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: hasBorder
          ? BorderSide(color: effectiveBorder, width: borderWidth)
          : BorderSide.none,
    );
    // Keep the inset previously supplied by the decorated container's border.
    final content = Padding(
      padding: padding.add(shape.dimensions),
      child: child,
    );
    final effectiveShadowStyle =
        shadowStyle ??
        PremiumSurfaceShadowScope.maybeOf(context) ??
        (prominent
            ? PremiumSurfaceShadowStyle.regular
            : PremiumSurfaceShadowStyle.none);
    final shadows = switch (effectiveShadowStyle) {
      PremiumSurfaceShadowStyle.floating => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: QuranTheme.isDark(context) ? 0.38 : 0.18,
          ),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
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

    return PremiumSurfaceShadowScope(
      style: PremiumSurfaceShadowStyle.none,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadows,
        ),
        child: Material(
          color: color ?? QuranTheme.surface(context),
          shape: shape,
          clipBehavior: clipBehavior,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, customBorder: shape, child: content),
        ),
      ),
    );
  }
}
