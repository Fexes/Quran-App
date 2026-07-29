import 'package:equatable/equatable.dart';

import '../../domain/entities/hifz_models.dart';

enum HifzDashboardStatus { initial, loading, success, failure }

class HifzDashboardState extends Equatable {
  const HifzDashboardState({
    required this.status,
    this.dashboard,
    this.errorMessage,
  });

  const HifzDashboardState.initial()
    : status = HifzDashboardStatus.initial,
      dashboard = null,
      errorMessage = null;

  final HifzDashboardStatus status;
  final HifzDashboard? dashboard;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, dashboard, errorMessage];
}
