import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/hadeeth_enc_item.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/repositories/hadith_repository.dart';
import 'hadith_library_state.dart';

class HadithLibraryCubit extends Cubit<HadithLibraryState> {
  HadithLibraryCubit({required HadithRepository repository})
    : _repository = repository,
      super(const HadithLibraryState.initial());

  final HadithRepository _repository;
  static const _pageSize = 50;
  var _searchRequestId = 0;

  Future<void> load() async {
    _searchRequestId++;
    emit(
      state.copyWith(
        status: HadithLibraryStatus.loading,
        selectedBookId: null,
        selectedChapterId: null,
        query: '',
      ),
    );
    try {
      final sources = await _repository.getContentSources();
      final books = await _repository.getBooks();
      emit(
        HadithLibraryState(
          status: books.isEmpty
              ? HadithLibraryStatus.empty
              : HadithLibraryStatus.success,
          books: books,
          chapters: const [],
          hadiths: const [],
          contentSources: sources,
          query: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HadithLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> loadHadeethEncLanguages() async {
    if (state.hadeethEncLanguages.isNotEmpty) {
      return;
    }
    emit(state.copyWith(hadeethEncLoading: true, hadeethEncErrorMessage: null));
    try {
      final languages = await _repository.getHadeethEncLanguages();
      final selectedLanguage =
          state.selectedHadeethEncLanguageCode ??
          _preferredHadeethEncLanguage(languages);
      final downloaded = selectedLanguage == null
          ? false
          : await _repository.hasHadeethEncLanguage(selectedLanguage);
      final items = selectedLanguage != null && downloaded
          ? await _hadeethEncPage(selectedLanguage)
          : const <HadithItem>[];
      emit(
        state.copyWith(
          hadeethEncLanguages: languages,
          selectedHadeethEncLanguageCode: selectedLanguage,
          selectedHadeethEncLanguageDownloaded: downloaded,
          hadeethEncHadiths: items,
          hasMoreHadeethEncHadiths: items.length == _pageSize,
          hadeethEncLoading: false,
          hadeethEncErrorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          hadeethEncLoading: false,
          hadeethEncErrorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> selectHadeethEncLanguage(String languageCode) async {
    final downloaded = await _repository.hasHadeethEncLanguage(languageCode);
    final items = downloaded
        ? await _hadeethEncPage(languageCode)
        : const <HadithItem>[];
    emit(
      state.copyWith(
        selectedHadeethEncLanguageCode: languageCode,
        selectedHadeethEncLanguageDownloaded: downloaded,
        hadeethEncHadiths: items,
        hasMoreHadeethEncHadiths: items.length == _pageSize,
        hadeethEncDownloadProgress: null,
        hadeethEncLoading: false,
        hadeethEncErrorMessage: null,
      ),
    );
  }

  Future<void> downloadSelectedHadeethEncLanguage() async {
    final languageCode =
        state.selectedHadeethEncLanguageCode ??
        _preferredHadeethEncLanguage(state.hadeethEncLanguages);
    if (languageCode == null) {
      return;
    }

    emit(
      state.copyWith(
        selectedHadeethEncLanguageCode: languageCode,
        hadeethEncLoading: true,
        hadeethEncErrorMessage: null,
      ),
    );
    await for (final progress in _repository.downloadHadeethEncLanguage(
      languageCode,
    )) {
      emit(
        state.copyWith(
          hadeethEncDownloadProgress: progress,
          hadeethEncLoading: !progress.isComplete && !progress.hasFailed,
          selectedHadeethEncLanguageDownloaded: progress.isComplete,
          hadeethEncErrorMessage: progress.hasFailed
              ? 'Hadith translation download failed.'
              : null,
        ),
      );
    }

    if (await _repository.hasHadeethEncLanguage(languageCode)) {
      final items = await _hadeethEncPage(languageCode);
      emit(
        state.copyWith(
          hadeethEncLoading: false,
          selectedHadeethEncLanguageDownloaded: true,
          hadeethEncHadiths: items,
          hasMoreHadeethEncHadiths: items.length == _pageSize,
        ),
      );
    }
  }

  Future<void> loadMoreHadeethEnc() async {
    final languageCode = state.selectedHadeethEncLanguageCode;
    if (languageCode == null || !state.hasMoreHadeethEncHadiths) {
      return;
    }
    final next = await _repository.getHadeethEncItems(
      languageCode: languageCode,
      offset: state.hadeethEncHadiths.length,
      limit: _pageSize,
    );
    emit(
      state.copyWith(
        hadeethEncHadiths: [
          ...state.hadeethEncHadiths,
          ..._toHadithItems(next),
        ],
        hasMoreHadeethEncHadiths: next.length == _pageSize,
      ),
    );
  }

  Future<List<HadithItem>> _hadeethEncPage(String languageCode) async {
    final items = await _repository.getHadeethEncItems(
      languageCode: languageCode,
      limit: _pageSize,
    );
    return _toHadithItems(items);
  }

  List<HadithItem> _toHadithItems(List<HadeethEncItem> items) {
    return [for (final item in items) item.toHadithItem()];
  }

  String? _preferredHadeethEncLanguage(List<HadeethEncLanguage> languages) {
    if (languages.isEmpty) {
      return null;
    }
    for (final language in languages) {
      if (language.code == 'en') {
        return 'en';
      }
    }
    return languages.first.code;
  }

  Future<void> openBook(
    String bookId, {
    String? chapterId,
    String? languageCode,
  }) async {
    _searchRequestId++;
    emit(
      state.copyWith(
        status: HadithLibraryStatus.loading,
        selectedBookId: bookId,
        selectedChapterId: chapterId,
        selectedTranslationLanguageCode: languageCode,
        query: '',
      ),
    );
    try {
      final sources = await _repository.getContentSources();
      final books = state.books.isEmpty
          ? await _repository.getBooks()
          : state.books;
      final chapters = await _repository.getChapters(bookId);
      final hadiths = await _repository.getHadiths(
        bookId: bookId,
        chapterId: chapterId,
        languageCode: languageCode,
        limit: _pageSize,
      );
      emit(
        HadithLibraryState(
          status: hadiths.isEmpty
              ? HadithLibraryStatus.empty
              : HadithLibraryStatus.success,
          books: books,
          chapters: chapters,
          hadiths: hadiths,
          contentSources: sources,
          query: '',
          selectedBookId: bookId,
          selectedChapterId: chapterId,
          selectedTranslationLanguageCode: languageCode,
          hasMoreHadiths: hadiths.length == _pageSize,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HadithLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final bookId = state.selectedBookId;
    if (bookId == null || !state.hasMoreHadiths || state.query.isNotEmpty) {
      return;
    }
    try {
      final next = await _repository.getHadiths(
        bookId: bookId,
        chapterId: state.selectedChapterId,
        languageCode: state.selectedTranslationLanguageCode,
        offset: state.hadiths.length,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          hadiths: [...state.hadiths, ...next],
          hasMoreHadiths: next.length == _pageSize,
        ),
      );
    } catch (_) {
      emit(state.copyWith(hasMoreHadiths: false));
    }
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    final requestId = ++_searchRequestId;
    if (normalized.isEmpty) {
      await load();
      return;
    }

    emit(
      state.copyWith(status: HadithLibraryStatus.loading, query: normalized),
    );
    try {
      final sources = await _repository.getContentSources();
      final books = await _repository.getBooks();
      final results = await _repository.search(normalized);
      if (requestId != _searchRequestId) {
        return;
      }
      emit(
        HadithLibraryState(
          status: results.isEmpty
              ? HadithLibraryStatus.empty
              : HadithLibraryStatus.success,
          books: books,
          chapters: const [],
          hadiths: results,
          contentSources: sources,
          query: normalized,
          selectedBookId: null,
          selectedChapterId: null,
        ),
      );
    } catch (error) {
      if (requestId != _searchRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: HadithLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> searchInBook({
    required String bookId,
    required String query,
    String? languageCode,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      await openBook(bookId, languageCode: languageCode);
      return;
    }
    final exactNumber = _exactHadithNumberFrom(normalized);
    if (exactNumber != null) {
      await lookupHadith(
        bookId: bookId,
        rawQuery: exactNumber,
        languageCode: languageCode,
      );
      return;
    }

    final requestId = ++_searchRequestId;
    emit(
      state.copyWith(
        status: HadithLibraryStatus.loading,
        query: normalized,
        selectedBookId: bookId,
        selectedChapterId: null,
        selectedTranslationLanguageCode: languageCode,
        hadiths: const [],
        hasMoreHadiths: false,
      ),
    );
    try {
      final sources = await _repository.getContentSources();
      final books = state.books.isEmpty
          ? await _repository.getBooks()
          : state.books;
      final chapters = await _repository.getChapters(bookId);
      final results = _repository is HadithScopedSearchRepository
          ? await (_repository as HadithScopedSearchRepository).searchInBook(
              bookId: bookId,
              query: normalized,
              languageCode: languageCode,
              limit: _pageSize,
            )
          : (await _repository.search(normalized, limit: _pageSize))
                .where((hadith) => hadith.bookId == bookId)
                .toList(growable: false);
      if (requestId != _searchRequestId) {
        return;
      }
      emit(
        HadithLibraryState(
          status: results.isEmpty
              ? HadithLibraryStatus.empty
              : HadithLibraryStatus.success,
          books: books,
          chapters: chapters,
          hadiths: results,
          contentSources: sources,
          query: normalized,
          selectedBookId: bookId,
          selectedChapterId: null,
          selectedTranslationLanguageCode: languageCode,
          hasMoreHadiths: false,
        ),
      );
    } catch (error) {
      if (requestId != _searchRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: HadithLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> lookupHadith({
    required String bookId,
    required String rawQuery,
    String? languageCode,
  }) async {
    _searchRequestId++;
    final hadithNumber = _hadithNumberFrom(rawQuery);
    if (hadithNumber == null) {
      emit(
        state.copyWith(
          status: HadithLibraryStatus.empty,
          query: rawQuery.trim(),
          selectedBookId: bookId,
          selectedChapterId: null,
          selectedTranslationLanguageCode: languageCode,
          hadiths: const [],
          hasMoreHadiths: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: HadithLibraryStatus.loading,
        query: hadithNumber,
        selectedBookId: bookId,
        selectedChapterId: null,
        selectedTranslationLanguageCode: languageCode,
        hadiths: const [],
        hasMoreHadiths: false,
      ),
    );
    try {
      final sources = await _repository.getContentSources();
      final books = state.books.isEmpty
          ? await _repository.getBooks()
          : state.books;
      final chapters = await _repository.getChapters(bookId);
      final item = await _repository.getHadithById(
        'hadith:$bookId:$hadithNumber',
        languageCode: languageCode,
      );
      emit(
        HadithLibraryState(
          status: item == null
              ? HadithLibraryStatus.empty
              : HadithLibraryStatus.success,
          books: books,
          chapters: chapters,
          hadiths: item == null ? const [] : [item],
          contentSources: sources,
          query: hadithNumber,
          selectedBookId: bookId,
          selectedChapterId: null,
          selectedTranslationLanguageCode: languageCode,
          hasMoreHadiths: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HadithLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  String? _hadithNumberFrom(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final match = RegExp(r'\d+(?:\.\d+)?').allMatches(normalized).lastOrNull;
    return match?.group(0);
  }

  String? _exactHadithNumberFrom(String raw) {
    final match = RegExp(r'^\s*#?\s*(\d+(?:\.\d+)?)\s*$').firstMatch(raw);
    return match?.group(1);
  }
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull {
    T? value;
    var found = false;
    for (final item in this) {
      value = item;
      found = true;
    }
    return found ? value : null;
  }
}
