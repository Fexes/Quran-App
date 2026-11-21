import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/search/local_search_revision.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:quran/features/hadith/data/stores/hadeeth_enc_store.dart';
import 'package:quran/features/hadith/data/stores/hadith_translation_store.dart';
import 'package:quran/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:quran/features/hifz/data/stores/hifz_store.dart';
import 'package:quran/features/library/data/stores/library_user_data_store.dart';
import 'package:quran/features/prayer/data/datasources/offline_prayer_city_data_source.dart';
import 'package:quran/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:quran/features/prayer_times/data/services/adhan_prayer_calculation_service.dart';
import 'package:quran/features/prayer_tracking/data/stores/prayer_tracking_store.dart';
import 'package:quran/features/quran/data/stores/quran_interlinear_words_store.dart';
import 'package:quran/features/quran/data/stores/quran_tafsir_store.dart';
import 'package:quran/features/quran/data/stores/quran_translation_store.dart';
import 'package:quran/features/quran/data/stores/quran_user_data_store.dart';
import 'package:quran/features/quran/domain/entities/quran_translation.dart';
import 'package:quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:quran/features/quran_audio/data/stores/quran_audio_download_store.dart';
import 'package:quran/features/reading_goals/data/stores/reading_progress_store.dart';
import 'package:quran/features/search/data/repositories/app_search_repository.dart';
import 'package:quran/features/search/data/sources/app_search_sources.dart';
import 'package:quran/features/search/data/sources/live_search_source.dart';
import 'package:quran/features/search/domain/entities/offline_search_result.dart';
import 'package:quran/features/search/domain/entities/search_document.dart';
import 'package:quran/features/search/domain/repositories/offline_search_repository.dart';
import 'package:quran/features/worship_tools/domain/repositories/divine_names_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'downloaded Quran content is searchable after save, edit, and removal',
    () async {
      final translations = QuranTranslationStore.memory();
      await translations.saveCatalog([QuranTranslationResource.urduJalandhari]);
      final source = _sources(
        translations,
      ).sources.singleWhere((source) => source.id == 'quran-translations');
      final registry = AppSearchSourceRegistry([source]);
      final engine = _MemoryEngine();
      final repository = AppSearchRepository(
        engine: engine,
        sources: registry,
        live: _live(),
      );
      addTearDown(repository.dispose);
      expect((await repository.search('downloaded')).hits, isEmpty);
      await translations.saveVerseTranslations(
        resourceId: 234,
        translations: {'1:1': 'downloaded text'},
      );
      final result = await repository.search('downloaded');
      expect(result.hits.single.passage.reference, 'Quran 1:1');
      expect(result.hits.single.passage.translations.single.language, 'ur');
      expect(result.hits.single.passage.route, contains('translation=234'));
      final syncCount = engine.syncCount;
      await repository.search('downloaded');
      expect(
        engine.syncCount,
        syncCount,
        reason: 'Unchanged stores must not rebuild per query.',
      );
      await translations.saveVerseTranslations(
        resourceId: 234,
        translations: {'1:1': 'edited text'},
      );
      expect((await repository.search('downloaded')).hits, isEmpty);
      expect((await repository.search('edited')).hits, hasLength(1));
      await translations.deleteResource(234);
      expect((await repository.search('edited')).hits, isEmpty);
    },
  );

  test(
    'completed stable revisions skip a reopened unchanged store and detect offline deletion',
    () async {
      final values = <String, Object?>{
        'selected_translation_resource': QuranTranslationResource.urduJalandhari
            .toJson(),
        'translation:234:verse:1:1': {
          'text': 'persisted local text',
          'fetchedAt': DateTime.now().toIso8601String(),
        },
      };
      AppSearchSourceRegistry registry(QuranTranslationStore store) =>
          AppSearchSourceRegistry([
            _sources(store).sources.singleWhere(
              (source) => source.id == 'quran-translations',
            ),
          ]);
      _MemoryEngine reopen(_MemoryEngine previous) => _MemoryEngine()
        ..sources.addAll(previous.sources)
        ..completedRevisions.addAll(previous.completedRevisions);
      final firstEngine = _MemoryEngine();
      final first = AppSearchRepository(
        engine: firstEngine,
        sources: registry(QuranTranslationStore.memory(values)),
        live: _live(),
      );
      expect((await first.search('persisted')).hits, hasLength(1));
      await first.dispose();
      final secondEngine = reopen(firstEngine);
      final reopenedStore = QuranTranslationStore.memory(
        Map.fromEntries(values.entries.toList().reversed),
      );
      final second = AppSearchRepository(
        engine: secondEngine,
        sources: registry(reopenedStore),
        live: _live(),
      );
      expect((await second.search('persisted')).hits, hasLength(1));
      expect(
        secondEngine.syncCount,
        0,
        reason:
            'Completed matching snapshots must survive a new coordinator/store instance.',
      );
      await reopenedStore.saveVerseTranslations(
        resourceId: 234,
        translations: {'1:1': 'edited local text'},
      );
      expect((await second.search('edited')).hits, hasLength(1));
      expect(secondEngine.syncCount, 1);
      await second.dispose();
      final thirdEngine = reopen(secondEngine);
      final afterOfflineDeletion = AppSearchRepository(
        engine: thirdEngine,
        sources: registry(QuranTranslationStore.memory()),
        live: _live(),
      );
      addTearDown(afterOfflineDeletion.dispose);
      expect((await afterOfflineDeletion.search('edited')).hits, isEmpty);
      expect(thirdEngine.syncCount, 1);
    },
  );

  test(
    'a skipped persisted snapshot still schedules expiry invalidation',
    () async {
      var available = true;
      LocalStoreSearchSource source() => LocalStoreSearchSource(
        id: 'persisted-expiry',
        snapshot: () => available ? {'item': 'private'} : {},
        nextExpiry: () => DateTime.now().add(const Duration(milliseconds: 30)),
        read: () =>
            Stream.fromIterable(available ? [_document('private')] : []),
      );
      final engine = _MemoryEngine()
        ..completedRevisions['persisted-expiry'] = source().revision
        ..sources['persisted-expiry'] = [_document('private')];
      final repository = AppSearchRepository(
        engine: engine,
        sources: AppSearchSourceRegistry([source()]),
        live: _live(),
      );
      addTearDown(repository.dispose);
      await repository.warmUp();
      expect(engine.syncCount, 0);
      available = false;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect((await repository.search('private')).hits, isEmpty);
      expect(engine.syncCount, 1);
    },
  );

  test(
    'tracking navigation questions search tools rather than only personal records',
    () async {
      final engine = _MemoryEngine();
      final settingsSource = _sources(
        QuranTranslationStore.memory(),
      ).sources.singleWhere((source) => source.id == 'settings');
      final repository = AppSearchRepository(
        engine: engine,
        sources: AppSearchSourceRegistry([settingsSource]),
        live: _live(),
      );
      addTearDown(repository.dispose);
      await repository.search('How can I track my fasting?');
      expect(engine.lastFilter, OfflineSearchFilter.tools);
      expect(
        engine.sources['settings']!.any(
          (document) =>
              document.passage.title.toLowerCase().contains('fasting'),
        ),
        isTrue,
      );
      await repository.search('my fasting records');
      expect(engine.lastFilter, OfflineSearchFilter.saved);
    },
  );

  test(
    'expired downloaded content is excluded and an imminent expiry invalidates its snapshot',
    () async {
      final old = DateTime.now().subtract(const Duration(days: 8));
      final translations = QuranTranslationStore.memory({
        'translation:234:verse:1:1': {
          'text': 'expired phrase',
          'fetchedAt': old.toIso8601String(),
        },
      });
      final source = _sources(
        translations,
      ).sources.singleWhere((source) => source.id == 'quran-translations');
      expect(
        await source.documents().expand((batch) => batch).toList(),
        isEmpty,
      );
      var available = true;
      final expiring = LocalStoreSearchSource(
        id: 'expiry-check',
        nextExpiry: () => DateTime.now().add(const Duration(milliseconds: 5)),
        read: () async* {
          if (available) yield _document('secret');
        },
      );
      final initial = expiring.revision;
      await expiring.documents().drain<void>();
      available = false;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(expiring.revision, isNot(initial));
    },
  );

  test(
    'coordinator retries a result when a deletion finishes during retrieval',
    () async {
      var documents = [_document('private note')];
      final source = LocalStoreSearchSource(
        id: 'race-test',
        read: () => Stream.fromIterable(documents),
      );
      final engine = _MemoryEngine();
      final repository = AppSearchRepository(
        engine: engine,
        sources: AppSearchSourceRegistry([source]),
        live: _live(),
      );
      addTearDown(repository.dispose);
      engine.afterSearch = () {
        documents = [];
        LocalSearchRevision.changed(source: source.id);
      };
      expect((await repository.search('private')).hits, isEmpty);
      expect(engine.syncCount, 2);
      repository.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(engine.indexingEnabled, isFalse);
    },
  );

  test(
    'concurrent searches serialize snapshots when content changes mid-sync',
    () async {
      var documents = [_document('original')];
      final source = LocalStoreSearchSource(
        id: 'concurrent-source',
        read: () => Stream.fromIterable(documents),
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      final engine = _MemoryEngine();
      engine.beforeSync = () async {
        if (!entered.isCompleted) {
          entered.complete();
          await release.future;
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      };
      final repository = AppSearchRepository(
        engine: engine,
        sources: AppSearchSourceRegistry([source]),
        live: _live(),
      );
      addTearDown(repository.dispose);
      final first = repository.search('edited');
      await entered.future;
      final second = repository.search('edited');
      documents = [_document('edited')];
      LocalSearchRevision.changed(source: source.id);
      release.complete();
      final results = await Future.wait([first, second]);
      expect(results.every((result) => result.hits.length == 1), isTrue);
      expect(engine.maxConcurrentSyncs, 1);
    },
  );

  test(
    'personal store restore and deletion notify only their source',
    () async {
      final library = LibraryUserDataStore.memory();
      final readingBefore = LocalSearchRevision.forSource('reading');
      final before = LocalSearchRevision.forSource('library-user');
      await library.saveNote('custom:item', 'A saved reflection');
      expect(LocalSearchRevision.forSource('library-user'), isNot(before));
      expect(LocalSearchRevision.forSource('reading'), readingBefore);
      await library.toggleBookmark('custom:item');
      expect(library.bookmarkedItemKeys, ['custom:item']);
      await library.restoreSnapshot({}, replace: true);
      expect(library.notes, isEmpty);
      expect(library.bookmarkedItemKeys, isEmpty);
    },
  );

  test(
    'explicit offline city queries use that city without changing the saved location',
    () async {
      final settings = SettingsStore.memory();
      await settings.setPrayerLocation(
        name: 'Karachi',
        latitude: 24.8608,
        longitude: 67.0104,
        timeZone: 'Asia/Karachi',
      );
      final live = _live(
        settings: settings,
        cities: OfflinePrayerCityDataSource(),
        clock: () => DateTime.utc(2026, 10, 14, 13),
      );
      final london = await live.search(
        'fajr time in London, United Kingdom tomorrow',
        OfflineSearchFilter.all,
      );
      expect(london.single.passage.metadata['location'], 'London');
      expect(london.single.passage.metadata['timeZone'], 'Europe/London');
      expect(london.single.passage.metadata['date'], '2026-10-15');
      expect(settings.prayerLocationName, 'Karachi');
      expect(settings.prayerTimeZone, 'Asia/Karachi');
      final native = await live.search(
        'timings in کراچی',
        OfflineSearchFilter.all,
      );
      expect(native, hasLength(6));
      expect(native.first.passage.metadata['location'], 'Karachi');
      final ambiguous = await live.search(
        'prayer times in London',
        OfflineSearchFilter.all,
      );
      expect(ambiguous.single.passage.canonicalId, 'live:choose-city');
      expect(ambiguous.single.passage.body, contains('United Kingdom'));
      expect(ambiguous.single.passage.body, contains('Canada'));
      expect(ambiguous.single.passage.metadata.containsKey('time'), isFalse);
      final unknown = await live.search(
        'prayer times for imaginary city',
        OfflineSearchFilter.all,
      );
      expect(unknown.single.passage.canonicalId, 'live:choose-city');
      expect(unknown.single.passage.metadata.containsKey('time'), isFalse);
    },
  );

  test(
    'live times use saved timezone day and recalculate on date/location change',
    () async {
      final settings = SettingsStore.memory();
      await settings.setPrayerLocation(
        name: 'Kiritimati',
        latitude: 1.8721,
        longitude: -157.4278,
        timeZone: 'Pacific/Kiritimati',
      );
      final live = _live(
        settings: settings,
        clock: () => DateTime.utc(2026, 10, 14, 13),
      );
      final today = await live.search(
        'fajr time today',
        OfflineSearchFilter.all,
      );
      expect(today.single.passage.metadata['date'], '2026-10-15');
      expect(today.single.passage.metadata['timeZone'], 'Pacific/Kiritimati');
      final tomorrow = await live.search(
        'fajr time tomorrow',
        OfflineSearchFilter.all,
      );
      expect(tomorrow.single.passage.metadata['date'], '2026-10-16');
      await settings.setPrayerLocation(
        name: 'Honolulu',
        latitude: 21.3099,
        longitude: -157.8581,
        timeZone: 'Pacific/Honolulu',
      );
      final changed = await live.search(
        'fajr time today',
        OfflineSearchFilter.all,
      );
      expect(changed.single.passage.metadata['date'], '2026-10-14');
      expect(changed.single.passage.metadata['location'], 'Honolulu');
      expect(
        await live.search('dua for iftar', OfflineSearchFilter.all),
        isEmpty,
      );
      expect(
        await live.search('fajr importance', OfflineSearchFilter.all),
        isEmpty,
      );
      expect(
        await live.search('jummah time', OfflineSearchFilter.all),
        isEmpty,
        reason:
            'Calculated Dhuhr must not invent a mosque congregation schedule.',
      );
      expect(
        await live.search(
          'what Quran says about prayer',
          OfflineSearchFilter.all,
        ),
        isEmpty,
      );
    },
  );
}

LiveSearchSource _live({
  SettingsStore? settings,
  DateTime Function()? clock,
  OfflinePrayerCityDataSource? cities,
}) {
  final store = settings ?? SettingsStore.memory();
  return LiveSearchSource(
    settings: store,
    clock: clock,
    cities: cities,
    prayerTimes: PrayerTimesRepositoryImpl(
      calculationService: const AdhanPrayerCalculationService(),
      settingsStore: store,
    ),
  );
}

AppSearchSourceRegistry _sources(QuranTranslationStore translations) =>
    createAppSearchSources(
      quran: _Quran(),
      translations: translations,
      tafsirs: QuranTafsirStore.memory(),
      interlinear: QuranInterlinearWordsStore.memory(),
      quranUser: QuranUserDataStore.memory(),
      hadith: _Hadith(),
      hadithTranslations: HadithTranslationStore.memory(),
      hadeethEnc: HadeethEncStore.memory(),
      azkar: _Azkar(),
      libraryUser: LibraryUserDataStore.memory(),
      hifz: HifzStore.memory(),
      reading: ReadingProgressStore.memory(),
      journal: PrayerTrackingStore.memory(),
      audio: QuranAudioDownloadStore.memory(),
      settings: SettingsStore.memory(),
      divineNames: _Names(),
    );

SearchDocument _document(String text) => SearchDocument(
  id: 'note',
  text: text,
  passage: OfflineSearchPassage(
    canonicalId: 'note',
    kind: 'notes',
    reference: '',
    title: 'My note',
    arabic: '',
    translations: const [],
    grades: const [],
    body: text,
    isUserContent: true,
  ),
);

class _MemoryEngine implements MutableOfflineSearchRepository {
  final sources = <String, List<SearchDocument>>{};
  final completedRevisions = <String, String>{};
  int syncCount = 0;
  int concurrentSyncs = 0;
  int maxConcurrentSyncs = 0;
  bool indexingEnabled = false;
  void Function()? afterSearch;
  Future<void> Function()? beforeSync;
  OfflineSearchFilter? lastFilter;
  @override
  Future<void> synchronizeSource(
    String sourceId,
    String revision,
    Stream<List<SearchDocument>> batches,
  ) async {
    concurrentSyncs++;
    if (concurrentSyncs > maxConcurrentSyncs) {
      maxConcurrentSyncs = concurrentSyncs;
    }
    try {
      await beforeSync?.call();
      sources[sourceId] = await batches.expand((batch) => batch).toList();
      completedRevisions[sourceId] = revision;
      syncCount++;
    } finally {
      concurrentSyncs--;
    }
  }

  @override
  Future<void> warmUp() async {}
  @override
  Future<Map<String, String>> completedSourceRevisions() async =>
      Map.of(completedRevisions);
  @override
  Future<void> setIndexingEnabled(bool enabled) async {
    indexingEnabled = enabled;
  }

  @override
  Future<void> dispose() async {}
  @override
  Future<OfflineSearchResponse> search(
    String query, {
    OfflineSearchFilter filter = OfflineSearchFilter.all,
    int limit = 20,
  }) async {
    lastFilter = filter;
    final hits = [
      for (final documents in sources.values)
        for (final document in documents)
          if (document.text.contains(query))
            OfflineSearchHit(passage: document.passage, score: 1),
    ];
    final callback = afterSearch;
    afterSearch = null;
    callback?.call();
    return OfflineSearchResponse(
      hits: hits,
      timingsMs: const {},
      semanticAvailable: true,
    );
  }
}

class _Quran implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Hadith implements HadithRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Azkar implements AzkarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Names implements DivineNamesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
