import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';
import 'premium_surface.dart';

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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final visibleActions = actions.take(2).toList(growable: false);
    return Row(
      children: [
        PremiumSurface(
          width: 44,
          height: 44,
          padding: EdgeInsets.zero,
          radius: 15,
          color: QuranTheme.softFill(context, primary),
          child: Icon(icon, color: primary, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QuranTheme.subText(context, 0.68),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 98,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var index = 0; index < visibleActions.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                _ShellHeaderActionButton(action: visibleActions[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShellHeaderActionButton extends StatelessWidget {
  const _ShellHeaderActionButton({required this.action});

  final ShellHeaderAction action;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.tooltip,
      child: Semantics(
        button: true,
        label: action.tooltip,
        child: PremiumSurface(
          onTap: action.onTap,
          width: 44,
          height: 44,
          padding: EdgeInsets.zero,
          radius: 15,
          child: ExcludeSemantics(
            child: Icon(action.icon, color: QuranTheme.text(context), size: 22),
          ),
        ),
      ),
    );
  }
}
