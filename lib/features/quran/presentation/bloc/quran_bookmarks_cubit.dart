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

  Future<void> load() async {
    emit(state.copyWith(status: QuranBookmarksStatus.loading));
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
            translationResource: selectedText == null
                ? null
                : selectedTranslation,
            collectionId: bookmark.collectionId,
          ),
        );
      }
      emit(
        QuranBookmarksState(
          status: QuranBookmarksStatus.success,
          bookmarks: state.selectedCollectionId == null
              ? summaries
              : summaries
                    .where(
                      (item) => item.collectionId == state.selectedCollectionId,
                    )
                    .toList(growable: false),
          collections: collections,
          selectedCollectionId: state.selectedCollectionId,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: QuranBookmarksStatus.failure,
          errorMessage: error.toString(),
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
    await load();
  }

  Future<void> createCollection(
    String name, {
    String description = '',
    int colorValue = 0xFF2E7D5B,
    int iconCodePoint = 0xe0bb,
  }) async {
    final repository = _collectionRepository;
    if (repository == null || name.trim().isEmpty) {
      return;
    }
    await repository.createBookmarkCollection(
      name: name,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );
    await load();
  }

  Future<void> moveBookmark(String verseKey, String collectionId) async {
    await _collectionRepository?.moveBookmarkToCollection(
      verseKey: verseKey,
      collectionId: collectionId,
    );
    await load();
  }

  Future<void> deleteCollection(String collectionId) async {
    await _collectionRepository?.deleteBookmarkCollection(collectionId);
    if (state.selectedCollectionId == collectionId) {
      emit(state.copyWith(clearSelectedCollection: true));
    }
    await load();
  }
}
