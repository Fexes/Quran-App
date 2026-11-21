import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../l10n/gen/app_localizations.dart';
import 'app_icon.dart';

class AppSettingsButton extends StatelessWidget {
  const AppSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).settingsTitle,
      onPressed: () => context.push(AppRoutes.settings),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: const AppIcon(Icons.settings_rounded, size: 22),
    );
  }
}
