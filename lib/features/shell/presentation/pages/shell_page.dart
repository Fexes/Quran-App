import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../prayer/presentation/pages/prayer_page.dart';
import '../../../quran/presentation/pages/quran_page.dart';
import '../../../quran_audio/presentation/widgets/quran_floating_audio_player.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/shell_cubit.dart';
import '../bloc/shell_state.dart';
import '../widgets/app_bottom_nav.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, ShellState>(
      builder: (context, state) {
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: state.index,
                  children: const [
                    HomePage(),
                    QuranPage(),
                    PrayerPage(),
                    LibraryPage(),
                    SettingsPage(),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: const QuranFloatingAudioPlayer(
                  bottomInset: AppBottomNav.audioDockInset,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(
                  currentDestination: state.destination,
                  onDestinationSelected: context
                      .read<ShellCubit>()
                      .setDestination,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
