import 'package:equatable/equatable.dart';

import '../../domain/entities/prayer_tracking_models.dart';

enum PrayerTrackingStatus { initial, loading, success, failure }

class PrayerTrackingState extends Equatable {
  const PrayerTrackingState({
    this.status = PrayerTrackingStatus.initial,
    this.selectedDate,
    this.dashboard,
    this.errorMessage,
  });

  final PrayerTrackingStatus status;
  final DateTime? selectedDate;
  final PrayerTrackingDashboard? dashboard;
  final String? errorMessage;

  PrayerTrackingState copyWith({
    PrayerTrackingStatus? status,
    DateTime? selectedDate,
    PrayerTrackingDashboard? dashboard,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PrayerTrackingState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, selectedDate, dashboard, errorMessage];
}
