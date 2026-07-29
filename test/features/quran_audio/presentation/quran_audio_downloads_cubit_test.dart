import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/content/content_source.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/quran/domain/entities/quran_audio_reciter.dart';
import 'package:quran/features/quran/domain/entities/quran_ayah.dart';
import 'package:quran/features/quran/domain/entities/quran_bookmark.dart';
import 'package:quran/features/quran/domain/entities/quran_last_read.dart';
import 'package:quran/features/quran/domain/entities/quran_reading_mode.dart';
import 'package:quran/features/quran/domain/entities/quran_surah.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran/domain/repositories/quran_translation_repository.dart';
import 'package:quran/features/quran_audio/data/repositories/quran_audio_download_repository.dart';
import 'package:quran/features/quran_audio/data/services/quran_audio_download_service.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/quran_audio/domain/entities/quran_audio_download_item.dart';
import 'package:quran/features/quran_audio/presentation/cubit/quran_audio_downloads_cubit.dart';
import 'package:quran/features/quran_audio/presentation/cubit/quran_audio_downloads_state.dart';

void main() {
  group('QuranAudioDownloadsCubit', () {
    test(
      'translation mode is unavailable without selected translation',
      () async {
        final harness = await _DownloadsHarness.create();
        final cubit = harness.cubit;

        await cubit.load();
        await cubit.setAudioType(QuranAudioDownloadAudioType.translation);

        expect(cubit.state.audioType, QuranAudioDownloadAudioType.translation);
        expect(cubit.state.selectedTranslation, isNull);
        expect(cubit.state.reciters, isEmpty);
        expect(cubit.state.selectedReciter, isNull);
        expect(cubit.state.surahGroups, isEmpty);

        await cubit.close();
        await harness.dispose();
      },
    );

    test(
      'translation surah download queues selected translation voice',
      () async {
        final harness = await _DownloadsHarness.create(
          selectedTranslation: _urduTranslation,
        );
        final cubit = harness.cubit;

        await cubit.load();
        await cubit.setAudioType(QuranAudioDownloadAudioType.translation);
        await cubit.downloadSurah(1);

        expect(cubit.state.selectedReciter?.id, 'translation:urdu');
        expect(
          harness.downloadService.enqueuedItems.map((item) => item.reciterId),
          ['translation:urdu', 'translation:urdu', 'translation:urdu'],
        );

        await cubit.close();
        await harness.dispose();
      },
    );

    test(
      'complete offline queues Arabic and selected translation audio',
      () async {
        final harness = await _DownloadsHarness.create(
          selectedTranslation: _urduTranslation,
        );
        final cubit = harness.cubit;

        await cubit.load();
        await cubit.downloadCompleteOffline();

        expect(
          harness.downloadService.enqueuedItems.map((item) => item.reciterId),
          [
            'arabic:alafasy',
            'arabic:alafasy',
            'arabic:alafasy',
            'translation:urdu',
            'translation:urdu',
            'translation:urdu',
          ],
        );

        await cubit.close();
        await harness.dispose();
      },
    );

    test('delete selected audio keeps other audio type', () async {
      final harness = await _DownloadsHarness.create(
        selectedTranslation: _urduTranslation,
      );
      final cubit = harness.cubit;
      final arabicReciter = _FakeQuranRepository.reciters[0];
      final translationReciter = _FakeQuranRepository.reciters[2];
      final arabicItems = await harness.downloadRepository.itemsForSurah(
        reciter: arabicReciter,
        surahNumber: 1,
      );
      final translationItems = await harness.downloadRepository.itemsForSurah(
        reciter: translationReciter,
        surahNumber: 1,
      );
      await harness.downloadRepository.store.saveItems([
        ...arabicItems,
        ...translationItems,
      ]);

      await cubit.load();
      await cubit.setAudioType(QuranAudioDownloadAudioType.translation);
      await cubit.deleteSelectedAudio();

      expect(
        harness.downloadService.cancelledItems.map((item) => item.reciterId),
        ['translation:urdu', 'translation:urdu', 'translation:urdu'],
      );
      expect(
        harness.downloadRepository.store.itemsForReciter('translation:urdu'),
        isEmpty,
      );
      expect(
        harness.downloadRepository.store.itemsForReciter('arabic:alafasy'),
        hasLength(3),
      );

      await cubit.close();
      await harness.dispose();
    });

    test('select translation language refreshes translation voices', () async {
      final harness = await _DownloadsHarness.create();
      final cubit = harness.cubit;

      await cubit.load();
      await cubit.setAudioType(QuranAudioDownloadAudioType.translation);
      expect(cubit.state.reciters, isEmpty);

      await cubit.selectTranslation(_urduTranslation.id);

      expect(cubit.state.selectedTranslation, _urduTranslation);
      expect(cubit.state.selectedReciter?.id, 'translation:urdu');
      expect(cubit.state.reciters.map((reciter) => reciter.id), [
        'translation:urdu',
      ]);

      await cubit.close();
      await harness.dispose();
    });
  });
}

const _urduTranslation = QuranTranslationResource(
  id: 22,
  languageName: 'Urdu',
  name: 'Urdu translation',
  authorName: 'Author',
  slug: 'urdu',
);

class _DownloadsHarness {
  const _DownloadsHarness({
    required this.cubit,
    required this.downloadRepository,
    required this.downloadService,
    required this.tempDirectory,
  });

  final QuranAudioDownloadsCubit cubit;
  final QuranAudioDownloadRepository downloadRepository;
  final _FakeDownloadService downloadService;
  final Directory tempDirectory;

  static Future<_DownloadsHarness> create({
    QuranTranslationResource? selectedTranslation,
  }) async {
    final quranRepository = _FakeQuranRepository();
    final downloadStore = QuranAudioDownloadStore.memory();
    final tempDirectory = await Directory.systemTemp.createTemp(
      'quran_audio_downloads_cubit_test_',
    );
    final downloadRepository = QuranAudioDownloadRepository(
      quranRepository: quranRepository,
      store: downloadStore,
      supportDirectoryProvider: () async => tempDirectory,
    );
    final downloadService = _FakeDownloadService();
    final translationRepository = _FakeTranslationRepository(
      selected: selectedTranslation,
    );
    final cubit = QuranAudioDownloadsCubit(
      quranRepository: quranRepository,
      translationRepository: translationRepository,
      downloadRepository: downloadRepository,
      downloadService: downloadService,
      settingsStore: SettingsStore.memory({
        'audio_translation_reciter_id': 'translation:urdu',
      }),
    );
    return _DownloadsHarness(
      cubit: cubit,
      downloadRepository: downloadRepository,
      downloadService: downloadService,
      tempDirectory: tempDirectory,
    );
  }

  Future<void> dispose() async {
    await downloadService.dispose();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

class _FakeDownloadService implements QuranAudioDownloadServicePort {
  final _updatesController = StreamController<void>.broadcast();
  final enqueuedItems = <QuranAudioDownloadItem>[];
  final cancelledItems = <QuranAudioDownloadItem>[];

  @override
  Stream<void> get updates => _updatesController.stream;

  @override
  Future<void> enqueueItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {
    enqueuedItems.addAll(items);
  }

  @override
  Future<void> cancelItems(Iterable<QuranAudioDownloadItem> items) async {
    cancelledItems.addAll(items);
  }

  @override
  Future<void> pauseItems(Iterable<QuranAudioDownloadItem> items) async {}

  @override
  Future<void> resumeItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {}

  @override
  Future<void> retryItems(
    Iterable<QuranAudioDownloadItem> items, {
    bool requiresWiFi = false,
  }) async {}

  Future<void> dispose() => _updatesController.close();
}

class _FakeQuranRepository implements QuranRepository {
  static const reciters = [
    QuranAudioReciter(
      id: 'arabic:alafasy',
      name: 'Alafasy',
      provider: QuranAudioProvider.everyAyah,
      identifier: 'Alafasy_128kbps',
    ),
    QuranAudioReciter(
      id: 'translation:english',
      name: 'English Voice',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'en.walk',
      languageCode: 'en',
      isTranslation: true,
    ),
    QuranAudioReciter(
      id: 'translation:urdu',
      name: 'Urdu Voice',
      provider: QuranAudioProvider.alQuranCloud,
      identifier: 'ur.khan',
      languageCode: 'ur',
      isTranslation: true,
    ),
  ];

  static const surah = QuranSurah(
    number: 1,
    englishName: 'Al-Fatihah',
    arabicName: 'الفاتحة',
    ayahCount: 3,
    revelationType: 'Meccan',
  );

  static const ayahs = [
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
      surahNumber: 1,
      number: 3,
      text: 'الرحمن الرحيم',
      translation: 'The Most Merciful.',
      page: 1,
      juz: 1,
      isSajda: false,
    ),
  ];

  String selectedReciterId = 'arabic:alafasy';

  @override
  Future<List<ContentSource>> getContentSources() async => const [];

  @override
  Future<List<QuranAudioReciter>> getAudioReciters() async => reciters;

  @override
  Future<List<QuranAyah>> getAyahs(int surahNumber) async => ayahs;

  @override
  Future<QuranAyahTextLayout> getAyahTextLayout() async =>
      QuranAyahTextLayout.separated;

  @override
  Future<List<QuranBookmark>> getBookmarks() async => const [];

  @override
  Future<QuranLastRead?> getLastRead() async => null;

  @override
  Future<List<QuranAyah>> getPageAyahs(
    int pageNumber, {
    bool includeTranslation = false,
    bool includeTafsir = false,
  }) async => ayahs;

  @override
  Future<int> getPageNumberForAyah({
    required int surahNumber,
    required int ayahNumber,
  }) async => 1;

  @override
  Future<String?> getSelectedAudioReciterId() async => selectedReciterId;

  @override
  Future<QuranSurah> getSurah(int surahNumber) async => surah;

  @override
  Future<List<QuranSurah>> getSurahs() async => const [surah];

  @override
  Future<bool> isBookmarked({
    required int surahNumber,
    required int ayahNumber,
  }) async => false;

  @override
  Future<void> saveAyahTextLayout(QuranAyahTextLayout layout) async {}

  @override
  Future<void> saveLastRead({
    required int surahNumber,
    required int ayahNumber,
  }) async {}

  @override
  Future<void> saveSelectedAudioReciterId(String reciterId) async {
    selectedReciterId = reciterId;
  }

  @override
  Future<List<QuranAyah>> search(String query, {int limit = 30}) async =>
      const [];

  @override
  Future<bool> toggleBookmark({
    required int surahNumber,
    required int ayahNumber,
  }) async => true;
}

class _FakeTranslationRepository implements QuranTranslationRepository {
  _FakeTranslationRepository({this.selected});

  QuranTranslationResource? selected;

  @override
  Future<List<QuranTranslationLanguage>> translationLanguages() async => const [
    QuranTranslationLanguage(
      languageName: 'English',
      displayName: 'English',
      resourceCount: 1,
      defaultResource: QuranTranslationResource(
        id: 20,
        languageName: 'English',
        name: 'English translation',
        authorName: 'Author',
        slug: 'english',
      ),
    ),
    QuranTranslationLanguage(
      languageName: 'Urdu',
      displayName: 'Urdu',
      resourceCount: 1,
      defaultResource: _urduTranslation,
    ),
  ];

  @override
  Future<QuranTranslationResource?> selectedTranslation() async => selected;

  @override
  Future<void> setSelectedTranslation(int? resourceId) async {
    selected = resourceId == _urduTranslation.id ? _urduTranslation : null;
  }

  @override
  Future<bool> hasFullTranslation(int resourceId) async => true;

  @override
  Stream<QuranTranslationDownloadProgress> downloadFullTranslation(
    int resourceId,
  ) async* {}

  @override
  Future<String?> cachedTranslationForVerse(
    int resourceId,
    String verseKey,
  ) async => null;

  @override
  Future<Map<String, String>> cachedTranslationsForSurah(
    int resourceId,
    int surahNumber,
  ) async => const {};
}
