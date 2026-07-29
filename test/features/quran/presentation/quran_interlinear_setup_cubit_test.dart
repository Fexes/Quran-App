import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/storage/settings_store.dart';
import 'package:quran/features/quran/domain/entities/quran_word.dart';
import 'package:quran/features/quran/domain/repositories/quran_interlinear_repository.dart';
import 'package:quran/features/quran/presentation/cubit/quran_interlinear_setup_cubit.dart';
import 'package:quran/features/quran/presentation/cubit/quran_interlinear_setup_state.dart';

void main() {
  group('QuranInterlinearSetupCubit', () {
    test('prompts when cache is missing and skip is not saved', () async {
      final cubit = QuranInterlinearSetupCubit(
        repository: _FakeInterlinearRepository(hasCache: false),
        settingsStore: SettingsStore.memory(),
      );

      await cubit.checkStartup();

      expect(cubit.state.status, QuranInterlinearSetupStatus.prompt);
      await cubit.close();
    });

    test('skip stores the current cache version', () async {
      final settingsStore = SettingsStore.memory();
      final repository = _FakeInterlinearRepository(hasCache: false);
      final cubit = QuranInterlinearSetupCubit(
        repository: repository,
        settingsStore: settingsStore,
      );

      await cubit.skipForNow();

      expect(cubit.state.status, QuranInterlinearSetupStatus.ready);
      expect(cubit.state.skipped, isTrue);
      expect(
        settingsStore.interlinearTranslationSkipVersion,
        repository.cacheVersion,
      );
      await cubit.close();
    });

    test('download reports progress and completes cache', () async {
      final repository = _FakeInterlinearRepository(hasCache: false);
      final cubit = QuranInterlinearSetupCubit(
        repository: repository,
        settingsStore: SettingsStore.memory(),
      );

      await cubit.download();

      expect(cubit.state.status, QuranInterlinearSetupStatus.complete);
      expect(cubit.state.progress?.completedPages, 2);
      expect(await repository.hasFullCache(), isTrue);
      await cubit.close();
    });
  });
}

class _FakeInterlinearRepository implements QuranInterlinearRepository {
  _FakeInterlinearRepository({required bool hasCache}) : _hasCache = hasCache;

  bool _hasCache;

  @override
  String get cacheVersion => 'test-cache-v1';

  @override
  Future<List<QuranWord>> cachedPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return const [];
  }

  @override
  Stream<QuranInterlinearDownloadProgress> downloadFullCache({
    String language = 'en',
  }) async* {
    yield const QuranInterlinearDownloadProgress(
      completedPages: 1,
      totalPages: 2,
      failedPages: 0,
    );
    _hasCache = true;
    yield const QuranInterlinearDownloadProgress(
      completedPages: 2,
      totalPages: 2,
      failedPages: 0,
      isComplete: true,
    );
  }

  @override
  Future<List<QuranWord>> getPageWords(
    int pageNumber, {
    String language = 'en',
  }) async {
    return const [];
  }

  @override
  Future<bool> hasFullCache({String language = 'en'}) async {
    return _hasCache;
  }
}
