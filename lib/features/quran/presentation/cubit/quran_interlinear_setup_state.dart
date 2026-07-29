import 'package:equatable/equatable.dart';

import '../../domain/entities/quran_word.dart';

enum QuranInterlinearSetupStatus {
  checking,
  ready,
  prompt,
  downloading,
  complete,
  failure,
}

class QuranInterlinearSetupState extends Equatable {
  const QuranInterlinearSetupState({
    required this.status,
    required this.progress,
    required this.errorMessage,
    required this.skipped,
  });

  const QuranInterlinearSetupState.initial()
    : status = QuranInterlinearSetupStatus.checking,
      progress = null,
      errorMessage = null,
      skipped = false;

  final QuranInterlinearSetupStatus status;
  final QuranInterlinearDownloadProgress? progress;
  final String? errorMessage;
  final bool skipped;

  bool get cacheComplete =>
      status == QuranInterlinearSetupStatus.complete ||
      status == QuranInterlinearSetupStatus.ready && !skipped;

  QuranInterlinearSetupState copyWith({
    QuranInterlinearSetupStatus? status,
    QuranInterlinearDownloadProgress? progress,
    bool clearProgress = false,
    String? errorMessage,
    bool clearError = false,
    bool? skipped,
  }) {
    return QuranInterlinearSetupState(
      status: status ?? this.status,
      progress: clearProgress ? null : progress ?? this.progress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      skipped: skipped ?? this.skipped,
    );
  }

  @override
  List<Object?> get props => [status, progress, errorMessage, skipped];
}
