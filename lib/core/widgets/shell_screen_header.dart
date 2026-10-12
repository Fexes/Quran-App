import 'package:flutter/material.dart';
import 'app_icon.dart';

import '../theme/quran_theme.dart';

class ShellHeaderAction {
  const ShellHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
}

class ShellScreenHeader extends StatelessWidget {
  const ShellScreenHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<ShellHeaderAction> actions;

  static double height(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return ((scaler.scale(24) * 1.2).ceilToDouble() +
            3 +
            (scaler.scale(12) * 1.35).ceilToDouble())
        .clamp(44.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final accent = QuranTheme.text(context);
    final visibleActions = actions.take(2).toList(growable: false);
    return SizedBox(
      height: height(context),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: AppIcon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context, 0.68),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (visibleActions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var index = 0; index < visibleActions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 2),
                  _ShellHeaderActionButton(action: visibleActions[index]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShellHeaderActionButton extends StatelessWidget {
  const _ShellHeaderActionButton({required this.action});

  final ShellHeaderAction action;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: action.tooltip,
      onPressed: action.onTap,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: AppIcon(action.icon, color: QuranTheme.text(context), size: 22),
    );
  }
}
