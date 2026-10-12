import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_ayah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/quran_translation_repository.dart';
import 'quran_bookmarks_state.dart';

class QuranBookmarksCubit extends Cubit<QuranBookmarksState> {
  QuranBookmarksCubit({
    required QuranRepository repository,
    QuranTranslationRepository? translationRepository,
  }) : _repository = repository,
       _collectionRepository = repository is QuranBookmarkCollectionsRepository
           ? repository as QuranBookmarkCollectionsRepository
           : null,
       _translationRepository = translationRepository,
       super(const QuranBookmarksState.initial());

  final QuranRepository _repository;
  final QuranBookmarkCollectionsRepository? _collectionRepository;
  final QuranTranslationRepository? _translationRepository;
  int _loadRequest = 0;

  Future<void> load() async {
    if (isClosed) return;
    final request = ++_loadRequest;
    final hasContent = state.status == QuranBookmarksStatus.success;
    emit(
      state.copyWith(
        status: hasContent ? state.status : QuranBookmarksStatus.loading,
        isRefreshing: hasContent,
      ),
    );
    try {
      final bookmarks = await _repository.getBookmarks();
      final collections =
          await _collectionRepository?.getBookmarkCollections() ?? const [];
      final translations = _translationRepository;
      var selectedTranslation = await translations?.selectedTranslation();
      if (selectedTranslation != null &&
          (translations == null ||
              !await translations.hasFullTranslation(selectedTranslation.id))) {
        selectedTranslation = null;
      }
      final summaries = <QuranBookmarkSummary>[];
      for (final bookmark in bookmarks) {
        final surah = await _repository.getSurah(bookmark.surahNumber);
        final ayahs = await _repository.getAyahs(bookmark.surahNumber);
        QuranAyah? ayah;
        for (final item in ayahs) {
          if (item.number == bookmark.ayahNumber) {
            ayah = item;
            break;
          }
        }
        if (ayah == null) {
          continue;
        }
        final selectedText = selectedTranslation == null
            ? null
            : await translations!.cachedTranslationForVerse(
                selectedTranslation.id,
                ayah.verseKey,
              );
        summaries.add(
          QuranBookmarkSummary(
            surah: surah,
            ayah: ayah,
            translation: selectedText ?? ayah.translation,
            createdAt: bookmark.createdAt,
            translationResource: selectedText == null
                ? null
                : selectedTranslation,
            collectionId: bookmark.collectionId,
          ),
        );
      }
      if (isClosed || request != _loadRequest) return;
      assert(
        summaries.map((item) => item.ayah.verseKey).toSet().length ==
            summaries.length,
      );
      emit(
        state.copyWith(
          status: QuranBookmarksStatus.success,
          bookmarks: summaries,
          collections: collections,
          clearSelectedCollection: !collections.any(
            (item) => item.id == state.selectedCollectionId,
          ),
          isRefreshing: false,
        ),
      );
    } catch (_) {
      if (isClosed || request != _loadRequest) return;
      emit(
        state.copyWith(
          status: hasContent
              ? QuranBookmarksStatus.success
              : QuranBookmarksStatus.failure,
          isRefreshing: false,
          errorMessage: 'Bookmarks could not be refreshed. Please try again.',
        ),
      );
    }
  }

  Future<void> selectCollection(String? collectionId) async {
    emit(
      state.copyWith(
        selectedCollectionId: collectionId,
        clearSelectedCollection: collectionId == null,
      ),
    );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void sortBy(QuranBookmarkSort sort) => emit(state.copyWith(sort: sort));

  Future<bool> createCollection(
    String name, {
    String description = '',
    int colorValue = 0xFF2E7D5B,
    int iconCodePoint = 0xe0bb,
  }) async {
    final repository = _collectionRepository;
    if (repository == null || name.trim().isEmpty) {
      return false;
    }
    return _update(() async {
      await repository.createBookmarkCollection(
        name: name,
        description: description,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      );
    });
  }

  Future<bool> moveBookmark(String verseKey, String collectionId) =>
      _update(() async {
        await _collectionRepository?.moveBookmarkToCollection(
          verseKey: verseKey,
          collectionId: collectionId,
        );
      });

  Future<bool> deleteCollection(String collectionId) => _update(() async {
    await _collectionRepository?.deleteBookmarkCollection(collectionId);
  });

  Future<bool> removeBookmark(QuranBookmarkSummary bookmark) =>
      _update(() async {
        if (await _repository.isBookmarked(
          surahNumber: bookmark.surah.number,
          ayahNumber: bookmark.ayah.number,
        )) {
          await _repository.toggleBookmark(
            surahNumber: bookmark.surah.number,
            ayahNumber: bookmark.ayah.number,
          );
        }
      });

  Future<bool> _update(Future<void> Function() action) async {
    if (isClosed || state.isUpdating) return false;
    emit(state.copyWith(isUpdating: true));
    try {
      await action();
      await load();
      return true;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            errorMessage: 'Changes could not be saved. Please try again.',
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(isUpdating: false, errorMessage: state.errorMessage),
        );
      }
    }
  }
}
