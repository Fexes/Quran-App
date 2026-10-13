import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dhikr_item.dart';
import '../../domain/repositories/azkar_repository.dart';
import 'azkar_library_state.dart';

class AzkarLibraryCubit extends Cubit<AzkarLibraryState> {
  AzkarLibraryCubit({required AzkarRepository repository})
    : _repository = repository,
      super(const AzkarLibraryState.initial());

  final AzkarRepository _repository;
  String _languageCode = 'en';
  int _requestRevision = 0;

  Future<void> load({String? categoryId, String? languageCode}) async {
    if (isClosed) return;
    final revision = ++_requestRevision;
    _languageCode = languageCode ?? _languageCode;
    emit(
      state.copyWith(
        status: AzkarLibraryStatus.loading,
        selectedCategoryId: categoryId,
        query: '',
      ),
    );
    try {
      final sources = await _repository.getContentSources();
      final categories = await _repository.getCategories();
      final dhikr = categoryId == null
          ? const <DhikrItem>[]
          : await _repository.getDhikr(
              categoryId: categoryId,
              languageCode: _languageCode,
              limit: 10000,
            );
      if (isClosed || revision != _requestRevision) return;
      emit(
        AzkarLibraryState(
          status: categories.isEmpty || (categoryId != null && dhikr.isEmpty)
              ? AzkarLibraryStatus.empty
              : AzkarLibraryStatus.success,
          categories: categories,
          dhikr: dhikr,
          contentSources: sources,
          query: '',
          selectedCategoryId: categoryId,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _requestRevision) return;
      emit(
        state.copyWith(
          status: AzkarLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> search(String query) async {
    if (isClosed) return;
    final normalized = query.trim();
    if (normalized.isEmpty) {
      await load(categoryId: state.selectedCategoryId);
      return;
    }

    final revision = ++_requestRevision;
    emit(state.copyWith(status: AzkarLibraryStatus.loading, query: normalized));
    try {
      final sources = await _repository.getContentSources();
      final categories = await _repository.getCategories();
      var results = await _repository.search(normalized);
      if (_languageCode != 'en') {
        final localized = <String, DhikrItem>{};
        for (final id in results.map((item) => item.categoryId).toSet()) {
          final items = await _repository.getDhikr(
            categoryId: id,
            languageCode: _languageCode,
            limit: 10000,
          );
          localized.addEntries(items.map((item) => MapEntry(item.id, item)));
        }
        results = [
          for (final item in results)
            localized[item.id] ?? item.withTranslation(translation: ''),
        ];
      }
      if (isClosed || revision != _requestRevision) return;
      emit(
        AzkarLibraryState(
          status: results.isEmpty
              ? AzkarLibraryStatus.empty
              : AzkarLibraryStatus.success,
          categories: categories,
          dhikr: results,
          contentSources: sources,
          query: normalized,
          selectedCategoryId: state.selectedCategoryId,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _requestRevision) return;
      emit(
        state.copyWith(
          status: AzkarLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
