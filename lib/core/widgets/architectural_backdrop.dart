import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';

/// Shared bundled artwork; decorative layers never capture reader gestures.
class ArchitecturalBackdrop extends StatelessWidget {
  const ArchitecturalBackdrop({
    super.key,
    this.prominent = false,
    this.imageAsset = assetPath,
    this.overlayColor = const Color(0x80000000),
  });

  final bool prominent;
  final String imageAsset;
  final Color overlayColor;

  static const assetPath = 'assets/images/architecture/courtyard.jpg';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: prominent
                  ? 1
                  : (QuranTheme.isDark(context) ? 0.07 : 0.04),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                cacheWidth: 1200,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ),
            ),
            if (prominent) ColoredBox(color: overlayColor),
          ],
        ),
      ),
    );
  }
}
