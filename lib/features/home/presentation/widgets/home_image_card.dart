import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/premium_surface.dart';

class HomeImageCard extends StatelessWidget {
  const HomeImageCard({
    super.key,
    required this.title,
    required this.icon,
    required this.image,
    required this.onTap,
    this.subtitle,
    this.imageAlignment = Alignment.center,
  });

  final String title;
  final IconData icon;
  final String image;
  final VoidCallback onTap;
  final String? subtitle;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textHeight =
            scaler.scale(22) * 1.25 * 3 +
            (subtitle == null ? 0 : scaler.scale(12) * 1.4 * 2 + 8);
        return Semantics(
          button: true,
          label: subtitle == null ? title : '$title, $subtitle',
          onTap: onTap,
          excludeSemantics: true,
          child: PremiumSurface(
            onTap: onTap,
            padding: EdgeInsets.zero,
            radius: 16,
            color: const Color(0xFF29342F),
            showBorder: false,
            shadowStyle: PremiumSurfaceShadowStyle.none,
            height: math.max(
              (constraints.maxWidth * 1.38).clamp(250.0, 360.0),
              textHeight + 104,
            ),
            child: Ink(
              decoration: BoxDecoration(
                image: DecorationImage(
                  opacity: 0.86,
                  image: ResizeImage(AssetImage(image), width: 720),
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                  onError: (error, stack) =>
                      debugPrint('Home card image unavailable: $error'),
                ),
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xA6000000),
                      Color(0x33000000),
                      Colors.transparent,
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: AppIcon(
                              icon,
                              size: 20,
                              strokeWidth: 1.1,
                              applyTextScaling: true,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                    letterSpacing: 0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.4,
                                letterSpacing: 0,
                              ),
                        ),
                      ],
                      const Spacer(),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          width: 52,
                          height: 34,
                          decoration: const ShapeDecoration(
                            color: Colors.white,
                            shape: StadiumBorder(),
                          ),
                          child: const AppIcon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF242927),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
