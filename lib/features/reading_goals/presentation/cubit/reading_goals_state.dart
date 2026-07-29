import 'package:equatable/equatable.dart';

import '../../domain/entities/reading_progress.dart';

enum ReadingGoalsStatus { initial, loading, success, failure }

class ReadingGoalsState extends Equatable {
  const ReadingGoalsState({
    required this.status,
    this.dashboard,
    this.errorMessage,
  });

  const ReadingGoalsState.initial()
    : status = ReadingGoalsStatus.initial,
      dashboard = null,
      errorMessage = null;

  final ReadingGoalsStatus status;
  final ReadingDashboard? dashboard;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, dashboard, errorMessage];
}
