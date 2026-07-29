import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/quran_glass_surface.dart';
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
  static const double audioDockInset = height + bottomMargin + 40;

  @override
  Widget build(BuildContext context) {
    final items = _items(AppLocalizations.of(context));

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
      child: QuranGlassSurface(
        height: height,
        radius: QuranTheme.radiusDock,
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
    );
  }

  List<_BottomNavItemData> _items(AppLocalizations l10n) {
    return [
      _BottomNavItemData(
        destination: ShellDestination.home,
        icon: Icons.home_rounded,
        label: l10n.tabHome,
      ),
      _BottomNavItemData(
        destination: ShellDestination.quran,
        icon: Icons.menu_book_rounded,
        label: l10n.tabQuran,
      ),
      _BottomNavItemData(
        destination: ShellDestination.prayer,
        icon: Icons.mosque_rounded,
        label: l10n.tabPrayer,
      ),
      _BottomNavItemData(
        destination: ShellDestination.library,
        icon: Icons.menu_book_rounded,
        label: l10n.tabLibrary,
      ),
      _BottomNavItemData(
        destination: ShellDestination.settings,
        icon: Icons.tune_rounded,
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
    final primary = Theme.of(context).colorScheme.primary;
    final muted = QuranTheme.subText(context, 0.62);
    final color = selected ? primary : muted;

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
                  color: selected
                      ? QuranTheme.softFill(context, primary)
                      : Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkResponse(
                    onTap: onTap,
                    containedInkWell: true,
                    customBorder: const CircleBorder(),
                    radius: 18,
                    child: SizedBox(
                      width: 32,
                      height: 30,
                      child: Icon(
                        item.icon,
                        color: color,
                        size: selected ? 22 : 20,
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
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
