import 'package:equatable/equatable.dart';

import '../../../../search/domain/entities/deep_search_result.dart';

enum QuranSearchStatus { initial, loading, success, empty, failure }

class QuranSearchState extends Equatable {
  const QuranSearchState({
    required this.status,
    required this.query,
    required this.sections,
    this.selectedCategory,
    this.errorMessage,
  });

  const QuranSearchState.initial()
    : status = QuranSearchStatus.initial,
      query = '',
      sections = const [],
      selectedCategory = null,
      errorMessage = null;

  final QuranSearchStatus status;
  final String query;
  final List<DeepSearchSection> sections;
  final DeepSearchCategory? selectedCategory;
  final String? errorMessage;

  List<DeepSearchSection> get visibleSections {
    final category = selectedCategory;
    if (category == null) {
      return sections;
    }
    return sections
        .where((section) => section.category == category)
        .toList(growable: false);
  }

  Map<DeepSearchCategory, int> get categoryCounts {
    return {
      for (final section in sections) section.category: section.totalCount,
    };
  }

  QuranSearchState copyWith({
    QuranSearchStatus? status,
    String? query,
    List<DeepSearchSection>? sections,
    DeepSearchCategory? selectedCategory,
    bool clearSelectedCategory = false,
    String? errorMessage,
  }) {
    return QuranSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      sections: sections ?? this.sections,
      selectedCategory: clearSelectedCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    sections,
    selectedCategory,
    errorMessage,
  ];
}
