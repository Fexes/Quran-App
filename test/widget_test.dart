import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/app/app.dart';
import 'package:quran/app/di/injection.dart';
import 'package:quran/app/router/app_router.dart';
import 'package:quran/app/router/app_routes.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/quran/data/repositories/quran_interlinear_repository_impl.dart';
import 'package:quran/features/quran/data/stores/quran_interlinear_words_store.dart';
import 'package:quran/features/quran/data/stores/quran_tafsir_store.dart';
import 'package:quran/features/quran/data/stores/quran_translation_store.dart';
import 'package:quran/features/quran/data/stores/quran_user_data_store.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_download_service.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_handler.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/quran_audio/data/stores/quran_word_timing_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_download_item.dart';

void main() {
  setUpAll(() async {
    final downloadStore = QuranAudioDownloadStore.memory();
    await configureDependencies(
      settingsStore: SettingsStore.memory({
        'interlinear_translation_skip_version':
            QuranInterlinearRepositoryImpl.currentCacheVersion,
      }),
      quranUserDataStore: QuranUserDataStore.memory(),
      quranInterlinearWordsStore: QuranInterlinearWordsStore.memory(),
      quranTranslationStore: QuranTranslationStore.memory(),
      quranTafsirStore: QuranTafsirStore.memory(),
      quranAudioHandler: QuranAudioHandler(),
      quranAudioDownloadStore: downloadStore,
      quranWordTimingStore: QuranWordTimingStore.memory(),
      quranAudioDownloadService: _NoopDownloadService(downloadStore),
      initializePrayerAlerts: false,
    );
  });

  testWidgets('app starts on the home dashboard', (tester) async {
    await tester.pumpWidget(const QuranApp());
    await _pumpStable(tester);

    expect(find.text('Guidance for the heart'), findsOneWidget);
    expect(find.text('Quran'), findsWidgets);
  });

  testWidgets('library tab shows hadith and azkar content', (tester) async {
    await tester.pumpWidget(const QuranApp());
    await _pumpStable(tester);

    await tester.tap(find.text('Library').last);
    await _pumpStable(tester);

    expect(find.text('Hadith'), findsWidgets);
    expect(find.text('Sahih al Bukhari'), findsOneWidget);

    expect(find.text('Azkar'), findsWidgets);
  });

  testWidgets('search screen accepts a deep search query', (
    tester,
  ) async {
    appRouter.go(AppRoutes.quranSearchPath());
    addTearDown(() => appRouter.go(AppRoutes.shell));

    await tester.pumpWidget(const QuranApp());
    await _pumpStable(tester);

    await tester.enterText(find.byType(EditableText), 'intentions');
    await tester.pump(const Duration(milliseconds: 350));
    await _pumpStable(tester);
    await _pumpStable(tester);

    expect(find.text('intentions'), findsOneWidget);
  });

  testWidgets('home dashboard opens Tasbieh shortcut', (tester) async {
    appRouter.go(AppRoutes.shell);

    await tester.pumpWidget(const QuranApp());
    await _pumpStable(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await _pumpStable(tester);

    expect(find.text('Tasbieh'), findsOneWidget);

    await tester.tap(find.text('Tasbieh').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('tasbieh-bead')), findsOneWidget);
  });
}

Future<void> _pumpStable(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

class _NoopDownloadService extends QuranAudioDownloadService {
  _NoopDownloadService(QuranAudioDownloadStore store) : super(store: store);

  final StreamController<void> _updates = StreamController<void>.broadcast();

  @override
  Stream<void> get updates => _updates.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> enqueueItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {}

  @override
  Future<void> pauseItems(Iterable<QuranAudioDownloadItem> items) async {}

  @override
  Future<void> resumeItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {}

  @override
  Future<void> cancelItems(Iterable<QuranAudioDownloadItem> items) async {}

  @override
  Future<void> retryItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {}

  @override
  Future<void> dispose() async {
    await _updates.close();
  }
}
