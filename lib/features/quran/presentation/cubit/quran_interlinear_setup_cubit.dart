import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/settings_store.dart';
import '../../domain/repositories/quran_interlinear_repository.dart';
import 'quran_interlinear_setup_state.dart';

class QuranInterlinearSetupCubit extends Cubit<QuranInterlinearSetupState> {
  QuranInterlinearSetupCubit({
    required QuranInterlinearRepository repository,
    required SettingsStore settingsStore,
  }) : _repository = repository,
       _settingsStore = settingsStore,
       super(const QuranInterlinearSetupState.initial());

  final QuranInterlinearRepository _repository;
  final SettingsStore _settingsStore;

  Future<void> checkStartup() async {
    emit(
      state.copyWith(
        status: QuranInterlinearSetupStatus.checking,
        clearError: true,
        clearProgress: true,
      ),
    );
    final complete = await _repository.hasFullCache();
    if (complete) {
      emit(state.copyWith(status: QuranInterlinearSetupStatus.complete));
      return;
    }
    if (_settingsStore.interlinearTranslationSkipVersion ==
        _repository.cacheVersion) {
      emit(
        state.copyWith(
          status: QuranInterlinearSetupStatus.ready,
          skipped: true,
        ),
      );
      return;
    }
    emit(state.copyWith(status: QuranInterlinearSetupStatus.prompt));
  }

  Future<void> skipForNow() async {
    await _settingsStore.setInterlinearTranslationSkipVersion(
      _repository.cacheVersion,
    );
    emit(
      state.copyWith(status: QuranInterlinearSetupStatus.ready, skipped: true),
    );
  }

  Future<bool> ensureDownloaded() async {
    final complete = await _repository.hasFullCache();
    if (complete) {
      emit(state.copyWith(status: QuranInterlinearSetupStatus.complete));
      return true;
    }
    await download();
    return state.status == QuranInterlinearSetupStatus.complete;
  }

  Future<bool> hasFullCache() {
    return _repository.hasFullCache();
  }

  Future<void> download() async {
    emit(
      state.copyWith(
        status: QuranInterlinearSetupStatus.downloading,
        clearError: true,
      ),
    );
    try {
      await for (final progress in _repository.downloadFullCache()) {
        emit(
          state.copyWith(
            status: progress.isComplete
                ? QuranInterlinearSetupStatus.complete
                : QuranInterlinearSetupStatus.downloading,
            progress: progress,
          ),
        );
      }
      if (await _repository.hasFullCache()) {
        emit(state.copyWith(status: QuranInterlinearSetupStatus.complete));
      } else if (state.status != QuranInterlinearSetupStatus.complete) {
        emit(
          state.copyWith(
            status: QuranInterlinearSetupStatus.failure,
            errorMessage: 'Some translation pages failed to download.',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranInterlinearSetupStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
