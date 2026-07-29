import 'package:equatable/equatable.dart';

import '../../domain/entities/qibla_direction.dart';

enum QiblaStatus { initial, loading, success, failure }

class QiblaState extends Equatable {
  const QiblaState({required this.status, this.direction, this.errorMessage});

  const QiblaState.initial()
    : status = QiblaStatus.initial,
      direction = null,
      errorMessage = null;

  final QiblaStatus status;
  final QiblaDirection? direction;
  final String? errorMessage;

  QiblaState copyWith({
    QiblaStatus? status,
    QiblaDirection? direction,
    String? errorMessage,
  }) {
    return QiblaState(
      status: status ?? this.status,
      direction: direction ?? this.direction,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, direction, errorMessage];
}
