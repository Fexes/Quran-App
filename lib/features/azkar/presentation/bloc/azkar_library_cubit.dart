import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dhikr_item.dart';
import '../../domain/repositories/azkar_repository.dart';
import 'azkar_library_state.dart';

class AzkarLibraryCubit extends Cubit<AzkarLibraryState> {
  AzkarLibraryCubit({required AzkarRepository repository})
    : _repository = repository,
      super(const AzkarLibraryState.initial());

  final AzkarRepository _repository;

  Future<void> load({String? categoryId}) async {
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
          : await _repository.getDhikr(categoryId: categoryId);
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
      emit(
        state.copyWith(
          status: AzkarLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      await load(categoryId: state.selectedCategoryId);
      return;
    }

    emit(state.copyWith(status: AzkarLibraryStatus.loading, query: normalized));
    try {
      final sources = await _repository.getContentSources();
      final categories = await _repository.getCategories();
      final results = await _repository.search(normalized);
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
      emit(
        state.copyWith(
          status: AzkarLibraryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
