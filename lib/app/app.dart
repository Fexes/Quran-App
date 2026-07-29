import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/locale_cubit.dart';
import '../core/localization/locale_state.dart';
import '../core/storage/settings_store.dart';
import '../core/theme/quran_theme.dart';
import '../core/theme/quran_theme_cubit.dart';
import '../core/theme/quran_theme_state.dart';
import '../features/shell/presentation/bloc/shell_cubit.dart';
import '../features/quran/domain/repositories/quran_repository.dart';
import '../features/quran/domain/repositories/quran_translation_repository.dart';
import '../features/quran_audio/data/repositories/quran_audio_download_repository.dart';
import '../features/quran_audio/data/services/quran_audio_download_service.dart';
import '../features/quran_audio/data/services/quran_audio_handler.dart';
import '../features/quran_audio/domain/repositories/quran_word_timing_repository.dart';
import '../features/quran_audio/presentation/cubit/quran_audio_cubit.dart';
import '../l10n/gen/app_localizations.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = getIt<SettingsStore>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => QuranThemeCubit(settingsStore: settingsStore),
        ),
        BlocProvider(create: (_) => LocaleCubit(settingsStore: settingsStore)),
        BlocProvider(create: (_) => ShellCubit()),
        BlocProvider(
          create: (_) => QuranAudioCubit(
            audioHandler: getIt<QuranAudioHandler>(),
            quranRepository: getIt<QuranRepository>(),
            translationRepository: getIt<QuranTranslationRepository>(),
            downloadRepository: getIt<QuranAudioDownloadRepository>(),
            downloadService: getIt<QuranAudioDownloadService>(),
            settingsStore: settingsStore,
            wordTimingRepository: getIt<QuranWordTimingRepository>(),
          ),
        ),
      ],
      child: const _QuranAppView(),
    );
  }
}

class _QuranAppView extends StatelessWidget {
  const _QuranAppView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranThemeCubit, QuranThemeState>(
      builder: (context, themeState) {
        final preset = QuranTheme.presetById(themeState.presetId);
        final theme = QuranTheme.buildTheme(
          preset: preset,
          fontWeightScale: themeState.fontWeightScale,
        );

        return BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return MaterialApp.router(
              title: AppConstants.appName,
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: theme,
              routerConfig: appRouter,
              locale: localeState.appLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final systemScale = mediaQuery.textScaler.scale(1);
                final effectiveScale = (systemScale * themeState.fontScale)
                    .clamp(0.8, 2.0)
                    .toDouble();
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: QuranTheme.systemUiOverlayStyle(themeState.mode),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      textScaler: TextScaler.linear(effectiveScale),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
