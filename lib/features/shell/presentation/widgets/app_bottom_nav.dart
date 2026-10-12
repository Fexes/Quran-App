import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/shell_state.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentDestination,
    required this.onDestinationSelected,
  });

  final ShellDestination currentDestination;
  final ValueChanged<ShellDestination> onDestinationSelected;

  static const double height = 62;
  static const double bottomMargin = 8;

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QuranTheme.surface(context),
        border: Border(top: BorderSide(color: QuranTheme.outline(context))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: bottomMargin),
        child: SizedBox(
          height: (46 + MediaQuery.textScalerOf(context).scale(12) * 1.4).clamp(
            height,
            double.infinity,
          ),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _BottomNavItem(
                    item: item,
                    selected: item.destination == currentDestination,
                    onTap: () => onDestinationSelected(item.destination),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_BottomNavItemData> _items(AppLocalizations l10n) {
    return [
      _BottomNavItemData(
        destination: ShellDestination.home,
        icon: Icons.home_outlined,
        label: l10n.tabHome,
      ),
      _BottomNavItemData(
        destination: ShellDestination.quran,
        icon: Icons.menu_book_outlined,
        label: l10n.tabQuran,
      ),
      _BottomNavItemData(
        destination: ShellDestination.prayer,
        icon: Icons.mosque_outlined,
        label: l10n.tabPrayer,
      ),
      _BottomNavItemData(
        destination: ShellDestination.library,
        icon: Icons.local_library_outlined,
        label: l10n.tabLibrary,
      ),
      _BottomNavItemData(
        destination: ShellDestination.settings,
        icon: Icons.tune_outlined,
        label: l10n.tabSettings,
      ),
    ];
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItemData item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.secondary
        : QuranTheme.subText(context, 0.68);

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkResponse(
                    onTap: onTap,
                    containedInkWell: true,
                    customBorder: const CircleBorder(),
                    radius: 24,
                    child: SizedBox(
                      width: 44,
                      height: 32,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: selected ? 1 : 0,
                          end: selected ? 1 : 0,
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        builder: (context, emphasis, child) => AppIcon(
                          item.icon,
                          size: 23,
                          strokeWidth: 1.5 + 0.8 * emphasis,
                          color: Color.lerp(
                            QuranTheme.subText(context, 0.68),
                            Theme.of(context).colorScheme.secondary,
                            emphasis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.destination,
    required this.icon,
    required this.label,
  });

  final ShellDestination destination;
  final IconData icon;
  final String label;
}
