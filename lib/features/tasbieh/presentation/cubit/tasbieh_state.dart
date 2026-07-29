import 'package:equatable/equatable.dart';

enum TasbiehStatus { initial, ready }

class TasbiehState extends Equatable {
  const TasbiehState({
    required this.status,
    required this.count,
    required this.target,
    this.updatedAt,
  });

  const TasbiehState.initial()
    : status = TasbiehStatus.initial,
      count = 0,
      target = 33,
      updatedAt = null;

  final TasbiehStatus status;
  final int count;
  final int target;
  final DateTime? updatedAt;

  double get progress {
    if (target <= 0) {
      return 0;
    }
    return (count / target).clamp(0.0, 1.0);
  }

  bool get isComplete => count >= target;

  TasbiehState copyWith({
    TasbiehStatus? status,
    int? count,
    int? target,
    DateTime? updatedAt,
  }) {
    return TasbiehState(
      status: status ?? this.status,
      count: count ?? this.count,
      target: target ?? this.target,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [status, count, target, updatedAt];
}
