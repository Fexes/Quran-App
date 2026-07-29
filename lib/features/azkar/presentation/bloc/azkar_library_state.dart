import 'package:equatable/equatable.dart';

import '../../../../core/content/content_source.dart';
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/dhikr_item.dart';

enum AzkarLibraryStatus { initial, loading, success, empty, failure }

class AzkarLibraryState extends Equatable {
  const AzkarLibraryState({
    required this.status,
    required this.categories,
    required this.dhikr,
    required this.contentSources,
    required this.query,
    this.selectedCategoryId,
    this.errorMessage,
  });

  const AzkarLibraryState.initial()
    : status = AzkarLibraryStatus.initial,
      categories = const [],
      dhikr = const [],
      contentSources = const [],
      query = '',
      selectedCategoryId = null,
      errorMessage = null;

  final AzkarLibraryStatus status;
  final List<AzkarCategory> categories;
  final List<DhikrItem> dhikr;
  final List<ContentSource> contentSources;
  final String query;
  final String? selectedCategoryId;
  final String? errorMessage;

  AzkarLibraryState copyWith({
    AzkarLibraryStatus? status,
    List<AzkarCategory>? categories,
    List<DhikrItem>? dhikr,
    List<ContentSource>? contentSources,
    String? query,
    String? selectedCategoryId,
    String? errorMessage,
  }) {
    return AzkarLibraryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      dhikr: dhikr ?? this.dhikr,
      contentSources: contentSources ?? this.contentSources,
      query: query ?? this.query,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    dhikr,
    contentSources,
    query,
    selectedCategoryId,
    errorMessage,
  ];
}
