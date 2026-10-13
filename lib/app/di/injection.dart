import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/widgets.dart';

import '../../core/storage/settings_store.dart';
import '../../features/backup/data/repositories/local_backup_repository.dart';
import '../../features/backup/domain/repositories/backup_repository.dart';
import '../../features/azkar/data/datasources/local_azkar_data_source.dart';
import '../../features/azkar/data/repositories/azkar_repository_impl.dart';
import '../../features/azkar/domain/repositories/azkar_repository.dart';
import '../../features/hadith/data/datasources/local_hadith_data_source.dart';
import '../../features/hadith/data/datasources/fawaz_hadith_translation_data_source.dart';
import '../../features/hadith/data/datasources/hadeeth_enc_data_source.dart';
import '../../features/hadith/data/repositories/hadith_repository_impl.dart';
import '../../features/hadith/data/stores/hadeeth_enc_store.dart';
import '../../features/hadith/data/stores/hadith_translation_store.dart';
import '../../features/hadith/domain/repositories/hadith_repository.dart';
import '../../features/hifz/data/repositories/hifz_repository_impl.dart';
import '../../features/hifz/data/stores/hifz_store.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/library/data/stores/library_user_data_store.dart';
import '../../features/library/domain/services/library_language_download_service.dart';
import '../../features/prayer/data/datasources/offline_prayer_city_data_source.dart';
import '../../features/prayer/data/services/prayer_alert_notification_service.dart';
import '../../features/prayer/data/services/prayer_location_refresh_service.dart';
import '../../features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../features/prayer_times/data/services/adhan_prayer_calculation_service.dart';
import '../../features/prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../features/prayer_tracking/data/repositories/prayer_tracking_repository_impl.dart';
import '../../features/prayer_tracking/data/stores/prayer_tracking_store.dart';
import '../../features/prayer_tracking/domain/repositories/prayer_tracking_repository.dart';
import '../../features/qibla/data/repositories/qibla_repository_impl.dart';
import '../../features/qibla/data/services/qibla_calculation_service.dart';
import '../../features/qibla/domain/repositories/qibla_repository.dart';
import '../../features/reading_goals/data/repositories/reading_progress_repository_impl.dart';
import '../../features/reading_goals/data/stores/reading_progress_store.dart';
import '../../features/reading_goals/domain/repositories/reading_progress_repository.dart';
import '../../features/quran/data/datasources/local_quran_data_source.dart';
import '../../features/quran/data/repositories/quran_interlinear_repository_impl.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/data/repositories/quran_tafsir_repository_impl.dart';
import '../../features/quran/data/repositories/quran_translation_repository_impl.dart';
import '../../features/quran/data/stores/quran_interlinear_words_store.dart';
import '../../features/quran/data/stores/quran_tafsir_store.dart';
import '../../features/quran/data/stores/quran_translation_store.dart';
import '../../features/quran/data/stores/quran_user_data_store.dart';
import '../../features/quran/domain/repositories/quran_interlinear_repository.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/repositories/quran_tafsir_repository.dart';
import '../../features/quran/domain/repositories/quran_translation_repository.dart';
import '../../features/quran_audio/data/repositories/quran_audio_download_repository.dart';
import '../../features/quran_audio/data/repositories/quran_word_timing_repository_impl.dart';
import '../../features/quran_audio/data/services/quran_audio_download_service.dart';
import '../../features/quran_audio/data/services/quran_audio_handler.dart';
import '../../features/quran_audio/data/stores/quran_audio_download_store.dart';
import '../../features/quran_audio/data/stores/quran_word_timing_store.dart';
import '../../features/quran_audio/domain/repositories/quran_word_timing_repository.dart';
import '../../features/search/data/repositories/local_deep_search_repository.dart';
import '../../features/search/domain/repositories/deep_search_repository.dart';
import '../../features/worship_tools/data/repositories/local_divine_names_repository.dart';
import '../../features/worship_tools/data/repositories/open_street_map_mosque_repository.dart';
import '../../features/worship_tools/domain/repositories/divine_names_repository.dart';
import '../../features/worship_tools/domain/repositories/mosque_locator_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({
  SettingsStore? settingsStore,
  QuranUserDataStore? quranUserDataStore,
  QuranInterlinearWordsStore? quranInterlinearWordsStore,
  QuranTranslationStore? quranTranslationStore,
  QuranTafsirStore? quranTafsirStore,
  QuranAudioDownloadStore? quranAudioDownloadStore,
  QuranWordTimingStore? quranWordTimingStore,
  ReadingProgressStore? readingProgressStore,
  HifzStore? hifzStore,
  PrayerTrackingStore? prayerTrackingStore,
  HadeethEncStore? hadeethEncStore,
  HadithTranslationStore? hadithTranslationStore,
  LibraryUserDataStore? libraryUserDataStore,
  QuranAudioHandler? quranAudioHandler,
  QuranAudioDownloadService? quranAudioDownloadService,
  bool initializePrayerAlerts = true,
}) async {
  if (!getIt.isRegistered<SettingsStore>()) {
    final store = settingsStore ?? await SettingsStore.open();
    getIt.registerSingleton<SettingsStore>(store);
  }

  if (!getIt.isRegistered<LocalQuranDataSource>()) {
    getIt.registerLazySingleton<LocalQuranDataSource>(LocalQuranDataSource.new);
  }
  await getIt<LocalQuranDataSource>().ensureQpcHafsLoaded();

  if (!getIt.isRegistered<QuranUserDataStore>()) {
    final store = quranUserDataStore ?? await QuranUserDataStore.open();
    getIt.registerSingleton<QuranUserDataStore>(store);
  }

  if (!getIt.isRegistered<QuranRepository>()) {
    getIt.registerLazySingleton<QuranRepository>(
      () =>
          QuranRepositoryImpl(localDataSource: getIt(), userDataStore: getIt()),
    );
  }

  if (!getIt.isRegistered<ReadingProgressStore>()) {
    final store =
        readingProgressStore ??
        (settingsStore != null
            ? ReadingProgressStore.memory()
            : await ReadingProgressStore.open());
    getIt.registerSingleton<ReadingProgressStore>(store);
  }

  if (!getIt.isRegistered<ReadingProgressRepository>()) {
    getIt.registerLazySingleton<ReadingProgressRepository>(
      () => ReadingProgressRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<HifzStore>()) {
    final store =
        hifzStore ??
        (settingsStore != null ? HifzStore.memory() : await HifzStore.open());
    getIt.registerSingleton<HifzStore>(store);
  }

  if (!getIt.isRegistered<HifzRepository>()) {
    getIt.registerLazySingleton<HifzRepository>(
      () => HifzRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<PrayerTrackingStore>()) {
    final store =
        prayerTrackingStore ??
        (settingsStore != null
            ? PrayerTrackingStore.memory()
            : await PrayerTrackingStore.open());
    getIt.registerSingleton<PrayerTrackingStore>(store);
  }

  if (!getIt.isRegistered<PrayerTrackingRepository>()) {
    getIt.registerLazySingleton<PrayerTrackingRepository>(
      () => PrayerTrackingRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<QuranInterlinearWordsStore>()) {
    final store =
        quranInterlinearWordsStore ?? await QuranInterlinearWordsStore.open();
    getIt.registerSingleton<QuranInterlinearWordsStore>(store);
  }

  if (!getIt.isRegistered<QuranInterlinearRepository>()) {
    getIt.registerLazySingleton<QuranInterlinearRepository>(
      () => QuranInterlinearRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<QuranTranslationStore>()) {
    final store = quranTranslationStore ?? await QuranTranslationStore.open();
    getIt.registerSingleton<QuranTranslationStore>(store);
  }

  if (!getIt.isRegistered<QuranTranslationRepository>()) {
    getIt.registerLazySingleton<QuranTranslationRepository>(
      () => QuranTranslationRepositoryImpl(
        store: getIt(),
        settingsStore: getIt(),
        libraryDownloads: getIt<LibraryLanguageDownloadService>(),
      ),
    );
  }

  if (!getIt.isRegistered<QuranTafsirStore>()) {
    final store = quranTafsirStore ?? await QuranTafsirStore.open();
    getIt.registerSingleton<QuranTafsirStore>(store);
  }

  if (!getIt.isRegistered<QuranTafsirRepository>()) {
    getIt.registerLazySingleton<QuranTafsirRepository>(
      () => QuranTafsirRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<QuranAudioDownloadStore>()) {
    final store =
        quranAudioDownloadStore ?? await QuranAudioDownloadStore.open();
    getIt.registerSingleton<QuranAudioDownloadStore>(store);
  }

  if (!getIt.isRegistered<QuranWordTimingStore>()) {
    final store = quranWordTimingStore ?? await QuranWordTimingStore.open();
    getIt.registerSingleton<QuranWordTimingStore>(store);
  }

  if (!getIt.isRegistered<QuranWordTimingRepository>()) {
    getIt.registerLazySingleton<QuranWordTimingRepository>(
      () => QuranWordTimingRepositoryImpl(store: getIt()),
    );
  }

  if (!getIt.isRegistered<QuranAudioDownloadRepository>()) {
    getIt.registerLazySingleton<QuranAudioDownloadRepository>(
      () => QuranAudioDownloadRepository(
        quranRepository: getIt(),
        store: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<QuranAudioDownloadService>()) {
    final service =
        quranAudioDownloadService ??
        QuranAudioDownloadService(store: getIt<QuranAudioDownloadStore>());
    await service.initialize();
    await getIt<QuranAudioDownloadRepository>().reconcileDownloadedFiles();
    getIt.registerSingleton<QuranAudioDownloadService>(service);
  }

  if (!getIt.isRegistered<QuranAudioHandler>()) {
    if (quranAudioHandler != null) {
      getIt.registerSingleton<QuranAudioHandler>(quranAudioHandler);
    } else {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.speech());
      final handler = await AudioService.init<QuranAudioHandler>(
        builder: QuranAudioHandler.new,
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.coreinfinite.quran.audio',
          androidNotificationChannelName: 'Quran audio',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      getIt.registerSingleton<QuranAudioHandler>(handler);
    }
  }

  if (!getIt.isRegistered<LocalHadithDataSource>()) {
    getIt.registerLazySingleton<LocalHadithDataSource>(
      LocalHadithDataSource.new,
    );
  }

  if (!getIt.isRegistered<HadeethEncDataSource>()) {
    getIt.registerLazySingleton<HadeethEncDataSource>(HadeethEncDataSource.new);
  }

  if (!getIt.isRegistered<FawazHadithTranslationDataSource>()) {
    getIt.registerLazySingleton<FawazHadithTranslationDataSource>(
      FawazHadithTranslationDataSource.new,
    );
  }

  if (!getIt.isRegistered<HadeethEncStore>()) {
    final store = hadeethEncStore ?? await HadeethEncStore.open();
    getIt.registerSingleton<HadeethEncStore>(store);
  }

  if (!getIt.isRegistered<HadithTranslationStore>()) {
    final store = hadithTranslationStore ?? await HadithTranslationStore.open();
    getIt.registerSingleton<HadithTranslationStore>(store);
  }

  if (!getIt.isRegistered<HadithRepository>()) {
    getIt.registerLazySingleton<HadithRepository>(
      () => HadithRepositoryImpl(
        localDataSource: getIt(),
        hadeethEncDataSource: getIt(),
        hadeethEncStore: getIt(),
        translationDataSource: getIt(),
        translationStore: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<LibraryUserDataStore>()) {
    final store = libraryUserDataStore ?? await LibraryUserDataStore.open();
    getIt.registerSingleton<LibraryUserDataStore>(store);
  }

  if (!getIt.isRegistered<DivineNamesRepository>()) {
    getIt.registerLazySingleton<DivineNamesRepository>(
      LocalDivineNamesRepository.new,
    );
  }

  if (!getIt.isRegistered<MosqueLocatorRepository>()) {
    getIt.registerLazySingleton<MosqueLocatorRepository>(
      () => OpenStreetMapMosqueRepository(userDataStore: getIt()),
    );
  }

  if (!getIt.isRegistered<BackupRepository>()) {
    getIt.registerLazySingleton<BackupRepository>(
      () => LocalBackupRepository(
        settingsStore: getIt(),
        quranUserDataStore: getIt(),
        readingProgressStore: getIt(),
        hifzStore: getIt(),
        prayerTrackingStore: getIt(),
        libraryUserDataStore: getIt(),
        translationStore: getIt<QuranTranslationStore>(),
        cancelPrayerAlerts: () =>
            getIt<PrayerAlertNotificationService>().cancelScheduledAlerts(),
        refreshPrayerAlerts: () =>
            getIt<PrayerAlertNotificationService>().syncUpcomingAlerts(),
      ),
    );
  }

  if (!getIt.isRegistered<LocalAzkarDataSource>()) {
    getIt.registerLazySingleton<LocalAzkarDataSource>(LocalAzkarDataSource.new);
  }

  if (!getIt.isRegistered<AzkarRepository>()) {
    getIt.registerLazySingleton<AzkarRepository>(
      () => AzkarRepositoryImpl(localDataSource: getIt()),
    );
  }

  if (!getIt.isRegistered<LibraryLanguageDownloadService>()) {
    getIt.registerLazySingleton<LibraryLanguageDownloadService>(
      () => LibraryLanguageDownloadService(
        hadithRepository: getIt(),
        azkarRepository: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<DeepSearchRepository>()) {
    getIt.registerFactory<DeepSearchRepository>(
      () => LocalDeepSearchRepository(
        quranRepository: getIt(),
        translationStore: getIt(),
        tafsirStore: getIt(),
        userDataStore: getIt(),
        hadithRepository: getIt(),
        azkarRepository: getIt(),
        libraryUserDataStore: getIt(),
      ),
    );
  }

  if (!getIt.isRegistered<OfflinePrayerCityDataSource>()) {
    getIt.registerLazySingleton<OfflinePrayerCityDataSource>(
      OfflinePrayerCityDataSource.new,
    );
  }

  if (!getIt.isRegistered<AdhanPrayerCalculationService>()) {
    getIt.registerLazySingleton<AdhanPrayerCalculationService>(
      AdhanPrayerCalculationService.new,
    );
  }

  if (!getIt.isRegistered<PrayerLocationRefreshService>()) {
    getIt.registerLazySingleton<PrayerLocationRefreshService>(
      () => PrayerLocationRefreshService(getIt(), getIt()),
    );
  }

  if (!getIt.isRegistered<PrayerTimesRepository>()) {
    getIt.registerLazySingleton<PrayerTimesRepository>(
      () => PrayerTimesRepositoryImpl(
        calculationService: getIt(),
        settingsStore: getIt(),
        locationRefreshService: settingsStore == null ? getIt() : null,
      ),
    );
  }

  if (!getIt.isRegistered<PrayerAlertNotificationService>()) {
    final service = PrayerAlertNotificationService(
      settingsStore: getIt(),
      prayerTimesRepository: getIt(),
      prayerTrackingStore: getIt(),
    );
    getIt.registerSingleton<PrayerAlertNotificationService>(service);
    if (initializePrayerAlerts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          service.syncUpcomingAlerts().catchError((Object error) {
            debugPrint('Could not renew prayer alerts after startup: $error');
          }),
        );
      });
    }
  }

  if (!getIt.isRegistered<QiblaCalculationService>()) {
    getIt.registerLazySingleton<QiblaCalculationService>(
      QiblaCalculationService.new,
    );
  }

  if (!getIt.isRegistered<QiblaRepository>()) {
    getIt.registerLazySingleton<QiblaRepository>(
      () => QiblaRepositoryImpl(
        calculationService: getIt(),
        settingsStore: getIt(),
        locationRefreshService: settingsStore == null ? getIt() : null,
      ),
    );
  }
}
