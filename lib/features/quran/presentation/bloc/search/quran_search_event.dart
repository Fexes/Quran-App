import 'package:equatable/equatable.dart';

import '../../../../search/domain/entities/deep_search_result.dart';

sealed class QuranSearchEvent extends Equatable {
  const QuranSearchEvent();

  @override
  List<Object> get props => [];
}

class QuranSearchSubmitted extends QuranSearchEvent {
  const QuranSearchSubmitted(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

class QuranSearchQueryChanged extends QuranSearchEvent {
  const QuranSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

class QuranSearchWarmUpRequested extends QuranSearchEvent {
  const QuranSearchWarmUpRequested();
}

class QuranSearchCategorySelected extends QuranSearchEvent {
  const QuranSearchCategorySelected(this.category);

  final DeepSearchCategory? category;

  @override
  List<Object> get props => [category ?? 'all'];
}

class QuranSearchCleared extends QuranSearchEvent {
  const QuranSearchCleared();
}
