import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/app/di/injection.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/core/theme/quran_theme_cubit.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/entities/quran_word.dart';
import 'package:quran/features/quran/domain/repositories/quran_interlinear_repository.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran/domain/repositories/quran_translation_repository.dart';
import 'package:quran/features/quran/presentation/bloc/quran_reader_bloc.dart';
import 'package:quran/features/quran/presentation/bloc/quran_reader_event.dart';
import 'package:quran/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:quran/features/quran/presentation/widgets/quran_book_text.dart';
import 'package:quran/features/quran_audio/data/repositories/quran_audio_download_repository.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_download_service.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_playback_port.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_queue_item.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_state.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_word_timing.dart';
import 'package:quran/features/quran_audio/domain/repositories/quran_word_timing_repository.dart';
import 'package:quran/features/quran_audio/presentation/cubit/quran_audio_cubit.dart';
import 'package:quran/l10n/gen/app_localizations.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('reader settings dialog can read route scoped blocs', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(tester.takeException(), isNull);
    expect(find.text('Reader settings'), findsOneWidget);
    expect(find.text('Ayah layout'), findsOneWidget);
    expect(find.text('Combined'), findsOneWidget);
    expect(find.text('Separated'), findsOneWidget);
    expect(find.text('Auto follow audio'), findsOneWidget);
    expect(find.text('Tafsir language'), findsOneWidget);
    expect(find.text('Translation size'), findsOneWidget);
    expect(find.text('Choose reciter'), findsNothing);
    expect(find.text('Test Alafasy'), findsNothing);

    await tester.tap(find.text('Combined'));
    await tester.pump();
    expect(repository.ayahTextLayout, QuranAyahTextLayout.combined);
  });

  testWidgets('reader font slider commits after drag ends', (tester) async {
    final repository = _FakeQuranRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_font_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    final emittedScales = <double>[];
    final subscription = themeCubit.stream.listen(
      (state) => emittedScales.add(state.quranArabicFontScale),
    );
    addTearDown(subscription.cancel);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    emittedScales.clear();
    final slider = find.byType(Slider).first;
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(emittedScales, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(emittedScales, hasLength(1));
    expect(emittedScales.single, greaterThan(1));
  });

  testWidgets('reader settings enables a selected downloaded translation', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final translationRepository = _FakeTranslationRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(translationRepository);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Translated opening.'), findsNothing);

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Translation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Translated opening.'), findsOneWidget);
  });

  testWidgets('reader settings translation switch enables and disables', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final translationRepository = _FakeTranslationRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _CompleteInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(translationRepository);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.tap(find.byTooltip('Reader settings'));
    await tester.pumpAndSettle();
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsAtLeastNWidgets(1));

    await tester.tap(switchFinder.first);
    await tester.pumpAndSettle();
    expect(find.text('Hide ayah translation'), findsNothing);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Translated opening.'), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Translated opening.'), findsNothing);
  });

  testWidgets('ayah mode renders RTL selected translation on the right', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final translationRepository = _FakeTranslationRepository(
      resource: _urduTranslation,
      selected: _urduTranslation,
      translationsBySurah: const {
        1: {'1:1': 'اردو ترجمہ'},
      },
    );
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(translationRepository);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('اردو ترجمہ').evaluate().isNotEmpty) {
        break;
      }
    }

    final translation = tester.widget<Text>(find.text('اردو ترجمہ'));

    expect(translation.textDirection, TextDirection.rtl);
    expect(translation.textAlign, TextAlign.right);
  });

  testWidgets('ayah mode shows follow audio when follow is disabled', (
    tester,
  ) async {
    final repository = _FakeQuranRepository(ayahCount: 8);
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    readerBloc.add(const QuranReaderFollowAudioChanged(false));
    await tester.pump();

    final ayah = (await repository.getAyahs(1))[5];
    final surah = await repository.getSurah(1);
    final reciter = (await repository.getAudioReciters()).first;
    playbackPort.emitPlaying(
      QuranAudioQueueItem.fromAyah(ayah: ayah, surah: surah, reciter: reciter),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Follow audio'), findsOneWidget);
  });

  testWidgets('opening a specific ayah is not hijacked by playing audio', (
    tester,
  ) async {
    final repository = _FakeQuranRepository(ayahCount: 8);
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    final ayahs = await repository.getAyahs(1);
    final surah = await repository.getSurah(1);
    final reciter = (await repository.getAudioReciters()).first;
    playbackPort.emitPlaying(
      QuranAudioQueueItem.fromAyah(
        ayah: ayahs[5],
        surah: surah,
        reciter: reciter,
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1, initialAyahNumber: 3),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    expect(readerBloc.state.currentVerseKey, '1:3');
    expect(readerBloc.state.selectedVerseKey, '1:3');
    expect(readerBloc.state.followAudio, false);
  });

  testWidgets(
    'ayah combined layout renders continuous book text instead of cards',
    (tester) async {
      final repository = _FakeQuranRepository(
        ayahTextLayout: QuranAyahTextLayout.combined,
      );
      final settingsStore = SettingsStore.memory();
      final downloadStore = QuranAudioDownloadStore.memory();
      final audioCubit = QuranAudioCubit(
        audioHandler: _FakePlaybackPort(),
        quranRepository: repository,
        downloadRepository: QuranAudioDownloadRepository(
          quranRepository: repository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_reader_page_test_'),
        ),
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );
      final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
      addTearDown(audioCubit.close);
      addTearDown(themeCubit.close);

      getIt
        ..registerSingleton<QuranRepository>(repository)
        ..registerSingleton<QuranInterlinearRepository>(
          const _EmptyInterlinearRepository(),
        )
        ..registerSingleton<QuranTranslationRepository>(
          const _EmptyTranslationRepository(),
        );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<QuranThemeCubit>.value(value: themeCubit),
            BlocProvider<QuranAudioCubit>.value(value: audioCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: QuranReaderPage(surahNumber: 1),
          ),
        ),
      );

      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CombinedPageText).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(CombinedPageText), findsOneWidget);
      expect(find.text('Tap for controls'), findsNothing);
    },
  );

  testWidgets('ayah combined layout keeps tap selection while audio plays', (
    tester,
  ) async {
    final repository = _FakeQuranRepository(
      ayahTextLayout: QuranAyahTextLayout.combined,
    );
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    final ayahs = await repository.getAyahs(1);
    final surah = await repository.getSurah(1);
    final reciter = (await repository.getAudioReciters()).first;
    playbackPort.emitPlaying(
      QuranAudioQueueItem.fromAyah(
        ayah: ayahs[1],
        surah: surah,
        reciter: reciter,
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CombinedPageText).evaluate().isNotEmpty) {
        break;
      }
    }

    final combined = tester.widget<CombinedPageText>(
      find.byType(CombinedPageText),
    );

    expect(combined.selectionEnabled, true);
    expect(combined.selectedVerseKey, '1:1');
    expect(combined.activeAudioVerseKey, '1:2');
  });

  testWidgets('ayah combined layout selects active audio ayah on change', (
    tester,
  ) async {
    final repository = _FakeQuranRepository(
      ayahTextLayout: QuranAyahTextLayout.combined,
    );
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CombinedPageText).evaluate().isNotEmpty) {
        break;
      }
    }

    final ayahs = await repository.getAyahs(1);
    final surah = await repository.getSurah(1);
    final reciter = (await repository.getAudioReciters()).first;
    playbackPort.emitPlaying(
      QuranAudioQueueItem.fromAyah(
        ayah: ayahs[1],
        surah: surah,
        reciter: reciter,
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 50));
      final combined = tester.widget<CombinedPageText>(
        find.byType(CombinedPageText),
      );
      if (combined.selectedVerseKey == '1:2') {
        break;
      }
    }

    final combined = tester.widget<CombinedPageText>(
      find.byType(CombinedPageText),
    );

    expect(combined.selectedVerseKey, '1:2');
    expect(combined.activeAudioVerseKey, '1:2');
  });

  testWidgets('ayah separated layout keeps tap selection while audio plays', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final playbackPort = _FakePlaybackPort();
    final audioCubit = QuranAudioCubit(
      audioHandler: playbackPort,
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }

    final ayahs = await repository.getAyahs(1);
    final surah = await repository.getSurah(1);
    final reciter = (await repository.getAudioReciters()).first;
    playbackPort.emitPlaying(
      QuranAudioQueueItem.fromAyah(
        ayah: ayahs.first,
        surah: surah,
        reciter: reciter,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('الحمد لله رب العالمين', findRichText: true));
    await tester.pump();

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    expect(readerBloc.state.selectedVerseKey, '1:2');
  });

  testWidgets(
    'ayah combined layout chunks long surahs instead of one huge text',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _FakeQuranRepository(
        ayahTextLayout: QuranAyahTextLayout.combined,
        ayahCount: 80,
      );
      final settingsStore = SettingsStore.memory();
      final downloadStore = QuranAudioDownloadStore.memory();
      final audioCubit = QuranAudioCubit(
        audioHandler: _FakePlaybackPort(),
        quranRepository: repository,
        downloadRepository: QuranAudioDownloadRepository(
          quranRepository: repository,
          store: downloadStore,
          supportDirectoryProvider: () async =>
              Directory.systemTemp.createTemp('quran_reader_page_test_'),
        ),
        downloadService: QuranAudioDownloadService(store: downloadStore),
        settingsStore: settingsStore,
        wordTimingRepository: const _EmptyWordTimingRepository(),
      );
      final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
      addTearDown(audioCubit.close);
      addTearDown(themeCubit.close);

      getIt
        ..registerSingleton<QuranRepository>(repository)
        ..registerSingleton<QuranInterlinearRepository>(
          const _EmptyInterlinearRepository(),
        )
        ..registerSingleton<QuranTranslationRepository>(
          const _EmptyTranslationRepository(),
        );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<QuranThemeCubit>.value(value: themeCubit),
            BlocProvider<QuranAudioCubit>.value(value: audioCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: QuranReaderPage(surahNumber: 1),
          ),
        ),
      );

      for (var index = 0; index < 10; index++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CombinedPageText).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(CombinedPageText), findsAtLeastNWidgets(2));
    },
  );

  testWidgets('ayah mode keeps reader top bar pinned while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeQuranRepository(ayahCount: 24);
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Reader settings').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byTooltip('Reader settings'), findsOneWidget);

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -1300),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Reader settings'), findsOneWidget);
  });

  testWidgets('reader shows draggable ayah scrollbar', (tester) async {
    final repository = _FakeQuranRepository(ayahCount: 24);
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byTooltip('Jump to ayah').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byTooltip('Jump to ayah'), findsOneWidget);
    expect(find.byKey(const ValueKey('ayah-scrollbar-preview')), findsNothing);

    await tester.drag(find.byTooltip('Jump to ayah'), const Offset(0, 120));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('ayah-scrollbar-preview')),
      findsOneWidget,
    );
  });

  testWidgets('surah switcher can jump to an ayah', (tester) async {
    final repository = _FakeQuranRepository(ayahCount: 8);
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Al-Fatihah').evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.tap(find.text('Al-Fatihah').first);
    await tester.pumpAndSettle();

    expect(find.text('Jump to ayah'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('surah-switcher-ayah-input')),
      '6',
    );
    await tester.tap(find.byKey(const ValueKey('surah-switcher-jump-button')));
    await tester.pumpAndSettle();

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    expect(readerBloc.state.currentVerseKey, '1:6');
    expect(readerBloc.state.selectedVerseKey, '1:6');
    expect(find.text('Jump to ayah'), findsNothing);
  });

  testWidgets('next surah capsule swipe opens next surah at first ayah', (
    tester,
  ) async {
    final repository = _FakeQuranRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Swipe up to go to next surah').evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.ensureVisible(find.text('Swipe up to go to next surah'));
    await tester.pump();
    await tester.drag(
      find.text('Swipe up to go to next surah'),
      const Offset(0, -72),
    );
    await tester.pumpAndSettle();

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    expect(readerBloc.state.surah?.number, 2);
    expect(readerBloc.state.currentVerseKey, '2:1');
    expect(readerBloc.state.selectedVerseKey, '2:1');
    expect(find.text('Al-Baqarah'), findsOneWidget);
    expect(
      find.text('ذلك الكتاب لا ريب فيه', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('screen swipe at surah end opens next surah', (tester) async {
    final repository = _FakeQuranRepository();
    final settingsStore = SettingsStore.memory();
    final downloadStore = QuranAudioDownloadStore.memory();
    final audioCubit = QuranAudioCubit(
      audioHandler: _FakePlaybackPort(),
      quranRepository: repository,
      downloadRepository: QuranAudioDownloadRepository(
        quranRepository: repository,
        store: downloadStore,
        supportDirectoryProvider: () async =>
            Directory.systemTemp.createTemp('quran_reader_page_test_'),
      ),
      downloadService: QuranAudioDownloadService(store: downloadStore),
      settingsStore: settingsStore,
      wordTimingRepository: const _EmptyWordTimingRepository(),
    );
    final themeCubit = QuranThemeCubit(settingsStore: settingsStore);
    addTearDown(audioCubit.close);
    addTearDown(themeCubit.close);

    getIt
      ..registerSingleton<QuranRepository>(repository)
      ..registerSingleton<QuranInterlinearRepository>(
        const _EmptyInterlinearRepository(),
      )
      ..registerSingleton<QuranTranslationRepository>(
        const _EmptyTranslationRepository(),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<QuranThemeCubit>.value(value: themeCubit),
          BlocProvider<QuranAudioCubit>.value(value: audioCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuranReaderPage(surahNumber: 1),
        ),
      ),
    );

    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Swipe up to go to next surah').evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.ensureVisible(find.text('Swipe up to go to next surah'));
    await tester.pump();
    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();

    final readerBloc = tester
        .element(find.byTooltip('Reader settings'))
        .read<QuranReaderBloc>();
    expect(readerBloc.state.surah?.number, 2);
    expect(readerBloc.state.currentVerseKey, '2:1');
  });
}

class _FakeQuranRepository implements QuranRepository {
  _FakeQuranRepository({
    this.ayahTextLayout = QuranAyahTextLayout.separated,
    this.ayahCount = 2,
  });

  final Set<String> _bookmarks = {};
  QuranAyahTextLayout ayahTextLayout;
  final int ayahCount;

  @override
  Future<List<ContentSource>> getContentSources() async {
    return const [
      ContentSource(id: 'test', name: 'Test', attribution: 'Test source.'),
    ];
  }

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async {
    return const [
      QuranAudioReciter(
        id: 'test:alafasy',
        name: 'Test Alafasy',
        provider: QuranAudioProvider.everyAyah,
        identifier: 'Alafasy_128kbps',
      ),
    ];
  }

  @override
  Future<String?> getSelectedAudioReciterId() async => null;

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) async {}

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async {
    return ayahTextLayout;
  }

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) async {
    ayahTextLayout = layout;
  }

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async {
    return _effectiveAyahs
        .where((ayah) => ayah.surahNumber == surahNumber)
        .toList(growable: false);
  }

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async {
    return _effectiveAyahs
        .where((ayah) => ayah.page == pageNumber.clamp(1, 604))
        .toList(growable: false);
  }

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _effectiveAyahs
        .firstWhere(
          (ayah) =>
              ayah.surahNumber == surahNumber && ayah.number == ayahNumber,
        )
        .page;
  }

  @override
  Future<QuranSurah> getSurah(int surahNumber) async {
    final surah = _surahs.firstWhere((surah) => surah.number == surahNumber);
    return QuranSurah(
      number: surah.number,
      englishName: surah.englishName,
      arabicName: surah.arabicName,
      ayahCount: ayahCount,
      revelationType: surah.revelationType,
    );
  }

  @override
  Future<List<QuranSurah>> getSurahs() async => [
    await getSurah(1),
    await getSurah(2),
  ];

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async {
    return const [];
  }

  @override
  Future<List<QuranBookmark>> getBookmarks() async {
    return _bookmarks.map((verseKey) {
      final parts = verseKey.split(':');
      return QuranBookmark(
        surahNumber: int.parse(parts[0]),
        ayahNumber: int.parse(parts[1]),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    return _bookmarks.contains('$surahNumber:$ayahNumber');
  }

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {}

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final verseKey = '$surahNumber:$ayahNumber';
    if (_bookmarks.remove(verseKey)) {
      return false;
    }
    _bookmarks.add(verseKey);
    return true;
  }

  static const _surahs = [
    QuranSurah(
      number: 1,
      englishName: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      ayahCount: 2,
      revelationType: 'Meccan',
    ),
    QuranSurah(
      number: 2,
      englishName: 'Al-Baqarah',
      arabicName: 'البقرة',
      ayahCount: 2,
      revelationType: 'Medinan',
    ),
  ];

  static const _ayahs = [
    QuranAyah(
      surahNumber: 1,
      number: 1,
      text: 'بسم الله الرحمن الرحيم',
      translation: 'In the name of Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 1,
      number: 2,
      text: 'الحمد لله رب العالمين',
      translation: 'All praise is for Allah.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 2,
      number: 1,
      text: 'الم',
      translation: 'Alif Lam Meem.',
      page: 2,
      juz: 1,
      isSajda: false,
    ),
    QuranAyah(
      surahNumber: 2,
      number: 2,
      text: 'ذلك الكتاب لا ريب فيه',
      translation: 'This is the Book.',
      page: 2,
      juz: 1,
      isSajda: false,
    ),
  ];

  List<QuranAyah> get _effectiveAyahs {
    if (ayahCount <= 2) {
      return _ayahs;
    }
    return [
      for (var index = 1; index <= ayahCount; index++)
        QuranAyah(
          surahNumber: 1,
          number: index,
          text: index.isOdd
              ? 'بسم الله الرحمن الرحيم'
              : 'الحمد لله رب العالمين',
          translation: 'Translation $index.',
          page: 1,
          juz: 1,
          isSajda: false,
        ),
    ];
  }
}

class _EmptyInterlinearRepository implements QuranInterlinearRepository {
  const _EmptyInterlinearRepository();

  @override
  String get cacheVersion => 'test-cache';

  @override
  Future<List<QuranWord>> getPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return const [];
  }

  @override
  Future<List<QuranWord>> cachedPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return const [];
  }

  @override
  Future<bool> hasFullCache({String language = 'en'}) async => false;

  @override
  Stream<QuranInterlinearDownloadProgress> downloadFullCache({
    String language = 'en',
  }) async* {}
}

class _CompleteInterlinearRepository implements QuranInterlinearRepository {
  const _CompleteInterlinearRepository();

  @override
  String get cacheVersion => 'test-cache';

  @override
  Future<List<QuranWord>> getPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return cachedPageWords(pageNumber, language: language);
  }

  @override
  Future<List<QuranWord>> cachedPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    if (pageNumber != 1 || language != 'en') {
      return const [];
    }
    return const [
      QuranWord(
        verseKey: '1:1',
        ayahNumber: 1,
        wordIndex: 1,
        arabicText: 'بسم',
        translation: 'In',
        page: 1,
        lineNumber: 1,
      ),
      QuranWord(
        verseKey: '1:1',
        ayahNumber: 1,
        wordIndex: 2,
        arabicText: 'الله',
        translation: 'name',
        page: 1,
        lineNumber: 1,
      ),
      QuranWord(
        verseKey: '1:1',
        ayahNumber: 1,
        wordIndex: 3,
        arabicText: 'الرحمن',
        translation: 'Allah',
        page: 1,
        lineNumber: 1,
      ),
      QuranWord(
        verseKey: '1:1',
        ayahNumber: 1,
        wordIndex: 4,
        arabicText: 'الرحيم',
        translation: 'Merciful',
        page: 1,
        lineNumber: 1,
      ),
    ];
  }

  @override
  Future<bool> hasFullCache({String language = 'en'}) async => language == 'en';

  @override
  Stream<QuranInterlinearDownloadProgress> downloadFullCache({
    String language = 'en',
  }) async* {
    yield const QuranInterlinearDownloadProgress(
      completedPages: 604,
      totalPages: 604,
      failedPages: 0,
      isComplete: true,
    );
  }
}

class _EmptyTranslationRepository implements QuranTranslationRepository {
  const _EmptyTranslationRepository();

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async =>
      const [];

  @override
  Future<QuranTranslationResource?> selectedTranslation() async => null;

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {}

  @override
  Future<bool> hasFullTranslation(int resourceId) async => false;

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {}

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async {
    return null;
  }

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async {
    return const {};
  }
}

class _FakeTranslationRepository implements QuranTranslationRepository {
  _FakeTranslationRepository({
    QuranTranslationResource resource = _englishTranslation,
    QuranTranslationResource? selected,
    Map<int, Map<String, String>> translationsBySurah = const {
      1: {'1:1': 'Translated opening.', '1:2': 'Translated praise.'},
    },
  }) : _resource = resource,
       _selected = selected,
       _translationsBySurah = translationsBySurah;

  final QuranTranslationResource _resource;
  final Map<int, Map<String, String>> _translationsBySurah;
  QuranTranslationResource? _selected;
  static const _englishTranslation = QuranTranslationResource(
    id: 85,
    languageName: 'english',
    name: 'M.A.S. Abdel Haleem',
    authorName: 'Abdul Haleem',
    slug: 'en-haleem',
  );

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async => [
    QuranTranslationLanguage(
      languageName: _resource.languageName,
      displayName: _resource.displayLanguage,
      resourceCount: 1,
      defaultResource: _resource,
    ),
  ];

  @override
  Future<QuranTranslationResource?> selectedTranslation() async => _selected;

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {
    _selected = resourceId == _resource.id ? _resource : null;
  }

  @override
  Future<bool> hasFullTranslation(int resourceId) async {
    return resourceId == _resource.id;
  }

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {}

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async {
    return (await cachedTranslationsForSurah(resourceId, 1))[verseKey];
  }

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async {
    if (resourceId != _resource.id || surahNumber != 1) {
      return const {};
    }
    return _translationsBySurah[surahNumber] ?? const {};
  }
}

const _urduTranslation = QuranTranslationResource(
  id: 234,
  languageName: 'urdu',
  name: 'Fatah Muhammad Jalandhari',
  authorName: 'Fatah Muhammad Jalandhari',
  slug: 'ur-fatah-muhammad-jalandhari',
);

class _EmptyWordTimingRepository implements QuranWordTimingRepository {
  const _EmptyWordTimingRepository();

  @override
  Future<QuranWordTimingResult> timingsFor({
    required QuranAudioReciter reciter,
    required QuranAudioQueueItem item,
  }) async {
    return QuranWordTimingResult.empty(
      reciterId: reciter.id,
      verseKey: item.verseKey,
    );
  }
}

class _FakePlaybackPort implements QuranAudioPlaybackPort {
  final _playbackState = StreamController<PlaybackState>.broadcast();
  final _mediaItem = StreamController<MediaItem?>.broadcast();
  final _queue = StreamController<List<MediaItem>>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _bufferedPosition = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _currentIndex = StreamController<int?>.broadcast();
  final _speed = StreamController<double>.broadcast();
  final _playerState = StreamController<PlayerState>.broadcast();

  void emitPlaying(QuranAudioQueueItem item) {
    final mediaItem = item.toMediaItem();
    _queue.add([mediaItem]);
    _currentIndex.add(0);
    _mediaItem.add(mediaItem);
    _playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.ready,
        playing: true,
        updatePosition: Duration.zero,
      ),
    );
  }

  @override
  Stream<PlaybackState> get playbackState => _playbackState.stream;

  @override
  Stream<MediaItem?> get mediaItem => _mediaItem.stream;

  @override
  Stream<List<MediaItem>> get queue => _queue.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration> get bufferedPositionStream => _bufferedPosition.stream;

  @override
  Stream<Duration?> get durationStream => _duration.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndex.stream;

  @override
  Stream<double> get speedStream => _speed.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerState.stream;

  @override
  int? get currentIndex => null;

  @override
  bool get playing => false;

  @override
  List<QuranAudioQueueItem> get currentQueue => const [];

  @override
  Future<void> loadAndPlay(
    List<QuranAudioQueueItem> items, {
    int startIndex = 0,
  }) async {}

  @override
  Future<void> setQuranRepeatMode(QuranAudioRepeatMode mode) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await Future.wait([
      _playbackState.close(),
      _mediaItem.close(),
      _queue.close(),
      _position.close(),
      _bufferedPosition.close(),
      _duration.close(),
      _currentIndex.close(),
      _speed.close(),
      _playerState.close(),
    ]);
  }
}
