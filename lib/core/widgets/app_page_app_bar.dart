import 'package:flutter/material.dart';

import 'app_settings_button.dart';

/// Keeps the app's settings available after opening a feature from a tab.
class AppPageAppBar extends AppBar {
  AppPageAppBar({
    super.key,
    super.title,
    super.leading,
    super.automaticallyImplyLeading,
    super.flexibleSpace,
    super.bottom,
    super.centerTitle,
    super.titleSpacing,
    super.toolbarHeight,
    List<Widget> actions = const [],
  }) : super(actions: [...actions, const AppSettingsButton()]);
}
