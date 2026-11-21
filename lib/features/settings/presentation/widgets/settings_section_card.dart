import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';

class SettingsItemIcon extends StatelessWidget {
  const SettingsItemIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: AppIcon(
        icon,
        size: 20,
        color: colors.onSurface.withValues(alpha: 0.72),
      ),
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.children,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(2, 0, 2, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppIcon(icon, size: 20, color: colors.onSurface),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.62),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
            side: BorderSide(
              color: Color.lerp(colors.outline, colors.onSurface, 0.05)!,
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: ListTileTheme(
              data: ListTileTheme.of(context).copyWith(
                minLeadingWidth: 36,
                horizontalTitleGap: 12,
                titleTextStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.62),
                  height: 1.45,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: 17,
                        thickness: 0.7,
                        color: colors.outline,
                      ),
                    children[index],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
