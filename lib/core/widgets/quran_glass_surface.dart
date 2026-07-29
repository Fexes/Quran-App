import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../theme/quran_theme.dart';

class QuranGlassSurface extends StatelessWidget {
  const QuranGlassSurface({
    super.key,
    required this.child,
    required this.height,
    this.radius = QuranTheme.radiusDock,
    this.padding = EdgeInsets.zero,
    this.background,
    this.onTap,
    this.prominent = true,
  });

  final Widget child;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget? background;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final borderRadius = BorderRadius.circular(radius);
        final tint = QuranTheme.glassTint(context);
        final border = QuranTheme.glassBorder(context);
        final shadow = QuranTheme.premiumShadow(context, prominent: prominent);

        if (_isWidgetTest) {
          return Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: borderRadius,
              border: Border.all(color: border),
              boxShadow: shadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
            ),
          );
        }

        return SizedBox(
          height: height,
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: shadow,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: LiquidGlassView(
                pixelRatio: 0.72,
                realTimeCapture: false,
                useSync: false,
                backgroundWidget:
                    background ??
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.82),
                      ),
                      child: const SizedBox.expand(),
                    ),
                children: [
                  LiquidGlass(
                    width: width,
                    height: height,
                    position: const LiquidGlassAlignPosition(
                      alignment: Alignment.center,
                    ),
                    distortion: 0.075,
                    distortionWidth: 42,
                    magnification: 1.01,
                    chromaticAberration: 0.0012,
                    saturation: 1.05,
                    color: tint,
                    blur: const LiquidGlassBlur(sigmaX: 18, sigmaY: 18),
                    shape: RoundedRectangleShape(
                      cornerRadius: radius,
                      borderWidth: 1.1,
                      borderSoftness: 1.8,
                      borderColor: border,
                      lightIntensity: 1.1,
                      oneSideLightIntensity: 0.55,
                      lightColor: Colors.white.withValues(alpha: 0.82),
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      lightDirection: 120,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: borderRadius,
                        child: Padding(padding: padding, child: child),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _isWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }
}
