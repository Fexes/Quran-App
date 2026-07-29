import 'package:equatable/equatable.dart';

enum ShellDestination { home, quran, prayer, library, settings }

class ShellState extends Equatable {
  const ShellState({
    required this.destination,
    required this.qiblaOpenRequestId,
  });

  const ShellState.initial()
    : destination = ShellDestination.home,
      qiblaOpenRequestId = 0;

  final ShellDestination destination;
  final int qiblaOpenRequestId;

  int get index => ShellDestination.values.indexOf(destination);

  ShellState copyWith({
    ShellDestination? destination,
    int? qiblaOpenRequestId,
  }) {
    return ShellState(
      destination: destination ?? this.destination,
      qiblaOpenRequestId: qiblaOpenRequestId ?? this.qiblaOpenRequestId,
    );
  }

  @override
  List<Object> get props => [destination, qiblaOpenRequestId];
}
