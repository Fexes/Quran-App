import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_surah.dart';

enum QuranListStatus { initial, loading, success, failure }

class QuranListState extends Equatable {
  const QuranListState({
    required this.status,
    required this.surahs,
    required this.visibleSurahs,
    required this.query,
    this.errorMessage,
  });

  const QuranListState.initial()
    : status = QuranListStatus.initial,
      surahs = const [],
      visibleSurahs = const [],
      query = '',
      errorMessage = null;

  final QuranListStatus status;
  final List<QuranSurah> surahs;
  final List<QuranSurah> visibleSurahs;
  final String query;
  final String? errorMessage;

  QuranListState copyWith({
    QuranListStatus? status,
    List<QuranSurah>? surahs,
    List<QuranSurah>? visibleSurahs,
    String? query,
    String? errorMessage,
  }) {
    return QuranListState(
      status: status ?? this.status,
      surahs: surahs ?? this.surahs,
      visibleSurahs: visibleSurahs ?? this.visibleSurahs,
      query: query ?? this.query,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    surahs,
    visibleSurahs,
    query,
    errorMessage,
  ];
}
